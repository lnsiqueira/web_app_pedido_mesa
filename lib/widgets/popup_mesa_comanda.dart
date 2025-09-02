import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:webapp_pedido_mesa/core/constants.dart';

// class PopupMesaComanda extends StatefulWidget {
//   const PopupMesaComanda({
//     super.key,
//     required this.formKey,
//     required this.mesaController,
//     required this.comandaController,
//   });

//   final GlobalKey<FormState> formKey;
//   final TextEditingController mesaController;
//   final TextEditingController comandaController;

//   @override
//   State<PopupMesaComanda> createState() => _PopupMesaComandaState();
// }

// class _PopupMesaComandaState extends State<PopupMesaComanda>
//     with TickerProviderStateMixin {
//   late AnimationController _shakeController;
//   late Animation<double> _shakeAnimation;
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _shakeController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );
//     _shakeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(
//       parent: _shakeController,
//       curve: Curves.elasticIn,
//     ));
//   }

//   @override
//   void dispose() {
//     _shakeController.dispose();
//     super.dispose();
//   }

//   void _triggerShakeAnimation() {
//     _shakeController.reset();
//     _shakeController.forward();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       insetPadding: const EdgeInsets.all(20),
//       child: AnimatedBuilder(
//         animation: _shakeAnimation,
//         builder: (context, child) {
//           final shakeValue = _shakeAnimation.value;
//           final offset = 8.0 * (shakeValue * 4.0 * (1.0 - shakeValue));

//           return Transform.translate(
//             offset: Offset(offset * (shakeValue > 0.5 ? -1 : 1), 0),
//             child: Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [
//                     Colors.white,
//                     Colors.grey.shade50,
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.08),
//                     blurRadius: 32,
//                     spreadRadius: 0,
//                     offset: const Offset(0, 8),
//                   ),
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.04),
//                     blurRadius: 16,
//                     spreadRadius: 0,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//                 border: Border.all(
//                   color: Colors.grey.shade200,
//                   width: 1,
//                 ),
//               ),
//               padding: const EdgeInsets.all(32),
//               child: Form(
//                 key: widget.formKey,
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Header moderno
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.blue.shade500,
//                                 Colors.blue.shade600,
//                               ],
//                             ),
//                             borderRadius: BorderRadius.circular(16),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.blue.withOpacity(0.3),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: const Icon(
//                             Icons.restaurant_menu,
//                             color: Colors.white,
//                             size: 24,
//                           ),
//                         ),
//                         const SizedBox(width: 16),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Mesa e Comanda',
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.grey.shade800,
//                                   letterSpacing: -0.5,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Informe os dados para continuar',
//                                 style: TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.grey.shade600,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 32),

//                     // Campo Mesa com design moderno
//                     _buildModernTextField(
//                       label: AppLocalizations.of(context)!.table,
//                       controller: widget.mesaController,
//                       hintText: AppLocalizations.of(context)!.enterTableNumber,
//                       icon: Icons.table_restaurant,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return AppLocalizations.of(context)!.enterTableNumber;
//                         }
//                         return null;
//                       },
//                     ),

//                     const SizedBox(height: 24),

//                     // Campo Comanda com design moderno
//                     _buildModernTextField(
//                       label: AppLocalizations.of(context)!.order,
//                       controller: widget.comandaController,
//                       hintText: AppLocalizations.of(context)!.enterOrderNumber,
//                       icon: Icons.receipt_long,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return AppLocalizations.of(context)!
//                               .pleaseEnterOrderNumber;
//                         }
//                         return null;
//                       },
//                     ),

//                     const SizedBox(height: 40),

