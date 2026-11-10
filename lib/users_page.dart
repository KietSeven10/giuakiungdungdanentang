import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firestore_api.dart';
import 'login_page.dart';
import 'state.dart';
import 'user_form_page.dart';
import 'user_model.dart';
import 'util.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<AppUser> users = [];
  bool loading = true;
  String? error;
  final _search = TextEditingController();
  String sort = 'name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      users = await FirestoreApi.list();
    } catch (e) {
      error = errText(e);
    }
    if (mounted) setState(() => loading = false);
  }

  List<AppUser> get filtered {
    final q = _search.text.trim().toLowerCase();
    final list = users
        .where((u) => q.isEmpty || u.hoten.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
        .toList();
    int cmp(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
    if (sort == 'name') list.sort((a, b) => cmp(a.hoten, b.hoten));
    if (sort == 'name_desc') list.sort((a, b) => cmp(b.hoten, a.hoten));
    if (sort == 'email') list.sort((a, b) => cmp(a.email, b.email));
    return list;
  }

  Future<void> _openForm([AppUser? u]) async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => UserFormPage(user: u, all: users)));
    if (ok == true) {
      if (!mounted) return;
      showMsg(context, u == null ? 'Đã thêm người dùng' : 'Đã cập nhật người dùng');
      _load();
    }
  }

  Future<void> _delete(AppUser u) async {
    if (u.id == AppState.current?.id) {
      showMsg(context, 'Không thể xóa tài khoản đang đăng nhập');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa "${u.hoten}" (${u.email}) không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirestoreApi.delete(u.id);
      if (!mounted) return;
      showMsg(context, 'Đã xóa ${u.hoten}');
      _load();
    } catch (e) {
      if (mounted) showMsg(context, errText(e));
    }
  }

  void _detail(AppUser u) {
    final bytes = u.imageBytes;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Thông tin người dùng'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 70,
              backgroundImage: bytes != null ? MemoryImage(bytes) : null,
              child: bytes == null ? const Icon(Icons.person, size: 70) : null,
            ),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.badge), title: Text(u.hoten), subtitle: const Text('Họ tên')),
            ListTile(leading: const Icon(Icons.email), title: Text(u.email), subtitle: const Text('Email')),
            const ListTile(leading: Icon(Icons.lock), title: Text('••••••••'), subtitle: Text('Mật khẩu (đã mã hóa SHA-256)')),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng'))],
      ),
    );
  }

  void _export() {
    bool withImg = false;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setS) {
        final data = users
            .map((u) => {'email': u.email, 'matkhau': u.matkhau, 'hoten': u.hoten, 'hinhanh': withImg ? u.hinhanh : ''})
            .toList();
        final text = const JsonEncoder.withIndent('  ').convert(data);
        return AlertDialog(
          title: const Text('Xuất cơ sở dữ liệu (JSON)'),
          content: SizedBox(
            width: 560,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CheckboxListTile(
                value: withImg,
                onChanged: (v) => setS(() => withImg = v ?? false),
                title: const Text('Kèm dữ liệu ảnh (base64, rất dài)'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              SizedBox(height: 280, child: SingleChildScrollView(child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)))),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (c.mounted) showMsg(c, 'Đã sao chép JSON. Dán vào file database.json để nộp.');
              },
              child: const Text('Sao chép JSON'),
            ),
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Đóng')),
          ],
        );
      }),
    );
  }

  Future<void> _import() async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nhập người dùng từ JSON'),
        content: SizedBox(
          width: 560,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Dán danh sách JSON (mỗi phần tử có email, matkhau, hoten, hinhanh). Email trùng sẽ bị bỏ qua.'),
            const SizedBox(height: 8),
            TextField(controller: ctrl, maxLines: 10, decoration: const InputDecoration(border: OutlineInputBorder())),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: const Text('Nhập')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      final list = jsonDecode(text) as List;
      final exist = users.map((u) => u.email.toLowerCase()).toSet();
      var n = 0;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        final email = (m['email'] ?? '').toString().trim();
        if (!isValidEmail(email) || exist.contains(email.toLowerCase())) continue;
        final mk = (m['matkhau'] ?? '').toString();
        await FirestoreApi.create(AppUser(
          email: email,
          matkhau: isHash(mk) ? mk : hashPassword(mk.isEmpty ? '123456' : mk),
          hoten: (m['hoten'] ?? '').toString(),
          hinhanh: (m['hinhanh'] ?? '').toString(),
        ));
        exist.add(email.toLowerCase());
        n++;
      }
      if (!mounted) return;
      showMsg(context, 'Đã nhập $n người dùng');
      _load();
    } catch (e) {
      if (mounted) showMsg(context, 'JSON không hợp lệ: ${errText(e)}');
    }
  }

  void _logout() {
    AppState.current = null;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý người dùng'),
        actions: [
          IconButton(tooltip: 'Làm mới', icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            tooltip: 'Chế độ tối',
            icon: Icon(AppState.themeMode.value == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              AppState.themeMode.value = AppState.themeMode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
              setState(() {});
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) => v == 'export' ? _export() : _import(),
            itemBuilder: (c) => const [
              PopupMenuItem(value: 'export', child: Text('Xuất JSON (nộp CSDL)')),
              PopupMenuItem(value: 'import', child: Text('Nhập JSON')),
            ],
          ),
          IconButton(tooltip: 'Đăng xuất', icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm người dùng'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo họ tên hoặc email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          }),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: sort,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('Tên A-Z')),
                DropdownMenuItem(value: 'name_desc', child: Text('Tên Z-A')),
                DropdownMenuItem(value: 'email', child: Text('Email')),
              ],
              onChanged: (v) => setState(() => sort = v ?? 'name'),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            Chip(avatar: const Icon(Icons.people, size: 18), label: Text('Tổng: ${users.length}')),
            const SizedBox(width: 8),
            Text('Hiển thị: ${list.length}', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('Đăng nhập: ${AppState.current?.email ?? ''}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.error_outline, size: 48, color: cs.error),
                          const SizedBox(height: 8),
                          Text(error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _load, child: const Text('Thử lại')),
                        ]),
                      ),
                    )
                  : list.isEmpty
                      ? const Center(child: Text('Không có người dùng nào'))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 440,
                            mainAxisExtent: 96,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: list.length,
                          itemBuilder: (c, i) {
                            final u = list[i];
                            final bytes = u.imageBytes;
                            return Card(
                              margin: EdgeInsets.zero,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _detail(u),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: cs.primaryContainer,
                                      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                                      child: bytes == null
                                          ? Text(u.hoten.isEmpty ? '?' : u.hoten[0].toUpperCase(),
                                              style: TextStyle(fontSize: 22, color: cs.onPrimaryContainer))
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(u.hoten, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ]),
                                    ),
                                    IconButton(tooltip: 'Sửa', icon: const Icon(Icons.edit), onPressed: () => _openForm(u)),
                                    IconButton(tooltip: 'Xóa', icon: Icon(Icons.delete, color: cs.error), onPressed: () => _delete(u)),
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ]),
    );
  }
}
