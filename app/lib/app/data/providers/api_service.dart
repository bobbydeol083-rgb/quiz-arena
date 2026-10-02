import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/values/app_config.dart';

/// Thrown for every API failure. [isNetworkError] is true when the backend
/// could not be reached at all (offline / wrong URL) — repositories use it
/// to switch to the offline fallback instead of showing an error.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  bool get isNetworkError => statusCode == null;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// HTTP client implementing the QuizArena backend contract exactly:
/// POST /api/auth/register|login|refresh, GET /api/auth/me,
/// GET /api/categories, GET /api/questions, POST /api/quiz/submit,
/// GET /api/leaderboard, GET /api/users/:id,
/// POST /api/players/location, GET /api/players/nearby, POST /api/rooms.
class ApiService {
  final http.Client _client;
  final String _baseUrlOverride;

  /// Current bearer token (set by AuthRepository after login / refresh).
  String? authToken;

  /// Hook used to transparently refresh an expired token on 401.
  /// Returns the new token, or null when refresh failed.
  Future<String?> Function()? onRefreshToken;

  static const Duration timeout = Duration(seconds: 12);

  ApiService({String? baseUrl, http.Client? client})
      : _baseUrlOverride = baseUrl ?? '',
        _client = client ?? http.Client();

  String get baseUrl =>
      _baseUrlOverride.isNotEmpty ? _baseUrlOverride : AppConfig.apiBase;

