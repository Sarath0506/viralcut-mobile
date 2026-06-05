import 'package:dio/dio.dart';

import '../auth/auth_storage.dart';
import 'api_base_url.dart';

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

class ApiClient {
  ApiClient({AuthStorage? storage})
      : _storage = storage ?? AuthStorage(),
        _dio = Dio(
          BaseOptions(
            baseUrl: kApiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  final Dio _dio;
  final AuthStorage _storage;

  Future<Response<dynamic>> _request(Future<Response<dynamic>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiException _mapDioError(DioException e) {
    final isEmulatorHost = kApiBaseUrl.contains('10.0.2.2');
    final deviceHint = isEmulatorHost
        ? 'On a real phone, run:\n'
            'flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3001\n'
            '(same Wi‑Fi, API running on PC)'
        : 'Check API is running at $kApiBaseUrl and firewall allows port 3001.';

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
    final headers = auth ? await _authHeaders() : null;
    final res = await _request(
      () => _dio.get<dynamic>(
        path,
        queryParameters: query,
        options: Options(headers: headers),
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
    final headers = auth ? await _authHeaders() : null;
    final res = await _request(
      () => _dio.post<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
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
    final headers = auth ? await _authHeaders() : null;
    final res = await _request(
      () => _dio.patch<dynamic>(
        path,
        data: body,
        options: Options(headers: headers),
      ),
    );
    return _parse(res, mapData);
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      throw ApiException('UNAUTHORIZED', 'Not logged in');
    }
    return {'Authorization': 'Bearer $token'};
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
          options: Options(headers: {'Content-Type': 'application/json'}),
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
  }) async {
    final data = await post<Map<String, dynamic>>(
      '/auth/creator/otp/verify',
      {
        'phone': phone,
        'code': code,
        if (displayName != null) 'displayName': displayName,
        if (username != null) 'username': username,
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

  Future<List<SubmissionItem>> fetchSubmissions({String tab = 'active'}) =>
      get(
        '/creator/submissions',
        (d) => (d as List<dynamic>)
            .map((e) => SubmissionItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        query: {'tab': tab},
      );

  Future<SubmissionDetail> fetchSubmission(String id) => get(
        '/creator/submissions/$id',
        (d) => SubmissionDetail.fromJson(d as Map<String, dynamic>),
      );

  Future<void> createSubmission({
    required String campaignId,
    required String draftDriveUrl,
  }) =>
      post<Map<String, dynamic>>(
        '/creator/submissions',
        {'campaignId': campaignId, 'draftDriveUrl': draftDriveUrl},
        (d) => d as Map<String, dynamic>,
      );

  Future<void> submitLiveLink({
    required String submissionId,
    required String liveReelUrl,
  }) =>
      patch<void>(
        '/creator/submissions/$submissionId/live-link',
        {'liveReelUrl': liveReelUrl},
        (_) {},
      );

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

class CreatorDashboard {
  CreatorDashboard({required this.wallet, required this.clipsUnderReview, required this.trending});
  final WalletData wallet;
  final int clipsUnderReview;
  final List<Campaign> trending;

  factory CreatorDashboard.fromJson(Map<String, dynamic> json) {
    return CreatorDashboard(
      wallet: WalletData.fromJson(json['wallet'] as Map<String, dynamic>),
      clipsUnderReview: json['clipsUnderReview'] as int? ?? 0,
      trending: (json['trending'] as List<dynamic>? ?? [])
          .map((e) => Campaign.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Campaign {
  Campaign({
    required this.id,
    required this.title,
    required this.ratePer1kDisplay,
    required this.maxPayoutPaise,
    required this.poolPercent,
    required this.brief,
    this.category,
    this.productUrl,
  });

  final String id;
  final String title;
  final String ratePer1kDisplay;
  final int maxPayoutPaise;
  final int poolPercent;
  final String brief;
  final String? category;
  final String? productUrl;

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as String,
        title: json['title'] as String,
        ratePer1kDisplay: json['ratePer1kDisplay'] as String,
        maxPayoutPaise: json['maxPayoutPaise'] as int,
        poolPercent: json['poolPercent'] as int? ?? 0,
        brief: json['brief'] as String? ?? '',
        category: json['category'] as String?,
        productUrl: json['productUrl'] as String?,
      );
}

class SubmissionItem {
  SubmissionItem({
    required this.id,
    required this.status,
    required this.campaignTitle,
    required this.estimatedPaise,
  });

  final String id;
  final String status;
  final String campaignTitle;
  final int estimatedPaise;

  factory SubmissionItem.fromJson(Map<String, dynamic> json) => SubmissionItem(
        id: json['id'] as String,
        status: json['status'] as String,
        campaignTitle: json['campaignTitle'] as String,
        estimatedPaise: json['estimatedPaise'] as int? ?? 0,
      );
}

class SubmissionDetail {
  SubmissionDetail({
    required this.id,
    required this.status,
    required this.ratePer1kDisplay,
    required this.eligibleViews,
    required this.estimatedPaise,
    this.liveReelUrl,
    this.rejectionReason,
  });

  final String id;
  final String status;
  final String ratePer1kDisplay;
  final int eligibleViews;
  final int estimatedPaise;
  final String? liveReelUrl;
  final String? rejectionReason;

  factory SubmissionDetail.fromJson(Map<String, dynamic> json) =>
      SubmissionDetail(
        id: json['id'] as String,
        status: json['status'] as String,
        ratePer1kDisplay: json['ratePer1kDisplay'] as String? ?? '',
        eligibleViews: json['eligibleViews'] as int? ?? 0,
        estimatedPaise: json['estimatedPaise'] as int? ?? 0,
        liveReelUrl: json['liveReelUrl'] as String?,
        rejectionReason: json['rejectionReason'] as String?,
      );
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
