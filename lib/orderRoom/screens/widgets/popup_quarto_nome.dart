import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';

import 'package:webapp_pedido_mesa/core/constants.dart';

class PopupQuartoNome extends StatefulWidget {
  const PopupQuartoNome({
    super.key,
    required this.formKey,
    required this.quartoController,
    required this.nomeController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController quartoController;
  final TextEditingController nomeController;

  @override
  State<PopupQuartoNome> createState() => _PopupQuartoNomeState();
}

class _PopupQuartoNomeState extends State<PopupQuartoNome>
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
                        label: AppLocalizations.of(context)!.quarto,
                        controller: widget.quartoController,
                        hintText:
                            AppLocalizations.of(context)!.enterQuartoNumber,
                        icon: Icons.table_restaurant,
                        isSmallScreen: isSmallScreen,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!
                                .enterQuartoNumber;
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 28),

                      // Campo Nome
                      _buildModernTextField(
                        label: AppLocalizations.of(context)!.nome,
                        controller: widget.nomeController,
                        hintText: AppLocalizations.of(context)!.enterNome,
                        icon: Icons.receipt_long,
                        isSmallScreen: isSmallScreen,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.enterNome;
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
                AppLocalizations.of(context)!.quartoEnome,
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final isNumber =
        keyboardType == null || keyboardType == TextInputType.number;
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
          keyboardType: keyboardType ?? TextInputType.number,
          inputFormatters: inputFormatters ??
              (isNumber ? [FilteringTextInputFormatter.digitsOnly] : null),
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
          // _buildModernButton(
          //   text: AppLocalizations.of(context)!.cancel,
          //   onPressed: () => Navigator.pop(context),
          //   isPrimary: false,
          //   isSmallScreen: isSmallScreen,
          // ),
        ],
      );
    } else {
      // Layout horizontal para telas maiores
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // _buildModernButton(
          //   text: AppLocalizations.of(context)!.cancel,
          //   onPressed: () => Navigator.pop(context),
          //   isPrimary: false,
          //   isSmallScreen: isSmallScreen,
          // ),
          // const SizedBox(width: 20),
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

      final nome = widget.nomeController.text;

      Navigator.pop(context, {
        'quarto': widget.quartoController.text,
        'nome': nome,
      });
    }
  }
}
