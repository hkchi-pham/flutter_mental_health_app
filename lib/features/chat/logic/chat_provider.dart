import 'package:flutter/foundation.dart';

import '../data/chat_repository.dart';
import '../data/models/chat_message.dart';
import '../data/models/conversation.dart';
import 'chat_date_group.dart';
import 'mood.dart';

/// State machine for the AI chat feature.
///
/// Owns:
///   - The conversation list with date-grouped access for the drawer (HIST-01/03).
///   - The active conversation's message thread (HIST-04).
///   - The selected mood and card/chip state (MOOD-02/03/04).
///   - Lazy conversation creation on first send (HIST-02).
///   - Optimistic user bubbles + typing indicator + error/retry state (AI-01/02/03).
///   - Auto-scroll trigger via [scrollTick] (CHAT-06).
///
/// Mirroring the [JournalProvider] / [GardenProvider] `ChangeNotifierProxyProvider`
/// wiring pattern in `main.dart`.
class ChatProvider extends ChangeNotifier {
  ChatProvider({required ChatRepository repository})
      : _repo = repository;

  final ChatRepository _repo;

  // ---------------------------------------------------------------------------
  // Conversation list state  (HIST-01/06)
  // ---------------------------------------------------------------------------

  /// Full conversation list, sorted newest-first by [Conversation.createdAt].
  List<Conversation> conversations = [];

  /// True while [loadConversations] is in flight. (HIST-06)
  bool conversationsLoading = false;

  /// Non-null when [loadConversations] failed. (HIST-06)
  String? conversationsError;

  // ---------------------------------------------------------------------------
  // Active conversation state
  // ---------------------------------------------------------------------------

  /// The id of the currently open conversation, or `null` when a fresh
  /// (not-yet-sent) new conversation is being composed. (HIST-02 lazy-create)
  String? activeConversationId;

  /// Messages of the active conversation, in chronological order.
  List<ChatMessage> messages = [];

  /// True while [openConversation] is fetching messages. (HIST-04)
  bool messagesLoading = false;

  /// Non-null when message loading or sending failed. (AI-03)
  String? messagesError;

  // ---------------------------------------------------------------------------
  // Mood state  (MOOD-02/03/04)
  // ---------------------------------------------------------------------------

  /// The mood the user has selected for this conversation, or `null`.
  Mood? selectedMood;

  /// Whether the mood full-card has been collapsed to the pinned chip.
  ///
  /// - `false`: fresh conversation — the full mood-select card is shown.
  /// - `true`:  a mood was chosen (or the conversation already existed) — only
  ///   the pinned chip is shown. Set to `true` always for existing conversations
  ///   so [openConversation] never shows the full card again (MOOD-04).
  bool moodCardCollapsed = false;

  // ---------------------------------------------------------------------------
  // Send / typing / error / retry state  (AI-01/02/03)
  // ---------------------------------------------------------------------------

  /// True while awaiting the bot reply. Blocks the send button (CHAT-04/AI-02).
  bool sending = false;

  /// The exact composed text of the last failed send. [retry] resends this
  /// without re-appending a user bubble. Cleared on success or new send. (AI-03)
  String? lastFailedText;

  // ---------------------------------------------------------------------------
  // Auto-scroll trigger  (CHAT-06)
  // ---------------------------------------------------------------------------

  /// Incremented whenever [messages] changes so UI listeners can scroll to the
  /// newest message. The value itself is meaningless — only changes matter.
  int scrollTick = 0;

  // ---------------------------------------------------------------------------
  // Conversation list  (HIST-01/03/06)
  // ---------------------------------------------------------------------------

  /// Loads (or reloads) the conversation list from the repository.
  ///
  /// Titles are already derived from the first-message store inside
  /// [ChatRepository.listConversations] — no further derivation here.
  ///
  /// HIST-01/03/06.
  Future<void> loadConversations() async {
    conversationsLoading = true;
    conversationsError = null;
    notifyListeners();

    try {
      final list = await _repo.listConversations();
      // Sort newest-first (HIST-03).
      conversations = list
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      conversationsError = '$e';
    } finally {
      conversationsLoading = false;
      notifyListeners();
    }
  }

