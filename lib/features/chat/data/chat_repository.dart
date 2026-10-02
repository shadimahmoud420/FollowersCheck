import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/message.dart';

abstract interface class ChatRepository {
  Future<Conversation> conversation(String id);
  Stream<List<ChatMessage>> watchMessages(String conversationId);
  Future<void> send(String conversationId, {String body, String? meetingPoint, Uint8List? jpegImage});
  Future<void> markRead(String conversationId);
  Future<String> imageUrl(String path);
}

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this._db);
  final SupabaseClient _db;

  String get _uid => _db.auth.currentUser!.id;

  @override
  Future<Conversation> conversation(String id) async {
    final row = await _db.from('conversations').select().eq('id', id).single();
    return Conversation.fromJson(row);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) => _db
      .from('messages')
      .stream(primaryKey: ['id'])
      .eq('conversation_id', conversationId)
      .order('id', ascending: false)
      .limit(200)
      .map((rows) => rows.map(ChatMessage.fromJson).toList());

  @override
  Future<void> send(String conversationId,
      {String body = '', String? meetingPoint, Uint8List? jpegImage}) async {
    String? imagePath;
    if (jpegImage != null) {
      imagePath = '$_uid/$conversationId/${const Uuid().v4()}.jpg';
      await _db.storage.from('chat-images').uploadBinary(
            imagePath,
            jpegImage,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
    }
    await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': _uid,
      'body': body.trim(),
      'image_path': imagePath,
      'meeting_point': (meetingPoint?.trim().isEmpty ?? true) ? null : meetingPoint!.trim(),
    });
  }

  @override
  Future<void> markRead(String conversationId) => _db
      .from('messages')
      .update({'read_at': DateTime.now().toUtc().toIso8601String()})
      .eq('conversation_id', conversationId)
      .neq('sender_id', _uid)
      .isFilter('read_at', null);

  @override
  Future<String> imageUrl(String path) =>
      _db.storage.from('chat-images').createSignedUrl(path, 60 * 60);
}
