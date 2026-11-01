import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chatbot_ai/ai/ai_service.dart';
import 'package:chatbot_ai/features/chat_screen.dart';

class FakeAiService extends AiService {
  final String? reply;
  final Exception? error;

  FakeAiService({this.reply, this.error});

  @override
  Future<String> ask(String question) async {
    if (error != null) throw error!;
    return reply ?? 'Halo, saya asisten AI!';
  }

  @override
  Future<void> saveApiKey(String key) async {}
}

void main() {
  group('ChatNotifier Unit Tests', () {
    test('Mengabaikan string kosong saat send', () async {
      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(FakeAiService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.send('   ');

      final state = container.read(chatProvider);
      expect(state.messages, isEmpty);
      expect(state.isBusy, isFalse);
    });

    test('Berhasil mengirim pesan dan menerima respons streaming AI', () async {
      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(
            FakeAiService(reply: 'Halo kampus!'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.send('Halo AI');

      final state = container.read(chatProvider);
      expect(state.messages.length, 2);
      expect(state.messages[0].text, 'Halo AI');
      expect(state.messages[0].isUser, isTrue);
      expect(state.messages[1].text, 'Halo kampus!');
      expect(state.messages[1].isUser, isFalse);
      expect(state.messages[1].isError, isFalse);
      expect(state.isBusy, isFalse);
    });

    test('Menangani kegagalan API dan menyimpan status error pada pesan', () async {
      final container = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(
            FakeAiService(error: Exception('Layanan AI Sibuk')),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      await notifier.send('Halo error');

      final state = container.read(chatProvider);
      expect(state.messages.length, 2);
      expect(state.messages[0].text, 'Halo error');
      expect(state.messages[1].text, 'Layanan AI Sibuk');
      expect(state.messages[1].isUser, isFalse);
      expect(state.messages[1].isError, isTrue);
      expect(state.isBusy, isFalse);
    });
  });
}

