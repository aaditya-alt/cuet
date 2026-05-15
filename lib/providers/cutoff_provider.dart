import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// PredictionResult — one matched (college, program) row
// ---------------------------------------------------------------------------
class PredictionResult {
  final String collegeName;
  final String programName;
  final double cutoffScore;
  final double userScore;
  final String chance; // 'High' | 'Medium' | 'Low'
  final String category;

  const PredictionResult({
    required this.collegeName,
    required this.programName,
    required this.cutoffScore,
    required this.userScore,
    required this.chance,
    required this.category,
  });
}

// ---------------------------------------------------------------------------
// DomainProgramMapping — maps CUET domain subjects → JSON program name keywords
// ---------------------------------------------------------------------------
class DomainProgramMapping {
  // Each entry: CUET domain subject label → list of lowercase substrings
  // that must appear in the JSON `program_name` for a match.
  static const Map<String, List<String>> _keywords = {
    'Mathematics/Applied Mathematics': [
      'mathematics', 'computer science', 'electronics',
      'physical science', 'b.com', 'bms', 'statistics',
      'operational research',
    ],
    'Physics': [
      'physics', 'electronics', 'physical science',
      'instrumentation',
    ],
    'Chemistry': [
      'chemistry', 'biomedical', 'botany', 'zoology',
      'life science', 'polymer', 'applied chemistry',
    ],
    'Biology/Biological Studies/Biotechnology/Biochemistry': [
      'biomedical', 'botany', 'zoology', 'life science',
      'microbiology', 'biotechnology', 'biochemistry', 'biological',
    ],
    'Computer Science/Informatics Practices': [
      'computer science', 'informatics', 'computer application',
      'physical science with computer',
    ],
    'Accountancy/Book Keeping': [
      'b.com', 'commerce', 'accountancy',
    ],
    'Business Studies': [
      'b.com', 'bms', 'business economics', 'commerce',
    ],
    'Economics/Business Economics': [
      'economics', 'b.com', 'business economics',
    ],
    'History': [
      'history', 'archaeological', 'ancient history',
    ],
    'Political Science': [
      'political science',
    ],
    'Geography/Geology': [
      'geography', 'geology',
    ],
    'Psychology': [
      'psychology',
    ],
    'Sociology': [
      'sociology', 'social work',
    ],
    'Hindi': [
      'hindi',
    ],
    'English': [
      'english', 'journalism', 'mass media', 'patrakarita',
    ],
    'Mass Media/Mass Communication': [
      'journalism', 'mass media', 'patrakarita', 'hindi patrakarita',
    ],
    'Physical Education/NCC/Yoga': [
      'physical education', 'sports',
    ],
    'Home Science': [
      'home science', 'food science', 'nutrition',
    ],
    'Fine Arts/Visual Arts (Sculpture/Painting)': [
      'fine arts', 'visual arts', 'applied arts',
    ],
    'Legal Studies': [
      'law', 'legal',
    ],
    'Environmental Science': [
      'environmental', 'life science',
    ],
    'Agriculture': [
      'agriculture', 'agronomy',
    ],
    'Performing Arts (Dance/Drama/Music)': [
      'music', 'dance', 'drama', 'performing',
    ],
    'Sanskrit': [
      'sanskrit',
    ],
    'B.El.Ed / Education': [
      'elementary education', 'b.el.ed', 'education',
    ],
  };

  static bool programMatchesDomain(String programName, String domainSubject) {
    final pLow = programName.toLowerCase().replaceAll('\n', ' ');
    final keywords = _keywords[domainSubject] ?? [];
    return keywords.any((kw) => pLow.contains(kw));
  }

  /// All known CUET domain subjects (for dropdown)
  static List<String> get allSubjects => _keywords.keys.toList()..sort();
}

// ---------------------------------------------------------------------------
// CutoffProvider
// ---------------------------------------------------------------------------
class CutoffProvider extends ChangeNotifier {
  /// _data[collegeName][programName][category] = cutoffScore
  Map<String, Map<String, Map<String, double>>> _data = {};

