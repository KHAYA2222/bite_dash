// services/food_service.dart
// Pure Firestore data layer — foods, categories, orders.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/food.dart';

class FoodService {
  static final FoodService _instance = FoodService._();
  factory FoodService() => _instance;
  FoodService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Categories ──────────────────────────────────────────────────────────────

  Stream<List<String>> categoriesStream() {
    return _db
        .collection('categories')
        .orderBy('order')
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return kDefaultCategories;
      return [
        'All',
        ...snap.docs.map((d) => d.data()['name'] as String),
      ];
    }).handleError((e) {
      debugPrint('[FoodService] categoriesStream error: $e');
      return kDefaultCategories;
    });
  }

  // ── Foods ───────────────────────────────────────────────────────────────────

  Stream<List<Food>> foodsStream({String? category}) {
    Query<Map<String, dynamic>> query = _db.collection('foods').orderBy('name');

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snap) {
      return snap.docs
          .map((doc) => _foodFromDoc(doc))
          .whereType<Food>()
          .toList();
    }).handleError((e) {
      debugPrint('[FoodService] foodsStream error: $e');
      return <Food>[];
    });
  }

  Stream<List<Food>> popularStream() {
    return _db
        .collection('foods')
        .where('isPopular', isEqualTo: true)
        .orderBy('rating', descending: true)
        .limit(8)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => _foodFromDoc(doc))
          .whereType<Food>()
          .toList();
    }).handleError((e) {
      debugPrint('[FoodService] popularStream error: $e');
      return <Food>[];
    });
  }

  Future<Food?> getFood(String id) async {
    try {
      final doc = await _db.collection('foods').doc(id).get();
      if (!doc.exists) return null;
      return _foodFromDoc(doc);
    } catch (e) {
      debugPrint('[FoodService] getFood error: $e');
      return null;
    }
  }

  Future<List<Food>> search(String query) async {
    try {
      final snap = await _db.collection('foods').get();
      final q = query.toLowerCase();
      return snap.docs
          .map((doc) => _foodFromDoc(doc))
          .whereType<Food>()
          .where((f) =>
              f.name.toLowerCase().contains(q) ||
              f.category.toLowerCase().contains(q) ||
              f.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    } catch (e) {
      debugPrint('[FoodService] search error: $e');
      return [];
    }
  }

  // ── Orders ──────────────────────────────────────────────────────────────────

  Future<String?> placeOrder({
    required String userId,
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    String deliveryAddress = '',
  }) async {
    try {
      final ref = await _db.collection('orders').add({
        'userId': userId,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'status': 'pending',
        'deliveryAddress': deliveryAddress,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FoodService] Order placed: ${ref.id}');
      return ref.id;
    } catch (e) {
      debugPrint('[FoodService] placeOrder error: $e');
      return null;
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ordersStream(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Seed ────────────────────────────────────────────────────────────────────

  /// Seeds all food items and categories into Firestore.
  /// Safe to call multiple times — uses fixed doc IDs so no duplicates.
  /// Call this once from an admin button in the app after signing in.
  Future<SeedResult> seedDatabase() async {
    try {
      debugPrint('[FoodService] Starting database seed...');

      // Seed categories
      final catBatch = _db.batch();
      for (final cat in _seedCategories) {
        final name = cat['name'] as String;
        catBatch.set(
          _db.collection('categories').doc(name.toLowerCase()),
          cat,
          SetOptions(merge: true),
        );
      }
      await catBatch.commit();
      debugPrint(
          '[FoodService] ✅ ${_seedCategories.length} categories seeded.');

      // Seed foods in batches of 10 (Firestore batch limit is 500 but good practice)
      final foodBatch = _db.batch();
      for (final food in _seedFoods) {
        final id = food['id'] as String;
        final data = Map<String, dynamic>.from(food)..remove('id');
        foodBatch.set(
          _db.collection('foods').doc(id),
          data,
          SetOptions(merge: true),
        );
      }
      await foodBatch.commit();
      debugPrint('[FoodService] ✅ ${_seedFoods.length} foods seeded.');

      return SeedResult(
        success: true,
        foodCount: _seedFoods.length,
        categoryCount: _seedCategories.length,
      );
    } catch (e) {
      debugPrint('[FoodService] seedDatabase error: $e');
      return SeedResult(success: false, error: e.toString());
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  // Accepts both DocumentSnapshot and QueryDocumentSnapshot.
  // DocumentSnapshot.data() returns Map? so we null-check before spreading.
  Food? _foodFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;
      return Food.fromJson(<String, dynamic>{...data, 'id': doc.id});
    } catch (e) {
      debugPrint(
          '[FoodService] Failed to parse food ' + doc.id + ': ' + e.toString());
      return null;
    }
  }
}

// ── Seed result ──────────────────────────────────────────────────────────────

class SeedResult {
  final bool success;
  final int foodCount;
  final int categoryCount;
  final String? error;

  const SeedResult({
    required this.success,
    this.foodCount = 0,
    this.categoryCount = 0,
    this.error,
  });
}

// ── Default categories (fallback only) ───────────────────────────────────────

const List<String> kDefaultCategories = [
  'All',
  'Burgers',
  'Pizza',
  'Sushi',
  'Salads',
  'Pasta',
  'Desserts',
  'Drinks',
];

// ── Seed data ────────────────────────────────────────────────────────────────

const List<Map<String, dynamic>> _seedCategories = [
  {'name': 'Burgers', 'order': 1},
  {'name': 'Pizza', 'order': 2},
  {'name': 'Sushi', 'order': 3},
  {'name': 'Salads', 'order': 4},
  {'name': 'Pasta', 'order': 5},
  {'name': 'Desserts', 'order': 6},
  {'name': 'Drinks', 'order': 7},
];

const List<Map<String, dynamic>> _seedFoods = [
  // ── Burgers ─────────────────────────────────────────────────────────────────
  {
    'id': 'b1',
    'name': 'Classic Smash Burger',
    'description':
        'Two smashed beef patties with American cheese, caramelised onions, pickles, and our secret smoky sauce on a brioche bun.',
    'price': 149.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&q=80',
    'category': 'Burgers',
    'rating': 4.8,
    'reviewCount': 324,
    'calories': 720,
    'prepTimeMinutes': 15,
    'isPopular': true,
    'isVegetarian': false,
    'ingredients': [
      'Beef patty',
      'American cheese',
      'Caramelised onions',
      'Pickles',
      'Brioche bun',
      'Secret sauce'
    ],
    'tags': ['Bestseller', 'Spicy'],
  },
  {
    'id': 'b2',
    'name': 'BBQ Bacon Burger',
    'description':
        'Juicy beef patty topped with crispy streaky bacon, cheddar, BBQ sauce, and crunchy onion rings.',
    'price': 164.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=600&q=80',
    'category': 'Burgers',
    'rating': 4.6,
    'reviewCount': 218,
    'calories': 850,
    'prepTimeMinutes': 18,
    'isPopular': true,
    'isVegetarian': false,
    'ingredients': [
      'Beef patty',
      'Bacon',
      'Cheddar',
      'BBQ sauce',
      'Onion rings'
    ],
    'tags': ['Meaty'],
  },
  {
    'id': 'b3',
    'name': 'Garden Veggie Burger',
    'description':
        'House-made black bean and roasted veggie patty with avocado, sprouts, tomato, and chipotle mayo.',
    'price': 134.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=600&q=80',
    'category': 'Burgers',
    'rating': 4.5,
    'reviewCount': 156,
    'calories': 520,
    'prepTimeMinutes': 14,
    'isPopular': false,
    'isVegetarian': true,
    'ingredients': [
      'Black bean patty',
      'Avocado',
      'Sprouts',
      'Tomato',
      'Chipotle mayo'
    ],
    'tags': ['Vegan', 'Healthy'],
  },
  // ── Pizza ────────────────────────────────────────────────────────────────────
  {
    'id': 'p1',
    'name': 'Margherita Napoletana',
    'description':
        'San Marzano tomato, fresh mozzarella di bufala, basil, and extra virgin olive oil on a perfectly charred Neapolitan crust.',
    'price': 159.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&q=80',
    'category': 'Pizza',
    'rating': 4.9,
    'reviewCount': 412,
    'calories': 680,
    'prepTimeMinutes': 20,
    'isPopular': true,
    'isVegetarian': true,
    'ingredients': [
      'San Marzano tomato',
      'Buffalo mozzarella',
      'Basil',
      'Olive oil'
    ],
    'tags': ['Classic', 'Vegetarian'],
  },
  {
    'id': 'p2',
    'name': 'Truffle & Mushroom',
    'description':
        'White base with wild mushroom medley, truffle oil, thyme, and aged parmesan on a thin crispy crust.',
    'price': 189.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80',
    'category': 'Pizza',
    'rating': 4.7,
    'reviewCount': 287,
    'calories': 740,
    'prepTimeMinutes': 22,
    'isPopular': false,
    'isVegetarian': true,
    'ingredients': [
      'Wild mushrooms',
      'Truffle oil',
      'Thyme',
      'Parmesan',
      'White sauce'
    ],
    'tags': ['Gourmet', 'Vegetarian'],
  },
  {
    'id': 'p3',
    'name': 'Spicy Salami',
    'description':
        'Tomato base loaded with spicy Calabrese salami, roasted peppers, chilli flakes, and smoked scamorza.',
    'price': 174.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80',
    'category': 'Pizza',
    'rating': 4.6,
    'reviewCount': 198,
    'calories': 810,
    'prepTimeMinutes': 20,
    'isPopular': true,
    'isVegetarian': false,
    'ingredients': [
      'Calabrese salami',
      'Roasted peppers',
      'Scamorza',
      'Chilli'
    ],
    'tags': ['Spicy', 'Meaty'],
  },
  // ── Sushi ────────────────────────────────────────────────────────────────────
  {
    'id': 's1',
    'name': 'Rainbow Roll (8 pcs)',
    'description':
        "California roll topped with alternating slices of tuna, salmon, yellowtail, and avocado. Chef's favourite.",
    'price': 199.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=600&q=80',
    'category': 'Sushi',
    'rating': 4.9,
    'reviewCount': 501,
    'calories': 420,
    'prepTimeMinutes': 12,
    'isPopular': true,
    'isVegetarian': false,
    'ingredients': [
      'Tuna',
      'Salmon',
      'Yellowtail',
      'Avocado',
      'Crab',
      'Cucumber',
      'Rice'
    ],
    'tags': ["Chef's Pick", 'Fresh'],
  },
  {
    'id': 's2',
    'name': 'Spicy Tuna Roll (6 pcs)',
    'description':
        'Fresh tuna with spicy sriracha mayo, cucumber, and sesame seeds wrapped in nori and sushi rice.',
    'price': 149.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1562802378-063ec186a863?w=600&q=80',
    'category': 'Sushi',
    'rating': 4.7,
    'reviewCount': 334,
    'calories': 320,
    'prepTimeMinutes': 10,
    'isPopular': true,
    'isVegetarian': false,
    'ingredients': [
      'Tuna',
      'Sriracha mayo',
      'Cucumber',
      'Sesame',
      'Nori',
      'Rice'
    ],
    'tags': ['Spicy', 'Popular'],
  },
  // ── Salads ───────────────────────────────────────────────────────────────────
  {
    'id': 'sa1',
    'name': 'Super Green Bowl',
    'description':
        'Kale, edamame, avocado, roasted chickpeas, cucumber, and sunflower seeds with miso-ginger dressing.',
    'price': 129.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600&q=80',
    'category': 'Salads',
    'rating': 4.6,
    'reviewCount': 189,
    'calories': 380,
    'prepTimeMinutes': 8,
    'isPopular': false,
    'isVegetarian': true,
    'ingredients': [
      'Kale',
      'Edamame',
      'Avocado',
      'Chickpeas',
      'Cucumber',
      'Miso dressing'
    ],
    'tags': ['Vegan', 'Healthy', 'Low-cal'],
  },
  {
    'id': 'sa2',
    'name': 'Grilled Caesar',
    'description':
        'Romaine hearts, grilled chicken, house-made Caesar dressing, sourdough croutons, and shaved parmesan.',
    'price': 139.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1550304943-4f24f54ddde9?w=600&q=80',
    'category': 'Salads',
    'rating': 4.5,
    'reviewCount': 211,
    'calories': 490,
    'prepTimeMinutes': 10,
    'isPopular': false,
    'isVegetarian': false,
    'ingredients': [
      'Romaine',
      'Grilled chicken',
      'Caesar dressing',
      'Croutons',
      'Parmesan'
    ],
    'tags': ['Classic', 'Protein'],
  },
  // ── Pasta ────────────────────────────────────────────────────────────────────
  {
    'id': 'pa1',
    'name': 'Cacio e Pepe',
    'description':
        'Perfectly al-dente tonnarelli pasta with aged Pecorino Romano, Parmigiano, and freshly cracked black pepper.',
    'price': 154.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=600&q=80',
    'category': 'Pasta',
    'rating': 4.8,
    'reviewCount': 276,
    'calories': 620,
    'prepTimeMinutes': 14,
    'isPopular': true,
    'isVegetarian': true,
    'ingredients': [
      'Tonnarelli',
      'Pecorino Romano',
      'Parmigiano',
      'Black pepper',
      'Butter'
    ],
    'tags': ['Classic', 'Vegetarian'],
  },
  {
    'id': 'pa2',
    'name': 'Lobster Linguine',
    'description':
        'Fresh linguine tossed with half a butter-poached lobster, cherry tomatoes, white wine, garlic, and chilli.',
    'price': 299.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1563379926898-05f4575a45d8?w=600&q=80',
    'category': 'Pasta',
    'rating': 4.9,
    'reviewCount': 143,
    'calories': 780,
    'prepTimeMinutes': 25,
    'isPopular': false,
    'isVegetarian': false,
    'ingredients': [
      'Linguine',
      'Lobster',
      'Cherry tomatoes',
      'White wine',
      'Garlic',
      'Chilli'
    ],
    'tags': ['Premium', 'Seafood'],
  },
  // ── Desserts ─────────────────────────────────────────────────────────────────
  {
    'id': 'd1',
    'name': 'Molten Lava Cake',
    'description':
        'Warm dark chocolate cake with a gooey molten centre, served with vanilla bean ice cream and raspberry coulis.',
    'price': 89.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=600&q=80',
    'category': 'Desserts',
    'rating': 4.9,
    'reviewCount': 389,
    'calories': 580,
    'prepTimeMinutes': 12,
    'isPopular': true,
    'isVegetarian': true,
    'ingredients': [
      'Dark chocolate',
      'Butter',
      'Eggs',
      'Sugar',
      'Vanilla ice cream'
    ],
    'tags': ['Indulgent', 'Hot'],
  },
  {
    'id': 'd2',
    'name': 'Mango Panna Cotta',
    'description':
        'Silky Italian vanilla cream set with fresh mango compote and passionfruit drizzle.',
    'price': 74.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=600&q=80',
    'category': 'Desserts',
    'rating': 4.7,
    'reviewCount': 214,
    'calories': 340,
    'prepTimeMinutes': 5,
    'isPopular': false,
    'isVegetarian': true,
    'ingredients': ['Cream', 'Vanilla', 'Mango', 'Passionfruit', 'Gelatin'],
    'tags': ['Light', 'Fruity'],
  },
  // ── Drinks ───────────────────────────────────────────────────────────────────
  {
    'id': 'dr1',
    'name': 'Matcha Latte',
    'description':
        'Ceremonial grade Japanese matcha whisked with steamed oat milk and a touch of honey. Hot or iced.',
    'price': 54.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?w=600&q=80',
    'category': 'Drinks',
    'rating': 4.8,
    'reviewCount': 441,
    'calories': 160,
    'prepTimeMinutes': 4,
    'isPopular': true,
    'isVegetarian': true,
    'ingredients': ['Matcha', 'Oat milk', 'Honey'],
    'tags': ['Vegan', 'Healthy'],
  },
  {
    'id': 'dr2',
    'name': 'Strawberry Basil Lemonade',
    'description':
        'Freshly squeezed lemonade muddled with strawberries and fresh basil. Refreshing and totally addictive.',
    'price': 49.99,
    'imageUrl':
        'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=600&q=80',
    'category': 'Drinks',
    'rating': 4.6,
    'reviewCount': 298,
    'calories': 140,
    'prepTimeMinutes': 3,
    'isPopular': false,
    'isVegetarian': true,
    'ingredients': ['Lemon', 'Strawberry', 'Basil', 'Sugar', 'Sparkling water'],
    'tags': ['Refreshing', 'Seasonal'],
  },
];
