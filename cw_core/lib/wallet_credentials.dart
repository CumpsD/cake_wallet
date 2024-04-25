import 'package:cw_core/wallet_info.dart';

abstract class WalletCredentials {
  WalletCredentials({
    required this.name,
    this.height,
    this.seedPhraseLength,
    this.walletInfo,
    this.password,
    this.derivationInfo,
  }) {
    if (this.walletInfo != null && derivationInfo != null) {
      this.walletInfo!.derivationInfo = derivationInfo;
    }
  }

  final String name;
  final int? height;
  int? seedPhraseLength;
  String? password;
  WalletInfo? walletInfo;
  DerivationInfo? derivationInfo;
}
