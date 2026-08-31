import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/lembrete.dart';

const _channelId = 'lembretes_channel_v2';
const _channelName = 'Lembretes';
const _channelDesc = 'Lembretes gerais do Save List';
const _channelIdAntigo = 'lembretes_channel';

class NotificacaoService {
  NotificacaoService._();
  static final instance = NotificacaoService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('ic_notif');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onResponseBackground,
    );
    const channel = AndroidNotificationChannel(_channelId, _channelName, description: _channelDesc, importance: Importance.max, playSound: true, enableVibration: true);
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.deleteNotificationChannel(_channelIdAntigo);
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
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
          icon: 'ic_notif',
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

  tz.TZDateTime _toZoned(DateTime dt) {
    final wall = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    return tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, wall.millisecondsSinceEpoch);
  }

  Future<DateTime?> _zoned(int id, String titulo, String? corpo, tz.TZDateTime at, NotificationDetails details, String payload, {DateTimeComponents? match}) async {
    final minAt = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, DateTime.now().add(const Duration(seconds: 5)).millisecondsSinceEpoch);
    final when = at.isBefore(minAt) ? minAt : at;
    Future<void> tentar(AndroidScheduleMode mode) => _plugin.zonedSchedule(id, titulo, corpo, when, details,
        androidScheduleMode: mode, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: payload, matchDateTimeComponents: match);
    for (final modo in [AndroidScheduleMode.exactAllowWhileIdle, AndroidScheduleMode.alarmClock, AndroidScheduleMode.inexactAllowWhileIdle]) {
      try {
        await tentar(modo);
        return DateTime(when.year, when.month, when.day, when.hour, when.minute, when.second);
      } catch (e) {
        debugPrint('SaveList/notif: modo $modo falhou: $e');
      }
    }
    return null;
  }

  Future<DateTime?> agendar(Lembrete l) async {
    await init();
    await cancelar(l.id);
    if (!l.ativo) return null;
    final nowWall = DateTime.now();
    final now = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, nowWall.millisecondsSinceEpoch);
    final base = _toZoned(l.dataHora);
    final payload = _payload(l);
    final details = _details(l.titulo, corpo: l.descricao);
    if (l.recorrencia == Recorrencia.nenhuma) {
      if (base.isBefore(now)) {
        debugPrint('SaveList/notif: "${l.titulo}" com horário no passado, não agenda');
        return null;
      }
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', base, details, payload);
    }
    if (l.recorrencia == Recorrencia.diaria) {
      final todayWall = DateTime(nowWall.year, nowWall.month, nowWall.day, base.hour, base.minute, base.second);
      var nextWall = todayWall;
      if (nextWall.isBefore(nowWall)) nextWall = nextWall.add(const Duration(days: 1));
      final next = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, nextWall.millisecondsSinceEpoch);
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', next, details, payload, match: DateTimeComponents.time);
    }
    if (l.recorrencia == Recorrencia.semanal) {
      final weekday = l.diaSemana ?? l.dataHora.weekday;
      final nextWall = _nextWeeklyWall(weekday, base.hour, base.minute, base.second);
      final next = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, nextWall.millisecondsSinceEpoch);
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', next, details, payload, match: DateTimeComponents.dayOfWeekAndTime);
    }
    if (l.recorrencia == Recorrencia.mensal) {
      var nextWall = DateTime(nowWall.year, nowWall.month, base.day, base.hour, base.minute, base.second);
      if (nextWall.isBefore(nowWall)) {
        var y = nowWall.year;
        var m = nowWall.month + 1;
        if (m > 12) {
          m = 1;
          y += 1;
        }
        nextWall = DateTime(y, m, base.day, base.hour, base.minute, base.second);
      }
      final next = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, nextWall.millisecondsSinceEpoch);
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', next, details, payload, match: DateTimeComponents.dayOfMonthAndTime);
    }
    return null;
  }

  DateTime _nextWeeklyWall(int weekday, int hour, int minute, [int second = 0]) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, hour, minute, second);
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
      try {
        await agendar(l);
      } catch (e) {
        debugPrint('SaveList/notif: erro reagendando "${l.titulo}": $e');
      }
    }
  }

  Future<List<String>> pendentes() async {
    await init();
    final reqs = await _plugin.pendingNotificationRequests();
    return [for (final r in reqs) r.title ?? '(sem título)']..sort();
  }

  static const _battery = MethodChannel('savelist/battery');

  Future<bool?> bateriaOtimizada() async {
    if (defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final ignorando = await _battery.invokeMethod<bool>('isIgnoring');
      return ignorando == false;
    } catch (e) {
      debugPrint('SaveList/notif: bateriaOtimizada falhou: $e');
      return null;
    }
  }

  Future<void> pedirIgnorarBateria() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _battery.invokeMethod('requestIgnore');
    } catch (e) {
      debugPrint('SaveList/notif: pedirIgnorarBateria falhou: $e');
    }
  }

  Future<void> mostrarTesteImediato() async {
    await init();
    await _plugin.show(999999, 'Teste Save List', 'Notificação de teste — se você vê isso, as notificações estão funcionando!', _details('Teste Save List', corpo: 'Notificação de teste — se você vê isso, as notificações estão funcionando!'));
  }

  Future<DateTime?> testeAlarme10s() async {
    await init();
    final wall = DateTime.now().add(const Duration(seconds: 10));
    final at = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, wall.millisecondsSinceEpoch);
    return _zoned(999998, 'Teste alarme Save List', 'Se esta notificação chegou (~10s), o alarme agendado funciona no seu aparelho!', at, _details('Teste alarme Save List', corpo: 'Se esta notificação chegou (~10s), o alarme agendado funciona no seu aparelho!'), '');
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
    final wall = DateTime.now().add(d);
    final local = DateTime(wall.year, wall.month, wall.day, wall.hour, wall.minute, wall.second);
    final at = tz.TZDateTime.fromMillisecondsSinceEpoch(tz.UTC, local.millisecondsSinceEpoch);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.max,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
        icon: 'ic_notif',
        styleInformation: BigTextStyleInformation(desc, contentTitle: t, summaryText: 'Save List • Lembrete adiado ${d.inMinutes}m'),
        ticker: t,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        actions: _actions,
      ),
      iOS: const DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    final zonedId = _idFor(id, d.inMinutes + DateTime.now().millisecondsSinceEpoch % 1000);
    try {
      await _plugin.zonedSchedule(zonedId, t, desc, at, details, androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: lembreteIdOrPayload);
    } catch (_) {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      tz.initializeTimeZones();
      await _plugin.zonedSchedule(zonedId, t, desc, at, details, androidScheduleMode: AndroidScheduleMode.alarmClock, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, payload: lembreteIdOrPayload);
    }
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
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      tz.initializeTimeZones();
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
