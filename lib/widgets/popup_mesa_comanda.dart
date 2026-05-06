import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';

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
      duration: const Duration(milliseconds: 1000),
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
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final shakeValue = _shakeAnimation.value;
          final offset = 12.0 * (shakeValue * 4.0 * (1.0 - shakeValue));

          return Transform.translate(
            offset: Offset(offset * (shakeValue > 0.5 ? -1 : 1), 0),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth * 0.95 : 500,
                // Limita a altura máxima mas sem definir altura fixa
                maxHeight: screenHeight * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  color: Colors.grey.shade200,
                  width: 1.2,
                ),
              ),
              // Column raiz: header + conteúdo scrollável + botão fixo
              child: Form(
                key: widget.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header (sempre visível, não scrolla) ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 20 : 28,
                        isSmallScreen ? 20 : 28,
                        isSmallScreen ? 20 : 28,
                        0,
                      ),
                      child: _buildHeader(isSmallScreen),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // ── Display + teclado (scrollável se necessário) ──
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 20 : 28,
                        ),
                        child: _buildComandaInput(isSmallScreen),
                      ),
                    ),

                    // ── Botão SEMPRE visível, fora do scroll ──
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        isSmallScreen ? 20 : 28,
                        isSmallScreen ? 12 : 16,
                        isSmallScreen ? 20 : 28,
                        isSmallScreen ? 20 : 28,
                      ),
                      child: _buildConfirmButton(isSmallScreen),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 9 : 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade600,
                Colors.orange.shade800,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: Colors.white,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            AppLocalizations.of(context)!.mesaEcomanda,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.brown.shade900,
              letterSpacing: -0.8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComandaInput(bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final isVerySmall = screenWidth <= 350;
    final isCompactHeight = screenHeight <= 680;

    // Fonte do display menor em telas compactas
    final displayFont = isVerySmall
        ? 22.0
        : isCompactHeight
            ? 26.0
            : 32.0;

    // Aspect ratio do teclado — mais "achatado" em telas pequenas
    final keyboardAspect = isVerySmall
        ? 1.3
        : isCompactHeight
            ? 1.4
            : 1.25;

    final keyboardSpacing = isVerySmall ? 6.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // DISPLAY
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isVerySmall ? 12 : 18,
            vertical: isVerySmall ? 12 : 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade50,
                Colors.orange.shade100.withOpacity(0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(isVerySmall ? 16 : 20),
            border: Border.all(
              color: Colors.orange.shade200,
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.comandaController.text.isEmpty
                  ? 'Digite a comanda'
                  : widget.comandaController.text,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: displayFont,
                fontWeight: FontWeight.w800,
                color: widget.comandaController.text.isEmpty
                    ? Colors.orange.shade300
                    : Colors.brown.shade900,
                letterSpacing: widget.comandaController.text.length > 6 ? 1 : 2,
              ),
            ),
          ),
        ),

        SizedBox(height: isVerySmall ? 10 : 16),

        // TECLADO
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 12,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: keyboardSpacing,
            crossAxisSpacing: keyboardSpacing,
            childAspectRatio: keyboardAspect,
          ),
          itemBuilder: (context, index) {
            if (index < 9) {
              final number = '${index + 1}';
              return _buildKeyboardButton(
                text: number,
                isVerySmall: isVerySmall,
                onTap: () {
                  setState(() {
                    widget.comandaController.text += number;
                  });
                },
              );
            }
            if (index == 9) {
              return _buildKeyboardButton(
                icon: Icons.backspace_rounded,
                isVerySmall: isVerySmall,
                onTap: () {
                  if (widget.comandaController.text.isNotEmpty) {
                    setState(() {
                      widget.comandaController.text =
                          widget.comandaController.text.substring(
                        0,
                        widget.comandaController.text.length - 1,
                      );
                    });
                  }
                },
              );
            }
            if (index == 10) {
              return _buildKeyboardButton(
                text: '0',
                isVerySmall: isVerySmall,
                onTap: () {
                  setState(() {
                    widget.comandaController.text += '0';
                  });
                },
              );
            }
            return _buildKeyboardButton(
              icon: Icons.clear_rounded,
              isVerySmall: isVerySmall,
              onTap: () {
                setState(() {
                  widget.comandaController.clear();
                });
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildKeyboardButton({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
    bool isVerySmall = false,
  }) {
    final fontSize = isVerySmall ? 20.0 : 26.0;
    final iconSize = isVerySmall ? 20.0 : 26.0;
    final radius = isVerySmall ? 14.0 : 18.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
            border: Border.all(color: Colors.orange.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: text != null
                ? FittedBox(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.brown.shade900,
                      ),
                    ),
                  )
                : Icon(
                    icon,
                    size: iconSize,
                    color: Colors.brown.shade900,
                  ),
          ),
        ),
      ),
    );
  }

  /// Botão de confirmação — sempre visível, fora do scroll
  Widget _buildConfirmButton(bool isSmallScreen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
        gradient: _isLoading
            ? LinearGradient(
                colors: [Colors.orange.shade300, Colors.orange.shade400],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.shade500,
                  Colors.orange.shade700,
                  Colors.deepOrange.shade700,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
        boxShadow: _isLoading
            ? []
            : [
                BoxShadow(
                  color: Colors.orange.shade400.withOpacity(0.55),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.deepOrange.shade300.withOpacity(0.25),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 18),
          splashColor: Colors.white.withOpacity(0.15),
          highlightColor: Colors.black.withOpacity(0.08),
          onTap: _isLoading ? null : _handleConfirm,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 14 : 16,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isLoading
                  ? Row(
                      key: const ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: isSmallScreen ? 17 : 20,
                          height: isSmallScreen ? 17 : 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Aguarde...',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('confirm'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 19 : 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppLocalizations.of(context)!.confirm,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
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
          debugPrint('STATUS CODE: ${response.statusCode}');
          debugPrint('BODY: ${response.body}');
          debugPrint('DATA: $data');

          if (data['Id'] != 0 && data['Status'] != null) {
            numeroComanda = comanda ?? '4500';
            Navigator.pop(context, {
              'comanda': comanda,
            });
          } else {
            _triggerShakeAnimation();
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Comanda não encontrada. Verifique o número e tente novamente.",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Erro ao consultar comanda: ${response.statusCode}",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
