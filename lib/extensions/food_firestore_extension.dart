// extensions/food_firestore_extension.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food.dart';

extension FoodFirestore on Food {
  /// Map Firestore doc to Food
  static Food fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Food(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      imageUrl: data['imageUrl'] as String? ?? '',
      category: data['category'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      calories: (data['calories'] as num?)?.toInt() ?? 0,
      prepTimeMinutes: (data['prepTimeMinutes'] as num?)?.toInt() ?? 0,
      isPopular: data['isPopular'] as bool? ?? false,
      isVegetarian: data['isVegetarian'] as bool? ?? false,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  /// Optional: Firestore map for writes (if ever needed)
  Map<String, dynamic> toFirestore() => {
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
