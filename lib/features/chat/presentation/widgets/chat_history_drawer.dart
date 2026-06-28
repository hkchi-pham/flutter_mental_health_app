import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/chat_date_group.dart';
import '../../logic/chat_provider.dart';

/// Left-side history drawer for the chat screen (HIST-01…06).
///
/// Structure:
///   1. Header — circular Komo avatar + "Cuộc trò chuyện" label.
///   2. "+ Cuộc trò chuyện mới" button — resets provider, closes the drawer.
///   3. Expanded body — state machine:
///      - loading (first load): centred [CircularProgressIndicator].
///      - error (no conversations loaded): error text + "Thử lại" button.
///      - empty (loaded, none): centred "Chào bạn! Bắt đầu trò chuyện nhé!".
///      - normal: [ListView] grouped by [ChatDateGroup] (Hôm nay … Tháng này),
///        each row [Dismissible] for swipe-to-delete + [confirmDismiss] dialog.
///        Active conversation row is highlighted in sage-green.
class ChatHistoryDrawer extends StatelessWidget {
  const ChatHistoryDrawer({super.key});

  // ---------------------------------------------------------------------------
  // Color tokens (mirroring chat_bubble.dart constants)
  // ---------------------------------------------------------------------------

  static const Color _cream = Color(0xFFFFF8E7);
  static const Color _sageGreen = Color(0xFFA5D6A7);
  static const Color _activeBg = Color(0x33A5D6A7); // sage-green ~20 % alpha
  static const Color _accentBar = Color(0xFFA5D6A7); // left accent bar
  static const Color _spinnerColor = Color(0xFF6B8E5A);
  static const Color _dialogBg = Color(0xFFFCF6E8);
  static const Color _headerText = Color(0xFF2E5232);
  static const Color _mutedText = Color(0xFF7A6952);
  static const Color _groupLabel = Color(0xFF8A7564);

  // ---------------------------------------------------------------------------
  // Public widget
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _cream,
      child: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, provider, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header.
                _buildHeader(),

                const Divider(height: 1, thickness: 1, color: Color(0xFFD9CDB9)),

                // 2. New conversation button.
                _buildNewConversationButton(context, provider),

                const Divider(height: 1, thickness: 1, color: Color(0xFFD9CDB9)),

                // 3. Expandable conversation body.
                Expanded(child: _buildBody(context, provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1: Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Komo avatar (HIST-01).
          ClipOval(
            child: Image.asset(
              'assets/ui_icons/icons/komo_avatar_@3x.png',
              width: 40,
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, _) => Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _sageGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Cuộc trò chuyện',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _headerText,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2: New conversation button (HIST-02)
  // ---------------------------------------------------------------------------

  Widget _buildNewConversationButton(
      BuildContext context, ChatProvider provider) {
    return ListTile(
      leading: const Icon(Icons.add, color: _headerText),
      title: const Text(
        '+ Cuộc trò chuyện mới',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _headerText,
        ),
      ),
      onTap: () {
        provider.startNewConversation();
        Navigator.of(context).pop(); // close drawer
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3: Conversation body state machine (HIST-06)
  // ---------------------------------------------------------------------------

  Widget _buildBody(BuildContext context, ChatProvider provider) {
    final conversations = provider.conversations;
    final loading = provider.conversationsLoading;
    final error = provider.conversationsError;

    // Loading state (first fetch — no conversations yet).
    if (loading && conversations.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            color: _spinnerColor,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    // Error state (fetch failed — no cached conversations).
    if (error != null && conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Không thể tải lịch sử.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: _mutedText),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => provider.loadConversations(),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: _headerText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state (loaded successfully, no conversations).
    if (conversations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Chào bạn! Bắt đầu trò chuyện nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _mutedText),
          ),
        ),
      );
    }

    // Normal state: grouped conversation list.
    return _ConversationList(provider: provider);
  }
}

// ---------------------------------------------------------------------------
// Grouped conversation list
// ---------------------------------------------------------------------------

/// Builds the grouped [ListView] from [provider.groupedConversations()].
///
/// Renders group header rows (Hôm nay, Hôm qua, Tuần này, Tháng này) followed
/// by individual conversation rows, each wrapped in a [Dismissible].
class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.provider});

  final ChatProvider provider;

  @override
  Widget build(BuildContext context) {
    final grouped = provider.groupedConversations();

    // Flatten into a list of widgets: header + row items per group.
    final items = <Widget>[];
    for (final entry in grouped.entries) {
      final group = entry.key;
      final conversations = entry.value;

      // Group header.
      items.add(_GroupHeader(label: group.label));

      // Conversation rows.
      for (final conv in conversations) {
        items.add(
          _ConversationRow(
            conv: conv,
            isActive: conv.id == provider.activeConversationId,
            onTap: () {
              provider.openConversation(conv.id);
              Navigator.of(context).pop(); // close drawer (HIST-04)
            },
            onDelete: () => provider.deleteConversation(conv.id),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      children: items,
    );
  }
}

// ---------------------------------------------------------------------------
// Group header row
// ---------------------------------------------------------------------------

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: ChatHistoryDrawer._groupLabel,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Conversation row (Dismissible, active highlight)
// ---------------------------------------------------------------------------

/// A single conversation row with:
///   - Swipe-to-delete (endToStart) + confirm dialog (HIST-05).
///   - Active conversation sage-green highlight + 4 px left accent bar (HIST-05).
///   - Tap → [onTap] (HIST-04).
class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.conv,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final dynamic conv; // Conversation
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChatHistoryDrawer._dialogBg,
        title: const Text(
          'Xoá cuộc trò chuyện?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A2E20),
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Cuộc trò chuyện này sẽ bị xoá vĩnh viễn.',
          style: TextStyle(color: Color(0xFF6B5A45), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Xoá',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (conv.title as String?) ?? 'Cuộc trò chuyện';
    final shortDate = itemShortDate(conv.createdAt as DateTime);

    return Dismissible(
      key: ValueKey(conv.id as String),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFFE53935).withValues(alpha: 0.85),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: _RowContent(
        title: title,
        shortDate: shortDate,
        isActive: isActive,
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row content with active highlight
// ---------------------------------------------------------------------------

class _RowContent extends StatelessWidget {
  const _RowContent({
    required this.title,
    required this.shortDate,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final String shortDate;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? ChatHistoryDrawer._activeBg : Colors.transparent,
          border: isActive
              ? const Border(
                  left: BorderSide(
                    color: ChatHistoryDrawer._accentBar,
                    width: 4,
                  ),
                )
              : null,
        ),
        padding: EdgeInsets.fromLTRB(
          isActive ? 12 : 16, // compensate for the 4 px left border
          10,
          12,
          10,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? ChatHistoryDrawer._headerText
                      : const Color(0xFF3D3522),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              shortDate,
              style: const TextStyle(
                fontSize: 12,
                color: ChatHistoryDrawer._mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
