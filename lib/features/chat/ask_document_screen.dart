import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/supabase_service.dart';
import '../../core/network/gemini_service.dart';
import '../models/document_model.dart';
import '../models/chat_message_model.dart';

class AskDocumentScreen extends StatefulWidget {
  final DocumentModel document;

  const AskDocumentScreen({
    super.key,
    required this.document,
  });

  @override
  State<AskDocumentScreen> createState() => _AskDocumentScreenState();
}

class _AskDocumentScreenState extends State<AskDocumentScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _supabaseService = SupabaseService();
  final _geminiService = GeminiService();

  List<ChatMessageModel> _messages = [];
  bool _isLoadingHistory = true;
  bool _isSending = false;

  final List<String> _quickPrompts = [
    'Jelaskan konsep utama secara sederhana',
    'Buat 2 contoh soal latihan dari materi ini',
    'Apa kesimpulan terpenting dari catatan ini?',
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final history = await _supabaseService.getChatHistory(widget.document.id);
    if (mounted) {
      setState(() {
        _messages = history;
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    }
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

  Future<void> _sendMessage([String? customPrompt]) async {
    final text = (customPrompt ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    // Simpan pesan user ke Supabase
    final userMsg = await _supabaseService.sendChatMessage(
      documentId: widget.document.id,
      role: 'user',
      message: text,
    );

    setState(() {
      _messages.add(userMsg);
    });
    _scrollToBottom();

    // Siapkan riwayat percakapan untuk Gemini
    final historyList = _messages.map((m) => {
      'role': m.role,
      'content': m.message,
    }).toList();

    // Panggil Gemini API
    final botReply = await _geminiService.askDocument(
      documentSummary: widget.document.summary,
      keyPoints: widget.document.keyPoints,
      question: text,
      chatHistory: historyList,
    );

    // Simpan balasan bot ke Supabase
    final botMsg = await _supabaseService.sendChatMessage(
      documentId: widget.document.id,
      role: 'model',
      message: botReply,
    );

    if (mounted) {
      setState(() {
        _messages.add(botMsg);
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tanya Dokumen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              widget.document.title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quick Prompts Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.background,
                      side: const BorderSide(color: AppColors.cardBorder),
                      onPressed: () => _sendMessage(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.cardBorder),

          // Chat Messages
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Mulai Diskusi dengan Dokumen',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ajukan pertanyaan apa saja tentang materi catatan ini.',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg.role == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.78,
                              ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                                  bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                                ),
                                border: isUser ? null : Border.all(color: AppColors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                msg.message,
                                style: TextStyle(
                                  color: isUser ? Colors.white : AppColors.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Sending Indicator
          if (_isSending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8),
                  Text('Gemini sedang mengetik jawaban...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),

          // Chat Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu dari catatan ini...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _isSending ? null : () => _sendMessage(),
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
