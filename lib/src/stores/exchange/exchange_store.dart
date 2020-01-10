import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/src/domain/common/crypto_currency.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/changenow/changenow_request.dart';
import 'package:cake_wallet/src/domain/exchange/exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_exchange_provider.dart';
import 'package:cake_wallet/src/domain/exchange/xmrto/xmrto_trade_request.dart';
import 'package:cake_wallet/src/domain/exchange/trade.dart';
import 'package:cake_wallet/src/stores/wallet/wallet_store.dart';
import 'package:cake_wallet/src/stores/exchange/exchange_trade_state.dart';
import 'package:cake_wallet/src/stores/exchange/limits_state.dart';
import 'package:cake_wallet/generated/i18n.dart';

part 'exchange_store.g.dart';

class ExchangeStore = ExchangeStoreBase with _$ExchangeStore;

abstract class ExchangeStoreBase with Store {
  ExchangeStoreBase(
      {@required ExchangeProvider initialProvider,
      @required CryptoCurrency initialDepositCurrency,
      @required CryptoCurrency initialReceiveCurrency,
      @required this.providerList,
      @required this.trades,
      @required this.walletStore}) {
    provider = initialProvider;
    depositCurrency = initialDepositCurrency;
    receiveCurrency = initialReceiveCurrency;
    limitsState = LimitsInitialState();
    tradeState = ExchangeTradeStateInitial();
    loadLimits();
  }

  @observable
  ExchangeProvider provider;

  @observable
  List<ExchangeProvider> providerList;

  @observable
  CryptoCurrency depositCurrency;

  @observable
  CryptoCurrency receiveCurrency;

  @observable
  LimitsState limitsState;

  @observable
  ExchangeTradeState tradeState;

  @observable
  String depositAmount;

  @observable
  String receiveAmount;

  @observable
  bool isValid;

  @observable
  String errorMessage;

  Box<Trade> trades;

  String depositAddress;

  String receiveAddress;

  WalletStore walletStore;

  @action
  void changeProvider({ExchangeProvider provider}) {
    this.provider = provider;
    depositAmount = '';
    receiveAmount = '';
  }

  @action
  void changeDepositCurrency({CryptoCurrency currency}) {
    depositCurrency = currency;
    _onPairChange();
  }

  @action
  void changeReceiveCurrency({CryptoCurrency currency}) {
    receiveCurrency = currency;
    _onPairChange();
  }

  @action
  void changeReceiveAmount({String amount}) {
    receiveAmount = amount;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      return;
    }

    final _amount = double.parse(amount) ?? 0;

