import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/lembrete.dart';

const _channelId = 'lembretes_channel_v2';
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
    const channel = AndroidNotificationChannel(_channelId, _channelName, description: _channelDesc, importance: Importance.max, playSound: true, enableVibration: true);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    _inited = true;
  }

  static const _actions = [
    AndroidNotificationAction('snooze_30m', '30m', showsUserInterface: false, cancelNotification: true),
    AndroidNotificationAction('snooze_2h', '2h', showsUserInterface: false, cancelNotification: true),
    AndroidNotificationAction('snooze_4h', '4h', showsUserInterface: false, cancelNotification: true),
    AndroidNotificationAction('snooze_24h', '24h', showsUserInterface: false, cancelNotification: true),
  ];

  NotificationDetails _details(String titulo, {String? corpo}) => NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.reminder,
          styleInformation: BigTextStyleInformation(corpo ?? '', contentTitle: titulo, summaryText: 'Save List • Lembrete'),
          ticker: titulo,
          enableVibration: true,
          playSound: true,
          autoCancel: true,
          ongoing: false,
          showWhen: true,
          actions: _actions,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true, threadIdentifier: _channelId),
      );

  int _idFor(String lembreteId, [int extra = 0]) => (lembreteId.hashCode & 0x7fffffff) + extra;

  String _payload(Lembrete l) => jsonEncode({'id': l.id, 'titulo': l.titulo, 'descricao': l.descricao});

  tz.TZDateTime _toZoned(DateTime dt) => tz.TZDateTime(tz.local, dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  Future<void> agendar(Lembrete l) async {
    await init();
    await cancelar(l.id);
    if (!l.ativo) return;
    final now = tz.TZDateTime.now(tz.local);
    final base = _toZoned(l.dataHora);
    final payload = _payload(l);
    final details = _details(l.titulo, corpo: l.descricao);
    if (l.recorrencia == Recorrencia.nenhuma) {
      if (base.isBefore(now)) return;
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', base, details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: payload);
      return;
    }
    if (l.recorrencia == Recorrencia.diaria) {
      final t = tz.TZDateTime(tz.local, now.year, now.month, now.day, base.hour, base.minute, base.second);
      final next = t.isBefore(now) ? t.add(const Duration(days: 1)) : t;
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', next, details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.time, payload: payload);
      return;
    }
    if (l.recorrencia == Recorrencia.semanal) {
      final weekday = l.diaSemana ?? base.weekday;
      var next = _nextWeekly(weekday, base.hour, base.minute, base.second);
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', next, details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime, payload: payload);
      return;
    }
    if (l.recorrencia == Recorrencia.mensal) {
      var next = tz.TZDateTime(tz.local, now.year, now.month, base.day, base.hour, base.minute, base.second);
      if (next.isBefore(now)) {
        var y = now.year;
        var m = now.month + 1;
        if (m > 12) {
          m = 1;
          y += 1;
        }
        next = tz.TZDateTime(tz.local, y, m, base.day, base.hour, base.minute, base.second);
      }
      await _plugin.zonedSchedule(_idFor(l.id), l.titulo, l.descricao ?? '', next, details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime, payload: payload);
    }
  }

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute, [int second = 0]) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute, second);
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

  Future<void> mostrarTesteImediato() async {
    await init();
    await _plugin.show(999999, 'Teste Save List', 'Notificação de teste — se você vê isso, as notificações estão funcionando!', _details('Teste Save List', corpo: 'Notificação de teste — se você vê isso, as notificações estão funcionando!'));
  }

  Future<void> adiar(String lembreteIdOrPayload, Duration d, {String? titulo, String? descricao}) async {
    await init();
    String id = lembreteIdOrPayload;
    String t = titulo ?? 'Lembrete';
    String desc = descricao ?? '';
    try {
      final m = jsonDecode(lembreteIdOrPayload) as Map<String, dynamic>;
      if (m['id'] != null) {
        id = m['id'] as String;
        t = titulo ?? (m['titulo'] as String? ?? 'Lembrete');
        desc = descricao ?? (m['descricao'] as String? ?? '');
      }
    } catch (_) {}
    final at = tz.TZDateTime.now(tz.local).add(d);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(desc, contentTitle: t, summaryText: 'Save List • Lembrete adiado ${d.inMinutes}m'),
        ticker: t,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        actions: _actions,
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _plugin.zonedSchedule(_idFor(id, d.inMinutes + DateTime.now().millisecondsSinceEpoch % 1000), t, desc, at, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: lembreteIdOrPayload);
  }

  void _onResponse(NotificationResponse r) {
    final action = r.actionId;
    final payload = r.payload;
    if (payload == null || action == null) return;
    Duration? d;
    if (action == 'snooze_30m') d = const Duration(minutes: 30);
    if (action == 'snooze_2h') d = const Duration(hours: 2);
    if (action == 'snooze_4h') d = const Duration(hours: 4);
    if (action == 'snooze_24h') d = const Duration(hours: 24);
    if (d != null) {
      String t = 'Lembrete';
      String desc = '';
      try {
        final m = jsonDecode(payload) as Map<String, dynamic>;
        t = m['titulo'] as String? ?? t;
        desc = m['descricao'] as String? ?? desc;
      } catch (_) {}
      adiar(payload, d, titulo: t, descricao: desc);
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
      String t = 'Lembrete';
      String desc = '';
      try {
        final m = jsonDecode(payload) as Map<String, dynamic>;
        t = m['titulo'] as String? ?? t;
        desc = m['descricao'] as String? ?? desc;
      } catch (_) {}
      NotificacaoService.instance.adiar(payload, d, titulo: t, descricao: desc);
    }
  }
}
