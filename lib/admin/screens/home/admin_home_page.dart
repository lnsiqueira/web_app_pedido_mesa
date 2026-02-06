import 'package:flutter/material.dart';
import 'package:webapp_pedido_mesa/admin/screens/home/admin_cardapio_diario_page.dart';
import 'package:webapp_pedido_mesa/admin/services/cardapio_admin_service.dart';
import 'package:webapp_pedido_mesa/widgets/primary_button.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool verificando = true;

  @override
  void initState() {
    super.initState();
    _verificarCardapioHoje();
  }

  Future<void> _verificarCardapioHoje() async {
    final jaExiste = await cardapioJaExisteHoje();

    if (jaExiste && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminCardapioDiarioPage(),
        ),
      );
      return;
    }

    setState(() => verificando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('images/logodd_clean.png', height: 40),
            ],
          ),
        ),
      ),
      body: Center(
        child: verificando
            ? const CircularProgressIndicator()
            : PrimaryActionButton(
                text: 'CARREGAR CARDÁPIO DIÁRIO',
                onPressed: () async {
                  final sucesso = await atualizarCardapioDiario();

                  if (sucesso && mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminCardapioDiarioPage(),
                      ),
                    );
                  }
                },
              ),
      ),
    );
  }
}
