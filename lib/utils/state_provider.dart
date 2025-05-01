import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppStateProvider extends ChangeNotifier {
  Map<String, dynamic>? _selectedAddress;
  User? _currentUser;
  final List<String> _cartItems = [];

  // 주소 상태
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  void setAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void clearAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  // 사용자 상태
  User? get currentUser => _currentUser;
  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  // 장바구니 상태
  List<String> get cartItems => List.unmodifiable(_cartItems);
  int get cartItemCount => _cartItems.length;

  void addToCart(String item) {
    _cartItems.add(item);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}
