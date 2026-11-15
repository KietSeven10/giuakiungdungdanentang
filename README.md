# Quản lý người dùng - Flutter + Firebase Firestore

Bài thi giữa kỳ môn Lập trình đa nền tảng. Sinh viên: Nguyễn Tuấn Kiệt, lớp 23SE5.

## Chức năng
- Đăng nhập admin, thêm, sửa, xóa, xem chi tiết người dùng
- Tìm kiếm, sắp xếp, chế độ tối, xuất và nhập JSON
- Ảnh đại diện(thư viện), chạy trên web và Android

## Cơ sở dữ liệu
Firestore, collection `users`, đúng 4 trường: `email`, `matkhau` (băm SHA-256), `hoten`, `hinhanh` (ảnh mã hóa base64).

## Cách chạy
1. Tạo project Firebase, bật Firestore (chế độ test, Rules cho phép đọc và ghi).
2. Mở `lib/config.dart`, điền `kProjectId` và `kApiKey` (Firebase Console > Project settings > Your apps > web app).
3. Chạy `flutter pub get`.
4. Chạy `flutter run -d chrome` (web) hoặc `flutter run` (Android).
5. Lần đầu bấm "Khởi tạo dữ liệu mẫu", rồi đăng nhập `admin@gmail.com` / `123456`.

## Video demo
https://www.youtube.com/watch?v=Leo2moZplw0
