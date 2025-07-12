import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class ChatHistoryService {
  static const String _keyPrefix = 'chat_history_';
  
  static Future<void> saveChatHistory(String cryptoSymbol, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$cryptoSymbol';
    final messagesJson = messages.map((msg) => msg.toJson()).toList();
    await prefs.setString(key, jsonEncode(messagesJson));
  }
  
  static Future<List<ChatMessage>> loadChatHistory(String cryptoSymbol) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$cryptoSymbol';
    final messagesJson = prefs.getString(key);
    
    if (messagesJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(messagesJson);
    return decoded.map((json) => ChatMessage.fromJson(json)).toList();
  }
  
  static Future<void> clearChatHistory(String cryptoSymbol) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$cryptoSymbol';
    await prefs.remove(key);
  }
  
  static Future<void> clearAllChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (String key in keys) {
      await prefs.remove(key);
    }
  }
}
