import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final _analytics = FirebaseAnalytics.instance;

  static void taskCompleted(int index) {
    _analytics.logEvent(
      name: 'task_completed',
      parameters: {'task_index': index},
    );
  }

  static void dayCompleted(int streak) {
    _analytics.logEvent(name: 'day_completed', parameters: {'streak': streak});
  }
}
