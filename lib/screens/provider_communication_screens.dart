import 'package:flutter/material.dart';

import '../models/chat_model.dart';
import '../services/chat_service.dart';

/// P27 — provider conversations list.
class ProviderConversationsScreen extends StatefulWidget {
  const ProviderConversationsScreen({super.key, this.conversationsFuture});
  final Future<List<Conversation>>? conversationsFuture;

  @override
  State<ProviderConversationsScreen> createState() =>
      _ProviderConversationsScreenState();
}

class _ProviderConversationsScreenState
    extends State<ProviderConversationsScreen> {
  late Future<List<Conversation>> _future;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.conversationsFuture ?? ChatService.getConversations();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: FutureBuilder<List<Conversation>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final conversations = snapshot.data ?? const <Conversation>[];
              return Column(children: [
                const SizedBox(height: 18),
                const Text('Chats',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 27, 20, 16),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search conversations',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE3E3E8)))),
                  ),
                ),
                Expanded(
                  child: conversations.isEmpty
                      ? const Center(child: Text('No conversations yet'))
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: conversations
                              .where((c) => (c.serviceNameEn ?? c.serviceName)
                                  .toLowerCase()
                                  .contains(_search.text.toLowerCase()))
                              .map((conversation) =>
                                  _conversationTile(context, conversation))
                              .toList(),
                        ),
                )
              ]);
            },
          ),
        ),
      );

  Widget _conversationTile(BuildContext context, Conversation conversation) {
    final other = conversation.client;
    final name = other.fullName;
    final initials = name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
            backgroundColor: const Color(0xFF16A385),
            child: Text(initials.isEmpty ? 'C' : initials,
                style: const TextStyle(color: Colors.white))),
        title: Text(name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(conversation.lastMessage?.content ?? 'No messages',
            maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: conversation.unreadCount > 0
            ? CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Text('${conversation.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11)))
            : null,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ProviderChatCustomerScreen(
                    conversationId: conversation.id, title: name))),
      ),
    );
  }
}

/// P28 — chat with a customer. Polling remains server-owned; every send goes
/// through ChatService so the same screen works for individual and company.
class ProviderChatCustomerScreen extends StatefulWidget {
  const ProviderChatCustomerScreen(
      {super.key,
      required this.conversationId,
      this.title = 'Customer',
      this.messagesFuture});
  final int conversationId;
  final String title;
  final Future<List<Message>>? messagesFuture;

  @override
  State<ProviderChatCustomerScreen> createState() =>
      _ProviderChatCustomerScreenState();
}

class _ProviderChatCustomerScreenState
    extends State<ProviderChatCustomerScreen> {
  late Future<List<Message>> _future;
  final _composer = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future =
        widget.messagesFuture ?? ChatService.getMessages(widget.conversationId);
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ChatService.sendMessage(widget.conversationId, text);
      _composer.clear();
      if (widget.messagesFuture == null) {
        setState(
            () => _future = ChatService.getMessages(widget.conversationId));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
            backgroundColor: const Color(0xFFF7F7F7),
            elevation: 0,
            foregroundColor: const Color(0xFF1A1A1A),
            centerTitle: true,
            title: Column(children: [
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              const Text('Online',
                  style: TextStyle(color: Color(0xFF16A385), fontSize: 11))
            ])),
        body: FutureBuilder<List<Message>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final messages = snapshot.data ?? const <Message>[];
            return Column(children: [
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 13),
                  child: Chip(label: Text('Today'))),
              Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: messages.length,
                          itemBuilder: (_, index) => _bubble(messages[index]),
                        )),
              _composerBar(),
            ]);
          },
        ),
      );

  Widget _bubble(Message message) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 9),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(message.content, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 6),
            Text(_time(message.createdAt),
                style: const TextStyle(color: Color(0xFF808080), fontSize: 10))
          ]),
        ),
      );

  Widget _composerBar() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: TextField(
          controller: _composer,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _send(),
          decoration: InputDecoration(
              hintText: 'Write a message',
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                  onPressed: _busy ? null : _send,
                  icon: const Icon(Icons.arrow_forward,
                      color: Color(0xFF8B5CF6))),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFE3E3E8)))),
        ),
      );
}

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
