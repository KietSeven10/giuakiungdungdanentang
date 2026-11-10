import 'dart:convert';
import 'dart:typed_data';

/// Chi co DUNG 4 truong: email, matkhau, hoten, hinhanh (theo yeu cau de thi).
/// id la ten tai lieu (document id) do Firestore tu sinh, khong phai truong du lieu.
class AppUser {
  final String id;
  final String email;
  final String matkhau; // luu dang bam SHA-256
  final String hoten;
  final String hinhanh; // anh ma hoa base64 ('' neu chua co)
  Uint8List? _bytes;

  AppUser({
    this.id = '',
    required this.email,
    required this.matkhau,
    required this.hoten,
    this.hinhanh = '',
  });

  Uint8List? get imageBytes {
    if (hinhanh.isEmpty) return null;
    try {
      return _bytes ??= base64Decode(hinhanh);
    } catch (_) {
      return null;
    }
  }

  factory AppUser.fromDoc(Map<String, dynamic> d) {
    final f = (d['fields'] as Map<String, dynamic>?) ?? {};
    String s(String k) => ((f[k] as Map<String, dynamic>?)?['stringValue'] as String?) ?? '';
    final name = (d['name'] as String?) ?? '';
    return AppUser(
      id: name.split('/').last,
      email: s('email'),
      matkhau: s('matkhau'),
      hoten: s('hoten'),
      hinhanh: s('hinhanh'),
    );
  }

  Map<String, dynamic> toFields() => {
        'email': {'stringValue': email},
        'matkhau': {'stringValue': matkhau},
        'hoten': {'stringValue': hoten},
        'hinhanh': {'stringValue': hinhanh},
      };
}