  /// Returns conversations bucketed by [ChatDateGroup] for the drawer.
  ///
  /// Preserves the newest-first ordering within each group. Only groups that
  /// contain at least one conversation are included (keys in enum order).
  ///
  /// HIST-03.
  Map<ChatDateGroup, List<Conversation>> groupedConversations() {
    final map = <ChatDateGroup, List<Conversation>>{};
    for (final conv in conversations) {
      final group = chatDateGroup(conv.createdAt);
      map.putIfAbsent(group, () => []).add(conv);
    }
    // Return only non-empty groups in the canonical enum order.
    final result = <ChatDateGroup, List<Conversation>>{};
    for (final group in ChatDateGroup.values) {
      if (map.containsKey(group)) result[group] = map[group]!;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Navigation / lifecycle  (HIST-02/04/05/MOOD-04)
  // ---------------------------------------------------------------------------

  /// Resets to a fresh, unsent new conversation.
  ///
  /// No POST is made here — the conversation is created lazily on the first
  /// send (HIST-02). The mood card is shown again so the user can pick a mood.
  void startNewConversation() {
    activeConversationId = null;
    messages = [];
    selectedMood = null;
    moodCardCollapsed = false;
    sending = false;
    messagesError = null;
    lastFailedText = null;
    notifyListeners();
  }

  /// Opens an existing conversation and loads its messages.
  ///
  /// Mood recovery (MOOD-04): reads the first-message map once and calls
  /// [moodFromFirstMessage] on the stored entry for [id]. If no stored entry
  /// exists (e.g. conversation created on another device), falls back to parsing
  /// the first user message in the freshly-loaded thread. If still null, uses
  /// [Mood.normal] as the unknown-mood sentinel so the pinned chip always renders.
  ///
  /// [moodCardCollapsed] is always set to `true` for existing conversations — the
  /// full mood card is never shown again once a conversation has messages. (MOOD-04)
  ///
  /// HIST-04.
  Future<void> openConversation(String id) async {
    activeConversationId = id;
    messagesLoading = true;
    messages = [];
    notifyListeners();

    try {
      // Load messages.
      final loaded = await _repo.loadMessages(id);
      messages = loaded;

      // MOOD-04: recover mood from the stored first-message string (same source
      // the drawer title is derived from — no separate fetch).
      final firstMsgMap = await _repo.firstMessages();
      Mood? recovered = moodFromFirstMessage(firstMsgMap[id]);

      // Fallback: parse the first user message from the loaded thread.
      if (recovered == null) {
        final firstUserMsg = messages
            .where((m) => m.role == ChatRole.user)
            .map((m) => m.content)
            .firstOrNull;
        recovered = moodFromFirstMessage(firstUserMsg);
      }

      // Final fallback: use Mood.normal so the pinned chip always renders.
      selectedMood = recovered ?? Mood.normal;

      // Existing conversations always show the collapsed pinned chip (MOOD-04).
      moodCardCollapsed = true;
    } catch (e) {
      messagesError = '$e';
    } finally {
      messagesLoading = false;
      scrollTick++;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Mood selection  (MOOD-02/03/04)
  // ---------------------------------------------------------------------------

  /// Records the user's mood selection and collapses the card to the pinned chip.
  ///
  /// MOOD-02/03/04.
  void selectMood(Mood m) {
    selectedMood = m;
    moodCardCollapsed = true;
    notifyListeners();
  }

  /// Re-expands the full mood-select card (e.g. user taps the pinned chip to
  /// change their mood before sending the first message).
  void reopenMoodCard() {
    moodCardCollapsed = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Send / retry  (AI-01/02/03, HIST-02/03, MOOD-03)
  // ---------------------------------------------------------------------------

  /// Sends [text] as the next user message.
  ///
  /// Guards:
  ///   - Returns immediately if [sending] is true (one-question-one-answer, CHAT-04).
  ///   - Returns immediately when both [text] is blank AND no mood is selected
  ///     (empty send makes no sense).
  ///
  /// Mood prepend (MOOD-03): if this is the first user message in the thread AND
  /// a mood is selected, prepends `selectedMood.prependSentence` to the content.
  /// The composed content (including the prepend) is shown in the user's own bubble.
  ///
  /// Lazy create (HIST-02): `POST /conversations/` fires here on the FIRST send
  /// of a fresh conversation (when [activeConversationId] is null).
  ///
  /// First-message persistence (HIST-03 / MOOD-04): on a successful first send,
  /// calls [ChatRepository.saveFirstMessage] so the drawer row shows a real title
  /// and [openConversation] can recover the mood from the same string — both from
  /// a single stored value.
  ///
  /// AI-03: on error the user bubble is kept in place; [messagesError] and
  /// [lastFailedText] are set so [retry] can resend.
  Future<void> send(String text) async {
    if (sending) return;
    if (text.trim().isEmpty && selectedMood == null) return;

    // Determine whether this is the conversation's first user message.
    final isFirstUserMessage =
        messages.where((m) => m.role == ChatRole.user).isEmpty;

    // Compose content: prepend mood sentence on the first message if a mood
    // is selected (MOOD-03).
    String content = text;
    if (isFirstUserMessage && selectedMood != null) {
      content = '${selectedMood!.prependSentence}$text';
    }

    // Optimistic user bubble.
    final userMsg = ChatMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      role: ChatRole.user,
      content: content,
    );
    messages = [...messages, userMsg];
    sending = true;
    messagesError = null;
    lastFailedText = null;
    scrollTick++;
    notifyListeners();

    await _dispatch(content, alreadyAppended: true, isFirstMessage: isFirstUserMessage);
  }

  /// Resends [lastFailedText] without duplicating the user bubble.
  ///
  /// The user bubble was already appended by the original [send] call. This
  /// method calls into [_dispatch] with `alreadyAppended: true` so it only
  /// (re-)creates the conversation if needed and calls sendChat + saves on
  /// success.
  ///
  /// AI-03.
  Future<void> retry() async {
    final text = lastFailedText;
    if (text == null) return;
    lastFailedText = null;
    messagesError = null;

    // The user bubble is already shown. Determine whether the first message
    // has ever been persisted (i.e. are we still on the first send attempt?).
    // A successful send would have already persisted and reloaded — if
    // activeConversationId is null we are still pre-create.
    final isFirstMessage =
        messages.where((m) => m.role == ChatRole.user).length == 1;

    sending = true;
    notifyListeners();

    await _dispatch(text, alreadyAppended: true, isFirstMessage: isFirstMessage);
  }

  /// Shared send/retry logic.
  ///
  /// Handles:
  ///   1. Lazy conversation creation (HIST-02) — `POST /conversations/` fires
  ///      only once, on the first send.
  ///   2. `POST /messages/chat` and bot reply appending (AI-01).
  ///   3. First-message persistence on success (HIST-03 / MOOD-04) — only when
  ///      [isFirstMessage] is true and the send succeeds.
  ///   4. Conversation list refresh so the drawer shows the new entry with its
  ///      derived title.
  ///   5. Error capture — sets [messagesError] and [lastFailedText] (AI-03).
  ///
  /// [alreadyAppended] must always be `true` here; the parameter is kept for
  /// clarity and to guard against future callers.
  Future<void> _dispatch(
    String content, {
    required bool alreadyAppended,
    required bool isFirstMessage,
  }) async {
    assert(alreadyAppended, '_dispatch expects the user bubble already in messages');

    try {
      // Lazy create: fire POST /conversations/ on the very first send.
      if (activeConversationId == null) {
        final id = await _repo.createConversation();
        activeConversationId = id;
      }
      final id = activeConversationId!;

      // Send to AI and append bot reply.
      final reply = await _repo.sendChat(
        conversationId: id,
        content: content,
      );
      final botMsg = ChatMessage(
        id: 'bot_${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.bot,
        content: reply,
      );
      messages = [...messages, botMsg];

      // Persist first message on success so title + mood recovery both work
      // from the same stored string (HIST-03 / MOOD-04).
      if (isFirstMessage) {
        await _repo.saveFirstMessage(id, content);
        // Refresh the conversation list so the drawer shows the new entry.
        await loadConversations();
      }
    } catch (e) {
      messagesError = 'Komo đang bận, thử lại sau';
      lastFailedText = content;
    } finally {
      sending = false;
      scrollTick++;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Delete  (HIST-05)
  // ---------------------------------------------------------------------------

  /// Deletes [id] from the backend and removes it from the local list.
  ///
  /// If [id] is the currently open conversation, resets to a fresh view via
  /// [startNewConversation] (per CONTEXT: deleting the active conversation
  /// clears the chat screen to a new-conversation state).
  ///
  /// HIST-05.
  Future<void> deleteConversation(String id) async {
    await _repo.deleteConversation(id);
    conversations = conversations.where((c) => c.id != id).toList();
    if (id == activeConversationId) {
      startNewConversation();
    }
    notifyListeners();
  }
}
