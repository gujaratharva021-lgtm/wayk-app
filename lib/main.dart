import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/alarm_poller.dart';
import 'theme/app_theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(OneXTaskHandler());
}

class OneXTaskHandler extends TaskHandler {
  @override
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await NotificationService.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    await AlarmPoller.checkOnceStandalone();
  }

  @override
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

void initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'OneX_foreground',
      channelName: 'OneX Background Service',
      channelDescription: 'Keeps OneX checking for alarms and reminders in the background.',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(20000),
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<void> startForegroundTask() async {
  if (await FlutterForegroundTask.isRunningService) return;
  await FlutterForegroundTask.startService(
    notificationTitle: 'OneX is active',
    notificationText: 'Watching for your alarms and reminders.',
    callback: startCallback,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await NotificationService.init();
      initForegroundTask();
      await startForegroundTask();

      final prefs = await SharedPreferences.getInstance();
      final alreadyAskedBattery = prefs.getBool('asked_battery_optimization') ?? false;
      if (!alreadyAskedBattery) {
        await prefs.setBool('asked_battery_optimization', true);
        try {
          final batteryIntent = AndroidIntent(
            action: 'android.settings.IGNORE_BATTERY_OPTIMIZATION_SETTINGS',
          );
          await batteryIntent.launch();
        } catch (_) {}
      }
    } catch (e) {
      print('Native init skipped/failed: $e');
    }
  }

  runApp(const OneXApp());
}

final ValueNotifier<bool> useFullWidthOnWeb = ValueNotifier(false);
final ValueNotifier<double> homeMaxWidth = ValueNotifier(480);

class OneXApp extends StatelessWidget {
  const OneXApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'OneX',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.dark,
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
        builder: (context, child) {
          if (!kIsWeb) return child!;
          return ValueListenableBuilder<bool>(
            valueListenable: useFullWidthOnWeb,
            builder: (context, fullWidth, _) {
              if (fullWidth) return child!;
              return ValueListenableBuilder<double>(
                valueListenable: homeMaxWidth,
                builder: (context, maxW, _) {
                  return Container(
                    color: const Color(0xFF000000),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxW),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40),
                            ],
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}