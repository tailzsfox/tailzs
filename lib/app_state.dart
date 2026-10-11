import 'package:flutter/material.dart'
    show ChangeNotifier, Color, Colors, VoidCallback;
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/api_requests/api_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _selectedSport = prefs.getString('ff_selectedSport') ?? _selectedSport;
    });
    _safeInit(() {
      _selectedMode = prefs.getString('ff_selectedMode') ?? _selectedMode;
    });
    _safeInit(() {
      _selectedTier = prefs.getString('ff_selectedTier') ?? _selectedTier;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  String _selectedSport = 'NCAAF';
  String get selectedSport => _selectedSport;
  set selectedSport(String value) {
    _selectedSport = value;
    prefs.setString('ff_selectedSport', value);
  }

  String _selectedMode = 'AUDIT';
  String get selectedMode => _selectedMode;
  set selectedMode(String value) {
    _selectedMode = value;
    prefs.setString('ff_selectedMode', value);
  }

  String _selectedDay = 'FRIDAY';
  String get selectedDay => _selectedDay;
  set selectedDay(String value) {
    _selectedDay = value;
  }

  String _selectedTier = 'TIER!';
  String get selectedTier => _selectedTier;
  set selectedTier(String value) {
    _selectedTier = value;
    prefs.setString('ff_selectedTier', value);
  }

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;
  set isSubscribed(bool value) {
    _isSubscribed = value;
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}
