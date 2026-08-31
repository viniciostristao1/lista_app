import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/lembrete.dart';

const _channelId = 'lembretes_channel_v3';
const _channelName = 'Lembretes';
const _channelDesc = 'Lembretes gerais do Save List';
const _chanAntigoV2 = 'lembretes_channel_v2';
const _chanAntigoV1 = 'lembretes_channel';

class NotificacaoService {
  NotificacaoService._();
  static final instance = NotificacaoService._();
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> _initTimezone() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));
      } catch (_) {}
    }
  }

  Future<void> init() async {
    if (_inited) return;
    await _initTimezone();
    const android = AndroidInitializationSettings('ic_notif');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onResponse,
      onDidReceiveBackgroundNotificationResponse: _onResponseBackground,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    const channel = AndroidNotificationChannel(_channelId, _channelName, description: _channelDesc, importance: Importance.max, playSound: true, enableVibration: true);
    await androidImpl?.createNotificationChannel(channel);
    await androidImpl?.deleteNotificationChannel(_chanAntigoV2);
    await androidImpl?.deleteNotificationChannel(_chanAntigoV1);
    await androidImpl?.deleteNotificationChannel('lembretes');
    await androidImpl?.requestNotificationsPermission();
    await androidImpl?.requestExactAlarmsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    _inited = true;
  }

  static const _actions = [
    AndroidNotificationAction('snooze_30m', '30m', showsUserInterface: false, cancelNotification: true),
    AndroidNotificationAction('snooze_2h', '2h', showsUserInterface: false, cancelNotification: true),
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

  tz.TZDateTime _toZonedLocal(DateTime dt) => tz.TZDateTime(tz.local, dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

  Future<bool> _canExact() async {
    try {
      final impl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ok = await impl?.canScheduleExactNotifications();
      if (ok != null) return ok;
    } catch (_) {}
    return true;
  }

  Future<DateTime?> _zoned(int id, String titulo, String? corpo, tz.TZDateTime at, NotificationDetails details, String payload, {DateTimeComponents? match}) async {
    final minAt = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5));
    final when = at.isBefore(minAt) ? minAt : at;
    final canExact = await _canExact();
    final modos = <AndroidScheduleMode>[];
    if (canExact) {
      modos.add(AndroidScheduleMode.exactAllowWhileIdle);
      modos.add(AndroidScheduleMode.alarmClock);
    } else {
      modos.add(AndroidScheduleMode.alarmClock);
      modos.add(AndroidScheduleMode.exactAllowWhileIdle);
    }
    modos.add(AndroidScheduleMode.inexactAllowWhileIdle);
    for (final modo in modos) {
      try {
        await _plugin.zonedSchedule(id, titulo, corpo, when, details, androidScheduleMode: modo, payload: payload, matchDateTimeComponents: match);
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
    final now = tz.TZDateTime.now(tz.local);
    final payload = _payload(l);
    final details = _details(l.titulo, corpo: l.descricao);
    if (l.recorrencia == Recorrencia.nenhuma) {
      final baseLocal = _toZonedLocal(l.dataHora);
      if (baseLocal.isBefore(now) && l.dataHora.isBefore(DateTime.now())) {
        debugPrint('SaveList/notif: "${l.titulo}" no passado local, não agenda');
        return null;
      }
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', baseLocal, details, payload);
    }
    if (l.recorrencia == Recorrencia.diaria) {
      final baseHour = l.dataHora.hour;
      final baseMin = l.dataHora.minute;
      final baseSec = l.dataHora.second;
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, baseHour, baseMin, baseSec);
      if (next.isBefore(now)) next = next.add(const Duration(days: 1));
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', next, details, payload, match: DateTimeComponents.time);
    }
    if (l.recorrencia == Recorrencia.semanal) {
      final weekday = l.diaSemana ?? l.dataHora.weekday;
      final next = _nextWeekly(weekday, l.dataHora.hour, l.dataHora.minute, l.dataHora.second);
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', next, details, payload, match: DateTimeComponents.dayOfWeekAndTime);
    }
    if (l.recorrencia == Recorrencia.mensal) {
      var next = tz.TZDateTime(tz.local, now.year, now.month, l.dataHora.day, l.dataHora.hour, l.dataHora.minute, l.dataHora.second);
      if (next.isBefore(now)) {
        var y = now.year;
        var m = now.month + 1;
        if (m > 12) {
          m = 1;
          y += 1;
        }
        next = tz.TZDateTime(tz.local, y, m, l.dataHora.day, l.dataHora.hour, l.dataHora.minute, l.dataHora.second);
      }
      return _zoned(_idFor(l.id), l.titulo, l.descricao ?? '', next, details, payload, match: DateTimeComponents.dayOfMonthAndTime);
    }
    return null;
  }

  tz.TZDateTime _nextWeekly(int weekday, int hour, int minute, [int second = 0]) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute, second);
    while (next.weekday != weekday || next.isBefore(now.add(const Duration(seconds: 1)))) {
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

  Future<List<PendingNotificationRequest>> pendentesDetalhe() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  Future<int> qtdAtivas() async {
    try {
      await init();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ativas = await android?.getActiveNotifications();
      if (ativas == null) return 0;
      return ativas.where((n) => n.channelId == _channelId).length;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> temAtiva() async => (await qtdAtivas()) > 0;

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
    final at = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    return _zoned(999998, 'Teste alarme Save List', 'Se esta notificação chegou (~10s), o alarme agendado funciona no seu aparelho!', at, _details('Teste alarme Save List', corpo: 'Se esta notificação chegou (~10s), o alarme agendado funciona no seu aparelho!'), '');
  }

  Future<void> adiar(String lembreteIdOrPayload, Duration d, {String? titulo, String? descricao}) async {
    try {
      await _initTimezone();
    } catch (_) {}
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
    final zonedId = _idFor(id, d.inMinutes + DateTime.now().millisecondsSinceEpoch % 10000);
    final canExact = await _canExact();
    final modo = canExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.alarmClock;
    try {
      await _plugin.zonedSchedule(zonedId, t, desc, at, details, androidScheduleMode: modo, payload: lembreteIdOrPayload);
    } catch (_) {
      await _plugin.zonedSchedule(zonedId, t, desc, at, details, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, payload: lembreteIdOrPayload);
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
      NotificacaoService.instance.adiar(payload, d, titulo: 'Lembrete', descricao: '');
    }
  }
}
