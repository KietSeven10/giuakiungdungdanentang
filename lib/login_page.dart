import 'package:flutter/material.dart';
import 'config.dart';
import 'firestore_api.dart';
import 'state.dart';
import 'user_model.dart';
import 'users_page.dart';
import 'util.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'admin@gmail.com');
  final _pass = TextEditingController(text: '123456');
  bool _hide = true;
  bool _busy = false;

  Future<void> _login() async {
    if (configMissing) {
      showMsg(context, 'Chưa cấu hình Firebase: sửa kProjectId và kApiKey trong lib/config.dart');
      return;
    }
    if (!isValidEmail(_email.text) || _pass.text.isEmpty) {
      showMsg(context, 'Vui lòng nhập email hợp lệ và mật khẩu');
      return;
    }
    setState(() => _busy = true);
    try {
      final users = await FirestoreApi.list();
      final e = _email.text.trim().toLowerCase();
      final h = hashPassword(_pass.text);
      AppUser? found;
      for (final u in users) {
        if (u.email.toLowerCase() == e && u.matkhau == h) found = u;
      }
      if (!mounted) return;
      if (found == null) {
        showMsg(context, users.isEmpty
            ? 'Chưa có dữ liệu. Bấm "Khởi tạo dữ liệu mẫu" bên dưới (chỉ làm lần đầu).'
            : 'Sai email hoặc mật khẩu');
      } else {
        AppState.current = found;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const UsersPage()));
        return;
      }
    } catch (e) {
      if (mounted) showMsg(context, errText(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _seed() async {
    if (configMissing) {
      showMsg(context, 'Chưa cấu hình Firebase: sửa kProjectId và kApiKey trong lib/config.dart');
      return;
    }
    setState(() => _busy = true);
    try {
      final users = await FirestoreApi.list();
      if (users.isNotEmpty) {
        if (mounted) showMsg(context, 'Cơ sở dữ liệu đã có ${users.length} người dùng, không cần khởi tạo.');
      } else {
        final seed = [
          ['admin@gmail.com', '123456', 'Quản trị viên'],
          ['quan.le@gmail.com', '123456', 'Lê Quân'],
          ['hoa.nguyen@gmail.com', '123456', 'Nguyễn Thị Hoa'],
        ];
        for (final s in seed) {
          await FirestoreApi.create(AppUser(email: s[0], matkhau: hashPassword(s[1]), hoten: s[2]));
        }
        if (mounted) showMsg(context, 'Đã tạo 3 tài khoản mẫu. Đăng nhập: admin@gmail.com / 123456');
      }
    } catch (e) {
      if (mounted) showMsg(context, errText(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.admin_panel_settings, size: 64, color: cs.primary),
                  const SizedBox(height: 8),
                  Text('Quản lý người dùng', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text('Đăng nhập phân hệ Admin'),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _hide,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _busy ? null : _seed, child: const Text('Khởi tạo dữ liệu mẫu (lần đầu)')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
