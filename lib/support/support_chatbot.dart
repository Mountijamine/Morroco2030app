import 'package:flutter/material.dart';

class SupportChatbotScreen extends StatefulWidget {
  const SupportChatbotScreen({Key? key}) : super(key: key);

  @override
  State<SupportChatbotScreen> createState() => _SupportChatbotScreenState();
}

class _SupportChatbotScreenState extends State<SupportChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Add initial welcome message
    _addBotMessage("Hello! I'm your Morocco 2030 World Cup assistant. How can I help you today?");
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
      ));
    });
    _scrollToBottom();
  }

  void _handleSubmitted(String text) {
    _messageController.clear();
    
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });
    
    _scrollToBottom();
    
    // Simulate AI thinking time
    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _isTyping = false;
      });
      _generateResponse(text);
    });
  }

  void _generateResponse(String userMessage) {
    // Simple rule-based responses for common questions
    final String query = userMessage.toLowerCase();
    String response = '';
    
    if (query.contains('ticket') || query.contains('buy') || query.contains('purchase')) {
      response = "Tickets for World Cup 2030 matches will be available through the official FIFA website. We'll update the app with direct purchase options once they're released.";
    } 
    else if (query.contains('stadium') || query.contains('venue')) {
      response = "Morocco will host matches at several stadiums including venues in Casablanca, Rabat, Marrakech, and Tangier. You can find detailed stadium information in the 'Venues' section of the app.";
    }
    else if (query.contains('transport') || query.contains('travel') || query.contains('getting around')) {
      response = "Morocco offers various transportation options including trains, buses, and taxis. During the World Cup, there will be special shuttle services between stadiums and city centers.";
    }
    else if (query.contains('accommodation') || query.contains('hotel') || query.contains('stay')) {
      response = "We recommend booking accommodation well in advance. The app will feature partner hotels and discounted rates closer to the event.";
    }
    else if (query.contains('food') || query.contains('restaurant') || query.contains('eat')) {
      response = "Morocco offers delicious cuisine! You'll find restaurant recommendations in the 'Discover' section, featuring both local Moroccan and international options.";
    }
    else if (query.contains('hello') || query.contains('hi') || query.contains('hey')) {
      response = "Hello! I'm here to help with your World Cup 2030 questions. What would you like to know about?";
    }
    else {
      response = "I don't have specific information about that yet. As we get closer to World Cup 2030, we'll update the app with more details. Is there something else I can help you with?";
    }
    
    _addBotMessage(response);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support Chat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFDCB00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF065d67).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF065d67)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Typing...', style: TextStyle(color: Color(0xFF065d67))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4.0,
                  color: Colors.black12,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: _handleSubmitted,
                      decoration: InputDecoration(
                        hintText: "Ask a question...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF065d67),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () => _handleSubmitted(_messageController.text),
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

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFFDCB00),
              child: Icon(
                Icons.support_agent,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: isUser 
                    ? const Color(0xFF065d67) 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8.0),
        ],
      ),
    );
  }
}