import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState extends ChangeNotifier {
  final Set<String> _myListIds = <String>{};

  AppState() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? ids = prefs.getStringList('my_list_ids');
      if (ids != null) {
        _myListIds.addAll(ids);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading my list: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('my_list_ids', _myListIds.toList());
    } catch (e) {
      print('Error saving my list: $e');
    }
  }

  bool isInMyList(String id) => _myListIds.contains(id);

  Set<String> get myListIds => Set.unmodifiable(_myListIds);

  void toggleMyList(String id) {
    if (_myListIds.contains(id)) {
      _myListIds.remove(id);
    } else {
      _myListIds.add(id);
    }
    notifyListeners();
    _save();
  }
}

class AppStateProvider extends InheritedNotifier<AppState> {
  AppStateProvider({super.key, required super.child})
      : super(notifier: AppState());

  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found in context');
    return provider!.notifier!;
  }

  static AppState read(BuildContext context) {
    final provider =
        context.getInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'AppStateProvider not found in context');
    return provider!.notifier!;
  }
}
