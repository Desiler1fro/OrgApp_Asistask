import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notification_preferences_repository.dart';

class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  NotificationPreferencesRepositoryImpl(this._prefs);

  final SharedPreferences _prefs;

  static const _kDeadline = 'notif.deadline.enabled';
  static const _kWorkBlock = 'notif.workBlock.enabled';
  static const _kCritical = 'notif.critical.enabled';

  final _controller = StreamController<NotificationPreferences>.broadcast();

  @override
  Future<NotificationPreferences> load() async {
    return NotificationPreferences(
      deadlineEnabled: _prefs.getBool(_kDeadline) ?? true,
      workBlockEnabled: _prefs.getBool(_kWorkBlock) ?? true,
      criticalEnabled: _prefs.getBool(_kCritical) ?? true,
    );
  }

  @override
  Future<void> save(NotificationPreferences prefs) async {
    await _prefs.setBool(_kDeadline, prefs.deadlineEnabled);
    await _prefs.setBool(_kWorkBlock, prefs.workBlockEnabled);
    await _prefs.setBool(_kCritical, prefs.criticalEnabled);
    _controller.add(prefs);
  }

  @override
  Stream<NotificationPreferences> watch() async* {
    yield await load();
    yield* _controller.stream;
  }
}