  bool _isLoading = true;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  CutoffProvider() {
    loadCutoffData();
  }

  // -------------------------------------------------------------------------
  // Load
  // -------------------------------------------------------------------------
  Future<void> loadCutoffData() async {
    try {
      _isLoading = true;
      notifyListeners();

      final String raw =
          await rootBundle.loadString('assets/data/du_cutoffs_2025.json');
      final List<dynamic> jsonList = json.decode(raw);

      _data = {};
      for (final item in jsonList) {
        final String college  = (item['college_name'] as String).trim();
        // Normalise newlines inside program names
        final String program  =
            (item['program_name'] as String).replaceAll('\n', ' ').trim();
        final String category = item['category'] as String;
        final double score    = (item['cutoff_score'] as num).toDouble();

        _data.putIfAbsent(college, () => {});
        _data[college]!.putIfAbsent(program, () => {});
        _data[college]![program]![category] = score;
      }

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      debugPrint('CutoffProvider error: $e');
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Simple point lookup (used by CollegeDetailsScreen)
  // -------------------------------------------------------------------------
  double? getCutoff(String college, String program, String appCategory) {
    if (_isLoading || _data.isEmpty) return null;
    final normalised = program.replaceAll('\n', ' ').trim();
    return _data[college.trim()]?[normalised]?[_mapCategory(appCategory)];
  }

  bool hasDataForCollege(String college) =>
      _data.containsKey(college.trim());

  /// All categories Round-1 cutoffs for a given (college, program)
  Map<String, double>? getAllCategoriesForProgram(
      String college, String program) {
    final normalised = program.replaceAll('\n', ' ').trim();
    return _data[college.trim()]?[normalised];
  }

  /// All programs offered by a college (from real data)
  List<String> getProgramsForCollege(String college) {
    return _data[college.trim()]?.keys.toList() ?? [];
  }

  // -------------------------------------------------------------------------
  // Prediction Engine
  // -------------------------------------------------------------------------

  /// Returns predictions matching [domainSubject] for the user's score+category.
  /// Composite score = language + domain1 + domain2 + domain3 (max 800).
  List<PredictionResult> getPredictionsForStudent({
    required double userScore,
    required String category,
    required String domainSubject,
  }) {
    if (_isLoading || _data.isEmpty) return [];

    final String jsonCategory = _mapCategory(category);
    final List<PredictionResult> results = [];

    for (final collegeEntry in _data.entries) {
      for (final programEntry in collegeEntry.value.entries) {
        // Only include programs relevant to the selected domain subject
        if (!DomainProgramMapping.programMatchesDomain(
            programEntry.key, domainSubject)) {
          continue;
        }

        final double? cutoff = programEntry.value[jsonCategory];
        if (cutoff == null) continue;

        final String chance = _computeChance(userScore, cutoff);

        results.add(PredictionResult(
          collegeName: collegeEntry.key,
          programName: programEntry.key,
          cutoffScore: cutoff,
          userScore: userScore,
          chance: chance,
          category: category,
        ));
      }
    }

    // Sort: High → Medium → Low; within group ascending by cutoff
    const chanceOrder = {'High': 0, 'Medium': 1, 'Low': 2};
    results.sort((a, b) {
      final oa = chanceOrder[a.chance] ?? 2;
      final ob = chanceOrder[b.chance] ?? 2;
      if (oa != ob) return oa.compareTo(ob);
      return a.cutoffScore.compareTo(b.cutoffScore);
    });

    return results;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _mapCategory(String appCategory) {
    switch (appCategory) {
      case 'General': return 'UR';
      case 'PwD':     return 'PwBD';
      default:        return appCategory; // OBC / SC / ST / EWS already match
    }
  }

  String _computeChance(double score, double cutoff) {
    if (score >= cutoff)         return 'High';
    if (score >= cutoff - 15)    return 'Medium';
    return 'Low';
  }
}