//                     // Botões modernos
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.end,
//                       children: [
//                         _buildModernButton(
//                           text: AppLocalizations.of(context)!.cancel,
//                           onPressed: () => Navigator.pop(context),
//                           isPrimary: false,
//                         ),
//                         const SizedBox(width: 16),
//                         _buildModernButton(
//                           text: AppLocalizations.of(context)!.confirm,
//                           onPressed: _isLoading ? null : _handleConfirm,
//                           isPrimary: true,
//                           isLoading: _isLoading,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildModernTextField({
//     required String label,
//     required TextEditingController controller,
//     required String hintText,
//     required IconData icon,
//     required String? Function(String?) validator,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: Colors.grey.shade800,
//             letterSpacing: -0.2,
//           ),
//         ),
//         const SizedBox(height: 12),
//         TextFormField(
//           controller: controller,
//           keyboardType: TextInputType.number,
//           inputFormatters: [
//             FilteringTextInputFormatter.digitsOnly,
//           ],
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: Colors.grey.shade800,
//           ),
//           decoration: InputDecoration(
//             hintText: hintText,
//             hintStyle: TextStyle(
//               color: Colors.grey.shade400,
//               fontWeight: FontWeight.w400,
//             ),
//             prefixIcon: Container(
//               margin: const EdgeInsets.all(12),
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Icon(
//                 icon,
//                 color: Colors.blue.shade600,
//                 size: 20,
//               ),
//             ),
//             border: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//                 width: 1.5,
//               ),
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(
//                 color: Colors.grey.shade300,
//                 width: 1.5,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(
//                 color: Colors.blue.shade500,
//                 width: 2,
//               ),
//             ),
//             errorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(
//                 color: Colors.red.shade400,
//                 width: 2,
//               ),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(16),
//               borderSide: BorderSide(
//                 color: Colors.red.shade400,
//                 width: 2,
//               ),
//             ),
//             filled: true,
//             fillColor: Colors.grey.shade50,
//             contentPadding: const EdgeInsets.symmetric(
//               horizontal: 20,
//               vertical: 16,
//             ),
//           ),
//           validator: validator,
//         ),
//       ],
//     );
//   }

//   Widget _buildModernButton({
//     required String text,
//     required VoidCallback? onPressed,
//     required bool isPrimary,
//     bool isLoading = false,
//   }) {
//     return SizedBox(
//       height: 48,
//       child: isPrimary
//           ? ElevatedButton(
//               onPressed: onPressed,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue.shade600,
//                 // foregroundColor: Colors.white,
//                 elevation: 0,
//                 shadowColor: Colors.transparent,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 32,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ).copyWith(
//                 backgroundColor: MaterialStateProperty.resolveWith((states) {
//                   if (states.contains(MaterialState.disabled)) {
//                     return Colors.grey.shade400;
//                   }
//                   if (states.contains(MaterialState.pressed)) {
//                     // return Colors.blue.shade700;
//                   }
//                   // return Colors.blue.shade600;
//                 }),
//               ),
//               child: isLoading
//                   ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : Text(
//                       text,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         letterSpacing: -0.2,
//                       ),
//                     ),
//             )
//           : TextButton(
//               onPressed: onPressed,
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.grey.shade600,
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//               child: Text(
//                 text,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   letterSpacing: -0.2,
//                 ),
//               ),
//             ),
//     );
//   }

//   Future<void> _handleConfirm() async {
//     if (widget.formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       final comanda = widget.comandaController.text;

//       var urlBratter = Urls.urlApiBratter;
//       final encodedUrl = Uri.encodeComponent(urlBratter);
//       final url =
//           '${Urls.urlApiAzure}Proxy/ConsultaComanda/?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}&idComanda=$comanda';

//       try {
//         final response = await http.get(
//           Uri.parse(url),
//           headers: {
//             'Content-Type': 'application/json',
//             'Accept': 'application/json',
//           },
//         );

//         setState(() {
//           _isLoading = false;
//         });

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);

//           // verifica se a comanda existe
//           if (data['Id'] != 0 && data['Status'] != null) {
//             // ✅ existe, pode prosseguir
//             Navigator.pop(context, {
//               'mesa': widget.mesaController.text,
//               'comanda': comanda,
//             });
//           } else {
//             // ❌ não existe - dispara animação de tremor
//             _triggerShakeAnimation();

//             // Vibração háptica para feedback adicional
//             HapticFeedback.heavyImpact();

//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Row(
//                   children: [
//                     Icon(
//                       Icons.error_outline,
//                       color: Colors.white,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         "Comanda não encontrada. Verifique o número e tente novamente.",
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 backgroundColor: Colors.red.shade600,
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 margin: const EdgeInsets.all(16),
//                 duration: const Duration(seconds: 4),
//               ),
//             );
//           }
//         } else {
//           // erro de comunicação - também dispara tremor
//           _triggerShakeAnimation();
//           HapticFeedback.heavyImpact();

//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   Icon(
//                     Icons.wifi_off,
//                     color: Colors.white,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       "Erro ao consultar comanda: ${response.statusCode}",
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               backgroundColor: Colors.orange.shade600,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               margin: const EdgeInsets.all(16),
//               duration: const Duration(seconds: 4),
//             ),
//           );
//         }
//       } catch (e) {
//         setState(() {
//           _isLoading = false;
//         });

//         _triggerShakeAnimation();
//         HapticFeedback.heavyImpact();

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(
//                   Icons.error_outline,
//                   color: Colors.white,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     "Erro de conexão: $e",
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             backgroundColor: Colors.red.shade600,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             margin: const EdgeInsets.all(16),
//             duration: const Duration(seconds: 4),
//           ),
//         );
//       }
//     }
//   }
// }

class PopupMesaComanda extends StatefulWidget {
  const PopupMesaComanda({
    super.key,
    required this.formKey,
    required this.mesaController,
    required this.comandaController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController mesaController;
  final TextEditingController comandaController;

  @override
  State<PopupMesaComanda> createState() => _PopupMesaComandaState();
}

class _PopupMesaComandaState extends State<PopupMesaComanda>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 1000), // Slower shake animation
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShakeAnimation() {
    _shakeController.reset();
    _shakeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400 || screenHeight < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      // Added useSafeArea: false to prevent the grey overlay
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final shakeValue = _shakeAnimation.value;
          final offset = 12.0 * (shakeValue * 4.0 * (1.0 - shakeValue));

          return Transform.translate(
            offset: Offset(offset * (shakeValue > 0.5 ? -1 : 1), 0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth * 0.9 : 500,
                maxHeight:
                    screenHeight * 0.8, // Limit height to prevent overflow
              ),
              decoration: BoxDecoration(
                color: Colors.white, // Fundo branco puro
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: isSmallScreen ? 20 : 25,
                    offset: Offset(0, isSmallScreen ? 6 : 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: isSmallScreen ? 10 : 12,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200, // borda bem clarinha
                  width: 1.2,
                ),
              ),
              padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
              child: SingleChildScrollView(
                child: Form(
                  key: widget.formKey,
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min, // Important for unbounded height
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header responsivo
                      _buildHeader(isSmallScreen),

                      SizedBox(height: isSmallScreen ? 24 : 36),

                      // Campo Mesa
                      _buildModernTextField(
                        label: AppLocalizations.of(context)!.table,
                        controller: widget.mesaController,
                        hintText:
                            AppLocalizations.of(context)!.enterTableNumber,
                        icon: Icons.table_restaurant,
                        isSmallScreen: isSmallScreen,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .enterTableNumber;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 28),

                      // Campo Comanda
                      _buildModernTextField(
                        label: AppLocalizations.of(context)!.order,
                        controller: widget.comandaController,
                        hintText:
                            AppLocalizations.of(context)!.enterOrderNumber,
                        icon: Icons.receipt_long,
                        isSmallScreen: isSmallScreen,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .pleaseEnterOrderNumber;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 32 : 48),

                      // Botões responsivos
                      _buildButtons(isSmallScreen),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment:
          isSmallScreen ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade600,
                    Colors.orange.shade800,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.orange.withOpacity(0.4),
                //     blurRadius: 12,
                //     offset: const Offset(0, 6),
                //   ),
                // ],
              ),
              child: Icon(
                Icons.restaurant_menu,
                color: Colors.white,
                size: isSmallScreen ? 24 : 28,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                AppLocalizations.of(context)!.mesaEcomanda,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.brown.shade900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
          ],
        ),
        // const SizedBox(height: 6),
        // Text(
        //   'Informe os dados para continuar',
        //   textAlign: isSmallScreen ? TextAlign.center : TextAlign.start,
        //   style: TextStyle(
        //     fontSize: isSmallScreen ? 13 : 15,
        //     color: Colors.brown.shade700,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
      ],
    );
  }

  Widget _buildModernTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isSmallScreen,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 17,
            fontWeight: FontWeight.w700,
            color: Colors.brown.shade900,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: isSmallScreen ? 10 : 14),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(
            fontSize: isSmallScreen ? 15 : 17,
            fontWeight: FontWeight.w500,
            color: Colors.brown.shade800,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.brown.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              margin: EdgeInsets.all(isSmallScreen ? 10 : 14),
              padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
              ),
              child: Icon(
                icon,
                color: Colors.orange.shade700,
                size: isSmallScreen ? 20 : 22,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              borderSide: BorderSide(
                color: Colors.orange.shade200,
                width: 1.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              borderSide: BorderSide(
                color: Colors.orange.shade200,
                width: 1.8,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              borderSide: BorderSide(
                color: Colors.orange.shade600,
                width: 2.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              borderSide: BorderSide(
                color: Colors.red.shade500,
                width: 2.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
              borderSide: BorderSide(
                color: Colors.red.shade500,
                width: 2.5,
              ),
            ),
            filled: true,
            fillColor: Colors.orange.shade50,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20 : 24,
              vertical: isSmallScreen ? 14 : 18,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildButtons(bool isSmallScreen) {
    if (isSmallScreen) {
      // Layout vertical para telas pequenas
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModernButton(
            text: AppLocalizations.of(context)!.confirm,
            onPressed: _isLoading ? null : _handleConfirm,
            isPrimary: true,
            isLoading: _isLoading,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
            isPrimary: false,
            isSmallScreen: isSmallScreen,
          ),
        ],
      );
    } else {
      // Layout horizontal para telas maiores
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildModernButton(
            text: AppLocalizations.of(context)!.cancel,
            onPressed: () => Navigator.pop(context),
            isPrimary: false,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(width: 20),
          _buildModernButton(
            text: AppLocalizations.of(context)!.confirm,
            onPressed: _isLoading ? null : _handleConfirm,
            isPrimary: true,
            isLoading: _isLoading,
            isSmallScreen: isSmallScreen,
          ),
        ],
      );
    }
  }

  Widget _buildModernButton({
    required String text,
    required VoidCallback? onPressed,
    required bool isPrimary,
    required bool isSmallScreen,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: isSmallScreen ? 48 : 52,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 28 : 36,
                  vertical: isSmallScreen ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                ),
              ).copyWith(
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.disabled)) {
                    return Colors.orange.shade200;
                  }
                  if (states.contains(MaterialState.pressed)) {
                    return Colors.orange.shade900;
                  }
                  return Colors.orange.shade700;
                }),
              ),
              child: isLoading
                  ? SizedBox(
                      width: isSmallScreen ? 20 : 24,
                      height: isSmallScreen ? 20 : 24,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
            )
          : TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.brown.shade700,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 28,
                  vertical: isSmallScreen ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: isSmallScreen ? 15 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
    );
  }

  Future<void> _handleConfirm() async {
    if (widget.formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final comanda = widget.comandaController.text;

      var urlBratter = Urls.urlApiBratter;
      final encodedUrl = Uri.encodeComponent(urlBratter);
      final url =
          '${Urls.urlApiAzure}Proxy/ConsultaComanda/?urlBratter=$encodedUrl&tokenBratter=${GlobalKeys.tokenBratter}&idComanda=$comanda';

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['Id'] != 0 && data['Status'] != null) {
            Navigator.pop(context, {
              'mesa': widget.mesaController.text,
              'comanda': comanda,
            });
          } else {
            _triggerShakeAnimation();
            HapticFeedback.heavyImpact();

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Comanda não encontrada. Verifique o número e tente novamente.",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          _triggerShakeAnimation();
          HapticFeedback.heavyImpact();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.wifi_off,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Erro ao consultar comanda: ${response.statusCode}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        _triggerShakeAnimation();
        HapticFeedback.heavyImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Erro de conexão: $e",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
