import 'package:flutter/material.dart';
import 'user_model.dart';

class AppState {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);
  static AppUser? current;
}
