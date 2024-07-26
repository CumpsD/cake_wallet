import 'dart:convert';

import 'package:cake_wallet/.secrets.g.dart' as secrets;
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_quote.dart';
import 'package:cake_wallet/buy/payment_method.dart';
import 'package:cake_wallet/entities/provider_types.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/utils/device_info.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MeldBuyProvider extends BuyProvider {
  MeldBuyProvider({required WalletBase wallet, bool isTestEnvironment = false})
      : super(wallet: wallet, isTestEnvironment: isTestEnvironment, ledgerVM: null);

  static const _isProduction = false;

  static const _baseUrl = _isProduction ? 'api.meld.io' : 'api-sb.meld.io';
  static const _providersProperties = '/service-providers/properties';
  static const _paymentMethodsPath = '/payment-methods';
  static const _quotePath = '/payments/crypto/quote';

  static const String sandboxUrl = 'sb.fluidmoney.xyz';
  static const String productionUrl = 'fluidmoney.xyz';

  static const String _baseWidgetUrl = _isProduction ? productionUrl : sandboxUrl;

  static String get _testApiKey => secrets.meldTestApiKey;

  static String get _testPublicKey => secrets.meldTestPublicKey;

  @override
  String get title => 'Meld';

  @override
  String get providerDescription => 'Meld Buy Provider Description';

  @override
  String get lightIcon => 'assets/images/meld_logo.svg';

  @override
  String get darkIcon => 'assets/images/meld_logo.svg';

  @override
  bool get isAggregator => true;

  @override
  Future<List<PaymentMethod>> getAvailablePaymentTypes(
      String fiatCurrency, String cryptoCurrency, bool isBuyAction) async {
    final params = {'fiatCurrencies': fiatCurrency, 'statuses': 'LIVE,RECENTLY_ADDED,BUILDING'};

    final path = '$_providersProperties$_paymentMethodsPath';
    final url = Uri.https(_baseUrl, path, params);

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': _isProduction ? '' : _testApiKey,
          'Meld-Version': '2023-12-19',
          'accept': 'application/json',
          'content-type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final paymentMethods =
            data.map((e) => PaymentMethod.fromMeldJson(e as Map<String, dynamic>)).toList();
        return paymentMethods;
      } else {
        print('Meld: Failed to fetch payment types');
        return List<PaymentMethod>.empty();
      }
    } catch (e) {
      print('Meld: Failed to fetch payment types: $e');
      return List<PaymentMethod>.empty();
    }
  }

  Future<Quote?> fetchQuote({
    required String sourceCurrency,
    required String destinationCurrency,
    required double amount,
    required PaymentType paymentType,
    required bool isBuyAction,
    required String walletAddress,
    String? countryCode = 'US',
  }) async {
    var paymentMethod = normalizePaymentMethod(paymentType);
    if (paymentMethod == null) paymentMethod = paymentType.name;

    log('Meld: Fetching buy quote: $sourceCurrency -> $destinationCurrency, amount: $amount, paymentMethod: $paymentMethod');

    final url = Uri.https(_baseUrl, _quotePath);
    final headers = {
      'Authorization': _testApiKey,
      'Meld-Version': '2023-12-19',
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    final body = jsonEncode({
      'countryCode': countryCode,
      'destinationCurrencyCode': destinationCurrency,
      'sourceAmount': amount,
      'sourceCurrencyCode': sourceCurrency,
      'paymentMethodType': paymentMethod,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final quote = Quote.fromMeldJson(data, ProviderType.meld, isBuyAction);

        quote.setSourceCurrency = sourceCurrency;
        quote.setDestinationCurrency = destinationCurrency;

        return quote;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching buy quote: $e');
      return null;
    }
  }

  Future<void>? launchTrade(
      {required BuildContext context,
      required Quote quote,
      required PaymentMethod paymentMethod,
      required double amount,
      required bool isBuyAction,
      required String cryptoCurrencyAddress,
      String? countryCode}) async {
    final actionType = isBuyAction ? 'BUY' : 'SELL';

    final params = {
      'publicKey': _isProduction ? '' : _testPublicKey,
      'countryCode': countryCode,
      'paymentMethodType': normalizePaymentMethod(paymentMethod.paymentMethodType),
      'sourceAmount': amount.toString(),
      'sourceCurrencyCode': quote.sourceCurrency,
      'destinationCurrencyCode': quote.destinationCurrency,
      'walletAddress': cryptoCurrencyAddress,
      'transactionType': actionType
    };

    final uri = Uri.https(_baseWidgetUrl, '', params);

    try {
      if (await canLaunchUrl(uri)) {
        if (DeviceInfo.instance.isMobile) {
          Navigator.of(context).pushNamed(Routes.webViewPage, arguments: [title, uri]);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      await showPopUp<void>(
          context: context,
          builder: (BuildContext context) {
            return AlertWithOneAction(
                alertTitle: "Meld",
                alertContent: S.of(context).buy_provider_unavailable + ': $e',
                buttonText: S.of(context).ok,
                buttonAction: () => Navigator.of(context).pop());
          });
    }
  }

  String? normalizePaymentMethod(PaymentType paymentType) {
    switch (paymentType) {
      case PaymentType.creditCard:
        return 'CREDIT_DEBIT_CARD';
      case PaymentType.applePay:
        return 'APPLE_PAY';
      case PaymentType.googlePay:
        return 'GOOGLE_PAY';
      case PaymentType.neteller:
        return 'NETELLER';
      case PaymentType.skrill:
        return 'SKRILL';
      case PaymentType.sepa:
        return 'SEPA';
      case PaymentType.sepaInstant:
        return 'SEPA_INSTANT';
      case PaymentType.ach:
        return 'ACH';
      case PaymentType.achInstant:
        return 'INSTANT_ACH';
      case PaymentType.Khipu:
        return 'KHIPU';
      case PaymentType.ovo:
        return 'OVO';
      case PaymentType.zaloPay:
        return 'ZALOPAY';
      case PaymentType.zaloBankTransfer:
        return 'ZA_BANK_TRANSFER';
      case PaymentType.gcash:
        return 'GCASH';
      case PaymentType.imps:
        return 'IMPS';
      case PaymentType.dana:
        return 'DANA';
      case PaymentType.ideal:
        return 'IDEAL';
      default:
        return null;
    }
  }

  @override
  Future<void> launchProvider(BuildContext context, bool? isBuyAction) {
    // TODO: implement launchProvider
    throw UnimplementedError();
  }
}