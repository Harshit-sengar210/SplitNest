import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Writes a system message document into `nests/{nestId}/Chats`.
///
/// Because Firestore transactions cannot include `await` after the first write,
/// we offer two entry points:
///
/// 1. [writeInTransaction] – use this when a Firestore [Transaction] is already
///    in progress. It calls `transaction.set(...)` so the chat message is
///    part of the same atomic write as the event that triggered it.
///
/// 2. [write] – use this when there is no open transaction (fire-and-forget
///    batch write outside a transaction).
///
/// All messages land in `nests/{nestId}/Chats` with `messageType = 'system'`
/// so the ChatTab renders them as centered information cards.
class SystemMessageService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Public: use inside a Firestore Transaction ─────────────────────────────

  /// Schedules a system message write as part of an open [transaction].
  /// Call this from inside `_firestore.runTransaction(...)`.
  static void writeInTransaction({
    required Transaction transaction,
    required String nestId,
    required String messageText,
  }) {
    final chatRef = _db
        .collection('nests')
        .doc(nestId)
        .collection('Chats')
        .doc(); // Firestore auto-ID

    final now = DateTime.now();

    transaction.set(chatRef, _buildPayload(nestId, messageText, now));

    // Also update nest-level chat metadata so the dashboard preview is correct
    final nestRef = _db.collection('nests').doc(nestId);
    transaction.update(nestRef, {
      'lastMessage': messageText,
      'lastMessageSender': 'System',
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageType': 'system',
    });
  }

  // ── Public: use outside a Firestore Transaction ────────────────────────────

  /// Writes a system message with a standalone batch commit.
  /// Prefer [writeInTransaction] when a transaction is available so the write
  /// is fully atomic with its companion event.
  static Future<void> write({
    required String nestId,
    required String messageText,
  }) async {
    final now = DateTime.now();
    final batch = _db.batch();

    final chatRef = _db
        .collection('nests')
        .doc(nestId)
        .collection('Chats')
        .doc();

    batch.set(chatRef, _buildPayload(nestId, messageText, now));

    final nestRef = _db.collection('nests').doc(nestId);
    batch.update(nestRef, {
      'lastMessage': messageText,
      'lastMessageSender': 'System',
      'lastMessageTime': Timestamp.fromDate(now),
      'lastMessageType': 'system',
    });

    await batch.commit();
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  static Map<String, dynamic> _buildPayload(
      String nestId, String messageText, DateTime now) {
    return {
      'groupId': nestId,
      'senderId': 'system',
      'senderName': 'System',
      'senderPhoto': null,
      'message': messageText,
      'messageType': 'system',
      'createdAt': FieldValue.serverTimestamp(),
      'editedAt': null,
      'isEdited': false,
      'isDeleted': false,
    };
  }

  // ── Message text factory methods ────────────────────────────────────────────
  // Centralise all message strings here so copy is consistent across the app.

  static String memberJoined(String memberName) =>
      '$memberName joined the nest 🎉';

  static String memberLeft(String memberName) =>
      '$memberName left the nest';

  static String expenseAdded({
    required String actorName,
    required String expenseTitle,
    required double amount,
    String currency = '₹',
  }) =>
      '$actorName added "$expenseTitle" — $currency${amount.toStringAsFixed(0)}';

  static String expenseUpdated({
    required String actorName,
    required String expenseTitle,
    required double newAmount,
    String currency = '₹',
  }) =>
      '$actorName updated "$expenseTitle" to $currency${newAmount.toStringAsFixed(0)}';

  static String expenseDeleted({
    required String actorName,
    required String expenseTitle,
  }) =>
      '$actorName deleted expense "$expenseTitle"';

  static String settlementCompleted({
    required String fromName,
    required String toName,
    required double amount,
    String currency = '₹',
  }) =>
      '$fromName paid $currency${amount.toStringAsFixed(0)} to $toName ✅';

  static String settlementUpdated({
    required String fromName,
    required String toName,
    required double oldAmount,
    required double newAmount,
    String currency = '₹',
  }) =>
      '$fromName updated payment to $toName: $currency${newAmount.toStringAsFixed(0)} (was $currency${oldAmount.toStringAsFixed(0)})';

  static String settlementDeleted({
    required String fromName,
    required String toName,
    required double amount,
    String currency = '₹',
  }) =>
      '$fromName removed settlement of $currency${amount.toStringAsFixed(0)} with $toName';

  static String cycleCompleted({
    required DateTime start,
    required DateTime end,
  }) {
    final formatter = DateFormat('MMM d, yyyy');
    return 'Cycle "${formatter.format(start)} - ${formatter.format(end)}" has been completed 🏁';
  }
}
