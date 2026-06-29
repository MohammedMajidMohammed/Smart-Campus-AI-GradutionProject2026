import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String scheduleBoxName = 'schedule_box';

  Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(scheduleBoxName);
  }

  Future<void> cacheSchedule(List<dynamic> scheduleData) async {
    final box = Hive.box(scheduleBoxName);
    await box.put('schedule', scheduleData);
  }

  List<dynamic>? getCachedSchedule() {
    final box = Hive.box(scheduleBoxName);
    return box.get('schedule');
  }
}
