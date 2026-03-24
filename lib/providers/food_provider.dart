import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food.dart';

class FoodProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Food> _foods = [];
  bool _isLoading = false;

  List<Food> get foods => _foods;
  bool get isLoading => _isLoading;

  // Fetch all foods
  Future<void> fetchFoods() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _db.collection('foods').get();

      _foods = snapshot.docs.map((doc) => Food.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('[FoodProvider] fetchFoods error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
