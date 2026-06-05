// lib/features/account/SupportChatScreen.dart

import 'dart:convert';
import 'package:astrologer_app/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// ─── Models ───────────────────────────────────────────────────────────────────

class SupportTicket {
  final String id;
  final String ticketNo;
  final String category;
  final String subject;
  final String message;
  final String status;
  final String adminReply;
  final String createdAt;

  const SupportTicket({
    required this.id,
    required this.ticketNo,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.adminReply,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id        : j['id']?.toString()          ?? '',
        ticketNo  : j['ticket_no']?.toString()   ?? '',
        category  : j['category']?.toString()    ?? 'Other',
        subject   : j['subject']?.toString()     ?? '',
        message   : j['message']?.toString()     ?? '',
        status    : j['status']?.toString()      ?? 'Open',
        adminReply: j['admin_reply']?.toString() ?? '',
        createdAt : j['created_at']?.toString()  ?? '',
      );
}

class SupportMessage {
  final String id;
  final String senderType;
  final String message;
  final String createdAt;

  const SupportMessage({
    required this.id,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id        : j['id']?.toString()          ?? '',
        senderType: j['sender_type']?.toString() ?? 'admin',
        message   : j['message']?.toString()     ?? '',
        createdAt : j['created_at']?.toString()  ?? '',
      );

  bool get isAstrologer => senderType == 'astrologer';
}

// ─── Service ──────────────────────────────────────────────────────────────────

class _SupportService {
  static const String _base = 'https://admin.astrogurujii.com/';
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body) async {
    final response = await http
        .post(
          Uri.parse('$_base$endpoint'),
          headers: await _headers(),
          body   : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<SupportTicket>> fetchTickets() async {
    final data = await _post('astrologer_api/support_ticket_list', {});
    if (data['result'] == true) {
      return (data['data'] as List? ?? [])
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(data['message'] ?? 'Failed to load tickets');
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
    String category = 'Other',
  }) async {
    final data = await _post('astrologer_api/support_ticket_create', {
      'subject' : subject,
      'message' : message,
      'category': category,
    });
    if (data['result'] == true) {
      return SupportTicket.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw Exception(data['message'] ?? 'Failed to create ticket');
  }

  Future<({SupportTicket ticket, List<SupportMessage> messages})>
      fetchMessages(String ticketId) async {
    final data = await _post(
      'astrologer_api/support_ticket_messages',
      {'ticket_id': ticketId},
    );
    if (data['result'] == true) {
      final inner = data['data'] as Map<String, dynamic>;
      return (
        ticket  : SupportTicket.fromJson(inner['ticket'] as Map<String, dynamic>),
        messages: (inner['messages'] as List? ?? [])
            .map((e) => SupportMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    throw Exception(data['message'] ?? 'Failed to load messages');
  }

  Future<void> sendReply(String ticketId, String message) async {
    final data = await _post('astrologer_api/support_ticket_reply', {
      'ticket_id': ticketId,
      'message'  : message,
    });
    if (data['result'] != true) {
      throw Exception(data['message'] ?? 'Send failed');
    }
  }
}

// ─── SupportChatScreen ────────────────────────────────────────────────────────

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _service = _SupportService();

  List<SupportTicket> _tickets = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final tickets = await _service.fetchTickets();
      if (!mounted) return;
      setState(() { _tickets = tickets; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error   = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ── Create-ticket bottom sheet ────────────────────────────────────────────
  void _showCreateSheet() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    showModalBottomSheet(
      context           : context,
      isScrollControlled: true,
      backgroundColor   : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        // Local StatefulBuilder so the button spinner works
        return StatefulBuilder(
          builder: (sheetCtx, setSheet) {
            bool sending = false;

            Future<void> submit() async {
              final subject = subjectCtrl.text.trim();
              final message = messageCtrl.text.trim();
              if (subject.isEmpty || message.isEmpty) return;

              setSheet(() => sending = true);
              try {
                await _service.createTicket(subject: subject, message: message);
                if (!mounted) return;
                Navigator.of(sheetCtx).pop();   // close sheet
                _load();                         // refresh list
              } catch (e) {
                setSheet(() => sending = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content        : Text(e.toString().replaceFirst('Exception: ', '')),
                  backgroundColor: Colors.red,
                  behavior       : SnackBarBehavior.floating,
                  margin         : const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ));
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left  : 16,
                right : 16,
                top   : 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize      : MainAxisSize.min,   // ← fixed crash
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width : 40, height: 4,
                      decoration: BoxDecoration(
                        color       : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(16)),

                  Text(
                    'New Support Ticket',
                    style: TextStyle(
                      fontSize  : FigmaSize.w(16),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(16)),

                  // Subject
                  TextField(
                    controller     : subjectCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText     : 'Subject',
                      hintStyle    : TextStyle(color: Colors.grey.shade400),
                      enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black)),
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(16)),

                  // Message
                  TextField(
                    controller     : messageCtrl,
                    maxLines       : 4,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText     : 'Describe your issue...',
                      hintStyle    : TextStyle(color: Colors.grey.shade400),
                      enabledBorder: OutlineInputBorder(
                        borderSide  : BorderSide(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide  : const BorderSide(color: Colors.black),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: FigmaSize.h(20)),

                  // Submit
                  SizedBox(
                    width : double.infinity,
                    height: FigmaSize.h(55),
                    child : ElevatedButton(
                      onPressed: sending ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700),
                        foregroundColor: Colors.black,
                        elevation      : 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      child: sending
                          ? const SizedBox(
                              width : 22, height: 22,
                              child : CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : Text(
                              'Submit',
                              style: TextStyle(
                                fontSize  : FigmaSize.w(18),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor   : Colors.white,
        elevation         : 0,
        leading           : IconButton(          // ← fixed: was Icon, not tappable
          icon    : const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Support Chat',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          // ticket list
          Expanded(child: _buildList()),

          // footer
          Padding(
            padding: EdgeInsets.all(FigmaSize.w(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Data shown for last 3 days only',
                  style: TextStyle(
                      color: Colors.grey, fontSize: FigmaSize.w(14)),
                ),
                SizedBox(height: FigmaSize.h(16)),
                SizedBox(
                  width : double.infinity,
                  height: FigmaSize.h(55),
                  child : ElevatedButton(
                    onPressed: _showCreateSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: Colors.black,
                      elevation      : 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      'Create New Chat',
                      style: TextStyle(
                          fontSize  : FigmaSize.w(18),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            SizedBox(height: FigmaSize.h(12)),
            Text(_error!, style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center),
            SizedBox(height: FigmaSize.h(12)),
            TextButton.icon(
              onPressed: _load,
              icon : const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_tickets.isEmpty) {
      return Center(
        child: Text(
          'No tickets in the last 3 days.\nTap "Create New Chat" to raise one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: FigmaSize.w(14)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color    : const Color(0xFFFFD700),
      child: ListView.builder(
        itemCount  : _tickets.length,
        itemBuilder: (_, i) {
          final t = _tickets[i];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TicketDetailScreen(ticket: t)),
              );
              _load();
            },
            child: TicketTile(
              ticketNo   : t.ticketNo,
              message    : t.message,
              dateTime   : t.createdAt,
              status     : t.status,
              statusColor: t.status == 'Open' ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }
}

// ─── TicketTile (unchanged UI) ────────────────────────────────────────────────

class TicketTile extends StatelessWidget {
  final String ticketNo;
  final String message;
  final String dateTime;
  final String status;
  final Color  statusColor;

  const TicketTile({
    super.key,
    required this.ticketNo,
    required this.message,
    required this.dateTime,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding   : EdgeInsets.symmetric(
          horizontal: FigmaSize.w(16), vertical: FigmaSize.h(12)),
      decoration: const BoxDecoration(
        color : Color(0xFFFFFBE6),
        border: Border(
            bottom: BorderSide(color: Color(0xFFFFE082), width: 1)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: Colors.black, fontSize: FigmaSize.w(14)),
                  children: [
                    const TextSpan(text: 'Ticket No. '),
                    TextSpan(
                      text : ticketNo,
                      style: const TextStyle(
                          color     : Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              SizedBox(height: FigmaSize.h(8)),
              Text(
                message,
                style: TextStyle(
                    fontSize: FigmaSize.w(15), fontWeight: FontWeight.w500),
              ),
              SizedBox(height: FigmaSize.h(8)),
              Text(
                dateTime,
                style: TextStyle(
                    color: Colors.black54, fontSize: FigmaSize.w(13)),
              ),
            ],
          ),
          Positioned(
            right: 0, top: 0,
            child: Text(
              status,
              style: TextStyle(
                color     : statusColor,
                fontWeight: FontWeight.bold,
                fontSize  : FigmaSize.w(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TicketDetailScreen ───────────────────────────────────────────────────────

class TicketDetailScreen extends StatefulWidget {
  final SupportTicket ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final _service    = _SupportService();
  final _msgCtrl    = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<SupportMessage> _messages = [];
  late SupportTicket   _ticket;
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _loadMessages();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final result = await _service.fetchMessages(_ticket.id);
      if (!mounted) return;
      setState(() {
        _ticket   = result.ticket;
        _messages = result.messages;
        _loading  = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await _service.sendReply(_ticket.id, text);
      _msgCtrl.clear();
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content        : Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
        behavior       : SnackBarBehavior.floating,
        margin         : const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve   : Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = _ticket.status == 'Closed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFEBC351),
        elevation      : 0,
        leading: IconButton(
          icon     : const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _ticket.ticketNo,
              style: const TextStyle(
                  color     : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize  : 15),
            ),
            Text(
              _ticket.subject,
              style   : const TextStyle(color: Colors.black87, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
            child: Chip(
              label: Text(
                _ticket.status,
                style: TextStyle(
                  color     : isClosed ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize  : 12,
                ),
              ),
              backgroundColor: isClosed
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              side: BorderSide(
                  color: isClosed ? Colors.red : Colors.green),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // messages
          Expanded(child: _buildMessages()),

          // input / closed banner
          isClosed ? _closedBanner() : _inputBar(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)));
    }
    if (_messages.isEmpty) {
      return const Center(
          child: Text('No messages yet',
              style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      controller : _scrollCtrl,
      padding    : const EdgeInsets.all(12),
      itemCount  : _messages.length,
      itemBuilder: (_, i) => _MessageBubble(_messages[i]),
    );
  }

  Widget _inputBar() {
    return Container(
      color  : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      child  : Row(
        children: [
          Expanded(
            child: TextField(
              controller     : _msgCtrl,
              textInputAction: TextInputAction.send,
              onSubmitted    : (_) => _send(),
              decoration: InputDecoration(
                hintText      : 'Type a message…',
                hintStyle     : const TextStyle(color: Colors.grey),
                filled        : true,
                fillColor     : const Color(0xFFF5F5F5),
                border        : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide  : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFFEBC351),
            child: _sending
                ? const SizedBox(
                    width : 18, height: 18,
                    child : CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                : IconButton(
                    icon     : const Icon(Icons.send, color: Colors.black),
                    onPressed: _send,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _closedBanner() {
    return Container(
      width  : double.infinity,
      padding: EdgeInsets.all(FigmaSize.w(12)),
      color  : const Color(0xFFFFF9E6),
      child  : Text(
        'This ticket is closed. Create a new ticket to get support.',
        textAlign: TextAlign.center,
        style: TextStyle(
            color   : Colors.orange.shade700,
            fontSize: FigmaSize.w(13)),
      ),
    );
  }
}

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final SupportMessage msg;
  const _MessageBubble(this.msg);

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isAstrologer;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child    : Container(
        margin: EdgeInsets.only(
          top   : FigmaSize.h(4),
          bottom: FigmaSize.h(4),
          left  : isMe ? FigmaSize.w(48) : 0,
          right : isMe ? 0 : FigmaSize.w(48),
        ),
        padding   : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color      : isMe
              ? const Color(0xFFEBC351)
              : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.only(
            topLeft    : const Radius.circular(16),
            topRight   : const Radius.circular(16),
            bottomLeft : Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : 'Support',
              style: TextStyle(
                fontSize  : FigmaSize.w(11),
                fontWeight: FontWeight.w600,
                color     : isMe ? Colors.black54 : Colors.grey,
              ),
            ),
            SizedBox(height: FigmaSize.h(4)),
            Text(
              msg.message,
              style: TextStyle(
                  fontSize: FigmaSize.w(14), color: Colors.black87),
            ),
            SizedBox(height: FigmaSize.h(4)),
            Text(
              msg.createdAt,
              style: TextStyle(
                  fontSize: FigmaSize.w(10), color: Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}