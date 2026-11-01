import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AiService {
  final _storage = const FlutterSecureStorage();

  // Urutan model: kalau yang pertama sibuk, coba berikutnya
  static const _models = [
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
  ];

  String _urlFor(String model) =>
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API key tidak tersedia. Silakan atur di pengaturan.');
    }

    String lastError = '';

    for (final model in _models) {
      for (var attempt = 1; attempt <= 2; attempt++) {
        final response = await http.post(
          Uri.parse(_urlFor(model)),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': question}
                ]
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['candidates'][0]['content']['parts'][0]['text'];
        }

        lastError = '[$model] ${response.statusCode}: ${response.body}';

        // 503/429 = sibuk, tunggu sebentar lalu coba lagi
        if (response.statusCode == 503 || response.statusCode == 429) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        break; // error lain (404, 400, dst): langsung coba model berikutnya
      }
    }

    throw Exception('Gagal memanggil AI API.\n$lastError');
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }
}