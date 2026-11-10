// ==== CHI CAN SUA 2 DONG NAY (lay trong Firebase Console > Project settings) ====
const String kProjectId = 'giuaky-nguoidung';
const String kApiKey = 'AIzaSyBFtcyf5rYIU65tQyFforCGZQU85lWHyE8';

bool get configMissing => kProjectId.startsWith('THAY') || kApiKey.startsWith('THAY');
