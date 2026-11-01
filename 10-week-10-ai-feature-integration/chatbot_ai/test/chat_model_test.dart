import 'package:flutter_test/flutter_test.dart';
import 'package:chatbot_ai/features/chat_screen.dart';

void main() {
  group('ChatMessage Model Tests', () {
    test('Inisialisasi ChatMessage user default dengan benar', () {
      const msg = ChatMessage(text: 'Halo Gemini', isUser: true);
      expect(msg.text, 'Halo Gemini');
      expect(msg.isUser, isTrue);
      expect(msg.isError, isFalse);
    });

    test('Inisialisasi ChatMessage bot dengan status error', () {
      const msg = ChatMessage(
        text: 'API Key tidak valid',
        isUser: false,
        isError: true,
      );
      expect(msg.text, 'API Key tidak valid');
      expect(msg.isUser, isFalse);
      expect(msg.isError, isTrue);
    });
  });

  group('ChatState Model Tests', () {
    test('Default ChatState memiliki nilai awal yang tepat', () {
      const state = ChatState();
      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.isStreaming, isFalse);
      expect(state.isBusy, isFalse);
    });

    test('isBusy bernilai true jika isLoading atau isStreaming aktif', () {
      const loadingState = ChatState(isLoading: true);
      expect(loadingState.isBusy, isTrue);

      const streamingState = ChatState(isStreaming: true);
      expect(streamingState.isBusy, isTrue);

      const idleState = ChatState(isLoading: false, isStreaming: false);
      expect(idleState.isBusy, isFalse);
    });

    test('copyWith memperbarui nilai state dengan benar', () {
      const initial = ChatState();
      final updated = initial.copyWith(
        messages: const [ChatMessage(text: 'Test', isUser: true)],
        isLoading: true,
      );

      expect(updated.messages.length, 1);
      expect(updated.messages.first.text, 'Test');
      expect(updated.isLoading, isTrue);
      expect(updated.isStreaming, isFalse);
      expect(updated.isBusy, isTrue);
    });
  });
}