  /// Builds `baseUrl + path?query`. Public so URL construction is unit
  /// testable without hitting the network.
  Uri buildUri(String path, [Map<String, String>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters: query?.isEmpty == true ? null : query,
    );
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json'};
    final token = authToken;
    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _decode(http.Response res) {
    if (res.body.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(res.body);
    } on FormatException {
      throw ApiException('Invalid server response', res.statusCode);
    }
  }

  Never _throwForStatus(http.Response res) {
    String message = 'Request failed (${res.statusCode})';
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['message'] is String) {
        message = body['message'] as String;
      } else if (body is Map && body['error'] is String) {
        message = body['error'] as String;
      }
    } catch (_) {}
    throw ApiException(message, res.statusCode);
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool auth = true,
    bool retried = false,
  }) async {
    late http.Response res;
    try {
      res = await request().timeout(timeout);
    } on SocketException {
      throw const ApiException(
          'Could not reach the server. Check your connection.');
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on HttpException catch (e) {
      throw ApiException('Network error: ${e.message}');
    }

    if (res.statusCode == 401 && auth && !retried && onRefreshToken != null) {
      final fresh = await onRefreshToken!();
      if (fresh != null && fresh.isNotEmpty) {
        authToken = fresh;
        return _send(request, auth: auth, retried: true);
      }
    }
    return res;
  }

  Future<dynamic> getJson(String path,
      {Map<String, String>? query, bool auth = true}) async {
    final res = await _send(
      () => _client.get(buildUri(path, query), headers: _headers(auth: auth)),
      auth: auth,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return _decode(res);
    _throwForStatus(res);
  }

  Future<dynamic> postJson(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await _send(
      () => _client.post(
        buildUri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
      auth: auth,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return _decode(res);
    _throwForStatus(res);
  }

  Future<dynamic> putJson(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await _send(
      () => _client.put(
        buildUri(path),
        headers: _headers(auth: auth),
        body: body == null ? null : jsonEncode(body),
      ),
      auth: auth,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return _decode(res);
    _throwForStatus(res);
  }

  Future<dynamic> deleteJson(String path, {bool auth = true}) async {
    final res = await _send(
      () => _client.delete(buildUri(path), headers: _headers(auth: auth)),
      auth: auth,
    );
    if (res.statusCode >= 200 && res.statusCode < 300) return _decode(res);
    _throwForStatus(res);
  }

  // ---- Auth -------------------------------------------------------------
  Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final json =
        await postJson('/auth/register', auth: false, body: {
      'username': username,
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final json = await postJson('/auth/login', auth: false, body: {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final json = await postJson('/auth/refresh', auth: false, body: {
      'refreshToken': refreshToken,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final json = await getJson('/auth/me');
    return Map<String, dynamic>.from(json as Map);
  }

  // ---- Content ------------------------------------------------------------
  Future<List<Map<String, dynamic>>> categories() async {
    final json = await getJson('/categories', auth: false);
    final list = json is List ? json : (json['categories'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<List<Map<String, dynamic>>> questions({
    String? category,
    String? difficulty,
    int count = 10,
  }) async {
    final query = <String, String>{'count': '$count'};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (difficulty != null && difficulty.isNotEmpty) {
      query['difficulty'] = difficulty;
    }
    final json = await getJson('/questions', query: query, auth: false);
    final list = json is List ? json : (json['questions'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> submitQuiz({
    required String mode,
    String? category,
    String? difficulty,
    required List<Map<String, dynamic>> answers,
    required String startedAt,
  }) async {
    final json = await postJson('/quiz/submit', body: {
      'mode': mode,
      'category': category,
      'difficulty': difficulty,
      'answers': answers,
      'startedAt': startedAt,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> leaderboard({
    String scope = 'weekly',
    int limit = 50,
  }) async {
    final json = await getJson('/leaderboard',
        query: {'scope': scope, 'limit': '$limit'}, auth: false);
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> userProfile(String id) async {
    final json = await getJson('/users/$id');
    return Map<String, dynamic>.from(json as Map);
  }

  // ---- Game Packs (custom publishable games) -------------------------------
  Future<Map<String, dynamic>> packsBrowse({
    String? search,
    String? mode,
    String sort = 'popular',
    int page = 1,
    int limit = 20,
  }) async {
    final query = <String, String>{
      'sort': sort,
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();
    if (mode != null && mode.isNotEmpty) query['mode'] = mode;
    final json = await getJson('/packs', query: query, auth: false);
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> packsMine() async {
    final json = await getJson('/packs/mine');
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> packDetail(String id) async {
    final json = await getJson('/packs/$id');
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> packCreate(Map<String, dynamic> body) async {
    final json = await postJson('/packs', body: body);
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> packUpdate(String id, Map<String, dynamic> body) async {
    final json = await putJson('/packs/$id', body: body);
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> packPublish(String id) async {
    final json = await postJson('/packs/$id/publish');
    return Map<String, dynamic>.from(json as Map);
  }

  Future<Map<String, dynamic>> packUnpublish(String id) async {
    final json = await postJson('/packs/$id/unpublish');
    return Map<String, dynamic>.from(json as Map);
  }

  Future<void> packDelete(String id) async {
    await deleteJson('/packs/$id');
  }

  Future<Map<String, dynamic>> packInstall(String id) async {
    final json = await postJson('/packs/$id/install');
    return Map<String, dynamic>.from(json as Map);
  }

  Future<void> packPlayed(String id) async {
    try {
      await postJson('/packs/$id/played');
    } catch (_) {
      // Best-effort counter; never block the UI.
    }
  }

  // ---- Social ---------------------------------------------------------------
  Future<Map<String, dynamic>> postLocation(double lng, double lat) async {
    final json = await postJson('/players/location', body: {
      'lng': lng,
      'lat': lat,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  Future<List<Map<String, dynamic>>> nearbyPlayers({
    int maxDistance = 5000,
    int limit = 20,
  }) async {
    final json = await getJson('/players/nearby',
        query: {'maxDistance': '$maxDistance', 'limit': '$limit'});
    final list = json is List ? json : (json['players'] as List? ?? []);
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createRoom({
    required String mode,
    String? category,
  }) async {
    final json = await postJson('/rooms', body: {
      'mode': mode,
      'category': category,
    });
    return Map<String, dynamic>.from(json as Map);
  }

  void close() => _client.close();
}
