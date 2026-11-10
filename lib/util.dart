import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

String hashPassword(String s) => sha256.convert(utf8.encode(s)).toString();

bool isHash(String s) => RegExp(r'^[a-f0-9]{64}$').hasMatch(s);

bool isValidEmail(String s) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s.trim());

String errText(Object e) => e.toString().replaceFirst('Exception: ', '');

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
