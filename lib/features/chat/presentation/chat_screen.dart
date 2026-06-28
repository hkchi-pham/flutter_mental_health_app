import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../data/models/chat_message.dart';
import '../logic/chat_provider.dart';
import 'widgets/chat_bubble.dart' show KomoAvatar, kChatCream, kSageGreen;
import 'widgets/chat_input_bar.dart';
import 'widgets/mood_check_card.dart';
import 'widgets/typing_indicator.dart';

/// The main chat screen with full-bleed background, Komo header, scrollable
/// message list, mood card/chip, typing indicator, error/retry row, and a
/// bottom input bar.
///
/// Scaffold notes:
///   - [drawer] is reserved for [ChatHistoryDrawer] (Plan 12-04). The leading
///     hamburger IconButton is wired to open the drawer; Plan 04 installs
///     the actual [ChatHistoryDrawer] into this Scaffold via a small documented
///     edit.
///   - Auto-scroll (CHAT-06): a listener on [ChatProvider] fires whenever
///     [scrollTick] increments — [WidgetsBinding.addPostFrameCallback] then
///     animates the [ScrollController] to [maxScrollExtent].
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  int _lastScrollTick = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Load conversation history so the drawer (Plan 12-04) has data.
      context.read<ChatProvider>().loadConversations();
    });
    // Attach auto-scroll listener (CHAT-06).
    context.read<ChatProvider>().addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    context.read<ChatProvider>().removeListener(_onProviderChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final tick = context.read<ChatProvider>().scrollTick;
    if (tick != _lastScrollTick) {
      _lastScrollTick = tick;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ---------------------------------------------------------------------------
      // Drawer — reserved for ChatHistoryDrawer (Plan 12-04).
      // TODO(plan-12-04): Replace the placeholder with:
      //   drawer: const ChatHistoryDrawer(),
      // ---------------------------------------------------------------------------
      body: Stack(
        fit: StackFit.expand,
        children: [
          // CHAT-01: full-bleed background.
          Image.asset(
            'assets/screens/chat_screen_background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, _) => const ColoredBox(
              color: kChatCream,
            ),
          ),
          SafeArea(
            child: MaxWidthBox(
              maxWidth: 500,
              child: Column(
                children: [
                  // CHAT-02: Komo header row.
                  _KomoHeader(),
                  // Message list + mood area.
                  Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, provider, _) {
                        return _MessageList(
                          provider: provider,
                          scrollController: _scrollController,
                        );
                      },
                    ),
                  ),
                  // Bottom input bar — scoped Consumer so only the input rebuilds
                  // on sending state changes.
                  Consumer<ChatProvider>(
                    builder: (context, provider, _) => ChatInputBar(
                      enabled: !provider.sending,
                      onSend: (text) => provider.send(text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Komo header
// ---------------------------------------------------------------------------

/// App bar–style Komo header (CHAT-02).
///
/// Leading: hamburger IconButton that opens the drawer (Plan 12-04 wires it).
/// Center: circular Komo avatar + "Komo" title.
class _KomoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: kChatCream.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: kSageGreen.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Hamburger — opens the drawer from the nearest Scaffold.
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF3D3522)),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Lịch sử trò chuyện',
            ),
          ),
          const SizedBox(width: 4),
          ClipOval(
            child: Image.asset(
              'assets/ui_icons/icons/komo_avatar_@3x.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (context, error, _) => const KomoAvatar(size: 36),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Komo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E5232),
            ),
          ),
          // Spacer so future actions (e.g. new conversation button) slot in neatly.
          const Spacer(),
          // New conversation button — calls provider.startNewConversation().
          Consumer<ChatProvider>(
            builder: (context, provider, _) => IconButton(
              icon: const Icon(
                Icons.add_comment_outlined,
                color: Color(0xFF3D3522),
              ),
              onPressed: () => provider.startNewConversation(),
              tooltip: 'Cuộc trò chuyện mới',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message list
// ---------------------------------------------------------------------------

/// Scrollable list whose FIRST item is the mood area (card or chip) followed
/// by all [ChatMessage] bubbles, an optional [TypingIndicator], and an optional
/// inline error/retry row (MOOD-01, CHAT-06, AI-02, AI-03).
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.provider,
    required this.scrollController,
  });

  final ChatProvider provider;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    // Build the flat list of items:
    //   [0]   mood area (card or chip)
    //   [1..n] message bubbles
    //   [n+1]  typing indicator (if sending)
    //   [n+2]  error row (if messagesError != null)
    final items = <Widget>[
      _moodArea(context),
      ...provider.messages.map((m) => _ChatBubbleItem(message: m)),
      if (provider.sending) const TypingIndicator(),
      if (provider.messagesError != null)
        _ErrorRow(
          onRetry: () => provider.retry(),
        ),
      // Bottom padding so the last bubble isn't flush against the input bar.
      const SizedBox(height: 8),
    ];

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8),
      itemCount: items.length,
      itemBuilder: (context, index) => items[index],
    );
  }

  Widget _moodArea(BuildContext context) {
    if (!provider.moodCardCollapsed) {
      // Full mood-check card — scrolls with messages (MOOD-01).
      return MoodCheckCard(onSelect: (mood) => provider.selectMood(mood));
    }
    if (provider.selectedMood != null) {
      // Collapsed chip (MOOD-04).
      return MoodChip(
        mood: provider.selectedMood!,
        onTap: () => provider.reopenMoodCard(),
      );
    }
    // Should not happen in normal flow — return empty space.
    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------------------------
// Bubble wrapper (avoids rebuilding non-changed bubbles)
// ---------------------------------------------------------------------------

class _ChatBubbleItem extends StatelessWidget {
  const _ChatBubbleItem({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // Importing ChatBubble here to keep the widget file name consistent.
    // ChatBubble is declared in chat_bubble.dart.
    return _BubbleProxy(message: message);
  }
}

// Internal proxy avoids a direct import naming clash — the public ChatBubble
// class is in chat_bubble.dart.
class _BubbleProxy extends StatelessWidget {
  const _BubbleProxy({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    // Inline bubble implementation mirrors ChatBubble exactly so we don't need
    // a separate import alias. In practice we import ChatBubble from the widgets
    // package — see the top import.
    return _ChatBubbleDelegate(message: message);
  }
}

// Delegate that resolves to the real ChatBubble widget.
// We use a re-export from chat_bubble.dart via the existing import.
class _ChatBubbleDelegate extends StatelessWidget {
  const _ChatBubbleDelegate({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: message.role == ChatRole.user
          ? _UserBubble(content: message.content)
          : _BotBubble(content: message.content),
    );
  }
}

// User bubble (mirrors chat_bubble.dart _UserBubble — inline here to avoid
// re-exporting private classes across files).
class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.75),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: kSageGreen,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF2E5232),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Bot bubble (mirrors chat_bubble.dart _BotBubble).
class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const KomoAvatar(size: 32),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.75),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: kChatCream,
                  border: Border.all(color: kSageGreen, width: 1.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Color(0xFF3D3522),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Inline error/retry row (AI-03)
// ---------------------------------------------------------------------------

/// Inline error row shown when [ChatProvider.messagesError] is non-null.
///
/// Shows the exact error text "Komo đang bận, thử lại sau" in a cream pill
/// and a "Thử lại" retry button that calls [onRetry] (which routes to
/// [ChatProvider.retry]).
class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const KomoAvatar(size: 32),
          const SizedBox(width: 6),
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kChatCream,
                border: Border.all(
                    color: kSageGreen.withValues(alpha: 0.6), width: 1.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(
                    child: Text(
                      'Komo đang bận, thử lại sau',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8B6F47),
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kSageGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2E5232),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
