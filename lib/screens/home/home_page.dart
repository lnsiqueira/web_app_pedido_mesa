import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? mesa;
  String? comanda;

  Future<void> _pedirMesaEComanda() async {
    final mesaController = TextEditingController();
    final comandaController = TextEditingController();

    // Dialog da mesa
    final mesaResult = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.enterTableNumber),
            content: TextField(
              controller: mesaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.table,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, mesaController.text),
                child: Text(AppLocalizations.of(context)!.continueText),
              ),
            ],
          ),
    );

    if (mesaResult != null && mesaResult.isNotEmpty) {
      final comandaResult = await showDialog<String>(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text(AppLocalizations.of(context)!.enterOrderNumber),
              content: TextField(
                controller: comandaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.order,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pop(context, comandaController.text),
                  child: Text(AppLocalizations.of(context)!.continueText),
                ),
              ],
            ),
      );

      if (comandaResult != null && comandaResult.isNotEmpty) {
        setState(() {
          mesa = mesaResult;
          comanda = comandaResult;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // TOPO: Logo à esquerda, bandeiras à direita
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('images/logodd.png', height: 48),
                  Row(
                    children: [
                      _buildFlag('images/br.png', 'pt', languageController),
                      const SizedBox(width: 8),
                      _buildFlag('images/en.png', 'en', languageController),
                      const SizedBox(width: 8),
                      _buildFlag('images/es.png', 'es', languageController),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BOTÃO central
            Center(
              child: ElevatedButton(
                onPressed: _pedirMesaEComanda,
                child: Text(
                  AppLocalizations.of(context)!.placeYourOrder.toUpperCase(),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Exibe mesa e comanda
            if (mesa != null && comanda != null)
              Column(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.table}: $mesa',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    '${AppLocalizations.of(context)!.order}: $comanda',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            const Spacer(),

            const Divider(height: 1, thickness: 1),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                '© 2025 BakeryFood. Todos os direitos reservados.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlag(String path, String lang, LanguageController controller) {
    return InkWell(
      onTap: () {
        controller.changeLanguage(lang);
      },
      child: Image.asset(path, width: 44),
    );
  }
}
  //   return SafeArea(
  //     child: Scaffold(
  //       appBar: AppBar(title: Text(AppLocalizations.of(context)!.helloWorld)),
  //       body: Row(
  //         mainAxisAlignment:
  //             MainAxisAlignment.spaceBetween, // Alinha os extremos
  //         children: [
  //           // Text(AppLocalizations.of(context)!.helloWorld),
  //           Row(
  //             children: [
  //               InkWell(
  //                 onTap: () {
  //                   languageController.isPortuguese = true;
  //                   languageController.isEnglish = false;
  //                   languageController.isSpain = false;
  //                   idioma = 'pt';
  //                   languageController.toggleLanguage();
  //                   setState(() {});
  //                 }, // Português
  //                 child: Image.asset('images/br.png', width: 44),
  //               ),
  //               SizedBox(width: 8),
  //               InkWell(
  //                 onTap: () {
  //                   languageController.isSpain = false;
  //                   languageController.isEnglish = true;
  //                   languageController.isPortuguese = false;
  //                   idioma = 'en';
  //                   languageController.toggleLanguage();
  //                   setState(() {});
  //                 }, // Inglês
  //                 child: Image.asset('images/en.png', width: 44),
  //               ),
  //               SizedBox(width: 8),
  //               InkWell(
  //                 onTap: () {
  //                   languageController.isSpain = true;
  //                   languageController.isEnglish = false;
  //                   languageController.isPortuguese = false;
  //                   idioma = 'es';
  //                   languageController.toggleLanguage();
  //                 }, // Espanhol
  //                 child: Image.asset('images/es.png', width: 44),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

