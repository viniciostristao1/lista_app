import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import 'auth_service.dart';
import 'firestore_refs.dart';
import 'prefs.dart';

class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  FirestoreRefs get _refs => _ref.read(firestoreRefsProvider);
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _coletar() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid;
    try {
      uid = _ref.read(uidProvider);
    } catch (_) {
      uid = null;
    }
    List<Map<String, dynamic>> mercados = [];
    List<Map<String, dynamic>> produtos = [];
    List<Map<String, dynamic>> listas = [];
    List<Map<String, dynamic>> pedidos = [];
    if (uid != null) {
      try {
        final mercadosSnap = await _refs.mercados.get();
        final produtosSnap = await _refs.produtos.get();
        final listasSnap = await _refs.listas.get();
        final pedidosSnap = await _refs.pedidos.get();
        mercados = mercadosSnap.docs.map((d) => Map<String, dynamic>.from(d.data())..['id'] = d.id).toList();
        produtos = produtosSnap.docs.map((d) => _produtoParaBackup(d)).toList();
        for (final doc in listasSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final itensSnap = await _refs.itens(doc.id).get();
          data['itens'] = itensSnap.docs.map((i) => Map<String, dynamic>.from(i.data())..['id'] = i.id).toList();
          listas.add(data);
        }
        pedidos = pedidosSnap.docs.map((d) => Map<String, dynamic>.from(d.data())..['id'] = d.id).toList();
      } catch (_) {}
    }

    final notaTexto = prefs.getString('notaRapidaTexto') ?? '';
    final notaTodo = prefs.getBool('notaRapidaTodo') ?? false;
    final notaFeitos = prefs.getStringList('notaRapidaFeitos') ?? const [];
    final tema = prefs.getString('tema');
    final idioma = prefs.getString('idioma');
    final fontScale = prefs.getDouble('fontScale');
    final ordemCat = prefs.getStringList('ordemCategorias');

    return {
      'versao': 1,
      'exportadoEm': DateTime.now().toIso8601String(),
      'uid': uid,
      'mercados': mercados,
      'produtos': produtos,
      'listas': listas,
      'pedidos': pedidos,
      'prefs': {
        'tema': tema,
        'idioma': idioma,
        'fontScale': fontScale,
        'ordemCategorias': ordemCat,
        'notaRapida': {'texto': notaTexto, 'todo': notaTodo, 'feitos': notaFeitos},
      },
    };
  }

  Map<String, dynamic> _produtoParaBackup(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = Map<String, dynamic>.from(doc.data());
    d['id'] = doc.id;
    final precos = d['precos'] as Map<String, dynamic>?;
    if (precos != null) {
      final convertido = <String, dynamic>{};
      precos.forEach((k, v) {
        final m = v as Map<String, dynamic>?;
        final ts = m?['data'];
        String? dataIso;
        if (ts is Timestamp) dataIso = ts.toDate().toIso8601String();
        convertido[k] = {'valor': m?['valor'], 'data': dataIso};
      });
      d['precos'] = convertido;
    }
    for (final k in ['observacoesAtualizadasEm', 'updatedAt', 'createdAt']) {
      final ts = d[k];
      if (ts is Timestamp) d[k] = ts.toDate().toIso8601String();
    }
    return d;
  }

  Future<void> exportarJson(BuildContext context) async {
    final t = _ref.read(stringsProvider);
    Map<String, dynamic>? dados;
    try {
      dados = await _coletar();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.falhaBackup}: $e')));
      }
      return;
    }
    String jsonStr;
    try {
      jsonStr = const JsonEncoder.withIndent('  ').convert(dados);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.falhaBackup}: $e')));
      }
      return;
    }
    final preview = jsonStr.length > 1200 ? '${jsonStr.substring(0, 1200)}...' : jsonStr;
    if (!context.mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: Text(t.exportarJson),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.backupExportado, style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.line)),
                child: Text(preview, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 8),
              Text('${(jsonStr.length / 1024).toStringAsFixed(1)} KB', style: TextStyle(color: AppColors.dim, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, 'copiar'),
            child: Text(t.copiar),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dCtx, 'compartilhar'),
            child: Text(t.exportarJson),
          ),
        ],
      ),
    );
    if (action == null) return;
    if (action == 'copiar') {
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.backupExportado} (copiado)')));
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final nome = 'savelist-backup-${DateTime.now().toIso8601String().split('T').first}.json';
      final file = File('${dir.path}/$nome');
      await file.writeAsString(jsonStr);
      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Save List backup',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.backupExportado)));
      }
    } catch (e) {
      try {
        await Clipboard.setData(ClipboardData(text: jsonStr));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.backupExportado} (copiado)')));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.falhaBackup}: $e')));
        }
      }
    }
  }

  Future<void> salvarNaNuvem(BuildContext context) async {
    final t = _ref.read(stringsProvider);
    String? uid;
    try {
      uid = _ref.read(uidProvider);
    } catch (_) {
      uid = null;
    }
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.entrarComGoogleBackup)));
      }
      return;
    }
    try {
      await _db.collection('users').doc(uid).set({'ultimoBackup': Timestamp.now()}, SetOptions(merge: true));
      await _db.collection('users').doc(uid).collection('backups').add({
        'criadoEm': Timestamp.now(),
        'versao': 1,
        'nota': 'snapshot manual',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.backupSalvoNuvem)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.falhaBackup}: $e')));
      }
    }
  }

  Future<void> importarJson(BuildContext context) async {
    final t = _ref.read(stringsProvider);
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
      if (res == null || res.files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.nenhumBackupEncontrado)));
        }
        return;
      }
      final file = res.files.first;
      String? conteudo;
      if (file.bytes != null) {
        conteudo = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        conteudo = await File(file.path!).readAsString();
      }
      if (conteudo == null || conteudo.isEmpty) throw 'Arquivo vazio';
      final dados = jsonDecode(conteudo) as Map<String, dynamic>;
      if (!context.mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(t.confirmarImportacao),
          content: Text(t.confirmarImportacaoMsg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.cancelar)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.importarJson)),
          ],
        ),
      );
      if (ok != true) return;
      await _restaurar(dados);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.backupImportado)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.falhaBackup}: $e')));
      }
    }
  }

  Future<void> _restaurar(Map<String, dynamic> dados) async {
    final prefs = await SharedPreferences.getInstance();
    final mercados = (dados['mercados'] as List?) ?? const [];
    final produtos = (dados['produtos'] as List?) ?? const [];
    final listas = (dados['listas'] as List?) ?? const [];
    final pedidos = (dados['pedidos'] as List?) ?? const [];
    final prefsMap = (dados['prefs'] as Map<String, dynamic>?) ?? const {};
    String? uid;
    try {
      uid = _ref.read(uidProvider);
    } catch (_) {
      uid = null;
    }
    if (uid != null) {
      try {
        await _limparColecao(_refs.mercados);
        await _limparColecao(_refs.produtos);
        await _limparColecao(_refs.pedidos);
        final listasSnap = await _refs.listas.get();
        for (final d in listasSnap.docs) {
          final itens = await _refs.itens(d.id).get();
          for (final it in itens.docs) {
            await it.reference.delete();
          }
          await d.reference.delete();
        }
      } catch (_) {}
    }

    if (uid != null) {
      for (final m in mercados) {
        final map = Map<String, dynamic>.from(m as Map);
        final id = map.remove('id') as String?;
        final data = _limparTimestamps(map);
        if (id != null) {
          try {
            await _refs.mercados.doc(id).set(data);
          } catch (_) {}
        }
      }
      for (final p in produtos) {
        final map = Map<String, dynamic>.from(p as Map);
        final id = map.remove('id') as String?;
        final precosRaw = map['precos'] as Map<String, dynamic>?;
        if (precosRaw != null) {
          final convertido = <String, dynamic>{};
          precosRaw.forEach((k, v) {
            final mm = Map<String, dynamic>.from(v as Map);
            final dataIso = mm['data'] as String?;
            convertido[k] = {
              'valor': mm['valor'],
              'data': dataIso == null ? Timestamp.now() : Timestamp.fromDate(DateTime.parse(dataIso))
            };
          });
          map['precos'] = convertido;
        }
        for (final k in ['observacoesAtualizadasEm', 'updatedAt', 'createdAt']) {
          final v = map[k];
          if (v is String) map[k] = Timestamp.fromDate(DateTime.parse(v));
        }
        final data = _limparTimestamps(map);
        if (id != null) {
          try {
            await _refs.produtos.doc(id).set(data);
          } catch (_) {}
        }
      }
      for (final l in listas) {
        final map = Map<String, dynamic>.from(l as Map);
        final id = map.remove('id') as String?;
        final itens = (map.remove('itens') as List?) ?? const [];
        for (final k in ['createdAt', 'finalizadaAt']) {
          final v = map[k];
          if (v is String) map[k] = Timestamp.fromDate(DateTime.parse(v));
        }
        final data = _limparTimestamps(map);
        final listaId = id ?? _refs.listas.doc().id;
        try {
          await _refs.listas.doc(listaId).set(data);
        } catch (_) {}
        for (final it in itens) {
          final im = Map<String, dynamic>.from(it as Map);
          final iid = im.remove('id') as String?;
          final cdata = _limparTimestamps(im);
          if (iid != null) {
            try {
              await _refs.itens(listaId).doc(iid).set(cdata);
            } catch (_) {}
          }
        }
      }
      for (final ped in pedidos) {
        final map = Map<String, dynamic>.from(ped as Map);
        final id = map.remove('id') as String?;
        final v = map['data'];
        if (v is String) map['data'] = Timestamp.fromDate(DateTime.parse(v));
        final data = _limparTimestamps(map);
        if (id != null) {
          try {
            await _refs.pedidos.doc(id).set(data);
          } catch (_) {}
        }
      }
    }

    final nota = prefsMap['notaRapida'] as Map<String, dynamic>?;
    if (nota != null) {
      await prefs.setString('notaRapidaTexto', nota['texto'] as String? ?? '');
      await prefs.setBool('notaRapidaTodo', nota['todo'] as bool? ?? false);
      final feitos = (nota['feitos'] as List?)?.map((e) => e.toString()).toList() ?? const [];
      await prefs.setStringList('notaRapidaFeitos', List<String>.from(feitos));
    }
    final tema = prefsMap['tema'] as String?;
    if (tema != null) await prefs.setString('tema', tema);
    final idioma = prefsMap['idioma'] as String?;
    if (idioma != null) await prefs.setString('idioma', idioma);
    final font = prefsMap['fontScale'];
    if (font is num) await prefs.setDouble('fontScale', font.toDouble());
    final ordem = prefsMap['ordemCategorias'] as List?;
    if (ordem != null) {
      await prefs.setStringList('ordemCategorias', ordem.map((e) => e.toString()).toList());
    }
  }

  Map<String, dynamic> _limparTimestamps(Map<String, dynamic> m) {
    m.removeWhere((k, v) => v == null);
    return m;
  }

  Future<void> _limparColecao(CollectionReference<Map<String, dynamic>> col) async {
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(ref));
