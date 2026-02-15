import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:arma2/backend/services/notification_service.dart';

class MessagingService {
  MessagingService._();

  static final MessagingService instance = MessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  Future<void> initialize() async {
    // ðŸ”´ REMOVED: subscribeToTopic('allUsers')
    await requestPermission();
    await logDeviceToken();

    _foregroundSubscription ??= FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      final notification = message.notification;

      if (notification == null) {
        debugPrint('No notification payload (data-only message)');
        return;
      }

      final title = notification.title ?? 'Notification';
      final body = notification.body ?? '';

      NotificationService().showNotification(title: title, body: body);

      debugPrint('Notification: $title - $body');
    });
  }

  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permission GRANTED');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Notification permission DENIED');
    } else {
      debugPrint('Notification permission NOT DETERMINED');
    }
  }

  Future<String?> getDeviceToken() {
    return _messaging.getToken();
  }

  Future<void> logDeviceToken() async {
    final token = await getDeviceToken();
    debugPrint('FCM Device Token: $token');
  }

  void dispose() {
    _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }
}
