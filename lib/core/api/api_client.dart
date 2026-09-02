import 'dart:async';

import 'package:dio/dio.dart';

import '../auth/auth_storage.dart';
import '../campaign/campaign_models.dart';
import '../campaign/leaderboard_models.dart';
import '../creator_profile/creator_profile.dart';
import '../notifications/notification_models.dart';
import '../participation/participation_models.dart';
import '../update/app_version_models.dart';
import 'api_base_url.dart';

export '../campaign/campaign_models.dart';
export '../campaign/leaderboard_models.dart';
export '../notifications/notification_models.dart';
export '../participation/participation_models.dart';
export '../update/app_version_models.dart';

class ApiException implements Exception {
  ApiException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

class ApiEnvelope<T> {
  ApiEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });

  final bool success;
  final T? data;
  final Map<String, dynamic>? error;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiEnvelope(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      error: json['error'] as Map<String, dynamic>?,
    );
  }
}

typedef SessionRefreshedCallback = Future<void> Function(AuthSession session);
typedef SessionExpiredCallback = Future<void> Function();

/// Dio [RequestOptions.extra] keys (dart-flutter-patterns).
abstract final class ApiRequestExtra {
  static const auth = 'auth';
  static const skipRefresh = 'skipRefresh';
  static const isRetry = '_isRetry';
}

