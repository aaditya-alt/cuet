import 'package:flutter/material.dart';
import '../models/college_model.dart';

class UserScoreProvider with ChangeNotifier {
  final UserScore _score = UserScore();

  UserScore get score => _score;

  void updateEnglish(double val) { _score.english = val; notifyListeners(); }
  void updateDomain1(double val) { _score.domain1 = val; notifyListeners(); }
  void updateDomain2(double val) { _score.domain2 = val; notifyListeners(); }
  void updateDomain3(double val) { _score.domain3 = val; notifyListeners(); }
  void updateGeneralTest(double val) { _score.generalTest = val; notifyListeners(); }
  void updateCategory(String cat) { _score.category = cat; notifyListeners(); }
  void updateGender(String gen) { _score.gender = gen; notifyListeners(); }
}
