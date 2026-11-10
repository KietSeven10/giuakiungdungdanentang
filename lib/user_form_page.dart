import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'firestore_api.dart';
import 'user_model.dart';
import 'util.dart';

class UserFormPage extends StatefulWidget {
  final AppUser? user; // null = them moi
  final List<AppUser> all;
  const UserFormPage({super.key, this.user, required this.all});
  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.user?.email ?? '');
  late final TextEditingController _hoten = TextEditingController(text: widget.user?.hoten ?? '');
  final TextEditingController _pass = TextEditingController();
  late String _hinhanh = widget.user?.hinhanh ?? '';
  Uint8List? _preview;
  bool _hide = true;
  bool _saving = false;

  bool get isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _preview = widget.user?.imageBytes;
  }

  Future<void> _chooseSource() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Chọn từ thư viện / máy tính'),
            onTap: () => Navigator.pop(c, ImageSource.gallery),
          ),
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Chụp ảnh bằng camera'),
              onTap: () => Navigator.pop(c, ImageSource.camera),
            ),
          if (_hinhanh.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Xóa ảnh'),
              onTap: () {
                Navigator.pop(c);
                setState(() {
                  _hinhanh = '';
                  _preview = null;
                });
              },
            ),
        ]),
      ),
    );
    if (src == null) return;
    try {
      final x = await ImagePicker().pickImage(source: src, maxWidth: 320, maxHeight: 320, imageQuality: 60);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final b64 = base64Encode(bytes);
      if (b64.length > 700000) {
        if (mounted) showMsg(context, 'Ảnh quá lớn, vui lòng chọn ảnh nhỏ hơn');
        return;
      }
      setState(() {
        _preview = bytes;
        _hinhanh = b64;
      });
    } catch (e) {
      if (mounted) showMsg(context, 'Không chọn được ảnh: ${errText(e)}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final pass = _pass.text;
      final hashed = (isEdit && pass.isEmpty) ? widget.user!.matkhau : hashPassword(pass);
      final u = AppUser(
        id: widget.user?.id ?? '',
        email: _email.text.trim(),
        matkhau: hashed,
        hoten: _hoten.text.trim(),
        hinhanh: _hinhanh,
      );
      if (isEdit) {
        await FirestoreApi.update(u);
      } else {
        await FirestoreApi.create(u);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showMsg(context, errText(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa người dùng' : 'Thêm người dùng')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.all(20), children: [
              Center(
                child: Stack(children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: _preview != null ? MemoryImage(_preview!) : null,
                    child: _preview == null ? Icon(Icons.person, size: 60, color: cs.onPrimaryContainer) : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: cs.primary,
                      child: IconButton(
                        tooltip: 'Chọn ảnh',
                        icon: Icon(Icons.camera_alt, size: 20, color: cs.onPrimary),
                        onPressed: _chooseSource,
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Center(child: TextButton.icon(onPressed: _chooseSource, icon: const Icon(Icons.image), label: const Text('Chọn hình ảnh'))),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email *', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Email không được để trống';
                  if (!isValidEmail(s)) return 'Email không hợp lệ';
                  final dup = widget.all.any((u) => u.email.toLowerCase() == s.toLowerCase() && u.id != (widget.user?.id ?? ''));
                  if (dup) return 'Email đã tồn tại';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hoten,
                decoration: const InputDecoration(labelText: 'Họ tên *', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder()),
                validator: (v) => (v ?? '').trim().isEmpty ? 'Họ tên không được để trống' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Mật khẩu mới (để trống nếu không đổi)' : 'Mật khẩu *',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: (v) {
                  final s = v ?? '';
                  if (isEdit && s.isEmpty) return null;
                  if (s.isEmpty) return 'Mật khẩu không được để trống';
                  if (s.length < 6) return 'Mật khẩu tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Hủy'))),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: Text(isEdit ? 'Cập nhật' : 'Lưu'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
