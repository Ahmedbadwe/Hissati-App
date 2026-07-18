import 'package:flutter/material.dart';
import '../utils/education_data.dart';

/// Holds the state for the 4 core Home Feed filters and notifies listeners
/// (e.g. FeedController) whenever the user changes them, so the feed query
/// can be re-run.
class FilterController extends ChangeNotifier {
  String? _eduLevel;
  String? _subject;
  RangeValues _priceRange = const RangeValues(30, 500);
  double _radiusKm = 10.0; // default per spec

  String? get eduLevel => _eduLevel;
  String? get subject => _subject;
  RangeValues get priceRange => _priceRange;
  double get radiusKm => _radiusKm;

  /// Subjects available for the currently selected level. Resets to an
  /// empty list until a level has been chosen.
  List<String> get availableSubjects =>
      _eduLevel == null ? const [] : EducationData.subjectsFor(_eduLevel!);

  void setEduLevel(String? level) {
    _eduLevel = level;
    // Selecting a new level invalidates the previously chosen subject
    // since the dynamic dropdown's options change.
    _subject = null;
    notifyListeners();
  }

  void setSubject(String? subject) {
    _subject = subject;
    notifyListeners();
  }

  void setPriceRange(RangeValues range) {
    _priceRange = range;
    notifyListeners();
  }

  void setRadiusKm(double radius) {
    _radiusKm = radius;
    notifyListeners();
  }

  void reset() {
    _eduLevel = null;
    _subject = null;
    _priceRange = const RangeValues(30, 500);
    _radiusKm = 10.0;
    notifyListeners();
  }

  bool get hasActiveFilters =>
      _eduLevel != null ||
      _subject != null ||
      _priceRange.start != 30 ||
      _priceRange.end != 500 ||
      _radiusKm != 10.0;
}
