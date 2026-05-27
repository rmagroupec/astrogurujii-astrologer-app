import 'package:astrologer_app/features/service/provider/ChatProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  final String astroId;
  final String userId;
  final String userName;
  final String userAvatar;
  const ChatScreen({
    super.key,
    required this.channelId,
    required this.astroId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ChatProvider>(context, listen: false);

      provider.initializeChat(
        widget.channelId,
        widget.astroId,
        widget.userId,
        senderName: widget.userName,
      );
      provider.addListener(() {
        if (provider.chatEnded) {
          _onChatEnded(provider.endReason);
        }
      });

      provider.listenTyping(widget.userId); // 👈 listen to other user typing
      provider.markMessagesSeen();
    });
  }

  @override
  void dispose() {
    Provider.of<ChatProvider>(context, listen: false).disposeChat();
    _messageController.dispose();
    super.dispose();
  }

  bool _endSheetShown = false;

  void _onChatEnded(String reason) {
    if (_endSheetShown) return;
    _endSheetShown = true;

    // Close keyboard
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              Text(
                reason,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // bottom sheet
                  Navigator.pop(context); // chat screen
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildLoyaltyBanner(),
          Consumer<ChatProvider>(
            builder: (_, chat, __) {
              return chat.isOtherTyping
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: Text(
                        "Typing...",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          Expanded(child: _MessageList(astroId: widget.astroId)),

          _buildInputBar(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFEBC351),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade300,
            child: Image.network(widget.userAvatar, fit: BoxFit.cover),
          ),

          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${widget.userName}",
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
              const Text(
                "Chat in process",
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _showEndChatDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("End", style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoyaltyBanner() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: const [
          Icon(Icons.star, color: Colors.orange, size: 18),
          SizedBox(width: 8),
          Text(
            "Yay! Just 08:16 minutes more to become a loyal user.",
            style: TextStyle(color: Colors.brown, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context);
    if (chat.chatEnded) {
      return Container(
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: const Text("Chat ended", style: TextStyle(color: Colors.grey)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              // Image picker hook (same as Android)
            },
          ),
          Expanded(
            child: TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message",
                border: InputBorder.none,
              ),
              onChanged: (value) {
                Provider.of<ChatProvider>(
                  context,
                  listen: false,
                ).setTyping(value.isNotEmpty);
              },
            ),
          ),
          CircleAvatar(
            backgroundColor: const Color(0xFFEBC351),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black),
              onPressed: () {
                final text = _messageController.text.trim();
                if (text.isEmpty) return;

                Provider.of<ChatProvider>(
                  context,
                  listen: false,
                ).sendTextMessage(text);

                _messageController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEndChatDialog(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("End Chat"),
          content: const Text(
            "Are you sure you want to end this chat session?",
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("End Chat"),
              onPressed: () async {
                await chatProvider.endChatApi(widget.channelId);

                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}

class _MessageList extends StatefulWidget {
  final String astroId;
  const _MessageList({required this.astroId});

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 10),
          itemCount: chat.messages.length,
          itemBuilder: (context, index) {
            final msg = chat.messages[index];
            final bool isMe = msg.from == widget.astroId;

            return Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: const EdgeInsets.all(12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFFFF9C4) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    msg.type == "image"
                        ? Container()
                        : Text(
                            msg.message,
                            style: TextStyle(color: Colors.black),
                          ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chat.formatTime(msg.dateTime),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        if (isMe)
                          const Icon(
                            Icons.done_all,
                            size: 14,
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
