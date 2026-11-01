import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatbot_ai/ai/ai_service.dart';
import 'package:chatbot_ai/features/chat_screen.dart';

class FakeAiService extends AiService {
  final String? reply;
  FakeAiService({this.reply});

  @override
  Future<String> ask(String question) async {
    return reply ?? 'Halo dari AI!';
  }

  @override
  Future<void> saveApiKey(String key) async {}
}

void main() {
  testWidgets('ChatScreen menampilkan komponen awal dan placeholder',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(FakeAiService()),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    // Verifikasi AppBar dan komponen judul
    expect(find.text('Chat AI'), findsOneWidget);
    expect(find.byIcon(Icons.key), findsOneWidget);

    // Verifikasi placeholder kondisi awal
    expect(find.text('Tanya apa saja ke AI 👋'), findsOneWidget);

    // Verifikasi input bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('Menekan tombol key membuka dialog konfigurasi API Key',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(FakeAiService()),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    // Tekan tombol ikon kunci di AppBar
    await tester.tap(find.byIcon(Icons.key));
    await tester.pumpAndSettle();

    // Verifikasi dialog muncul
    expect(find.text('Atur API Key'), findsOneWidget);
    expect(find.text('Tempel API key di sini'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    // Tekan Batal untuk menutup dialog
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Atur API Key'), findsNothing);
  });

  testWidgets('Mengirim pertanyaan menampilkan bubble chat user dan respons AI',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiServiceProvider.overrideWithValue(
            FakeAiService(reply: 'Halo mahasiswa, ada yang bisa dibantu?'),
          ),
        ],
        child: const MaterialApp(home: ChatScreen()),
      ),
    );

    // Ketik pertanyaan di TextField
    final textFieldFinder = find.byType(TextField);
    await tester.enterText(textFieldFinder, 'Halo AI');
    expect(find.text('Halo AI'), findsOneWidget);

    // Tekan tombol kirim
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Placeholder awal harus sudah hilang
    expect(find.text('Tanya apa saja ke AI 👋'), findsNothing);
    expect(find.text('Halo AI'), findsOneWidget);

    // Selesaikan animasi typewriter dan stream response
    await tester.pumpAndSettle();

    // Pastikan bubble respons AI muncul
    expect(
      find.text('Halo mahasiswa, ada yang bisa dibantu?'),
      findsOneWidget,
    );
  });
}
