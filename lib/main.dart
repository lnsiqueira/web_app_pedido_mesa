import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webapp_pedido_mesa/admin/screens/home/admin_home_page.dart';
import 'package:webapp_pedido_mesa/core/constants.dart';
import 'package:webapp_pedido_mesa/core/controllers/language_controller.dart';
import 'package:webapp_pedido_mesa/core/model/carrinho_model.dart';
import 'package:webapp_pedido_mesa/core/model/mesa_comanda_model.dart';
import 'package:webapp_pedido_mesa/core/model/quarto_nome_model.dart';
import 'package:webapp_pedido_mesa/core/provider/produtos_cache_provider.dart';
import 'package:webapp_pedido_mesa/firebase_options.dart';
import 'package:webapp_pedido_mesa/l10n/app_localizations.dart';
import 'package:webapp_pedido_mesa/orderRoom/screens/home/order_home_page.dart';
import 'package:webapp_pedido_mesa/screens/splash/splash_screen.dart';
import 'package:http/http.dart' as http;
import 'package:webapp_pedido_mesa/services/nfce/model/filial_nf_model.dart';
import 'package:webapp_pedido_mesa/services/storage/carrinho_storage.dart';

//-- /?admin
//-- /?filialId=123
//--?filialId=cOfPgf6ajwzfBaRJ7xMS
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance(); // força a inicialização

  GestureBinding.instance.resamplingEnabled = false;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await tokenApiBratter();
  globalFilialData = await getFilial();

  CarrinhoStorage.limparCarrinho();

  final params = Uri.base.queryParameters;

  if (params.containsKey('filialId')) {
    codFilial = params['filialId']!;
    if (codFilial.isEmpty || codFilial == '0') {
      ErrorApp(
        message: 'Parâmetros Numero do Apartamenro é obrigatórios na URL',
      );
      return;
    }
    runApp(const MyOrderRoom());
    return;
  } else if (params.containsKey('admin')) {
    runApp(const MyAdmin());
    return;
  } else {
    runApp(const MyApp());
  }
  try {
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(message: 'Erro ao carregar configurações: $e'));
  }

  ///runApp(const MyApp());
}

class MyAdmin extends StatelessWidget {
  const MyAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarrinhoModel()),
        ChangeNotifierProvider(create: (_) => ProdutosCacheProvider()),
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
              home: AdminHomePage(),
            );
          },
        ),
      ],
    );
  }
}

class MyOrderRoom extends StatelessWidget {
  const MyOrderRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarrinhoModel()),
        ChangeNotifierProvider(create: (_) => ProdutosCacheProvider()),
        ChangeNotifierProvider(create: (_) => QuartoNomeModel()),
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
              home: OrderHomePage(),
            );
          },
        ),
      ],
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;

  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      ),
    );
  }
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

Future<FilialNFModel?> getFilial() async {
  //final url = Uri.parse('${Urls.urlApiBratter}filial');
  try {
    var urlBratter = Urls.urlApiBratter;
    final encodedUrl = Uri.encodeComponent(urlBratter);

    final url =
        '${Urls.urlApiAzure}Proxy/filial?urlBratter=${encodedUrl}&tokenBratter=${GlobalKeys.tokenBratter}';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      return FilialNFModel.fromJson(data);
    } else {
      print('Erro ao buscar dados da filial: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Erro ao obter informações da filial: $e');
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarrinhoModel()),
        ChangeNotifierProvider(create: (_) => ProdutosCacheProvider()),
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
