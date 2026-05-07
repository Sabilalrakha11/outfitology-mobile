import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';

// ============================================================
// NOTIFICATION MODEL
// ============================================================
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'order', 'promo', 'system'
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? payload;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.payload,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'body': body, 'type': type,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead, 'payload': payload,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'], title: json['title'], body: json['body'], type: json['type'],
    createdAt: DateTime.parse(json['createdAt']),
    isRead: json['isRead'] ?? false,
    payload: json['payload'],
  );
}

// ============================================================
// NOTIFICATION MANAGER — Singleton
// ============================================================
class NotificationManager extends ChangeNotifier {
  static final NotificationManager _i = NotificationManager._internal();
  factory NotificationManager() => _i;
  NotificationManager._internal();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications =>
      List.from(_notifications)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('notifications');
    if (raw != null) {
      final List list = jsonDecode(raw);
      _notifications.clear();
      _notifications.addAll(list.map((e) => AppNotification.fromJson(e)));
      notifyListeners();
    }
  }

  Future<void> add(AppNotification notif) async {
    _notifications.insert(0, notif);
    notifyListeners();
    await _save();
  }

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) { _notifications[idx].isRead = true; notifyListeners(); await _save(); }
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) { n.isRead = true; }
    notifyListeners();
    await _save();
  }

  Future<void> delete(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notifications', jsonEncode(_notifications.map((n) => n.toJson()).toList()));
  }

  // Helper: tambah notif order status
  Future<void> addOrderNotification({
    required String orderId,
    required String status,
  }) async {
    final messages = {
      'pending': ('Payment Received 🎉', 'Your order #$orderId is awaiting processing.'),
      'dikemas': ('Order Being Packed 📦', 'Your items are being carefully packed.'),
      'dikirim': ('On the Way! 🚚', 'Your package is out for delivery.'),
      'diterima': ('Delivered! ✅', 'Your order has been delivered. Enjoy!'),
    };
    final msg = messages[status] ?? ('Order Update', 'Status: $status');
    await add(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: msg.$1, body: msg.$2, type: 'order',
      createdAt: DateTime.now(),
      payload: {'orderId': orderId, 'status': status},
    ));
  }
}

// ============================================================
// NOTIFICATION SCREEN
// ============================================================
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _manager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_refresh);
    _manager.load();
  }

  @override
  void dispose() {
    _manager.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  IconData _iconFor(String type) {
    switch (type) {
      case 'order': return Icons.local_shipping_outlined;
      case 'promo': return Icons.local_offer_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'order': return Colors.blue;
      case 'promo': return Colors.orange;
      default: return AppTheme.stone;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final notifs = _manager.notifications;
    return Scaffold(
      backgroundColor: AppTheme.fog,
      appBar: AppBar(
        backgroundColor: AppTheme.fog,
        title: const Text('NOTIFICATIONS'),
        actions: [
          if (notifs.isNotEmpty) ...[
            if (_manager.unreadCount > 0)
              TextButton(
                onPressed: () => _manager.markAllRead(),
                child: Text('READ ALL', style: AppTheme.labelCaps),
              ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'clear') _manager.clearAll();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'clear',
                  child: Text('Clear all', style: AppTheme.bodyMedium)),
              ],
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ],
      ),
      body: notifs.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'NO NOTIFICATIONS',
              subtitle: 'You\'re all caught up!\nWe\'ll notify you about your orders.',
            )
          : ListView.separated(
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
              itemBuilder: (_, i) {
                final notif = notifs[i];
                return Dismissible(
                  key: Key(notif.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade400,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => _manager.delete(notif.id),
                  child: InkWell(
                    onTap: () => _manager.markRead(notif.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      color: notif.isRead ? AppTheme.canvas : AppTheme.fog,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Icon badge
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: _colorFor(notif.type).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(notif.type), size: 20, color: _colorFor(notif.type)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(
                                child: Text(notif.title,
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: notif.isRead ? FontWeight.w400 : FontWeight.w700,
                                    fontSize: 13,
                                  )),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 8, height: 8, margin: const EdgeInsets.only(left: 8),
                                  decoration: const BoxDecoration(
                                    color: AppTheme.ink, shape: BoxShape.circle),
                                ),
                            ]),
                            const SizedBox(height: 4),
                            Text(notif.body, style: AppTheme.bodySmall.copyWith(height: 1.5)),
                            const SizedBox(height: 6),
                            Text(_timeAgo(notif.createdAt),
                              style: AppTheme.bodySmall.copyWith(fontSize: 11)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================
// NOTIFICATION BADGE — Reusable widget untuk AppBar
// ============================================================
class NotificationBadge extends StatefulWidget {
  final VoidCallback onTap;
  const NotificationBadge({super.key, required this.onTap});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _manager = NotificationManager();

  @override
  void initState() {
    super.initState();
    _manager.addListener(_rebuild);
    _manager.load();
  }

  @override
  void dispose() { _manager.removeListener(_rebuild); super.dispose(); }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final count = _manager.unreadCount;
    return GestureDetector(
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Stack(clipBehavior: Clip.none, children: [
          const Icon(Icons.notifications_outlined, size: 24, color: AppTheme.ink),
          if (count > 0)
            Positioned(
              top: -4, right: -4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18, height: 18,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }
}