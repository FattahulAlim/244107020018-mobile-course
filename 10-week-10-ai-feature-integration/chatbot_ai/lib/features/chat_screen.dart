import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';

// ---------------------------------------------------------------
// Model & State
// ---------------------------------------------------------------
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading; // nunggu respons dari API
  final bool isStreaming; // teks AI lagi "diketik"

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
  });

  bool get isBusy => isLoading || isStreaming;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isStreaming,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

// ---------------------------------------------------------------
// Provider
// ---------------------------------------------------------------
final aiServiceProvider = Provider<AiService>((ref) => AiService());

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.isBusy) return;

    // 1. Tambah pesan user + nyalakan loading
    state = state.copyWith(
      messages: [...state.messages, ChatMessage(text: question, isUser: true)],
      isLoading: true,
    );

    try {
      // 2. Panggil AI
      final answer = await ref.read(aiServiceProvider).ask(question);

      // 3. Siapkan bubble kosong untuk AI, lalu "ketik" pelan-pelan
      state = state.copyWith(
        messages: [...state.messages, const ChatMessage(text: '', isUser: false)],
        isLoading: false,
        isStreaming: true,
      );
      await _typewriter(answer);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(text: msg, isUser: false, isError: true),
        ],
        isLoading: false,
      );
    } finally {
      state = state.copyWith(isLoading: false, isStreaming: false);
    }
  }

  /// Efek streaming: munculin teks sedikit demi sedikit.
  Future<void> _typewriter(String full) async {
    const chunkSize = 3;
    var end = 0;
    while (end < full.length) {
      end = (end + chunkSize).clamp(0, full.length);
      _updateLastMessage(full.substring(0, end));
      await Future.delayed(const Duration(milliseconds: 20));
    }
  }

  void _updateLastMessage(String text) {
    final msgs = [...state.messages];
    msgs[msgs.length - 1] = ChatMessage(text: text, isUser: false);
    state = state.copyWith(messages: msgs);
  }
}

// ---------------------------------------------------------------
// UI
// ---------------------------------------------------------------
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).send(text);
  }

  Future<void> _showApiKeyDialog() async {
    final keyController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Atur API Key'),
        content: TextField(
          controller: keyController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Tempel API key di sini'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved == true && keyController.text.trim().isNotEmpty) {
      await ref.read(aiServiceProvider).saveApiKey(keyController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key tersimpan')),
      );
    }
    keyController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);

    // Auto-scroll tiap ada perubahan pesan
    ref.listen<ChatState>(chatProvider, (_, _) => _scrollToBottom()); // Tadi underscore kanan double

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Atur API key',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty && !chat.isLoading
                ? const Center(child: Text('Tanya apa saja ke AI 👋'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: chat.messages.length + (chat.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chat.messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: chat.messages[index]);
                    },
                  ),
          ),
          _buildInputBar(chat),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatState chat) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !chat.isBusy,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Ketik pertanyaan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: chat.isBusy ? null : _send,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    final bgColor = message.isError
        ? scheme.errorContainer
        : isUser
            ? scheme.primary
            : scheme.surfaceContainerHighest;
    final textColor = message.isError
        ? scheme.onErrorContainer
        : isUser
            ? scheme.onPrimary
            : scheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}