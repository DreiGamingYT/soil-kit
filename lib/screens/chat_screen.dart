import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class OrderChatScreen extends StatefulWidget {
  final String orderId;
  const OrderChatScreen({super.key, required this.orderId});

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final _ctrl   = TextEditingController();
  final _db     = FirebaseFirestore.instance;
  final _scroll = ScrollController();

  CollectionReference get _msgs =>
      _db.collection('orders').doc(widget.orderId).collection('messages');

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _msgs.add({
      'text':      text,
      'sender':    'customer',
      'uid':       FirebaseAuth.instance.currentUser?.uid ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _ctrl.clear();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outline),
        ),
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _msgs.orderBy('createdAt').snapshots(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet.\nSend one to start the conversation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withOpacity(0.4),
                      height: 1.6,
                    ),
                  ),
                );
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final m         = docs[i].data() as Map<String, dynamic>;
                  final isCustomer = m['sender'] == 'customer';
                  final ts        = m['createdAt'] as Timestamp?;
                  final time      = ts != null
                      ? TimeOfDay.fromDateTime(ts.toDate()).format(context)
                      : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isCustomer
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isCustomer) ...[
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: SoilColors.primaryLight,
                            child: const Icon(Icons.support_agent_rounded,
                                size: 14, color: SoilColors.primary),
                          ),
                          const SizedBox(width: 8),
                        ],
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.68,
                          ),
                          child: Column(
                            crossAxisAlignment: isCustomer
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCustomer
                                      ? SoilColors.primary
                                      : cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.only(
                                    topLeft:     const Radius.circular(16),
                                    topRight:    const Radius.circular(16),
                                    bottomLeft:  Radius.circular(isCustomer ? 16 : 4),
                                    bottomRight: Radius.circular(isCustomer ? 4 : 16),
                                  ),
                                ),
                                child: Text(
                                  m['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    height: 1.45,
                                    color: isCustomer
                                        ? Colors.white
                                        : cs.onSurface,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: cs.onSurface.withOpacity(0.35),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outline)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message admin...',
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Sr.rPill),
                    borderSide: BorderSide(color: cs.outline),
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: SoilColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}