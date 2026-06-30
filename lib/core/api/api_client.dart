import 'package:dio/dio.dart';

import '../auth/auth_storage.dart';
import '../campaign/campaign_models.dart';
import '../participation/participation_models.dart';
import 'api_base_url.dart';

export '../campaign/campaign_models.dart';
export '../participation/participation_models.dart';

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
            final token = await _storage.getAccessToken();
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
      return await _dio.fetch<dynamic>(options);
    } on DioException {
      return null;
    }
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
    final refresh = await _storage.getRefreshToken();
    if (refresh == null) {
      await _onSessionExpired?.call();
      return null;
    }

    try {
      final response = await _dio.post<dynamic>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
        options: _options(auth: false, skipRefresh: true),
      );
      final session = await _parse(
        response,
        (data) => AuthSession.fromJson(data as Map<String, dynamic>),
      );
      await _onSessionRefreshed?.call(session);
      return session;
    } catch (_) {
      await _onSessionExpired?.call();
      return null;
    }
  }

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioError(e);
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

  /// Revokes refresh token on server (best-effort).
  Future<void> logoutSession() async {
    final refresh = await _storage.getRefreshToken();
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

  // Creator
  Future<CreatorDashboard> fetchDashboard() => get(
        '/creator/dashboard',
        (d) => CreatorDashboard.fromJson(d as Map<String, dynamic>),
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

  Future<Participation> joinCampaign(String campaignId) => post(
        '/creator/campaigns/$campaignId/join',
        {},
        (d) => Participation.fromJson(d as Map<String, dynamic>),
      );

  Future<Participation> fetchParticipationByCampaign(String campaignId) =>
      get(
        '/creator/campaigns/$campaignId/participation',
        (d) => Participation.fromJson(d as Map<String, dynamic>),
      );

  Future<List<ParticipationListItem>> fetchParticipations({
    String tab = 'active',
  }) =>
      get(
        '/creator/participations',
        (d) => (d as List<dynamic>)
            .map(
              (e) => ParticipationListItem.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        query: {'tab': tab},
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

  Future<Map<String, int>> refreshDeliverableViews(String deliverableId) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/creator/deliverables/$deliverableId/refresh-views',
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

  Future<WalletData> fetchWallet() => get(
        '/wallet',
        (d) => WalletData.fromJson(d as Map<String, dynamic>),
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

  Future<Map<String, dynamic>> fetchMe() => get(
        '/users/me',
        (d) => d as Map<String, dynamic>,
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
  });

  final int availablePaise;
  final int pendingPaise;
  final int lifetimePaise;

  factory WalletData.fromJson(Map<String, dynamic> json) => WalletData(
        availablePaise: json['availablePaise'] as int? ?? 0,
        pendingPaise: json['pendingPaise'] as int? ?? 0,
        lifetimePaise: json['lifetimePaise'] as int? ?? 0,
      );
}

class TransactionItem {
  TransactionItem({required this.type, required this.amountPaise, required this.createdAt});
  final String type;
  final int amountPaise;
  final String createdAt;

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        type: json['type'] as String,
        amountPaise: json['amountPaise'] as int,
        createdAt: json['createdAt'] as String,
      );
}

class PayoutMethod {
  PayoutMethod({required this.id, required this.label, required this.accountMasked});
  final String id;
  final String label;
  final String accountMasked;

  factory PayoutMethod.fromJson(Map<String, dynamic> json) => PayoutMethod(
        id: json['id'] as String,
        label: json['label'] as String,
        accountMasked: json['accountMasked'] as String,
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
