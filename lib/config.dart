// ==== CHI CAN SUA 2 DONG NAY (lay trong Firebase Console > Project settings) ====
const String kProjectId = 'giuaky-nguoidung';
const String kApiKey = 'THAY_API_KEY';

bool get configMissing => kProjectId.startsWith('THAY') || kApiKey.startsWith('THAY');
