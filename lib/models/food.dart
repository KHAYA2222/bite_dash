// models/food.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double rating;
  final int reviewCount;
  final int calories;
  final int prepTimeMinutes;
  final bool isPopular;
  final bool isVegetarian;
  final List<String> ingredients;
  final List<String> tags;

  const Food({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.calories,
    required this.prepTimeMinutes,
    this.isPopular = false,
    this.isVegetarian = false,
    this.ingredients = const [],
    this.tags = const [],
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      calories: (json['calories'] as num).toInt(),
      prepTimeMinutes: (json['prepTimeMinutes'] as num).toInt(),
      isPopular: json['isPopular'] as bool? ?? false,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'category': category,
        'rating': rating,
        'reviewCount': reviewCount,
        'calories': calories,
        'prepTimeMinutes': prepTimeMinutes,
        'isPopular': isPopular,
        'isVegetarian': isVegetarian,
        'ingredients': ingredients,
        'tags': tags,
      };

  Food copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    double? rating,
    int? reviewCount,
    int? calories,
    int? prepTimeMinutes,
    bool? isPopular,
    bool? isVegetarian,
    List<String>? ingredients,
    List<String>? tags,
  }) =>
      Food(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        rating: rating ?? this.rating,
        reviewCount: reviewCount ?? this.reviewCount,
        calories: calories ?? this.calories,
        prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
        isPopular: isPopular ?? this.isPopular,
        isVegetarian: isVegetarian ?? this.isVegetarian,
        ingredients: ingredients ?? this.ingredients,
        tags: tags ?? this.tags,
      );
}

// ── CartItem ──────────────────────────────────────────────────────────────────

class CartItem {
  final Food food;
  int quantity;
  String? specialNote;

  CartItem({required this.food, this.quantity = 1, this.specialNote});

  double get totalPrice => food.price * quantity;

  Map<String, dynamic> toJson() => {
        'foodId': food.id,
        'foodName': food.name,
        'foodPrice': food.price,
        'foodImageUrl': food.imageUrl,
        'quantity': quantity,
        if (specialNote != null) 'specialNote': specialNote,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Reconstruct a minimal Food from the stored snapshot fields
    final food = Food(
      id: json['foodId'] as String? ?? '',
      name: json['foodName'] as String? ?? '',
      description: '',
      price: (json['foodPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: json['foodImageUrl'] as String? ?? '',
      category: '',
      rating: 0,
      reviewCount: 0,
      calories: 0,
      prepTimeMinutes: 0,
    );
    return CartItem(
      food: food,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      specialNote: json['specialNote'] as String?,
    );
  }
}

// ── Order ─────────────────────────────────────────────────────────────────────

class Order {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime? createdAt;
  final String deliveryAddress;
  final String? orderNumber;
  final String? driverId; // assigned driver UID
  final String? driverName; // driver display name
  final String paymentMethod; // 'cod' | 'payfast'
  final String paymentStatus; // 'pending' | 'paid' | 'awaiting_payment'

  const Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.createdAt,
    required this.deliveryAddress,
    this.orderNumber,
    this.driverId,
    this.driverName,
    this.paymentMethod = 'cod',
    this.paymentStatus = 'pending',
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Parse from a Firestore DocumentSnapshot
  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['createdAt'];
    return Order(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerEmail: d['customerEmail'] as String? ?? '',
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromString(d['status'] as String? ?? 'pending'),
      createdAt: ts is Timestamp ? ts.toDate() : null,
      deliveryAddress: d['deliveryAddress'] as String? ?? '',
      orderNumber: d['orderNumber'] as String?,
      driverId: d['driverId'] as String?,
      driverName: d['driverName'] as String?,
      paymentMethod: d['paymentMethod'] as String? ?? 'cod',
      paymentStatus: d['paymentStatus'] as String? ?? 'pending',
      items: (d['items'] as List<dynamic>? ?? [])
          .map((i) => CartItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': status.value,
        'deliveryAddress': deliveryAddress,
        'orderNumber': orderNumber,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ── OrderStatus ───────────────────────────────────────────────────────────────

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled;

  static OrderStatus fromString(String s) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == s,
      orElse: () => OrderStatus.pending,
    );
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.onTheWay:
        return 'onTheWay';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.pending:
        return 'Waiting for restaurant to confirm your order.';
      case OrderStatus.confirmed:
        return 'Restaurant has confirmed your order!';
      case OrderStatus.preparing:
        return 'The kitchen is busy making your food.';
      case OrderStatus.onTheWay:
        return 'Your driver is on the way to you!';
      case OrderStatus.delivered:
        return 'Order delivered. Enjoy your meal!';
      case OrderStatus.cancelled:
        return 'This order was cancelled.';
    }
  }

  String get emoji {
    switch (this) {
      case OrderStatus.pending:
        return '🕐';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.preparing:
        return '👨‍🍳';
      case OrderStatus.onTheWay:
        return '🛵';
      case OrderStatus.delivered:
        return '🎉';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  int get step => index; // 0-5 for progress indicator
}
