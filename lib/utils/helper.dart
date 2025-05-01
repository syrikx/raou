import 'package:flutter/material.dart';

void showSnack(BuildContext context, String message, {int seconds = 1}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: seconds),
    ),
  );
}
