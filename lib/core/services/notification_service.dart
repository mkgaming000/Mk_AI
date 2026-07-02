import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../storage/local_storage_service.dart';

/// Fires local notifications for long-running background tasks
/// (image/video/music generation, agent runs) completing. Respects the
/// user's "Notifications" setting — if disabled, this is a silent no-op.
class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _idCounter = 0;

  Future<void> init() async {
    if (_initialized) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> show({
    required String title,
    required String body,
    String channelId = 'omniforge_general',
    String channelName = 'OmniForge AI',
  }) async {
    if (!_initialized) await init();
    if (!LocalStorageService.instance.notificationsEnabled) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(_idCounter++, title, body, details);
  }

  Future<void> notifyGenerationComplete({
    required String feature,
    required String summary,
  }) =>
      show(title: '$feature complete', body: summary);

  Future<void> notifyAgentDone(String agentName) => show(
        title: '$agentName finished',
        body: 'Your agent has completed its task.',
      );
}
