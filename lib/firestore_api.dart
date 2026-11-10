import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'user_model.dart';

/// Goi Firestore bang REST API (khong can cai SDK/native, chay duoc web + Android + iOS).
class FirestoreApi {
  static String get _base =>
      'https://firestore.googleapis.com/v1/projects/$kProjectId/databases/(default)/documents/users';

  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  static void _check(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    String status = '';
    String msg = '';
    try {
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final e = j['error'] as Map<String, dynamic>;
      status = (e['status'] ?? '').toString();
      msg = (e['message'] ?? '').toString();
    } catch (_) {}
    if (status == 'PERMISSION_DENIED') {
      throw Exception('Firestore chưa mở quyền. Vào Firebase > Firestore Database > Rules, đặt "allow read, write: if true;" rồi Publish.');
    }
    if (msg.contains('API key not valid') || status == 'INVALID_ARGUMENT' && msg.contains('API key')) {
      throw Exception('API key sai. Kiểm tra lại kApiKey trong lib/config.dart.');
    }
    if (status == 'NOT_FOUND' || r.statusCode == 404) {
      throw Exception('Chưa tạo Firestore Database hoặc sai Project ID (kProjectId).');
    }
    throw Exception('Lỗi ${r.statusCode}: $msg');
  }

  static Future<List<AppUser>> list() async {
    final out = <AppUser>[];
    String? token;
    do {
      final url = '$_base?pageSize=100&key=$kApiKey${token == null ? '' : '&pageToken=$token'}';
      final r = await http.get(Uri.parse(url));
      _check(r);
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      for (final d in (j['documents'] as List? ?? [])) {
        out.add(AppUser.fromDoc(d as Map<String, dynamic>));
      }
      token = j['nextPageToken'] as String?;
    } while (token != null);
    return out;
  }

  static Future<void> create(AppUser u) async {
    final r = await http.post(
      Uri.parse('$_base?key=$kApiKey'),
      headers: _headers,
      body: jsonEncode({'fields': u.toFields()}),
    );
    _check(r);
  }

  static Future<void> update(AppUser u) async {
    const mask = 'updateMask.fieldPaths=email&updateMask.fieldPaths=matkhau&updateMask.fieldPaths=hoten&updateMask.fieldPaths=hinhanh';
    final r = await http.patch(
      Uri.parse('$_base/${u.id}?key=$kApiKey&$mask'),
      headers: _headers,
      body: jsonEncode({'fields': u.toFields()}),
    );
    _check(r);
  }

  static Future<void> delete(String id) async {
    final r = await http.delete(Uri.parse('$_base/$id?key=$kApiKey'));
    _check(r);
  }
}
