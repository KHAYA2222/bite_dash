// models/food.dart
// Food model — read from Firestore 'foods' collection

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

  // ✅ Simple Firestore factory (matches your provider)
  factory Food.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data()!;

    return Food.fromJson({
      ...data,
      'id': snapshot.id, // inject document ID
    });
  }

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      category: json['category'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      calories: json['calories'] as int,
      prepTimeMinutes: json['prepTimeMinutes'] as int,
      isPopular: json['isPopular'] as bool? ?? false,
      isVegetarian: json['isVegetarian'] as bool? ?? false,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
  }

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
  }) {
    return Food(
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
}

// Cart item model
class CartItem {
  final Food food;
  int quantity;
  String? specialNote;

  CartItem({
    required this.food,
    this.quantity = 1,
    this.specialNote,
  });

  double get totalPrice => food.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'food': food.toJson(),
      'quantity': quantity,
      'specialNote': specialNote,
    };
  }
}

// Order model
class Order {
  final String id;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String deliveryAddress;

  const Order({
    required this.id,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.deliveryAddress,
  });

  double get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
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
}
