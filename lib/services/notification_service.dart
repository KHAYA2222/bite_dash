// services/notification_service.dart
//
// Handles FCM push notifications for both users and admins.
//
// Flow:
//   1. App starts → requestPermission() + getToken() → saves FCM token to
//      Firestore users/{uid}/fcmToken
//   2. Order placed → Cloud Function triggers → sends notification to admin
//      tokens stored in Firestore admins/{uid}/fcmToken
//   3. Admin updates status → Cloud Function triggers → sends notification
//      to the user's stored FCM token
//   4. App in foreground → FirebaseMessaging.onMessage shows in-app banner
//   5. App in background/terminated → system tray notification, tap opens app

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Top-level handler required by FCM for background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by this point
  debugPrint('[FCM] Background message: ${message.messageId}');
  debugPrint('[FCM] Title: ${message.notification?.title}');
  debugPrint('[FCM] Body:  ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // In-app banner callback — set from main.dart after app builds
  void Function(String title, String body)? onForegroundMessage;

  // ── Init ────────────────────────────────────────────────────────────────────

  /// Call once from main.dart after Firebase.initializeApp()
  static Future<void> registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Call after the user signs in.
  Future<void> init(String userId) async {
    // 1. Request permission (iOS + Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notifications denied by user.');
      return;
    }

    // 2. Get and save the FCM token
    await _saveToken(userId);

    // 3. Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _saveToken(userId, token: newToken);
    });

    // 4. Foreground messages → show in-app banner
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground: ${message.notification?.title}');
      final title = message.notification?.title ?? '';
      final body = message.notification?.body ?? '';
      if (title.isNotEmpty) {
        onForegroundMessage?.call(title, body);
      }
    });

    // 5. Handle tap on notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Opened from background: ${message.data}');
      // Navigate based on message.data['orderId'] if needed
    });

    // 6. Handle tap when app was terminated
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] Launched from terminated: ${initial.data}');
    }
  }

  /// Save/refresh FCM token to Firestore users/{uid}
  Future<void> _saveToken(String userId, {String? token}) async {
    try {
      final t = token ?? await _fcm.getToken();
      if (t == null) return;
      await _db.collection('users').doc(userId).update({
        'fcmToken': t,
        'fcmUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token saved for $userId');
    } catch (e) {
      debugPrint('[FCM] _saveToken error: $e');
    }
  }

  /// Remove FCM token on sign out so no stale notifications are delivered
  Future<void> clearToken(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _fcm.deleteToken();
      debugPrint('[FCM] Token cleared for $userId');
    } catch (e) {
      debugPrint('[FCM] clearToken error: $e');
    }
  }

  /// Get the current token (useful for debugging)
  Future<String?> getToken() => _fcm.getToken();
}

// ── In-app notification banner ───────────────────────────────────────────────
// Shown as an overlay when a push arrives while the app is in the foreground.

class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
  });

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _dismiss() {
    _ac.reverse().then((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: GestureDetector(
            onTap: () {
              _dismiss();
              widget.onTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2B1C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Global overlay helper ─────────────────────────────────────────────────────

class NotificationOverlay {
  static final _key = GlobalKey<NavigatorState>();
  static GlobalKey<NavigatorState> get navigatorKey => _key;

  static void show(String title, String body) {
    final ctx = _key.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (_) => Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: InAppNotificationBanner(title: title, body: body),
        ),
      ),
    );
  }
}
