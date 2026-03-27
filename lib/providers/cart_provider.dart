// providers/cart_provider.dart

import 'package:flutter/material.dart';
import '../models/food.dart';

// ── Delivery config ───────────────────────────────────────────────────────────
// Adjust these values to match your actual delivery pricing.
const double kFreeDeliveryThreshold = 300.0; // R300 and over = free delivery
const double kDeliveryFee = 29.99; // flat fee below threshold

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.totalPrice);

  double get deliveryFee => subtotal > 0
      ? (subtotal >= kFreeDeliveryThreshold ? 0 : kDeliveryFee)
      : 0;

  double get total => subtotal + deliveryFee;

  bool get freeDelivery => subtotal >= kFreeDeliveryThreshold;

  double get amountToFreeDelivery =>
      freeDelivery ? 0 : kFreeDeliveryThreshold - subtotal;

  bool isInCart(String foodId) => _items.any((item) => item.food.id == foodId);

  int quantityOf(String foodId) {
    try {
      return _items.firstWhere((item) => item.food.id == foodId).quantity;
    } catch (_) {
      return 0;
    }
  }

  void addItem(Food food) {
    final idx = _items.indexWhere((item) => item.food.id == food.id);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(food: food));
    }
    notifyListeners();
  }

  void removeItem(String foodId) {
    final idx = _items.indexWhere((item) => item.food.id == foodId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  void deleteItem(String foodId) {
    _items.removeWhere((item) => item.food.id == foodId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void updateNote(String foodId, String note) {
    final idx = _items.indexWhere((item) => item.food.id == foodId);
    if (idx >= 0) {
      _items[idx].specialNote = note;
      notifyListeners();
    }
  }
}
