import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

class Chatbox extends StatefulWidget {
  const Chatbox({super.key});

  @override
  State<Chatbox> createState() => _ChatboxState();
}

class _ChatboxState extends State<Chatbox> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  GenerativeModel? _model;

  @override
  void initState() {
    super.initState();
    _initAI();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Khởi tạo Firebase AI Gemini
  Future<void> _initAI() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'Xin chào 👋 Tôi là trợ lý tài chính, bạn cần giúp gì?',
          'timestamp': DateTime.now(),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': '⚠️ Lỗi khi khởi tạo AI: $e',
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  // Tải lịch sử chat từ Firestore
  Future<void> _loadChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('chat_logs')
          .doc(user.uid)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final history = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'role': data['role'],
          'text': data['text'],
          'timestamp': data['timestamp']?.toDate() ?? DateTime.now(),
        };
      }).toList();

      setState(() {
        _messages.addAll(history);
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  // Gửi tin nhắn
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _model == null) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final user = FirebaseAuth.instance.currentUser;
      String spendingInfo = "Chưa có dữ liệu người dùng.";

      if (user != null && !user.isAnonymous) {
        final snapshot = await FirebaseFirestore.instance
            .collection('transactions')
            .doc(user.uid)
            .collection('items')
            .orderBy('date', descending: true)
            .limit(50) // Lấy 50 giao dịch gần nhất
            .get();

        double totalIncome = 0;
        double totalExpense = 0;
        List<String> transactionDetails = [];

        for (var doc in snapshot.docs) {
          final data = doc.data();
          final isIncome = data['isIncome'] == true;
          final amount = (data['amount'] ?? 0).toDouble();
          final description = data['description'] ?? 'Không có mô tả';
          final category = data['category'] ?? 'Chưa phân loại';

          // Xử lý ngày tháng
          String dateStr = 'Không có ngày';
          if (data['date'] != null) {
            try {
              final date = (data['date'] as Timestamp).toDate();
              dateStr = '${date.day}/${date.month}/${date.year}';
            } catch (e) {
              dateStr = data['date'].toString();
            }
          }

          if (isIncome) {
            totalIncome += amount;
            transactionDetails.add(
              "📈 Thu nhập: ${amount.toStringAsFixed(0)}₫ - $description (Loại: $category, Ngày: $dateStr)",
            );
          } else {
            totalExpense += amount;
            transactionDetails.add(
              "📉 Chi tiêu: ${amount.toStringAsFixed(0)}₫ - $description (Loại: $category, Ngày: $dateStr)",
            );
          }
        }

        final balance = totalIncome - totalExpense;

        // Tạo thông tin chi tiết
        spendingInfo =
            """
TỔNG QUAN TÀI CHÍNH:
- Tổng thu nhập: ${totalIncome.toStringAsFixed(0)}₫
- Tổng chi tiêu: ${totalExpense.toStringAsFixed(0)}₫
- Số dư còn lại: ${balance.toStringAsFixed(0)}₫

CHI TIẾT ${transactionDetails.length} GIAO DỊCH GẦN NHẤT:
${transactionDetails.join('\n')}
        """;
      }

      final prompt = [
        Content.text("""
        Bạn là trợ lý tài chính cá nhân thông minh, thân thiện.
        
        THÔNG TIN TÀI CHÍNH CỦA NGƯỜI DÙNG:
        $spendingInfo

        CÂU HỎI:
        "$text"
        
        HƯỚNG DẪN TRẢ LỜI:
        - Trả lời ngắn gọn dễ hiểu, chỉ trả lời chi tiết khi người dùng yêu cầu
        - Phân tích dữ liệu chi tiết nếu người dùng hỏi về giao dịch cụ thể
        - Đưa ra lời khuyên thực tế dựa trên thói quen chi tiêu
        - Trả lời ngắn gọn nhưng đầy đủ thông tin
        - Sử dụng emoji phù hợp để dễ đọc
        - Nếu hỏi về chi tiêu theo danh mục, hãy tổng hợp từ dữ liệu trên
        """),
      ];

      final response = await _model!.generateContent(prompt);
      final reply = response.text ?? "Xin lỗi, tôi chưa thể trả lời.";

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': reply,
          'timestamp': DateTime.now(),
        });
      });

      _scrollToBottom();

      // Lưu hội thoại vào Firestore
      if (user != null) {
        final chatRef = FirebaseFirestore.instance
            .collection('chat_logs')
            .doc(user.uid)
            .collection('messages');

        await chatRef.add({
          'role': 'user',
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await chatRef.add({
          'role': 'assistant',
          'text': reply,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': '⚠️ Lỗi: $e',
          'timestamp': DateTime.now(),
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? const Color(0xFF6B43FF),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý tài chính',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Powered by Gemini AI',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa lịch sử chat?'),
                  content: const Text(
                    'Bạn có chắc muốn xóa toàn bộ lịch sử trò chuyện?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Xóa',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 80,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Bắt đầu trò chuyện',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(
                                  0xFF6B43FF,
                                ).withOpacity(0.1),
                                child: const Icon(
                                  Icons.smart_toy_rounded,
                                  color: Color(0xFF6B43FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isUser
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF6B43FF),
                                            Color(0xFF8B5FFF),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isUser
                                      ? null
                                      : isDark
                                      ? theme.cardColor
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(
                                      isUser ? 18 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      isUser ? 4 : 18,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (isUser
                                                  ? const Color(0xFF6B43FF)
                                                  : Colors.black)
                                              .withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 17,
                                    color: isUser
                                        ? Colors.white
                                        : theme.textTheme.bodyMedium?.color,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            if (isUser) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF6B43FF),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Đang suy nghĩ...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            ),

          // Input area - Fixed at bottom with proper padding
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyMedium,
                          decoration: InputDecoration(
                            hintText: "Hỏi về chi tiêu của bạn...",
                            hintStyle: TextStyle(color: theme.disabledColor),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B43FF), Color(0xFF8B5FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B43FF).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isLoading ? Icons.stop_rounded : Icons.send_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
