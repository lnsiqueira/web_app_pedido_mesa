import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt')
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @tapToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap to start'**
  String get tapToStart;

  /// No description provided for @scan.
  ///
  /// In en, this message translates to:
  /// **'Scan the product on the reader'**
  String get scan;

  /// No description provided for @weighDish.
  ///
  /// In en, this message translates to:
  /// **'Do you want to weigh your dish?'**
  String get weighDish;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @readProdcut.
  ///
  /// In en, this message translates to:
  /// **'Read the product in the\nreader below'**
  String get readProdcut;

  /// No description provided for @readQRCode.
  ///
  /// In en, this message translates to:
  /// **'Read your QR Code'**
  String get readQRCode;

  /// No description provided for @yourCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart'**
  String get yourCart;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty,'**
  String get cartEmpty;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'add some item!'**
  String get addItem;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @finalizarText.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finalizarText;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention!'**
  String get attention;

  /// No description provided for @addSomething.
  ///
  /// In en, this message translates to:
  /// **'Please add something to your cart before proceeding.'**
  String get addSomething;

  /// No description provided for @invalidCPF.
  ///
  /// In en, this message translates to:
  /// **'Invalid CPF.'**
  String get invalidCPF;

  /// No description provided for @addDish.
  ///
  /// In en, this message translates to:
  /// **'Add new dish'**
  String get addDish;

  /// No description provided for @weigh.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT (KG)'**
  String get weigh;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'PRICE/KG'**
  String get price;

  /// No description provided for @orderCancel.
  ///
  /// In en, this message translates to:
  /// **'Your order will be canceled'**
  String get orderCancel;

  /// No description provided for @inText.
  ///
  /// In en, this message translates to:
  /// **'in'**
  String get inText;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'seconds'**
  String get seconds;

  /// No description provided for @inactivity.
  ///
  /// In en, this message translates to:
  /// **' due to inactivity.'**
  String get inactivity;

  /// No description provided for @wantContinue.
  ///
  /// In en, this message translates to:
  /// **'Do you want to continue with the order?'**
  String get wantContinue;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @continueOrder.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueOrder;

  /// No description provided for @wantCPF.
  ///
  /// In en, this message translates to:
  /// **'Do you want to enter your CPF?'**
  String get wantCPF;

  /// No description provided for @providingCPF.
  ///
  /// In en, this message translates to:
  /// **'By providing your CPF, you\'ll accumulate points and we\'ll be able \nto make exclusive offers for you!'**
  String get providingCPF;

  /// No description provided for @benefitsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'These benefits can be used with our upcoming app!'**
  String get benefitsUpcoming;

  /// No description provided for @dontWant.
  ///
  /// In en, this message translates to:
  /// **'I don\'t want to inform'**
  String get dontWant;

  /// No description provided for @wantpay.
  ///
  /// In en, this message translates to:
  /// **'How do you want to pay for your purchase?'**
  String get wantpay;

  /// No description provided for @invoiceCPF.
  ///
  /// In en, this message translates to:
  /// **'Do you want your CPF on the invoice?'**
  String get invoiceCPF;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @pesando.
  ///
  /// In en, this message translates to:
  /// **'Weighing...'**
  String get pesando;

  /// No description provided for @processingRequest.
  ///
  /// In en, this message translates to:
  /// **'We are processing your request.'**
  String get processingRequest;

  /// No description provided for @wantPrintInvoice.
  ///
  /// In en, this message translates to:
  /// **'Do you want to print an invoice?'**
  String get wantPrintInvoice;

  /// No description provided for @returnHome.
  ///
  /// In en, this message translates to:
  /// **'Returning to home due to inactivity'**
  String get returnHome;

  /// No description provided for @cancelingIn.
  ///
  /// In en, this message translates to:
  /// **'Canceling in'**
  String get cancelingIn;

  /// No description provided for @continuePage.
  ///
  /// In en, this message translates to:
  /// **'Continue on page'**
  String get continuePage;

  /// No description provided for @placeYourOrder.
  ///
  /// In en, this message translates to:
  /// **'place your order'**
  String get placeYourOrder;

  /// No description provided for @pleaseEnterOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter the order number'**
  String get pleaseEnterOrderNumber;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @enterTableNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter the table number'**
  String get enterTableNumber;

  /// No description provided for @table.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get table;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get myOrders;

  /// No description provided for @mesaEcomanda.
  ///
  /// In en, this message translates to:
  /// **'Table and Order'**
  String get mesaEcomanda;

  /// No description provided for @enterOrderNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter the order number'**
  String get enterOrderNumber;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @quartoEnome.
  ///
  /// In en, this message translates to:
  /// **'Quarto e Nome'**
  String get quartoEnome;

  /// No description provided for @quarto.
  ///
  /// In en, this message translates to:
  /// **'Quarto'**
  String get quarto;

  /// No description provided for @nome.
  ///
  /// In en, this message translates to:
  /// **'Nome'**
  String get nome;

  /// No description provided for @enterQuartoNumber.
  ///
  /// In en, this message translates to:
  /// **'Informe o número do quarto'**
  String get enterQuartoNumber;

  /// No description provided for @enterNome.
  ///
  /// In en, this message translates to:
  /// **'Informe o seu do nome'**
  String get enterNome;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
