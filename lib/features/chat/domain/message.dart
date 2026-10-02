class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    this.imagePath,
    this.meetingPoint,
    required this.createdAt,
    this.readAt,
  });

  final int id;
  final String conversationId;
  final String senderId;
  final String body;
  final String? imagePath;
  final String? meetingPoint;
  final DateTime createdAt;
  final DateTime? readAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as int,
        conversationId: j['conversation_id'] as String,
        senderId: j['sender_id'] as String,
        body: j['body'] as String? ?? '',
        imagePath: j['image_path'] as String?,
        meetingPoint: j['meeting_point'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at'] as String),
      );
}

class Conversation {
  const Conversation({
    required this.id,
    required this.offerId,
    required this.userA,
    required this.userB,
    required this.lastMessageAt,
  });

  final String id;
  final String offerId;
  final String userA;
  final String userB;
  final DateTime lastMessageAt;

  String otherUser(String uid) => uid == userA ? userB : userA;

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id: j['id'] as String,
        offerId: j['offer_id'] as String,
        userA: j['user_a'] as String,
        userB: j['user_b'] as String,
        lastMessageAt: DateTime.parse(j['last_message_at'] as String),
      );
}
