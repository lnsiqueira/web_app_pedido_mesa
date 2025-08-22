import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/filial_nfe.dart';
import 'package:webapp_pedido_mesa/services/nfce/model/log_model.dart';

class NfeSequencialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> obterAtualizaProximoNumeroNfe(
    Log log, {
    required String filialId,
    required String serie,
  }) async {
    try {
      // 1. Obter referência do documento
      final query =
          await _firestore
              .collection('filialNfe')
              .where('filialId', isEqualTo: filialId)
              .where('serie', isEqualTo: serie)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        throw Exception('Caixa não encontrada para esta filial');
      }

      final doc = query.docs.first;
      final filialNfe = FilialNfe.fromFirestore(doc);

      // 2. Criar transação segura
      return await _firestore.runTransaction<int>((transaction) async {
        // Reler o documento dentro da transação
        final freshDoc = await transaction.get(doc.reference);
        final freshData = FilialNfe.fromFirestore(freshDoc);

        // Incrementar o número
        final novoNumero = freshData.numNfe + 1;

        // Atualizar no Firestore
        transaction.update(doc.reference, {'numNfe': novoNumero});

        return novoNumero;
      });
    } catch (e) {
      print('Erro ao obter próximo número NFC-e: $e');

      log.descricaoChave = '${log.descricaoChave} | Erro: ${e.toString()}';

      rethrow;
    }
  }

  Future<int> obterProximoNumeroNfe({
    required String filialId,
    required String serie,
  }) async {
    try {
      // 1. Obter referência do documento
      final query =
          await _firestore
              .collection('filialNfe')
              .where('filialId', isEqualTo: filialId)
              .where('serie', isEqualTo: serie)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        throw Exception('Caixa não encontrada para esta filial');
      }

      final doc = query.docs.first;
      final filialNfe = FilialNfe.fromFirestore(doc);

      return filialNfe.numNfe + 1;
    } catch (e) {
      print('Erro ao obter próximo número NFC-e: $e');
      //gravar log local
      // await saveLocalService.saveLogLocally(
      rethrow;
    }
  }

  Future<void> atualizarNumeroNfe({
    required String filialId,
    required String serie,
    required int novoNumero,
  }) async {
    try {
      // 1. Obter referência do documento
      final query =
          await _firestore
              .collection('filialNfe')
              .where('filialId', isEqualTo: filialId)
              .where('serie', isEqualTo: serie)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        throw Exception('Caixa não encontrada para esta filial');
      }

      final doc = query.docs.first;

      // 2. Criar transação segura para atualização
      await _firestore.runTransaction((transaction) async {
        // Reler o documento dentro da transação
        final freshDoc = await transaction.get(doc.reference);
        final freshData = FilialNfe.fromFirestore(freshDoc);

        // Verificar se o número ainda é consistente
        if (freshData.numNfe >= novoNumero) {
          throw Exception('Número NFC-e já foi atualizado por outro processo');
        }

        // Atualizar no Firestore
        transaction.update(doc.reference, {'numNfe': novoNumero});
      });
    } catch (e) {
      print('Erro ao atualizar número NFC-e: $e');
      //gravar log local
      // await saveLocalService.saveLogLocally(
      rethrow;
    }
  }

  // Método para criar um novo registro inicial se não existir
  Future<void> criarRegistroInicial({
    required String filialId,
    required String caixa,
    int numeroInicial = 1,
  }) async {
    await _firestore.collection('filialNfe').add({
      'serie': caixa,
      'numNfe': numeroInicial,
      'filialId': filialId,
    });
  }
}
