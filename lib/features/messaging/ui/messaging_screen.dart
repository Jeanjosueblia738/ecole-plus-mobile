import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/messaging_api_service.dart';
import '../../../core/theme/app_colors.dart';

class MessagingScreen extends ConsumerStatefulWidget {
  const MessagingScreen({super.key});
  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await MessagingApiService.getConversations();
      if (mounted) {
        setState(() => _conversations = data);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Impossible de charger les conversations');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger les conversations'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _fmtTime(String? dateStr) {
    if (dateStr == null) {
      return '';
    }
    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return '';
    }
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Messagerie',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadConversations),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversation(context),
        backgroundColor: primaryBlue,
        child: const Icon(Icons.edit_outlined, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _conversations.isEmpty
              ? _buildError()
              : _conversations.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  child: ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (ctx, i) => _ConvTile(
                      conv: _conversations[i],
                      fmtTime: _fmtTime,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                _ConversationScreen(conv: _conversations[i]),
                          )).then((_) => _loadConversations()),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Aucune conversation',
            style: TextStyle(color: textGrey, fontSize: 16)),
        SizedBox(height: 8),
        Text('Appuyez sur + pour démarrer',
            style: TextStyle(color: textGrey, fontSize: 13)),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Erreur',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textGrey, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConversations,
            child: const Text('Réessayer'),
          ),
        ]),
      ),
    );
  }

  void _showNewConversation(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _NewConversationScreen(),
        )).then((_) => _loadConversations());
  }
}

// ── Tuile conversation ─────────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final Map<String, dynamic> conv;
  final String Function(String?) fmtTime;
  final VoidCallback onTap;
  const _ConvTile(
      {required this.conv, required this.fmtTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lastMsg = conv['lastMessage'] as Map<String, dynamic>?;
    final subject = conv['subject'] as String? ?? 'Message direct';
    final type = conv['type'] as String? ?? 'DIRECT';
    final isGroup = type != 'DIRECT';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
        ),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGroup ? Icons.group_outlined : Icons.chat_outlined,
              color: primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(subject,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis)),
                      if (lastMsg != null)
                        Text(fmtTime(lastMsg['createdAt'] as String?),
                            style:
                                const TextStyle(fontSize: 11, color: textGrey)),
                    ]),
                if (lastMsg != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${lastMsg['senderName']?.toString().split(' ').first ?? ''} : ${lastMsg['content'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: textGrey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ])),
        ]),
      ),
    );
  }
}

// ── Écran conversation ─────────────────────────────────────────────────────
class _ConversationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> conv;
  const _ConversationScreen({required this.conv});
  @override
  ConsumerState<_ConversationScreen> createState() =>
      _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<_ConversationScreen> {
  List<dynamic> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await MessagingApiService.getMessages(widget.conv['id'] as String);
      if (mounted) {
        setState(() {
          _messages = data;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossible de charger les messages';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger les messages'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final content = _ctrl.text.trim();
    if (content.isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      final msg = await MessagingApiService.sendMessage(
          widget.conv['id'] as String, content);
      _ctrl.clear();
      if (mounted) {
        setState(() => _messages.add(msg));
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'envoyer le message"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  String _fmtTime(String? dateStr) {
    if (dateStr == null) {
      return '';
    }
    final date = DateTime.tryParse(dateStr);
    if (date == null) {
      return '';
    }
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final subject = widget.conv['subject'] as String? ?? 'Message direct';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subject,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(
              '${(widget.conv['participants'] as List?)?.length ?? 0} participant(s)',
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: _loadMessages),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: textGrey)),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadMessages,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _messages.isEmpty
                  ? const Center(
                      child: Text('Aucun message',
                          style: TextStyle(color: textGrey)))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i] as Map<String, dynamic>;
                        final isMe = msg['senderId'] == auth.userId;
                        return _MessageBubble(
                            msg: msg, isMe: isMe, fmtTime: _fmtTime);
                      },
                    ),
        ),

        // Input
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Votre message...',
                    hintStyle: const TextStyle(color: textGrey, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF1F3F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sending ? null : _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _sending ? Colors.grey : primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Bulle message ──────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final String Function(String?) fmtTime;
  const _MessageBubble(
      {required this.msg, required this.isMe, required this.fmtTime});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(msg['senderName'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 11,
                      color: textGrey,
                      fontWeight: FontWeight.w600)),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? primaryBlue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Text(msg['content'] as String? ?? '',
                    style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : Colors.black87,
                        height: 1.4)),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(fmtTime(msg['createdAt'] as String?),
                style: const TextStyle(fontSize: 10, color: textGrey)),
          ),
        ],
      ),
    );
  }
}

