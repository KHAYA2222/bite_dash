// services/order_service.dart
// All order-related Firestore operations.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/food.dart';

class OrderService {
  static final OrderService _instance = OrderService._();
  factory OrderService() => _instance;
  OrderService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Place order ─────────────────────────────────────────────────────────────

  /// Creates an order document and returns the new Order.
  /// Returns null on failure.
  Future<Order?> placeOrder({
    required String userId,
    required String customerName,
    required String customerEmail,
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    String deliveryAddress = '',
  }) async {
    try {
      // Generate a short human-readable order number
      final orderNumber = _generateOrderNumber();

      final data = {
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': OrderStatus.pending.value,
        'deliveryAddress': deliveryAddress,
        'orderNumber': orderNumber,
        'createdAt': FieldValue.serverTimestamp(),
        // Admin notification fields
        'isRead': false, // admin marks as read
        'adminNote': '', // admin can add a note
      };

      final ref = await _db.collection('orders').add(data);
      debugPrint('[OrderService] Order placed: ${ref.id} ($orderNumber)');

      // Return the order immediately (createdAt will be null until server responds)
      return Order(
        id: ref.id,
        userId: userId,
        customerName: customerName,
        customerEmail: customerEmail,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        status: OrderStatus.pending,
        deliveryAddress: deliveryAddress,
        orderNumber: orderNumber,
      );
    } catch (e) {
      debugPrint('[OrderService] placeOrder error: $e');
      return null;
    }
  }

  // ── User streams ────────────────────────────────────────────────────────────

  /// Live stream of a single order — for real-time tracking.
  Stream<Order?> orderStream(String orderId) {
    return _db.collection('orders').doc(orderId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Order.fromFirestore(doc);
    }).handleError((e) {
      debugPrint('[OrderService] orderStream error: $e');
      return null;
    });
  }

  /// Live stream of all orders for a user, newest first.
  Stream<List<Order>> userOrdersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
            (snap) => snap.docs.map((doc) => Order.fromFirestore(doc)).toList())
        .handleError((e) {
      debugPrint('[OrderService] userOrdersStream error: $e');
      return <Order>[];
    });
  }

  // ── Admin streams ───────────────────────────────────────────────────────────

  /// Live stream of ALL orders for admin — newest first.
  Stream<List<Order>> allOrdersStream() {
    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
            (snap) => snap.docs.map((doc) => Order.fromFirestore(doc)).toList())
        .handleError((e) {
      debugPrint('[OrderService] allOrdersStream error: $e');
      return <Order>[];
    });
  }

  /// Live stream of unread orders — for admin notification badge.
  Stream<int> unreadOrderCount() {
    return _db
        .collection('orders')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length)
        .handleError((_) => 0);
  }

  // ── Admin actions ───────────────────────────────────────────────────────────

  /// Update an order's status. Called by admin.
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _db.collection('orders').doc(orderId).update({
        'status': status.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OrderService] Order $orderId → ${status.label}');
      return true;
    } catch (e) {
      debugPrint('[OrderService] updateOrderStatus error: $e');
      return false;
    }
  }

  /// Mark an order as read by admin.
  Future<void> markOrderRead(String orderId) async {
    try {
      await _db.collection('orders').doc(orderId).update({'isRead': true});
    } catch (e) {
      debugPrint('[OrderService] markOrderRead error: $e');
    }
  }

  // ── Helper ──────────────────────────────────────────────────────────────────

  String _generateOrderNumber() {
    final now = DateTime.now();
    final suffix = now.millisecondsSinceEpoch % 10000;
    return 'ORD-${now.year % 100}${(now.month).toString().padLeft(2, '0')}$suffix';
  }
}
