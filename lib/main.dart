import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/firebase_options.dart';
import 'package:webapp_pedido_mesa/screens/splash/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await tokenApiBratter();

  runApp(const MyApp());
}

Future<void> tokenApiBratter() async {
  var urlBratter = Urls.urlApiBratter + "/User";
  String username = GlobalKeys.userApiBratter;
  String password = GlobalKeys.passwordApiBratter;

  final encodedUrl = Uri.encodeComponent(urlBratter);

  var url =
      '${Urls.urlApiAzure}Proxy/token?username=${username}&password=${password}&urlBratter=${encodedUrl}';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final token = data['token'];
      GlobalKeys.tokenBratter = token;

      print('Token: $token');
    } else {
      print('Erro ao carregar categorias: ${response.statusCode}');
    }
  } catch (e) {
    print('Erro: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarrinhoModel()),

        ChangeNotifierProvider(create: (_) => MesaComandaModel()),
        ChangeNotifierProvider(
          create: (context) => LanguageController(),
          builder: (context, child) {
            final languageController = Provider.of<LanguageController>(context);

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Dona Deola',
              theme: ThemeData(
                textTheme: GoogleFonts.nunitoTextTheme(), // Fonte padrão global

                colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
              ),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [
                Locale('en'), // English
                Locale('es'), // Spanish
                Locale('pt'), // Portuguese
              ],
              locale: languageController.locale,

              home: SplashScreen(),
            );
          },
        ),
      ],
    );
  }
}
