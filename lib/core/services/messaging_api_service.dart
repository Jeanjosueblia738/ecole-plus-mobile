import '../network/api_client.dart';

class MessagingApiService {
  static Future<List<dynamic>> getConversations() async {
    final response = await ApiClient.instance.get('/messaging/conversations');
    return response.data as List<dynamic>;
  }

  static Future<List<dynamic>> getMessages(String conversationId) async {
    final response = await ApiClient.instance
        .get('/messaging/conversations/$conversationId/messages');
    return response.data as List<dynamic>;
  }

  static Future<Map<String, dynamic>> sendMessage(
      String conversationId, String content) async {
    final response = await ApiClient.instance.post(
      '/messaging/conversations/$conversationId/messages',
      data: {'content': content},
    );
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> createConversation({
    required String firstMessage,
    required List<String> participantIds,
    required List<String> participantTypes,
    String? subject,
    String type = 'DIRECT',
  }) async {
    final response =
        await ApiClient.instance.post('/messaging/conversations', data: {
      'firstMessage': firstMessage,
      'participantIds': participantIds,
      'participantTypes': participantTypes,
      if (subject != null) 'subject': subject,
      'type': type,
    });
    return response.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getRecipients() async {
    final response = await ApiClient.instance.get('/messaging/recipients');
    return response.data as Map<String, dynamic>;
  }

  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiClient.instance.get('/messaging/unread');
      return (response.data['unreadCount'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }
}
