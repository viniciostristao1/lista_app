import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/lembrete.dart';

const _channelId = 'lembretes_channel';
const _channelName = 'Lembretes';
const _channelDesc = 'Lembretes gerais do Save List';

class NotificacaoService {
  NotificacaoService._();
  static final instance = NotificacaoService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
    } catch (_) {}
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onResponseBackground,
    );
    const channel = AndroidNotificationChannel(_channelId, _channelName, description: _channelDesc, importance: Importance.high);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    _inited = true;
  }

  static const _actions = [
    AndroidNotificationAction('snooze_30m', '30m', showsUserInterface: false),
    AndroidNotificationAction('snooze_2h', '2h', showsUserInterface: false),
    AndroidNotificationAction('snooze_4h', '4h', showsUserInterface: false),
    AndroidNotificationAction('snooze_24h', '24h', showsUserInterface: false),
  ];

  NotificationDetails _details(String titulo) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(titulo),
          actions: _actions,
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
      );

  int _idFor(String lembreteId, [int extra = 0]) => lembreteId.hashCode + extra;

  Future<void> agendar(Lembrete l) async {
    await init();
    await cancelar(l.id);
    if (!l.ativo) return;
    final now = tz.TZDateTime.now(tz.local);
    final base = tz.TZDateTime.from(l.dataHora, tz.local);
    if (l.recorrencia == Recorrencia.nenhuma) {
      if (base.isBefore(now)) return;
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', base, _details(l.titulo),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: l.id);
      return;
    }
    if (l.recorrencia == Recorrencia.diaria) {
      final t = tz.TZDateTime(tz.local, now.year, now.month, now.day, base.hour, base.minute);
      final next = t.isBefore(now) ? t.add(const Duration(days: 1)) : t;
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', next, _details(l.titulo),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.time, payload: l.id);
      return;
    }
    if (l.recorrencia == Recorrencia.semanal) {
      final weekday = l.diaSemana ?? base.weekday;
      var next = _nextWeekly(weekday, base.hour, base.minute);
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', next, _details(l.titulo),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, payload: l.id);
      return;
    }
    if (l.recorrencia == Recorrencia.mensal) {
      var next = tz.TZDateTime(tz.local, now.year, now.month, base.day, base.hour, base.minute);
      if (next.isBefore(now)) {
        next = tz.TZDateTime(tz.local, now.year, now.month + 1, base.day, base.hour, base.minute);
      }
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', next, _details(l.titulo),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, payload: l.id);
    }
  }

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (next.weekday != weekday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  Future<void> cancelar(String lembreteId) async {
    await _plugin.cancel(_idFor(lembreteId));
  }

  Future<void> cancelarTodos() async => _plugin.cancelAll();

  Future<void> reagendarTodos(List<Lembrete> lista) async {
    for (final l in lista) {
      await agendar(l);
    }
  }

  Future<void> adiar(String lembreteId, Duration d, {String? titulo, String? descricao}) async {
    await init();
    final at = tz.TZDateTime.now(tz.local).add(d);
    await _plugin.zonedSchedule(_idFor(lembreteId, d.inMinutes), titulo ?? 'Lembrete', descricao ?? '', at, NotificationDetails(
      android: AndroidNotificationDetails(_channelId, _channelName, importance: Importance.high, priority: Priority.high, actions: _actions),
    ), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: lembreteId);
  }

  void _onResponse(NotificationResponse r) {
    final action = r.actionId;
    final payload = r.payload;
    if (payload == null) return;
    if (action == null) return;
    Duration? d;
    if (action == 'snooze_30m') d = const Duration(minutes: 30);
    if (action == 'snooze_2h') d = const Duration(hours: 2);
    if (action == 'snooze_4h') d = const Duration(hours: 4);
    if (action == 'snooze_24h') d = const Duration(hours: 24);
    if (d != null) {
      adiar(payload, d);
    }
  }

  @pragma('vm:entry-point')
  static void _onResponseBackground(NotificationResponse r) {
    final action = r.actionId;
    final payload = r.payload;
    if (payload == null || action == null) return;
    Duration? d;
    if (action == 'snooze_30m') d = const Duration(minutes: 30);
    if (action == 'snooze_2h') d = const Duration(hours: 2);
    if (action == 'snooze_4h') d = const Duration(hours: 4);
    if (action == 'snooze_24h') d = const Duration(hours: 24);
    if (d != null) {
      NotificacaoService.instance.adiar(payload, d);
    }
  }
}
