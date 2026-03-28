// services/food_service.dart
// Firestore data layer — foods, categories.

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
      return ['All', ...snap.docs.map((d) => d.data()['name'] as String)];
    }).handleError((e) {
      debugPrint('[FoodService] categoriesStream error: $e');
      return kDefaultCategories;
    });
  }

  Future<List<String>> getCategories() async {
    try {
      final snap = await _db.collection('categories').orderBy('order').get();
      if (snap.docs.isEmpty) return kDefaultCategories.skip(1).toList();
      return snap.docs.map((d) => d.data()['name'] as String).toList();
    } catch (e) {
      debugPrint('[FoodService] getCategories error: $e');
      return kDefaultCategories.skip(1).toList();
    }
  }

  // ── Foods — read ────────────────────────────────────────────────────────────

  Stream<List<Food>> foodsStream({String? category}) {
    Query<Map<String, dynamic>> query = _db.collection('foods').orderBy('name');
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    return query
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => _parse(doc)).whereType<Food>().toList())
        .handleError((e) {
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
        .map((snap) =>
            snap.docs.map((doc) => _parse(doc)).whereType<Food>().toList())
        .handleError((e) {
      debugPrint('[FoodService] popularStream error: $e');
      return <Food>[];
    });
  }

  /// All foods as a one-time fetch — used by admin menu screen.
  Future<List<Food>> getAllFoods() async {
    try {
      final snap = await _db.collection('foods').orderBy('category').get();
      return snap.docs.map((d) => _parse(d)).whereType<Food>().toList();
    } catch (e) {
      debugPrint('[FoodService] getAllFoods error: $e');
      return [];
    }
  }

  Future<List<Food>> search(String query) async {
    try {
      final snap = await _db.collection('foods').get();
      final q = query.toLowerCase();
      return snap.docs
          .map((d) => _parse(d))
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

  // ── Foods — admin write ─────────────────────────────────────────────────────

  /// Add a new food item. Returns the new document ID.
  Future<String?> addFood(Map<String, dynamic> data) async {
    try {
      final ref = await _db.collection('foods').add(data);
      debugPrint('[FoodService] Food added: ${ref.id}');
      return ref.id;
    } catch (e) {
      debugPrint('[FoodService] addFood error: $e');
      return null;
    }
  }

  /// Update an existing food item by document ID.
  Future<bool> updateFood(String id, Map<String, dynamic> data) async {
    try {
      await _db.collection('foods').doc(id).update(data);
      debugPrint('[FoodService] Food updated: $id');
      return true;
    } catch (e) {
      debugPrint('[FoodService] updateFood error: $e');
      return false;
    }
  }

  /// Delete a food item.
  Future<bool> deleteFood(String id) async {
    try {
      await _db.collection('foods').doc(id).delete();
      debugPrint('[FoodService] Food deleted: $id');
      return true;
    } catch (e) {
      debugPrint('[FoodService] deleteFood error: $e');
      return false;
    }
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  Food? _parse(DocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      if (data == null) return null;
      return Food.fromJson(<String, dynamic>{...data, 'id': doc.id});
    } catch (e) {
      debugPrint('[FoodService] parse error ${doc.id}: $e');
      return null;
    }
  }
}

// Fallback category list — used when Firestore 'categories' is empty.
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