    provider
        .calculateAmount(
            from: depositCurrency, to: receiveCurrency, amount: _amount)
        .then((amount) => amount.toString())
        .then((amount) => depositAmount = amount);
  }

  @action
  void changeDepositAmount({String amount}) {
    depositAmount = amount;

    if (amount == null || amount.isEmpty) {
      depositAmount = '';
      return;
    }

    final _amount = double.parse(amount);
    provider
        .calculateAmount(
            from: depositCurrency, to: receiveCurrency, amount: _amount)
        .then((amount) => amount.toString())
        .then((amount) => receiveAmount = amount);
  }

  @action
  Future loadLimits() async {
    limitsState = LimitsIsLoading();

    try {
      final limits = await provider.fetchLimits(
          from: depositCurrency, to: receiveCurrency);
      limitsState = LimitsLoadedSuccessfully(limits: limits);
    } catch (e) {
      limitsState = LimitsLoadedFailure(error: e.toString());
    }
  }

  @action
  Future createTrade() async {
    TradeRequest request;

    if (provider is XMRTOExchangeProvider) {
      request = XMRTOTradeRequest(
          to: receiveCurrency,
          from: depositCurrency,
          amount: receiveAmount,
          address: receiveAddress,
          refundAddress: depositAddress);
    }

    if (provider is ChangeNowExchangeProvider) {
      request = ChangeNowRequest(
          from: depositCurrency,
          to: receiveCurrency,
          amount: depositAmount,
          refundAddress: depositAddress,
          address: receiveAddress);
    }

    try {
      tradeState = TradeIsCreating();
      final trade = await provider.createTrade(request: request);
      trade.walletId = walletStore.id;
      await trades.add(trade);
      tradeState = TradeIsCreatedSuccessfully(trade: trade);
    } catch (e) {
      tradeState = TradeIsCreatedFailure(error: e.toString());
    }
  }

  @action
  void reset() {
    depositAmount = '';
    receiveAmount = '';
    depositAddress = '';
    receiveAddress = '';
    provider = XMRTOExchangeProvider();
    depositCurrency = CryptoCurrency.xmr;
    receiveCurrency = CryptoCurrency.btc;
  }

  List<ExchangeProvider> providersForCurrentPair() {
    return _providersForPair(from: depositCurrency, to: receiveCurrency);
  }

  List<ExchangeProvider> _providersForPair(
      {CryptoCurrency from, CryptoCurrency to}) {
    final providers = providerList
        .where((provider) => provider.pairList
            .where((pair) =>
                pair.from == depositCurrency && pair.to == receiveCurrency)
            .isNotEmpty)
        .toList();

    return providers;
  }

  void _onPairChange() {
    final isPairExist = provider.pairList
        .where((pair) =>
            pair.from == depositCurrency && pair.to == receiveCurrency)
        .isNotEmpty;

    if (!isPairExist) {
      final provider =
          _providerForPair(from: depositCurrency, to: receiveCurrency);

      if (provider != null) {
        changeProvider(provider: provider);
      }
    }

    depositAmount = '';
    receiveAmount = '';

    loadLimits();
  }

  ExchangeProvider _providerForPair({CryptoCurrency from, CryptoCurrency to}) {
    final providers = _providersForPair(from: from, to: to);
    return providers.isNotEmpty ? providers[0] : null;
  }

  void validateAddress(String value, {CryptoCurrency cryptoCurrency}) {
    // XMR (95), ADA (105), BCH (42), BNB (42), BTC (34, 42), DASH (34), EOS (42),
    // ETH (42), LTC (34), NANO (64, 65), TRX (34), USDT (42), XLM (56), XRP (34)
    const pattern = '^[0-9a-zA-Z]{95}\$|^[0-9a-zA-Z]{34}\$|^[0-9a-zA-Z]{42}\$|^[0-9a-zA-Z]{56}\$|^[0-9a-zA-Z]{64}\$|^[0-9a-zA-Z]{65}\$|^[0-9a-zA-Z]{105}\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    if (isValid && cryptoCurrency != null) {
      switch (cryptoCurrency) {
        case CryptoCurrency.xmr:
          isValid = (value.length == 95);
          break;
        case CryptoCurrency.ada:
          isValid = (value.length == 105);
          break;
        case CryptoCurrency.bch:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.bnb:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.btc:
          isValid = (value.length == 34)||(value.length == 42);
          break;
        case CryptoCurrency.dash:
          isValid = (value.length == 34);
          break;
        case CryptoCurrency.eos:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.eth:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.ltc:
          isValid = (value.length == 34);
          break;
        case CryptoCurrency.nano:
          isValid = (value.length == 64)||(value.length == 65);
          break;
        case CryptoCurrency.trx:
          isValid = (value.length == 34);
          break;
        case CryptoCurrency.usdt:
          isValid = (value.length == 42);
          break;
        case CryptoCurrency.xlm:
          isValid = (value.length == 56);
          break;
        case CryptoCurrency.xrp:
          isValid = (value.length == 34);
          break;
      }
    }

    errorMessage = isValid ? null : S.current.error_text_address;
  }

  void validateCryptoCurrency(String value) {
    const pattern = '^([0-9]+([.][0-9]{0,12})?|[.][0-9]{1,12})\$';
    final regExp = RegExp(pattern);
    isValid = regExp.hasMatch(value);
    errorMessage = isValid ? null : S.current.error_text_crypto_currency;
  }
}
