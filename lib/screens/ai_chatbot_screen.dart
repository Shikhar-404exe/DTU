/// AI Chatbot Screen with Voice Interface
/// Main conversational UI with TTS/STT integration

import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../services/voice_service.dart';
import '../services/youtube_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({Key? key}) : super(key: key);

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String? _sessionId;
  String _userId = 'user_001';
  ChatMode _currentMode = ChatMode.auto;
  bool _isLoading = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _initializeSession();
    VoiceService.initTTS();
    VoiceService.initSTT();
  }

  Future<void> _initializeSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id') ?? 'user_001';

    final sessionId = await ChatbotService.createSession(
      userId: _userId,
      mode: _currentMode,
    );

    if (sessionId != null) {
      setState(() {
        _sessionId = sessionId;
      });

      // Load history
      final history = await ChatbotService.getHistory(sessionId: sessionId);
      setState(() {
        _messages.addAll(history);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _sessionId == null) return;

    final userMessage = ChatMessage(
      role: 'user',
      content: text,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // Send to backend
    final response = await ChatbotService.sendMessage(
      sessionId: _sessionId!,
      message: text,
      mode: _currentMode,
    );

    setState(() {
      _isLoading = false;
    });

    if (response != null && response['success']) {
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response['response'],
        agentId: response['agent_id'],
        mode: response['mode'],
      );

      setState(() {
        _messages.add(assistantMessage);
      });
      _scrollToBottom();

      // Auto-speak response
      if (mounted) {
        _speakMessage(response['response']);
      }
    } else {
      _showError('Failed to get response');
    }
  }

  Future<void> _speakMessage(String text) async {
    setState(() {
      _isSpeaking = true;
    });

    await VoiceService.speak(
      text: text,
      language: _selectedLanguage,
      useOnline: _currentMode != ChatMode.offline,
    );

    if (mounted) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _startListening() async {
    if (_isListening) return;

    setState(() {
      _isListening = true;
    });

    final result = await VoiceService.listen(
      language: '${_selectedLanguage}-IN',
      timeout: const Duration(seconds: 10),
      onResult: (text) {
        if (mounted && text.isNotEmpty) {
          _messageController.text = text;
        }
      },
    );

    setState(() {
      _isListening = false;
    });

    if (result != null && result.isNotEmpty) {
      _sendMessage(result);
    }
  }

  Future<void> _stopSpeaking() async {
    await VoiceService.stop();
    setState(() {
      _isSpeaking = false;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          // Language selector
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (lang) {
              setState(() {
                _selectedLanguage = lang;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'hi', child: Text('हिंदी')),
              const PopupMenuItem(value: 'pa', child: Text('ਪੰਜਾਬੀ')),
              const PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
              const PopupMenuItem(value: 'te', child: Text('తెలుగు')),
            ],
          ),
          // Mode selector
          PopupMenuButton<ChatMode>(
            icon: Icon(_currentMode == ChatMode.offline
                ? Icons.cloud_off
                : _currentMode == ChatMode.online
                    ? Icons.cloud
                    : Icons.cloud_queue),
            onSelected: (mode) {
              setState(() {
                _currentMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ChatMode.auto,
                child: Row(
                  children: [
                    Icon(Icons.cloud_queue),
                    SizedBox(width: 8),
                    Text('Auto'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ChatMode.online,
                child: Row(
                  children: [
                    Icon(Icons.cloud),
                    SizedBox(width: 8),
                    Text('Online'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ChatMode.offline,
                child: Row(
                  children: [
                    Icon(Icons.cloud_off),
                    SizedBox(width: 8),
                    Text('Offline'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('AI is thinking...'),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice input button
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : null,
                  ),
                  onPressed: _isListening ? null : _startListening,
                ),

                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),

                // Stop speaking button (when speaking)
                if (_isSpeaking)
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    onPressed: _stopSpeaking,
                  ),

                // Send button
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (message.agentId != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'via ${message.agentId}',
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    VoiceService.stop();
    super.dispose();
  }
}
