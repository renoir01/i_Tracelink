import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.arb');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Quick access getters
  String get appName => translate('appName');
  String get appTagline => translate('appTagline');
  String get welcome => translate('welcome');
  String get welcomeBack => translate('welcomeBack');
  String get welcomeSubtitle => translate('welcomeSubtitle');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get pleaseEnterEmail => translate('pleaseEnterEmail');
  String get pleaseEnterValidEmail => translate('pleaseEnterValidEmail');
  String get pleaseEnterPassword => translate('pleaseEnterPassword');
  String get passwordTooShort => translate('passwordTooShort');
  String get login => translate('login');
  String get register => translate('register');
  String get logout => translate('logout');
  String get dashboard => translate('dashboard');
  String get selectLanguage => translate('selectLanguage');
  String get english => translate('english');
  String get kinyarwanda => translate('kinyarwanda');
  String get selectUserType => translate('selectUserType');
  String get seedProducer => translate('seedProducer');
  String get agroDealer => translate('agroDealer');
  String get farmerCooperative => translate('farmerCooperative');
  String get aggregator => translate('aggregator');
  String get institution => translate('institution');
  String get seedProducerDesc => translate('seedProducerDesc');
  String get agroDealerDesc => translate('agroDealerDesc');
  String get farmerCooperativeDesc => translate('farmerCooperativeDesc');
  String get aggregatorDesc => translate('aggregatorDesc');
  String get institutionDesc => translate('institutionDesc');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get forgotPassword => translate('forgotPassword');
  String get phoneNumber => translate('phoneNumber');
  String get submit => translate('submit');
  String get cancel => translate('cancel');
  String get notifications => translate('notifications');
  String get profile => translate('profile');
  String get help => translate('help');
  String get settings => translate('settings');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'rw'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