class ApiClient {
  ApiClient({
    AuthStorage? storage,
    SessionRefreshedCallback? onSessionRefreshed,
    SessionExpiredCallback? onSessionExpired,
    Dio? dio,
  })  : _storage = storage ?? AuthStorage(),
        _onSessionRefreshed = onSessionRefreshed,
        _onSessionExpired = onSessionExpired,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: kApiBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            ) {
    if (dio == null) {
      _attachAuthInterceptors();
    }
  }

  void _attachAuthInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra[ApiRequestExtra.auth] != false) {
            // A hung Keychain read here blocks every request before Dio's
            // own connect/receive timeouts ever get a chance to apply —
            // seen as requests (e.g. dashboard fetch) spinning forever.
            String? token;
            try {
              token = await _storage.getAccessToken().timeout(const Duration(seconds: 5));
            } catch (_) {
              token = null;
            }
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) async {
          final resolved = await _tryRefreshAndRetry(error);
          if (resolved != null) {
            handler.resolve(resolved);
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Parses API error envelopes for tests and interceptors.
  static ApiException? parseErrorEnvelope(dynamic data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['success'] == true) return null;
    final err = data['error'] as Map<String, dynamic>?;
    if (err == null) return null;
    return ApiException(
      err['code'] as String? ?? 'INTERNAL_ERROR',
      err['message'] as String? ?? 'Request failed',
    );
  }

  final Dio _dio;
  final AuthStorage _storage;
  final SessionRefreshedCallback? _onSessionRefreshed;
  final SessionExpiredCallback? _onSessionExpired;
  Future<AuthSession?>? _refreshInFlight;

  Future<Response<dynamic>?> _tryRefreshAndRetry(DioException error) async {
    final status = error.response?.statusCode;
    if (status != 401) return null;

    final extra = error.requestOptions.extra;
    if (extra[ApiRequestExtra.auth] == false ||
        extra[ApiRequestExtra.skipRefresh] == true ||
        extra[ApiRequestExtra.isRetry] == true) {
      return null;
    }

    final envelope = _errorEnvelopeFromResponse(error.response?.data);
    if (envelope?.code != 'UNAUTHORIZED') return null;

    final session = await _refreshSession();
    if (session == null) return null;

    final options = error.requestOptions;
    options.extra[ApiRequestExtra.isRetry] = true;
    options.headers['Authorization'] = 'Bearer ${session.accessToken}';
    try {
      return await _dio.fetch<dynamic>(options).timeout(_requestDeadline);
    } on DioException {
      return null;
    } on TimeoutException {
      return null;
    }
  }

  /// Forces a session refresh and returns the new access token — used by
  /// the realtime socket to get a live token when the server rejects a
  /// stale one, since (unlike REST calls) the socket has no interceptor
  /// to refresh on auth failure automatically.
  Future<String?> refreshAccessToken() async {
    final session = await _refreshSession();
    return session?.accessToken;
  }

  Future<AuthSession?> _refreshSession() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight;
    }

    _refreshInFlight = _doRefreshSession();
    try {
      return await _refreshInFlight;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<AuthSession?> _doRefreshSession() async {
    String? refresh;
    try {
      refresh = await _storage.getRefreshToken().timeout(const Duration(seconds: 5));
    } catch (_) {
      // The read itself failed or timed out (e.g. a slow Keychain unlock
      // right after app resume) — this says nothing about whether a valid
      // refresh token actually exists, so don't wipe the session over it.
      // A clean read that genuinely finds nothing (no exception, refresh
      // stays null) still falls through to the real logout below.
      return null;
    }
    if (refresh == null) {
      await _onSessionExpired?.call();
      return null;
    }

    try {
      final response = await _dio
          .post<dynamic>(
            '/auth/refresh',
            data: {'refreshToken': refresh},
            options: _options(auth: false, skipRefresh: true),
          )
          .timeout(_requestDeadline);
      final session = await _parse(
        response,
        (data) => AuthSession.fromJson(data as Map<String, dynamic>),
      );
      await _onSessionRefreshed?.call(session);
      return session;
    } on DioException catch (e) {
      // Only a genuine rejection from the server means the refresh token
      // is actually invalid/expired — log out. A network-level failure
      // (very common right after app resume, before connectivity is fully
      // back) says nothing about the token's validity, so don't wipe the
      // session over it; just fail this attempt and let the next trigger
      // retry with what's still a perfectly good refresh token.
      final envelope = _errorEnvelopeFromResponse(e.response?.data);
      if (e.response?.statusCode == 401 || envelope?.code == 'UNAUTHORIZED') {
        await _onSessionExpired?.call();
      }
      return null;
    } catch (_) {
      // Non-network failure (e.g. malformed response) — treat the same as
      // a network hiccup, not a token rejection.
      return null;
    }
  }

  /// Hard backstop so no request can hang indefinitely regardless of cause
  /// (Dio's own connect/receive timeouts don't cover time spent stuck
  /// earlier — e.g. inside an interceptor — before the request is sent).
  static const _requestDeadline = Duration(seconds: 45);

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try {
      return await call().timeout(_requestDeadline);
    } on DioException catch (e) {
      throw _mapDioError(e);
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'Request timed out. Please try again.');
    }
  }

  Options _options({bool auth = true, bool skipRefresh = false}) {
    return Options(
      extra: {
        ApiRequestExtra.auth: auth,
        ApiRequestExtra.skipRefresh: skipRefresh,
      },
    );
  }

  ApiException _mapDioError(DioException e) {
    final isEmulatorHost = kApiBaseUrl.contains('10.0.2.2');
    final deviceHint = isEmulatorHost
        ? 'On a real phone, run:\n'
            'flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3001\n'
            '(same Wi‑Fi, API running on PC)'
        : 'Check API is running at $kApiBaseUrl and firewall allows port 3001.';

    final envelope = _errorEnvelopeFromResponse(e.response?.data);
    if (envelope != null) {
      return envelope;
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'NETWORK_TIMEOUT',
          'Cannot reach the API (timed out).\n$deviceHint',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'NETWORK_ERROR',
          'Cannot connect to the API.\n$deviceHint',
        );
      default:
        final status = e.response?.statusCode;
        if (status != null) {
          return ApiException(
            'HTTP_$status',
            'Request failed ($status).',
          );
        }
        return ApiException(
          'NETWORK_ERROR',
          'Network error. $deviceHint',
        );
    }
  }

  ApiException? _errorEnvelopeFromResponse(dynamic data) =>
      ApiClient.parseErrorEnvelope(data);

  Future<T> _parse<T>(
    Response<dynamic> response,
    T Function(dynamic data) mapData,
  ) async {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw ApiException('INTERNAL_ERROR', 'Invalid response');
    }
    if (body['success'] != true) {
      final err = body['error'] as Map<String, dynamic>?;
      throw ApiException(
        err?['code'] as String? ?? 'INTERNAL_ERROR',
        err?['message'] as String? ?? 'Request failed',
      );
    }
    return mapData(body['data']);
  }

  Future<T> get<T>(
    String path,
    T Function(dynamic data) mapData, {
    bool auth = true,
    Map<String, dynamic>? query,
  }) async {
    final res = await _request(
      () => _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: _options(auth: auth),
      ),
    );
    return _parse(res, mapData);
  }

  Future<T> post<T>(
    String path,
    Object? body,
    T Function(dynamic data) mapData, {
    bool auth = true,
  }) async {
    final res = await _request(
      () => _dio.post<dynamic>(
        path,
        data: body,
        options: _options(auth: auth),
      ),
    );
    return _parse(res, mapData);
  }

  Future<T> patch<T>(
    String path,
    Object? body,
    T Function(dynamic data) mapData, {
    bool auth = true,
  }) async {
    final res = await _request(
      () => _dio.patch<dynamic>(
        path,
        data: body,
        options: _options(auth: auth),
      ),
    );
    return _parse(res, mapData);
  }

  Future<T> delete<T>(
    String path,
    T Function(dynamic data) mapData, {
    bool auth = true,
  }) async {
    final res = await _request(
      () => _dio.delete<dynamic>(
        path,
        options: _options(auth: auth),
      ),
    );
    return _parse(res, mapData);
  }

  /// Revokes refresh token on server (best-effort).
  Future<void> logoutSession() async {
    String? refresh;
    try {
      refresh = await _storage.getRefreshToken().timeout(const Duration(seconds: 5));
    } catch (_) {
      refresh = null;
    }
    if (refresh == null) return;
    try {
      await _request(
        () => _dio.post<void>(
          '/auth/logout',
          data: {'refreshToken': refresh},
          options: _options(auth: false, skipRefresh: true),
        ),
      );
    } on ApiException {
      // Still clear local session if API is unreachable.
    }
  }

  Future<void> deleteAccount() => delete<void>('/users/me', (_) {});

  // Auth
  Future<void> requestOtp(String phone) => post<void>(
        '/auth/creator/otp/request',
        {'phone': phone},
        (_) {},
        auth: false,
      );

  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    String? displayName,
    String? username,
    String? email,
  }) async {
    final data = await post<Map<String, dynamic>>(
      '/auth/creator/otp/verify',
      {
        'phone': phone,
        'code': code,
        if (displayName != null) 'displayName': displayName,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
      },
      (d) => d as Map<String, dynamic>,
      auth: false,
    );
    return AuthSession.fromJson(data);
  }

  Future<AppVersionInfo> fetchAppVersion() => get(
        '/app-version',
        (d) => AppVersionInfo.fromJson(d as Map<String, dynamic>),
        auth: false,
      );

  // Creator
  Future<CreatorDashboard> fetchDashboard({String? creatorProfileId}) => get(
        '/creator/dashboard',
        (d) => CreatorDashboard.fromJson(d as Map<String, dynamic>),
        query: creatorProfileId != null ? {'creatorProfileId': creatorProfileId} : null,
      );

  Future<List<Campaign>> fetchCampaigns() => get(
        '/creator/campaigns',
        (d) => (d as List<dynamic>)
            .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<Campaign> fetchCampaign(String id) => get(
        '/creator/campaigns/$id',
        (d) => Campaign.fromJson(d as Map<String, dynamic>),
      );

  Future<Participation> joinCampaign(
    String campaignId,
    String creatorProfileId,
  ) =>
      post(
        '/creator/campaigns/$campaignId/join',
        {'creatorProfileId': creatorProfileId},
        (d) => Participation.fromJson(d as Map<String, dynamic>),
      );

  Future<Participation> fetchParticipationByCampaign(
    String campaignId,
    String creatorProfileId,
  ) =>
      get(
        '/creator/campaigns/$campaignId/participation',
        (d) => Participation.fromJson(d as Map<String, dynamic>),
        query: {'creatorProfileId': creatorProfileId},
      );

  Future<Leaderboard> fetchLeaderboard(
    String campaignId, {
    String? creatorProfileId,
  }) =>
      get(
        '/creator/campaigns/$campaignId/leaderboard',
        (d) => Leaderboard.fromJson(d as Map<String, dynamic>),
        query: creatorProfileId != null
            ? {'creatorProfileId': creatorProfileId}
            : null,
      );

  Future<List<CreatorProfile>> fetchCreatorProfiles() => get(
        '/creator/profiles',
        (d) => (d as List<dynamic>)
            .map((e) => CreatorProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<CreatorProfile> createCreatorProfile({
    required String platform,
    required String handle,
    String? label,
  }) =>
      post(
        '/creator/profiles',
        {
          'platform': platform,
          'handle': handle,
          if (label != null && label.isNotEmpty) 'label': label,
        },
        (d) => CreatorProfile.fromJson(d as Map<String, dynamic>),
      );

  Future<void> setDefaultCreatorProfile(String id) => patch<void>(
        '/creator/profiles/$id/default',
        {},
        (_) {},
      );

  Future<void> deleteCreatorProfile(String id) => delete<void>(
        '/creator/profiles/$id',
        (_) {},
      );

  Future<Map<String, dynamic>> connectProfileSocial(
    String profileId,
    String platform,
    String handle,
  ) =>
      post(
        '/creator/profiles/$profileId/social/$platform',
        {'handle': handle},
        (d) => d as Map<String, dynamic>,
      );

  Future<void> disconnectProfileSocial(String profileId, String platform) =>
      delete<void>('/creator/profiles/$profileId/social/$platform', (_) {});

  /// Starts the Instagram Business Login OAuth handshake — returns the URL
  /// to open in a browser and a transactionId to redeem once Instagram
  /// redirects back (see [completeInstagramOAuth]).
  Future<InstagramOAuthStart> startInstagramOAuth(String profileId) => post(
        '/creator/profiles/$profileId/social/instagram/oauth/start',
        {},
        (d) => InstagramOAuthStart.fromJson(d as Map<String, dynamic>),
      );

  /// Redeems a completed OAuth transaction (the deep-link handler calls this
  /// once `halchal://instagram-callback` fires with `status=ready`).
  Future<Map<String, dynamic>> completeInstagramOAuth(
    String profileId,
    String transactionId,
  ) =>
      post(
        '/creator/profiles/$profileId/social/instagram/oauth/$transactionId/complete',
        {},
        (d) => d as Map<String, dynamic>,
      );

  Future<OverallLeaderboard> fetchOverallLeaderboard() => get(
        '/creator/leaderboard',
        (d) => OverallLeaderboard.fromJson(d as Map<String, dynamic>),
      );

  Future<List<ParticipationListItem>> fetchParticipations({
    String tab = 'active',
    String? creatorProfileId,
  }) =>
      get(
        '/creator/participations',
        (d) => (d as List<dynamic>)
            .map(
              (e) => ParticipationListItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        query: {
          'tab': tab,
          if (creatorProfileId != null) 'creatorProfileId': creatorProfileId,
        },
      );

  Future<Participation> fetchParticipation(String id) => get(
        '/creator/participations/$id',
        (d) => Participation.fromJson(d as Map<String, dynamic>),
      );

  Future<void> submitDeliverableDraft({
    required String deliverableId,
    required String draftDriveUrl,
  }) =>
      patch<void>(
        '/creator/deliverables/$deliverableId/draft',
        {'draftDriveUrl': draftDriveUrl},
        (_) {},
      );

  Future<String> uploadDraftFile({
    required String deliverableId,
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final resp = await _dio.post<Map<String, dynamic>>(
      '/creator/deliverables/$deliverableId/upload-draft',
      data: formData,
    );
    return (resp.data?['data']?['url'] as String?) ?? '';
  }

  Future<void> submitDeliverableLiveProof({
    required String deliverableId,
    required String livePostUrl,
  }) =>
      patch<void>(
        '/creator/deliverables/$deliverableId/live-proof',
        {'livePostUrl': livePostUrl},
        (_) {},
      );

  Future<Map<String, dynamic>> fetchSocialStats(String platform, String handle) {
    return post<Map<String, dynamic>>(
      '/users/me/social-stats/$platform',
      {'handle': handle},
      (d) => (d as Map<String, dynamic>?) ?? {},
    );
  }

  Future<void> disconnectSocial(String platform) {
    return delete<void>(
      '/users/me/social-stats/$platform',
      (_) {},
    );
  }

  Future<Map<String, int>> refreshDeliverableViews(String deliverableId) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/creator/deliverables/$deliverableId/refresh-views',
      options: Options(receiveTimeout: const Duration(seconds: 150)),
    );
    final body = resp.data ?? {};
    final data = (body['data'] as Map<String, dynamic>?) ?? body;
    return {
      'viewCount':    data['viewCount']    as int? ?? 0,
      'reach':        data['reach']        as int? ?? 0,
      'likeCount':    data['likeCount']    as int? ?? 0,
      'commentCount': data['commentCount'] as int? ?? 0,
      'shareCount':   data['shareCount']   as int? ?? 0,
    };
  }

  Future<WalletData> fetchWallet({String? creatorProfileId}) => get(
        '/wallet',
        (d) => WalletData.fromJson(d as Map<String, dynamic>),
        query: creatorProfileId != null ? {'creatorProfileId': creatorProfileId} : null,
      );

  Future<List<TransactionItem>> fetchTransactions() => get(
        '/wallet/transactions',
        (d) {
          final items = (d as Map<String, dynamic>)['items'] as List<dynamic>;
          return items
              .map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
              .toList();
        },
      );

  Future<List<PayoutMethod>> fetchPayoutMethods() => get(
        '/payout-methods',
        (d) => (d as List<dynamic>)
            .map((e) => PayoutMethod.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<PayoutMethod> createPayoutMethod({
    required String type,
    required String label,
    required String accountHolderName,
    required String account,
    String? ifscCode,
    String? bankName,
  }) =>
      post(
        '/payout-methods',
        {
          'type': type,
          'label': label,
          'accountHolderName': accountHolderName,
          'account': account,
          if (ifscCode != null) 'ifscCode': ifscCode,
          if (bankName != null) 'bankName': bankName,
        },
        (d) => PayoutMethod.fromJson(d as Map<String, dynamic>),
      );

  Future<PayoutMethod> updatePayoutMethod(
    String id, {
    String? accountHolderName,
    String? ifscCode,
    String? bankName,
    String? label,
  }) =>
      patch(
        '/payout-methods/$id',
        {
          if (accountHolderName != null) 'accountHolderName': accountHolderName,
          if (ifscCode != null) 'ifscCode': ifscCode,
          if (bankName != null) 'bankName': bankName,
          if (label != null) 'label': label,
        },
        (d) => PayoutMethod.fromJson(d as Map<String, dynamic>),
      );

  /// Full, decrypted account number — fetched on demand only when the user
  /// taps "reveal", never included in the regular payout methods list.
  Future<String> revealPayoutMethodAccountNumber(String id) => get(
        '/payout-methods/$id/reveal',
        (d) => (d as Map<String, dynamic>)['accountNumber'] as String,
      );

  Future<void> setDefaultPayoutMethod(String id) => patch<void>(
        '/payout-methods/$id/default',
        {},
        (_) {},
      );

  Future<void> deletePayoutMethod(String id) => delete<void>(
        '/payout-methods/$id',
        (_) {},
      );

  Future<WithdrawalResult> createWithdrawal({
    required int amountPaise,
    required String payoutMethodId,
    String? idempotencyKey,
  }) =>
      post(
        '/withdrawals',
        {
          'amountPaise': amountPaise,
          'payoutMethodId': payoutMethodId,
          if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
        },
        (d) => WithdrawalResult.fromJson(d as Map<String, dynamic>),
      );

  Future<SupportTicket> createSupportTicket({
    required String subject,
    required String message,
  }) =>
      post(
        '/support/tickets',
        {'subject': subject, 'message': message},
        (d) => SupportTicket.fromJson(d as Map<String, dynamic>),
      );

  Future<List<SupportTicket>> fetchSupportTickets() => get(
        '/support/tickets',
        (d) => (d as List<dynamic>)
            .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<List<Faq>> fetchFaqs() => get(
        '/faqs',
        (d) => (d as List<dynamic>)
            .map((e) => Faq.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Future<Map<String, dynamic>> fetchMe() => get(
        '/users/me',
        (d) => d as Map<String, dynamic>,
      );

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? phone,
    String? bio,
    String? avatarUrl,
    Map<String, String>? socialLinks,
  }) =>
      patch(
        '/users/me',
        {
          if (displayName != null) 'displayName': displayName,
          if (phone != null) 'phone': phone,
          if (bio != null) 'bio': bio,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (socialLinks != null) 'socialLinks': socialLinks,
        },
        (d) => d as Map<String, dynamic>,
      );

  Future<String> uploadAvatar({
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final resp = await _dio.post<Map<String, dynamic>>(
      '/users/me/avatar',
      data: formData,
    );
    return (resp.data?['data']?['url'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> submitKyc({
    required String filePath,
    required String fileName,
    required String mimeType,
    String documentType = 'id_proof',
  }) async {
    final formData = FormData.fromMap({
      'documentType': documentType,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
        contentType: DioMediaType.parse(mimeType),
      ),
    });
    final resp = await _dio.post<Map<String, dynamic>>(
      '/users/me/kyc',
      data: formData,
    );
    return (resp.data?['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<List<AppNotification>> fetchNotifications({bool unreadOnly = false}) =>
      get(
        '/notifications',
        (d) => (d as List<dynamic>)
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList(),
        query: unreadOnly ? {'unreadOnly': 'true'} : null,
      );

  Future<int> fetchUnreadNotificationCount() => get(
        '/notifications/unread-count',
        (d) => (d as Map<String, dynamic>)['count'] as int? ?? 0,
      );

  Future<void> markNotificationRead(String id) => patch<void>(
        '/notifications/$id/read',
        {},
        (_) {},
      );

  Future<void> markAllNotificationsRead() => patch<void>(
        '/notifications/read-all',
        {},
        (_) {},
      );

  /// Registers a push device token. Not called anywhere yet — there's no
  /// Firebase/APNs SDK in the app to produce a real token from. Wire this up
  /// once `firebase_messaging` is added with real Firebase config files.
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) =>
      post<void>(
        '/users/me/device-token',
        {'token': token, 'platform': platform},
        (_) {},
      );
}

class InstagramOAuthStart {
  InstagramOAuthStart({required this.authorizationUrl, required this.transactionId});
  final String authorizationUrl;
  final String transactionId;

  factory InstagramOAuthStart.fromJson(Map<String, dynamic> json) => InstagramOAuthStart(
        authorizationUrl: json['authorizationUrl'] as String,
        transactionId: json['transactionId'] as String,
      );
}

class AuthSession {
  AuthSession({required this.accessToken, required this.refreshToken, required this.user});
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    return AuthSession(
      accessToken: tokens['accessToken'] as String,
      refreshToken: tokens['refreshToken'] as String,
      user: json['user'] as Map<String, dynamic>,
    );
  }
}

class SocialLinks {
  const SocialLinks({
    required this.instagram,
    required this.youtube,
    required this.twitter,
  });

  final bool instagram;
  final bool youtube;
  final bool twitter;

  factory SocialLinks.fromJson(Map<String, dynamic>? json) => SocialLinks(
        instagram: json?['instagram'] as bool? ?? false,
        youtube: json?['youtube'] as bool? ?? false,
        twitter: json?['twitter'] as bool? ?? false,
      );
}

class CreatorDashboard {
  CreatorDashboard({
    required this.wallet,
    required this.clipsUnderReview,
    required this.socialLinks,
    required this.trending,
  });

  final WalletData wallet;
  final int clipsUnderReview;
  final SocialLinks socialLinks;
  final List<Campaign> trending;

  factory CreatorDashboard.fromJson(Map<String, dynamic> json) {
    return CreatorDashboard(
      wallet: WalletData.fromJson(json['wallet'] as Map<String, dynamic>),
      clipsUnderReview: json['clipsUnderReview'] as int? ?? 0,
      socialLinks: SocialLinks.fromJson(
        json['socialLinks'] as Map<String, dynamic>?,
      ),
      trending: (json['trending'] as List<dynamic>? ?? [])
          .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WalletData {
  WalletData({
    required this.availablePaise,
    required this.pendingPaise,
    required this.lifetimePaise,
    this.clipsUnderReview = 0,
  });

  final int availablePaise;
  final int pendingPaise;
  final int lifetimePaise;
  final int clipsUnderReview;

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
        availablePaise: json['availablePaise'] as int? ?? 0,
        pendingPaise: json['pendingPaise'] as int? ?? 0,
        lifetimePaise: json['lifetimePaise'] as int? ?? 0,
        clipsUnderReview: json['clipsUnderReview'] as int? ?? 0,
      );
}

class TransactionItem {
  TransactionItem({required this.type, required this.amountPaise, required this.createdAt, this.note});
  final String type;
  final int amountPaise;
  final String createdAt;
  final String? note;

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        type: json['type'] as String,
        amountPaise: json['amountPaise'] as int,
        createdAt: json['createdAt'] as String,
        note: json['note'] as String?,
      );
}

class PayoutMethod {
  PayoutMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.accountHolderName,
    required this.accountMasked,
    this.ifscCode,
    this.bankName,
    required this.isDefault,
  });
  final String id;
  final String type;
  final String label;
  final String accountHolderName;
  final String accountMasked;
  final String? ifscCode;
  final String? bankName;
  final bool isDefault;

  factory PayoutMethod.fromJson(Map<String, dynamic> json) => PayoutMethod(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'bank',
        label: json['label'] as String,
        accountHolderName: json['accountHolderName'] as String? ?? '',
        accountMasked: json['accountMasked'] as String,
        ifscCode: json['ifscCode'] as String?,
        bankName: json['bankName'] as String?,
        isDefault: json['isDefault'] as bool? ?? false,
      );
}

class WithdrawalResult {
  WithdrawalResult({required this.netPaise, required this.feePaise});
  final int netPaise;
  final int feePaise;

  factory WithdrawalResult.fromJson(Map<String, dynamic> json) =>
      WithdrawalResult(
        netPaise: json['netPaise'] as int,
        feePaise: json['feePaise'] as int,
      );
}

class SupportTicket {
  SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    this.resolutionNote,
    this.resolvedAt,
    required this.createdAt,
  });
  final String id;
  final String subject;
  final String message;
  final String status;
  final String? resolutionNote;
  final String? resolvedAt;
  final String createdAt;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: json['id'] as String,
        subject: json['subject'] as String,
        message: json['message'] as String,
        status: json['status'] as String,
        resolutionNote: json['resolutionNote'] as String?,
        resolvedAt: json['resolvedAt'] as String?,
        createdAt: json['createdAt'] as String,
      );
}

class Faq {
  Faq({required this.id, required this.question, required this.answer});
  final String id;
  final String question;
  final String answer;

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        id: json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}
