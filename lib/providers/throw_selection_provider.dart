import 'package:flutter/foundation.dart';
import '../models/javelin_throw.dart';

/// Provider to manage throw selection for analytics comparison
class ThrowSelectionProvider with ChangeNotifier {
  final Set<String> _selectedThrowIds = {};

  Set<String> get selectedThrowIds => _selectedThrowIds;
  int get selectedCount => _selectedThrowIds.length;
  bool get hasSelection => _selectedThrowIds.isNotEmpty;
  bool get canCompare => _selectedThrowIds.isNotEmpty;

  bool isSelected(String throwId) => _selectedThrowIds.contains(throwId);

  bool toggleThrow(String throwId) {
    if (_selectedThrowIds.contains(throwId)) {
      _selectedThrowIds.remove(throwId);
      notifyListeners();
      return true;
    } else {
      if (_selectedThrowIds.length >= 5) {
        return false;
      }
      _selectedThrowIds.add(throwId);
      notifyListeners();
      return true;
    }
  }

  void selectThrow(String throwId) {
    _selectedThrowIds.add(throwId);
    notifyListeners();
  }

  void deselectThrow(String throwId) {
    _selectedThrowIds.remove(throwId);
    notifyListeners();
  }

  void clearSelection() {
    _selectedThrowIds.clear();
    notifyListeners();
  }

  List<JavelinThrow> getSelectedThrows(List<JavelinThrow> allThrows) {
    return allThrows.where((t) => _selectedThrowIds.contains(t.id)).toList();
  }
}
