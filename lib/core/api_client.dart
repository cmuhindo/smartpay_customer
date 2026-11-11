import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

class CustomerLoginResult {
  final UserProfile user;
  final bool mustChangePassword;

  const CustomerLoginResult({
    required this.user,
    required this.mustChangePassword,
  });
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.smartpayug.com/api',
  );

  final http.Client _client;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> get token => _storage.read(key: 'smartpay_token');

  Future<Map<String, String>> _headers() async {
    final accessToken = await token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  Future<dynamic> _request(
      String method,
      String path, {
        Map<String, dynamic>? body,
      }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _headers();
    late http.Response response;

    switch (method) {
      case 'POST':
        response = await _client.post(uri, headers: headers, body: jsonEncode(body ?? {}));
        break;
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      default:
        throw UnsupportedError('Unsupported HTTP method: $method');
    }

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? {} : jsonDecode(response.body);
    } catch (_) {
      decoded = {'message': response.body};
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? (decoded['message'] ?? decoded['errors']?.toString() ?? 'Request failed')
          : 'Request failed';
      throw ApiException(response.statusCode, message.toString());
    }

    return decoded;
  }

  Future<CustomerLoginResult> login({
    required String phoneNumber,
    required String password,
    required String deviceName,
  }) async {
    final result = await _request('POST', '/customer/login', body: {
      'phone_number': phoneNumber,
      'password': password,
      'device_name': deviceName,
    }) as Map<String, dynamic>;

    await _storage.write(
      key: 'smartpay_token',
      value: result['token'] as String,
    );

    final userJson = Map<String, dynamic>.from(
      result['user'] as Map<String, dynamic>,
    );
    userJson['must_change_password'] =
        result['must_change_password'] as bool? ??
            userJson['must_change_password'] as bool? ??
            false;

    final user = UserProfile.fromJson(userJson);
    if (user.mustChangePassword) {
      await _storage.delete(key: 'smartpay_user');
    } else {
      await _storage.write(
        key: 'smartpay_user',
        value: jsonEncode(user.toJson()),
      );
    }

    return CustomerLoginResult(
      user: user,
      mustChangePassword: user.mustChangePassword,
    );
  }

  Future<UserProfile> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final result = await _request('POST', '/customer/password/change', body: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    }) as Map<String, dynamic>;

    final userJson = Map<String, dynamic>.from(
      result['user'] as Map<String, dynamic>,
    );
    userJson['must_change_password'] = false;

    final user = UserProfile.fromJson(userJson);
    await _storage.write(
      key: 'smartpay_user',
      value: jsonEncode(user.toJson()),
    );

    return user;
  }

  Future<UserProfile> me() async {
    final result = await _request('GET', '/customer/me') as Map<String, dynamic>;
    final user = UserProfile.fromJson(result);
    await _storage.write(
      key: 'smartpay_user',
      value: jsonEncode(user.toJson()),
    );
    return user;
  }

  Future<UserProfile?> cachedUser() async {
    final raw = await _storage.read(key: 'smartpay_user');
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearLocalSession() async {
    await _storage.delete(key: 'smartpay_token');
    await _storage.delete(key: 'smartpay_user');
  }

  Future<void> logout() async {
    try {
      await _request('POST', '/customer/logout');
    } finally {
      await clearLocalSession();
    }
  }

  Future<List<Loan>> loans() async {
    final result = await _request('GET', '/customer/loans') as Map<String, dynamic>;
    final data = (result['data'] as List<dynamic>? ?? const []);
    return data.map((item) => Loan.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Loan> loan(int id) async {
    final result = await _request('GET', '/customer/loans/$id') as Map<String, dynamic>;
    return Loan.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<List<CustomerCase>> cases() async {
    final result = await _request('GET', '/customer/cases') as Map<String, dynamic>;
    final data = (result['data'] as List<dynamic>? ?? const []);
    return data.map((item) => CustomerCase.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CustomerCaseDetail> caseDetail(int id) async {
    final result = await _request('GET', '/customer/cases/$id') as Map<String, dynamic>;
    return CustomerCaseDetail.fromJson(result['data'] as Map<String, dynamic>);
  }

  Future<PaymentAttempt> initiateRepayment({
    required int loanId,
    required double amount,
    required String phoneNumber,
  }) async {
    final result = await _request('POST', '/customer/loans/$loanId/repayments', body: {
      'amount': amount,
      'payer_phone_number': phoneNumber,
    }) as Map<String, dynamic>;
    return PaymentAttempt.fromJson(result);
  }

  Future<PaymentAttempt> repaymentStatus({
    required int loanId,
    required int paymentId,
  }) async {
    final result = await _request(
      'GET',
      '/customer/loans/$loanId/repayments/$paymentId/status',
    ) as Map<String, dynamic>;
    return PaymentAttempt.fromJson(result);
  }
}
