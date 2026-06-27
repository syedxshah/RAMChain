import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ram_model.dart';
import '../services/api_service.dart';

class AppProvider extends ChangeNotifier {
  String _baseUrl = 'http://localhost:8000';
  String _currentModel = '';
  List<String> _models = [];
  RamStats? _ramStats;
  List<DataEntry> _dataEntries = [];
  bool _isLoading = false;
  String _statusMessage = '';
  bool _statusIsError = false;

  String get baseUrl => _baseUrl;
  String get currentModel => _currentModel;
  List<String> get models => _models;
  RamStats? get ramStats => _ramStats;
  List<DataEntry> get dataEntries => _dataEntries;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  bool get statusIsError => _statusIsError;

  late ApiService _api;

  AppProvider() {
    _api = ApiService(baseUrl: _baseUrl);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('base_url') ?? 'http://localhost:8000';
    _currentModel = prefs.getString('current_model') ?? '';
    final savedModels = prefs.getStringList('models') ?? [];
    _models = savedModels;
    _api = ApiService(baseUrl: _baseUrl);
    notifyListeners();
    if (_currentModel.isNotEmpty) {
      await refresh();
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('base_url', _baseUrl);
    await prefs.setString('current_model', _currentModel);
    await prefs.setStringList('models', _models);
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    _api = ApiService(baseUrl: url);
    _savePrefs();
    notifyListeners();
  }

  void setCurrentModel(String model) {
    _currentModel = model;
    _savePrefs();
    notifyListeners();
    refresh();
  }

  void addModel(String model) {
    if (!_models.contains(model)) {
      _models.add(model);
      _savePrefs();
      notifyListeners();
    }
  }

  void removeModel(String model) {
    _models.remove(model);
    if (_currentModel == model) {
      _currentModel = _models.isNotEmpty ? _models.first : '';
    }
    _savePrefs();
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_currentModel.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.getRamStats(_currentModel),
        _api.getAllData(_currentModel),
      ]);

      _ramStats = results[0] as RamStats?;
      _dataEntries = results[1] as List<DataEntry>;
    } catch (e) {
      _setStatus('Error fetching data: $e', isError: true);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String> createModel(String name, int size) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.createModel(name, size);
      if (result.containsKey('error')) {
        _setStatus(result['error'], isError: true);
        return result['error'];
      }
      addModel(name);
      setCurrentModel(name);
      _setStatus('Model "$name" created successfully!');
      return 'ok';
    } catch (e) {
      final msg = 'Failed: $e';
      _setStatus(msg, isError: true);
      return msg;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> insertData(
      String key, String value, int? ttl) async {
    try {
      final result = await _api.insertData(_currentModel, key, value, ttl);
      if (result.containsKey('error')) {
        _setStatus(result['error'], isError: true);
        return result['error'];
      }
      _setStatus('Key "$key" inserted!');
      await refresh();
      return 'ok';
    } catch (e) {
      final msg = 'Failed: $e';
      _setStatus(msg, isError: true);
      return msg;
    }
  }

  Future<String> updateData(String key, String newValue) async {
    try {
      final result = await _api.updateData(_currentModel, key, newValue);
      if (result.containsKey('error')) {
        _setStatus(result['error'], isError: true);
        return result['error'];
      }
      _setStatus('Key "$key" updated!');
      await refresh();
      return 'ok';
    } catch (e) {
      final msg = 'Failed: $e';
      _setStatus(msg, isError: true);
      return msg;
    }
  }

  Future<String> deleteData(String key) async {
    try {
      final result = await _api.deleteData(_currentModel, key);
      if (result.containsKey('error')) {
        _setStatus(result['error'], isError: true);
        return result['error'];
      }
      _setStatus('Key "$key" deleted!');
      await refresh();
      return 'ok';
    } catch (e) {
      final msg = 'Failed: $e';
      _setStatus(msg, isError: true);
      return msg;
    }
  }

  Future<Map<String, dynamic>> getData(String key) async {
    return await _api.getData(_currentModel, key);
  }

  void _setStatus(String msg, {bool isError = false}) {
    _statusMessage = msg;
    _statusIsError = isError;
    notifyListeners();
  }

  void clearStatus() {
    _statusMessage = '';
    notifyListeners();
  }
}
