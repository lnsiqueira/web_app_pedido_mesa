import 'package:cloud_firestore/cloud_firestore.dart';

class FilialNfe {
  final String? id;
  final String serie;
  final int numNfe;
  final String filialId;

  FilialNfe({
    this.id,
    required this.serie,
    required this.numNfe,
    required this.filialId,
  });

  factory FilialNfe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FilialNfe(
      id: doc.id,
      serie: data['serie'] ?? '',
      numNfe: data['numNfe'] ?? 0,
      filialId: data['filialId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'serie': serie, 'numNfe': numNfe, 'filialId': filialId};
  }
}
