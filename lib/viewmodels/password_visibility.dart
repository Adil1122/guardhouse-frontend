import 'package:flutter/foundation.dart';

class PasswordVisibility extends ChangeNotifier {
  bool obscured;

  PasswordVisibility({this.obscured = true});

  void toggle() {
    obscured = !obscured;
    notifyListeners();
  }

  void set(bool value) {
    if (obscured != value) {
      obscured = value;
      notifyListeners();
    }
  }
}
