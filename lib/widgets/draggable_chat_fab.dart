import 'package:flutter/material.dart';
import '../screens/conversations_list_screen.dart';

/// Draggable Floating Action Button للشات
/// يمكن تحريكه في أي مكان على الشاشة
/// يتغير لون الخلفية عند وجود رسائل جديدة
class DraggableChatFAB extends StatefulWidget {
  final ValueNotifier<int> unreadMessagesCount;
  final VoidCallback onChatOpened;

  const DraggableChatFAB({
    super.key,
    required this.unreadMessagesCount,
    required this.onChatOpened,
  });

  @override
  State<DraggableChatFAB> createState() => _DraggableChatFABState();
}

class _DraggableChatFABState extends State<DraggableChatFAB> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // تحديد الموضع الافتراضي في الأسفل إذا لم يتم تحديده بعد
    _position ??= Offset(20, size.height - 140);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // تحديث الموقع مع التأكد من بقائه داخل الشاشة
            double newX = (_position!.dx + details.delta.dx)
                .clamp(0.0, size.width - 60.0);
            double newY = (_position!.dy + details.delta.dy)
                .clamp(0.0, size.height - 60.0);
            _position = Offset(newX, newY);
          });
        },
        child: ValueListenableBuilder<int>(
          valueListenable: widget.unreadMessagesCount,
          builder: (context, count, child) {
            // تغيير اللون حسب وجود رسائل غير مقروءة
            final hasUnread = count > 0;
            final backgroundColor = hasUnread
                ? const Color(0xFFEF4444) // أحمر عند وجود رسائل
                : const Color(0xFF8B5CF6); // بنفسجي بدون رسائل

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  // فتح شاشة المحادثات
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConversationsListScreen(),
                    ),
                  );
                  // إعلام الشاشة الرئيسية بإعادة تحميل عدد الرسائل
                  widget.onChatOpened();
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity( 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(
                          Icons.chat_bubble,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      // عرض رقم الرسائل غير المقروءة
                      if (hasUnread)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity( 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: TextStyle(
                                  color: backgroundColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
