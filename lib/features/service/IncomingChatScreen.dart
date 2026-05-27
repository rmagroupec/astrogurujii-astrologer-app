import 'package:flutter/material.dart';

class IncomingChatRequestScreen extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final String messagePreview;

  const IncomingChatRequestScreen({
    super.key,
    required this.userName,
    required this.userAvatar,
    required this.messagePreview,
  });

  @override
  State<IncomingChatRequestScreen> createState() =>
      _IncomingChatRequestScreenState();
}

class _IncomingChatRequestScreenState
    extends State<IncomingChatRequestScreen> {
  bool _isHandled = false;

  void _handleAccept() {
    if (_isHandled) return;
    setState(() => _isHandled = true);
    Navigator.of(context).pop('accept');
  }

  void _handleDecline() {
    if (_isHandled) return;
    setState(() => _isHandled = true);
    Navigator.of(context).pop('decline');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Chat Request"),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage(widget.userAvatar),
              ),
              const SizedBox(height: 16),
              Text(
                widget.userName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.messagePreview,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isHandled ? null : _handleAccept,
                      child: const Text("Accept"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isHandled ? null : _handleDecline,
                      child: const Text("Decline"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}