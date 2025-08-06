import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/categorias.dart';
import 'package:webapp_pedido_mesa/main.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/screens/item/item_page.dart';
import 'package:webapp_pedido_mesa/widgets/conexao_wrapper.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? mesa;
  String? comanda;
  List<Categoria> categorias = [];
  bool isLoading = false;

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
        _carregarCategorias();
      }
    }
  }

  Future<void> _carregarCategorias() async {
    setState(() {
      isLoading = true;
    });

    const url =
        '${Urls.urlApiAzure}/Categorias/categoria-by-filial/8urs76lF1QwjcNpi3CwD';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          categorias = data.map((e) => Categoria.fromJson(e)).toList();
        });
      } else {
        print('Erro ao carregar categorias: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / 3 - 24;

    return SafeArea(
      child: Scaffold(
        body: ConexaoWrapper(
          child: LayoutBuilder(
            builder:
                (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset('images/logodd.png', height: 48),
                                Row(
                                  children: [
                                    _buildFlag(
                                      'images/br.png',
                                      'pt',
                                      languageController,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFlag(
                                      'images/en.png',
                                      'en',
                                      languageController,
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFlag(
                                      'images/es.png',
                                      'es',
                                      languageController,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Center(
                            child: ElevatedButton(
                              onPressed: _pedirMesaEComanda,
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                )!.placeYourOrder.toUpperCase(),
                              ),
                            ),
                          ),
                          isLoading
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: const CircularProgressIndicator(),
                              )
                              : SizedBox(),

                          const SizedBox(height: 40),
                          if (mesa != null && comanda != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context)!.table}: $mesa',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    '${AppLocalizations.of(context)!.order}: $comanda',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children:
                                        categorias.map((categoria) {
                                          return SizedBox(
                                            width: itemWidth.clamp(100, 200),
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                backgroundColor: Colors.white,
                                                foregroundColor: Colors.black,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) => ItensPage(
                                                          idCategoria:
                                                              categoria.id,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: Image.network(
                                                      categoria.imagem,
                                                      height: 80,
                                                      width: 80,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons.broken_image,
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: Text(
                                                      categoria.desCategoria,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          const Spacer(),
                          const Divider(height: 1, thickness: 1),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              '© 2025 BakeryFood. Todos os direitos reservados.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ),
    );

    // return SafeArea(
    //   child: Scaffold(
    //     body: ConexaoWrapper(
    //       child: Column(
    //         children: [
    //           // TOPO: Logo à esquerda, bandeiras à direita
    //           Padding(
    //             padding: const EdgeInsets.symmetric(
    //               horizontal: 16,
    //               vertical: 12,
    //             ),
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 Image.asset('images/logodd.png', height: 48),
    //                 Row(
    //                   children: [
    //                     _buildFlag('images/br.png', 'pt', languageController),
    //                     const SizedBox(width: 8),
    //                     _buildFlag('images/en.png', 'en', languageController),
    //                     const SizedBox(width: 8),
    //                     _buildFlag('images/es.png', 'es', languageController),
    //                   ],
    //                 ),
    //               ],
    //             ),
    //           ),

    //           const SizedBox(height: 40),

    //           // BOTÃO central
    //           Center(
    //             child: ElevatedButton(
    //               onPressed: _pedirMesaEComanda,
    //               child: Text(
    //                 AppLocalizations.of(context)!.placeYourOrder.toUpperCase(),
    //               ),
    //             ),
    //           ),

    //           const SizedBox(height: 40),

    //           // Exibe mesa e comanda
    //           if (mesa != null && comanda != null)
    //             Column(
    //               children: [
    //                 Text(
    //                   '${AppLocalizations.of(context)!.table}: $mesa',
    //                   style: const TextStyle(fontSize: 18),
    //                 ),
    //                 Text(
    //                   '${AppLocalizations.of(context)!.order}: $comanda',
    //                   style: const TextStyle(fontSize: 18),
    //                 ),
    //                 Wrap(
    //                   spacing: 12,
    //                   runSpacing: 12,
    //                   children:
    //                       categorias.map((categoria) {
    //                         return ElevatedButton(
    //                           style: ElevatedButton.styleFrom(
    //                             padding: const EdgeInsets.all(12),
    //                             backgroundColor: Colors.white,
    //                             foregroundColor: Colors.black,
    //                           ),
    //                           onPressed: () {},
    //                           child: Column(
    //                             mainAxisSize: MainAxisSize.min,
    //                             children: [
    //                               ClipRRect(
    //                                 borderRadius: BorderRadius.circular(8),
    //                                 child: FadeInImage.assetNetwork(
    //                                   placeholder: 'images/placeholder.png',
    //                                   image: categoria.imagem,
    //                                   height: 80,
    //                                   width: 80,
    //                                   fit: BoxFit.cover,
    //                                   imageErrorBuilder:
    //                                       (context, error, stackTrace) =>
    //                                           const Icon(Icons.broken_image),
    //                                 ),
    //                               ),
    //                               // Image.network(
    //                               //   categoria.imagem,
    //                               //   height: 80,
    //                               //   width: 80,
    //                               //   fit: BoxFit.cover,
    //                               // ),
    //                               const SizedBox(height: 8),
    //                               Text(
    //                                 categoria.desCategoria,
    //                                 textAlign: TextAlign.center,
    //                                 maxLines: 2,
    //                                 overflow: TextOverflow.ellipsis,
    //                                 style: const TextStyle(fontSize: 14),
    //                               ),
    //                             ],
    //                           ),
    //                         );
    //                       }).toList(),
    //                 ),
    //               ],
    //             ),
    //           const Spacer(),

    //           const Divider(height: 1, thickness: 1),
    //           const Padding(
    //             padding: EdgeInsets.symmetric(vertical: 12.0),
    //             child: Text(
    //               '© 2025 BakeryFood. Todos os direitos reservados.',
    //               style: TextStyle(fontSize: 12, color: Colors.grey),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
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

