import 'package:flutter/material.dart';
import '../models/college_model.dart';

class WishlistProvider with ChangeNotifier {
  final List<CollegeModel> _wishlist = [];

  List<CollegeModel> get wishlist => _wishlist;

  void toggleWishlist(CollegeModel college) {
    if (isInWishlist(college.id)) {
      _wishlist.removeWhere((c) => c.id == college.id);
    } else {
      _wishlist.add(college);
    }
    notifyListeners();
  }

  bool isInWishlist(String id) {
    return _wishlist.any((c) => c.id == id);
  }

  void reorderWishlist(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final CollegeModel item = _wishlist.removeAt(oldIndex);
    _wishlist.insert(newIndex, item);
    notifyListeners();
  }
}
