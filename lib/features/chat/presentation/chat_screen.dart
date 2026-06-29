import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/responsive.dart';
import '../data/models/chat_message.dart';
import '../logic/chat_provider.dart';
import 'widgets/chat_bubble.dart' show KomoAvatar, kChatCream, kSageGreen;
import 'widgets/chat_history_drawer.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/mood_check_card.dart';
import 'widgets/typing_indicator.dart';

/// The main chat screen with full-bleed background, Komo header, scrollable
/// message list, mood card/chip, typing indicator, error/retry row, and a
/// bottom input bar.
///
/// Scaffold notes:
///   - [drawer] is [ChatHistoryDrawer] (installed in Plan 12-04). The leading
///     hamburger IconButton calls [Scaffold.of(context).openDrawer()] via a
///     [Builder] so the correct [Scaffold] ancestor is found.
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
  // Cache the provider reference so dispose() never touches context.
  late final ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    // Read is safe in initState — context is available and the widget is
    // already attached to the tree.
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Load conversation history so ChatHistoryDrawer has data.
      _chatProvider.loadConversations();
    });
    // Attach auto-scroll listener (CHAT-06).
    _chatProvider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    // Use the cached reference — never call context.read in dispose().
    _chatProvider.removeListener(_onProviderChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    final tick = _chatProvider.scrollTick;
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
      // ChatHistoryDrawer installed in Plan 12-04 (HIST-01…06).
      drawer: const ChatHistoryDrawer(),
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
            child: Column(
              children: [
                // CHAT-02: Komo header row — full screen width (FIX B — 12-05).
                _KomoHeader(),
                // Message list + mood area — capped at 500 px so mood card and
                // bubbles don't stretch on wide screens (FIX B — 12-05).
                Expanded(
                  child: MaxWidthBox(
                    maxWidth: 500,
                    child: Consumer<ChatProvider>(
                      builder: (context, provider, _) {
                        return _MessageList(
                          provider: provider,
                          scrollController: _scrollController,
                        );
                      },
                    ),
                  ),
                ),
                // Bottom input bar — full screen width (FIX B — 12-05).
                // Scoped Consumer so only the input rebuilds on sending state
                // changes.
                Consumer<ChatProvider>(
                  builder: (context, provider, _) => ChatInputBar(
                    enabled: !provider.sending,
                    onSend: (text) => provider.send(text),
                  ),
                ),
              ],
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
/// Leading: hamburger IconButton that opens [ChatHistoryDrawer] via a [Builder].
/// Center: circular Komo avatar + "Komo" title.
/// Trailing: new-conversation button using new_chat_icon_@3x.png asset.
///
/// All sizes scale with the available band width (clamped) so the header
/// looks good on 360 px phones and wider tablets (responsive fix 7).
class _KomoHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        // Responsive sizes — clamped for 360 px phone → 500 px band.
        final avatarSize = (w * 0.09).clamp(32.0, 44.0);
        final titleFontSize = (w * 0.044).clamp(15.0, 20.0);
        final iconBtnSize = (w * 0.09).clamp(32.0, 44.0);
        final vPad = (w * 0.016).clamp(6.0, 12.0);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: vPad),
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
              SizedBox(width: w * 0.01),
              ClipOval(
                child: Image.asset(
                  'assets/ui_icons/icons/komo_avatar_@3x.png',
                  width: avatarSize,
                  height: avatarSize,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, _) =>
                      KomoAvatar(size: avatarSize),
                ),
              ),
              SizedBox(width: w * 0.02),
              Text(
                'Komo',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E5232),
                ),
              ),
              // Spacer pushes the new-conversation button to the right.
              const Spacer(),
              // New conversation button — PNG asset, falls back to Material icon.
              Consumer<ChatProvider>(
                builder: (context, provider, _) => GestureDetector(
                  onTap: () => provider.startNewConversation(),
                  child: Tooltip(
                    message: 'Cuộc trò chuyện mới',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Image.asset(
                        'assets/ui_icons/icons/new_chat_icon_@3x.png',
                        width: iconBtnSize,
                        height: iconBtnSize,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, _) => Icon(
                          Icons.add_comment_outlined,
                          color: const Color(0xFF3D3522),
                          size: iconBtnSize,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
