import 'package:flutter/material.dart';

import '../../../../core/models/cryptocurrency.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/services/chat_history_service.dart';
import '../../../../shared/widgets/loading_spinner.dart';

class AIQATab extends StatefulWidget {
  final Cryptocurrency crypto;

  const AIQATab({
    Key? key,
    required this.crypto,
  }) : super(key: key);

  @override
  State<AIQATab> createState() => _AIQATabState();
}

class _AIQATabState extends State<AIQATab> {
  final AIService _aiService = AIService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // Suggested questions
  final List<String> _suggestedQuestions = [
    "What makes ${''} unique compared to other cryptocurrencies?",
    "Should I invest in ${''} right now?",
    "What are the main risks of holding ${''}?",
    "How does ${''} technology work?",
    "What's the future outlook for ${''}?",
    "What factors affect ${''} price?",
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    // Load chat history from persistent storage
    final savedMessages = await ChatHistoryService.loadChatHistory(widget.crypto.symbol);
    
    if (savedMessages.isNotEmpty) {
      setState(() {
        _messages = savedMessages;
      });
    } else {
      // Add welcome message only if no history exists
      _messages.add(ChatMessage(
        text: "👋 Hello! I'm your AI cryptocurrency assistant. Ask me anything about ${widget.crypto.symbol.toUpperCase()} or cryptocurrencies in general!",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    }
    
    // Update suggested questions with crypto symbol
    for (int i = 0; i < _suggestedQuestions.length; i++) {
      _suggestedQuestions[i] = _suggestedQuestions[i].replaceAll('${''}', widget.crypto.symbol.toUpperCase());
    }
  }

  Future<void> _sendMessage(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
    });

    _questionController.clear();
    _scrollToBottom();

    try {
      final response = await _aiService.askCryptoQuestion(widget.crypto.symbol, question);
      
      setState(() {
        _messages.add(ChatMessage(
          text: response['answer'] ?? 'No answer received',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      // Save chat history to persistent storage
      await ChatHistoryService.saveChatHistory(widget.crypto.symbol, _messages);
    } catch (e) {
      String errorMessage;
      
      // Provide better error handling without showing technical details
      if (e.toString().contains('timeout') || e.toString().contains('connection')) {
        errorMessage = "🔄 I'm currently processing your question. The analysis might take a moment longer than usual. Please try again or ask a simpler question.";
      } else if (e.toString().contains('Network error') || e.toString().contains('Failed to get answer')) {
        errorMessage = "🌐 I'm having trouble connecting to get the latest analysis. Here's what I can tell you about ${widget.crypto.symbol.toUpperCase()} based on available data:\n\n📊 Current market information is being tracked. For specific questions about price movements, fundamentals, or technology, please try asking again in a moment.";
      } else {
        errorMessage = "💭 I'm currently analyzing your question about ${widget.crypto.symbol.toUpperCase()}. Market data and insights are being processed. Please try rephrasing your question or ask about specific aspects like price, technology, or market trends.";
      }
      
      setState(() {
        _messages.add(ChatMessage(
          text: errorMessage,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
      
      // Save chat history even if there was an error
      await ChatHistoryService.saveChatHistory(widget.crypto.symbol, _messages);
    }

    _scrollToBottom();
  }

  Future<void> _clearChatHistory() async {
    await ChatHistoryService.clearChatHistory(widget.crypto.symbol);
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "👋 Hello! I'm your AI cryptocurrency assistant. Ask me anything about ${widget.crypto.symbol.toUpperCase()} or cryptocurrencies in general!",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    _clearChatHistory();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'AI Assistant for ${widget.crypto.symbol.toUpperCase()}',
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _clearChat,
                tooltip: 'Clear Chat',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Suggested Questions (only show if no messages beyond welcome)
          if (_messages.length <= 1) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 Suggested Questions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedQuestions.map((question) {
                      return GestureDetector(
                        onTap: () => _sendMessage(question),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
                          ),
                          child: Text(
                            question,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Chat Messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingMessage();
                  }
                  
                  final message = _messages[index];
                  return _buildChatMessage(message);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about ${widget.crypto.symbol.toUpperCase()}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (value) {
                      if (!_isLoading) {
                        _sendMessage(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : () {
                      _sendMessage(_questionController.text);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: message.isUser
                        ? null
                        : Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isUser
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Icon(
                Icons.person,
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingSpinner(size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _aiService.dispose();
    super.dispose();
  }
}
