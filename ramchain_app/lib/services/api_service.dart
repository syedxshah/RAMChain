import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ram_model.dart';

class ApiService {
  String baseUrl;

  ApiService({required this.baseUrl});

  String _clean(String url) => url.trimRight().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> createModel(String name, int size) async {
    final url = Uri.parse('${_clean(baseUrl)}/create');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'size': size}),
    );
    return jsonDecode(response.body);
  }

  Future<RamStats?> getRamStats(String modelName) async {
    try {
      final base = _clean(baseUrl);
      // Note: /total_ram returns self.size (node count), NOT allocated MB.
      // We compute totalRam = remaining + used which is always correct.
      final results = await Future.wait([
        http.get(Uri.parse('$base/remaining_ram/$modelName')),
        http.get(Uri.parse('$base/space_used/$modelName')),
      ]);

      double parseVal(http.Response r, String field) {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final raw = body[field]?.toString() ?? '0';
        return double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }

      final remaining = parseVal(results[0], 'remaining');
      final used = parseVal(results[1], 'used');
      // Total = allocated model size = remaining + used
      final total = remaining + used;

      return RamStats(totalRam: total, remainingRam: remaining, usedRam: used);
    } catch (_) {
      return null;
    }
  }


  Future<List<DataEntry>> getAllData(String modelName) async {
    try {
      final url = Uri.parse('${_clean(baseUrl)}/getall/$modelName');
      final response = await http.get(url);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (body['data'] is List) {
        return (body['data'] as List)
            .map((item) => DataEntry.fromList(item as List))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> insertData(
      String modelName, String key, String value, int? ttl) async {
    final url = Uri.parse('${_clean(baseUrl)}/insert');
    final body = <String, dynamic>{'name': modelName, 'key': key, 'value': value};
    if (ttl != null && ttl > 0) body['ttl'] = ttl;
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateData(
      String modelName, String key, String newValue) async {
    final url = Uri.parse('${_clean(baseUrl)}/update');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName, 'key': key, 'new_value': newValue}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> deleteData(String modelName, String key) async {
    final url = Uri.parse('${_clean(baseUrl)}/delete');
    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName, 'key': key}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getData(String modelName, String key) async {
    final url = Uri.parse('${_clean(baseUrl)}/getdata');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': modelName, 'key': key}),
    );
    return jsonDecode(response.body);
  }
}
