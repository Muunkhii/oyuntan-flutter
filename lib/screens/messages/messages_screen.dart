// lib/screens/messages/messages_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

// ignore_for_file: use_build_context_synchronously

// ── Conversation list ──────────────────────────────────────────
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override State<MessagesScreen> createState() => _MessagesScreenState();
}
class _MessagesScreenState extends State<MessagesScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override void initState() { super.initState(); _load(); }
  void _load() => setState(() { _future = MessageService().getConversations(); });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Мессеж')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
          }
          final convs = snap.data ?? [];
          if (convs.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 52, color: AppColors.faint),
              SizedBox(height: 12),
              Text('Мессеж байхгүй байна', style: TextStyle(color: AppColors.muted)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: convs.length,
              itemBuilder: (ctx, i) {
                final c       = convs[i];
                final uid     = c['other_uid'] as String;
                final name    = (c['company_name'] as String?)?.isNotEmpty == true
                    ? c['company_name'] as String
                    : (c['student_name'] as String? ?? 'Хэрэглэгч');
                final photo   = (c['company_photo'] as String?) ?? (c['student_photo'] as String?);
                final last    = c['last_message'] as String? ?? '';
                final unread  = (c['unread'] as num?)?.toInt() ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(otherUid: uid, otherName: name, otherPhoto: photo)));
                      _load();
                    },
                    child: AppCard(child: Row(children: [
                      _Avatar(name: name, photo: photo, size: 48),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(name,
                            style: TextStyle(fontSize: 14, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500))),
                          Text(_formatTime(c['created_at'] as String?),
                            style: const TextStyle(fontSize: 10, color: AppColors.faint)),
                        ]),
                        const SizedBox(height: 3),
                        Row(children: [
                          Expanded(child: Text(last,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12,
                              color: unread > 0 ? AppColors.text : AppColors.muted,
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal))),
                          if (unread > 0)
                            Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text('$unread',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                        ]),
                      ])),
                    ])),
                  ),
                ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt  = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      }
      return '${dt.month}/${dt.day}';
    } catch (_) { return ''; }
  }
}

// ── Individual chat ────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final String otherUid, otherName;
  final String? otherPhoto;
  const ChatScreen({super.key, required this.otherUid, required this.otherName, this.otherPhoto});
  @override State<ChatScreen> createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  String _myUid = '';

  @override
  void initState() {
    super.initState();
    _myUid = context.read<AuthProvider>().uid;
    _load();
  }

  @override void dispose() { _ctrl.dispose(); _scroll.dispose(); super.dispose(); }

  void _load() => setState(() {
    _future = MessageService().getMessages(widget.otherUid);
  });

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await MessageService().send(widget.otherUid, text);
      _load();
      await Future.delayed(const Duration(milliseconds: 300));
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Row(children: [
          _Avatar(name: widget.otherName, photo: widget.otherPhoto, size: 34),
          const SizedBox(width: 10),
          Text(widget.otherName, style: const TextStyle(fontSize: 15)),
        ]),
      ),
      body: Column(children: [
        Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2));
            }
            final msgs = snap.data ?? [];
            if (msgs.isEmpty) {
              return const Center(child: Text('Мессеж байхгүй', style: TextStyle(color: AppColors.muted)));
            }
            return ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: msgs.length,
              itemBuilder: (ctx, i) {
                final m  = msgs[i];
                final me = (m['sender_uid'] as String) == _myUid;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!me) ...[
                        _Avatar(name: widget.otherName, photo: widget.otherPhoto, size: 28),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: me ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft:     const Radius.circular(16),
                            topRight:    const Radius.circular(16),
                            bottomLeft:  Radius.circular(me ? 16 : 4),
                            bottomRight: Radius.circular(me ? 4 : 16),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                        ),
                        child: Text(m['content'] as String? ?? '',
                          style: TextStyle(fontSize: 13,
                            color: me ? Colors.white : AppColors.text, height: 1.4)),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        )),
        // ── Input bar ────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 14),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Мессеж бичнэ үү...',
                filled: true, fillColor: AppColors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border, width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            )),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44, height: 44,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Avatar helper ──────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final String? photo;
  final double size;
  const _Avatar({required this.name, this.photo, required this.size});
  @override
  Widget build(BuildContext context) {
    if (photo != null && photo!.isNotEmpty) {
      try {
        return CircleAvatar(radius: size / 2,
          backgroundImage: MemoryImage(base64Decode(photo!)));
      } catch (_) {}
    }
    return CircleAvatar(radius: size / 2,
      backgroundColor: AppColors.primaryLight,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.35, fontWeight: FontWeight.w700, color: AppColors.primaryDark)));
  }
}
