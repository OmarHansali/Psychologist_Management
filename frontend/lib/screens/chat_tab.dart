import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../utils/api_config.dart';

class ChatTab extends StatefulWidget {
  final String token;
  final int userId;
  final bool isPatient;
  const ChatTab({super.key, required this.token, required this.userId, this.isPatient = false});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  List conversations = [];
  List chatMessages = [];
  int? selectedConversationId;
  String? selectedName;
  final chatController = TextEditingController();
  bool isLoadingChat = false;
  bool isChatOpen = false;

  // Ajoute un timer pour le polling
  Duration pollingInterval = Duration(seconds: 3);
  bool pollingActive = false;

  @override
  void initState() {
    super.initState();
    fetchConversations();
    startPolling();
  }

  @override
  void dispose() {
    pollingActive = false;
    chatController.dispose();
    super.dispose();
  }

  void startPolling() async {
    pollingActive = true;
    while (pollingActive) {
      await Future.delayed(pollingInterval);
      if (!mounted) break;
      if (isChatOpen && selectedConversationId != null) {
        await fetchMessages(selectedConversationId!, selectedName ?? '', silent: true);
      } else {
        await fetchConversations();
      }
    }
  }

  Future<void> fetchConversations() async {
    setState(() { isLoadingChat = true; });
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        conversations = json.decode(response.body)['conversations'];
      });
    } else {
      setState(() {
        conversations = [];
      });
    }
    setState(() { isLoadingChat = false; });
  }

  Future<void> fetchMessages(int conversationId, String name, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        isLoadingChat = true;
        selectedConversationId = conversationId;
        selectedName = name;
        chatMessages = [];
        isChatOpen = true;
      });
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/messages/$conversationId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        chatMessages = json.decode(response.body)['messages'];
        selectedConversationId = conversationId;
        selectedName = name;
        isChatOpen = true;
      });
      // Marquer les messages comme vus
      await markMessagesAsSeen(conversationId);
    } else if (!silent) {
      setState(() {
        chatMessages = [];
      });
    }
    if (!silent) setState(() { isLoadingChat = false; });
  }

  Future<void> markMessagesAsSeen(int conversationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/messages/$conversationId/seen');
    await http.post(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    // Pas besoin de gérer la réponse ici, c'est juste pour notifier le backend
  }

  Future<void> sendMessage() async {
    if (selectedConversationId == null || chatController.text.trim().isEmpty) return;
    setState(() { isLoadingChat = true; });
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/messages');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'conversation_id': selectedConversationId,
        'content': chatController.text.trim(),
      }),
    );
    if (response.statusCode == 200) {
      chatController.clear();
      await fetchMessages(selectedConversationId!, selectedName ?? '');
    }
    setState(() { isLoadingChat = false; });
  }

  String getOtherName(Map conv) {
    if (widget.isPatient) {
      return conv['psychologist_name'] ?? 'Psychologue';
    } else {
      return conv['patient_name'] ?? 'Patient';
    }
  }

  Widget buildConversationList() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Conversations'),
        automaticallyImplyLeading: false,
      ),
      body: isLoadingChat
          ? Center(child: CircularProgressIndicator())
          : ListView(
              children: conversations.map<Widget>((conv) {
                final name = getOtherName(conv);
                final unread = conv['unread_count'] ?? 0;
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: conv['last_message'] != null
                      ? Text(conv['last_message']['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)
                      : Text('Aucun message'),
                  trailing: unread > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text('$unread', style: TextStyle(color: Colors.white, fontSize: 12)),
                        )
                      : null,
                  onTap: () => fetchMessages(conv['id'], name),
                );
              }).toList(),
            ),
    );
  }

  Widget buildChatArea() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              isChatOpen = false;
              selectedConversationId = null;
              selectedName = null;
              chatMessages = [];
            });
            fetchConversations();
          },
        ),
        title: Text('Chat avec $selectedName'),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoadingChat
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    reverse: true,
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = chatMessages[chatMessages.length - 1 - index];
                      final isMe = msg['sender_id'] == widget.userId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[400] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['content'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    msg['sent_at'] != null
                                        ? DateFormat('HH:mm').format(DateTime.parse(msg['sent_at']))
                                        : '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe ? Colors.white70 : Colors.grey[600],
                                    ),
                                  ),
                                  if (!isMe && msg['seen'] == true)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(Icons.done_all, size: 16, color: Colors.green),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: isLoadingChat ? null : sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Affiche la liste ou le chat plein écran selon l'état
    return isChatOpen ? buildChatArea() : buildConversationList();
  }
}