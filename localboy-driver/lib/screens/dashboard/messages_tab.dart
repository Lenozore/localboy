import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final ApiService _api = ApiService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final response = await _api.get('/messages/unread-count');
      setState(() => _unreadCount = response.data['count'] ?? 0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$_unreadCount new', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nice empty state
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, size: 44, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 20),
            const Text('All Caught Up! 🎉',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Messages from tourists will\nappear here during active trips',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2E7D32).withValues(alpha: 0.08),
                    const Color(0xFF1B5E20).withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.grey[500], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tourists can message you once a trip starts',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
