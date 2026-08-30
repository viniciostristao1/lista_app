import 'package:cloud_firestore/cloud_firestore.dart';

enum Recorrencia { nenhuma, diaria, semanal, mensal }

extension RecorrenciaLabel on Recorrencia {
  String get nome {
    switch (this) {
      case Recorrencia.nenhuma: return 'Uma vez';
      case Recorrencia.diaria: return 'Diária';
      case Recorrencia.semanal: return 'Semanal';
      case Recorrencia.mensal: return 'Mensal';
    }
  }
}

class Lembrete {
  const Lembrete({
    required this.id,
    required this.titulo,
    this.descricao,
    required this.dataHora,
    this.recorrencia = Recorrencia.nenhuma,
    this.diaSemana,
    this.ativo = true,
    this.createdAt,
  });

  final String id;
  final String titulo;
  final String? descricao;
  final DateTime dataHora;
  final Recorrencia recorrencia;
  final int? diaSemana;
  final bool ativo;
  final DateTime? createdAt;

  factory Lembrete.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Lembrete(
      id: doc.id,
      titulo: (d['titulo'] as String?) ?? '',
      descricao: d['descricao'] as String?,
      dataHora: (d['dataHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recorrencia: Recorrencia.values.firstWhere(
        (e) => e.name == (d['recorrencia'] as String?),
        orElse: () => Recorrencia.nenhuma,
      ),
      diaSemana: (d['diaSemana'] as num?)?.toInt(),
      ativo: (d['ativo'] as bool?) ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'titulo': titulo,
        'descricao': descricao,
        'dataHora': Timestamp.fromDate(dataHora),
        'recorrencia': recorrencia.name,
        'diaSemana': diaSemana,
        'ativo': ativo,
        'createdAt': createdAt == null ? Timestamp.now() : Timestamp.fromDate(createdAt!),
      };
}
