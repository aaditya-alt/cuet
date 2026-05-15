import 'package:flutter/material.dart';
import '../models/college_model.dart';

class UserScoreProvider with ChangeNotifier {
  final UserScore _score = UserScore();

  UserScore get score => _score;

  void updateLanguageScore(double val) { _score.english = val; notifyListeners(); }
  void updateDomainScore(double val)   { _score.domain1 = val; notifyListeners(); }
  void updateDomain2Score(double val)  { _score.domain2 = val; notifyListeners(); }
  void updateDomain3Score(double val)  { _score.domain3 = val; notifyListeners(); }
  void updateDomainSubject(String sub) { _score.domainSubject = sub; notifyListeners(); }
  void updateGeneralTest(double val)   { _score.generalTest = val; notifyListeners(); }
  void updateCategory(String cat)      { _score.category = cat; notifyListeners(); }
  void updateGender(String gen)        { _score.gender = gen; notifyListeners(); }

  // Legacy aliases so existing callers still compile
  void updateEnglish(double val) => updateLanguageScore(val);
  void updateDomain1(double val) => updateDomainScore(val);
  void updateDomain2(double val) => updateDomain2Score(val);
  void updateDomain3(double val) => updateDomain3Score(val);
}
