import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 初始化时区数据
    tz.initializeTimeZones();
    
    // Android初始化设置
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS初始化设置
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 初始化设置
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // 处理通知点击事件
        print('Notification clicked: ${details.payload}');
      },
    );
  }

  Future<void> scheduleDailyNotification({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    // 取消之前设置的重复通知
    await _notificationsPlugin.cancel(0);

    // 设置Android通知详情
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'daily_reminder',
      '每日提醒',
      channelDescription: '每日目标提醒',
      importance: Importance.max,
      priority: Priority.high,
    );

    // 设置iOS通知详情
    const DarwinNotificationDetails iOSNotificationDetails =
        DarwinNotificationDetails();

    // 通知详情
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    // 设置时区
    final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);

    // 安排重复通知
    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.Location location = tz.getLocation(tz.local.name);
    tz.TZDateTime scheduledDate = tz.TZDateTime(location, DateTime.now().year,
        DateTime.now().month, DateTime.now().day, hour, minute);

    // 如果设置的时间已经过去，则安排到明天
    if (scheduledDate.isBefore(tz.TZDateTime.now(location))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 设置Android通知详情
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'default_channel',
      '默认通知',
      channelDescription: '默认通知渠道',
      importance: Importance.max,
      priority: Priority.high,
    );

    // 设置iOS通知详情
    const DarwinNotificationDetails iOSNotificationDetails =
        DarwinNotificationDetails();

    // 通知详情
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}