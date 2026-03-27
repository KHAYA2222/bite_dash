import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/food.dart';
import '../extensions/food_firestore_extension.dart';

class FoodProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Food>> getAllFoods() async {
    final snapshot = await _db.collection('foods').get();
    return snapshot.docs.map(FoodFirestore.fromFirestore).toList();
  }
}