// ── Nouvelle conversation ──────────────────────────────────────────────────
class _NewConversationScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<_NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState
    extends ConsumerState<_NewConversationScreen> {
  List<dynamic> _users = [];
  List<dynamic> _teachers = [];
  final List<Map<String, dynamic>> _selected = [];
  bool _loading = true;
  bool _sending = false;
  final _subjectCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    try {
      final data = await MessagingApiService.getRecipients();
      if (mounted) {
        setState(() {
          _users = (data['users'] as List?) ?? [];
          _teachers = (data['teachers'] as List?) ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger les destinataires'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isSelected(String id) => _selected.any((s) => s['id'] == id);

  void _toggle(Map<String, dynamic> r) {
    setState(() {
      if (_isSelected(r['id'] as String)) {
        _selected.removeWhere((s) => s['id'] == r['id']);
      } else {
        _selected.add(r);
      }
    });
  }

  Future<void> _send() async {
    if (_selected.isEmpty || _msgCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      await MessagingApiService.createConversation(
        firstMessage: _msgCtrl.text.trim(),
        participantIds: _selected.map((s) => s['id'] as String).toList(),
        participantTypes: _selected.map((s) => s['type'] as String).toList(),
        subject:
            _subjectCtrl.text.trim().isEmpty ? null : _subjectCtrl.text.trim(),
        type: _selected.length > 1 ? 'GROUP' : 'DIRECT',
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  List<dynamic> get _filtered {
    final all = [..._users, ..._teachers];
    final auth = ref.read(authProvider);
    return all.where((r) {
      if (r['id'] == auth.userId) {
        return false;
      }
      final q = _search.toLowerCase();
      if (q.isEmpty) {
        return true;
      }
      final name =
          '${r['firstName'] ?? ''} ${r['lastName'] ?? ''}'.toLowerCase();
      return name.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Nouveau message',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed:
                _sending || _selected.isEmpty || _msgCtrl.text.trim().isEmpty
                    ? null
                    : _send,
            child: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Envoyer',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Sélectionnés
              if (_selected.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _selected
                          .map((r) => Chip(
                                label: Text(
                                    '${r['firstName']} ${r['lastName']}',
                                    style: const TextStyle(fontSize: 12)),
                                deleteIcon: const Icon(Icons.close, size: 14),
                                onDeleted: () => _toggle(r),
                                backgroundColor:
                                    primaryBlue.withValues(alpha: 0.1),
                                side: BorderSide(
                                    color: primaryBlue.withValues(alpha: 0.3)),
                              ))
                          .toList()),
                ),

              // Formulaire
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un destinataire...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF1F3F8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectCtrl,
                    decoration: InputDecoration(
                      hintText: 'Sujet (optionnel)',
                      filled: true,
                      fillColor: const Color(0xFFF1F3F8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _msgCtrl,
                    onChanged: (_) => setState(() {}),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      filled: true,
                      fillColor: const Color(0xFFF1F3F8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ]),
              ),

              const Divider(height: 1),

              // Liste destinataires
              Expanded(
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (ctx, i) {
                    final r = _filtered[i] as Map<String, dynamic>;
                    final selected = _isSelected(r['id'] as String);
                    return ListTile(
                      onTap: () => _toggle(r),
                      leading: CircleAvatar(
                        backgroundColor: primaryBlue.withValues(alpha: 0.1),
                        child: Text(
                          '${(r['firstName'] as String? ?? 'U')[0]}${(r['lastName'] as String? ?? '')[0]}',
                          style: const TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      title: Text('${r['firstName']} ${r['lastName']}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(r['role'] as String? ?? '',
                          style: const TextStyle(fontSize: 12)),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined,
                              color: Colors.grey),
                    );
                  },
                ),
              ),
            ]),
    );
  }
}
