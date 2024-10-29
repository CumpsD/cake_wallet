import 'dart:convert';

import 'package:bitcoin_base/bitcoin_base.dart';

abstract class BaseBitcoinAddressRecord {
  BaseBitcoinAddressRecord(
    this.address, {
    required this.index,
    this.isChange = false,
    int txCount = 0,
    int balance = 0,
    String name = '',
    bool isUsed = false,
    required this.type,
    bool? isHidden,
  })  : _txCount = txCount,
        _balance = balance,
        _name = name,
        _isUsed = isUsed,
        _isHidden = isHidden ?? isChange;

  @override
  bool operator ==(Object o) => o is BaseBitcoinAddressRecord && address == o.address;

  final String address;
  final bool _isHidden;
  bool get isHidden => _isHidden;
  bool isChange;
  final int index;
  int _txCount;
  int _balance;
  String _name;
  bool _isUsed;

  int get txCount => _txCount;

  String get name => _name;

  int get balance => _balance;

  set txCount(int value) => _txCount = value;

  set balance(int value) => _balance = value;

  bool get isUsed => _isUsed;

  void setAsUsed() => _isUsed = true;
  void setNewName(String label) => _name = label;

  int get hashCode => address.hashCode;

  BitcoinAddressType type;

  String toJSON();
}

class BitcoinAddressRecord extends BaseBitcoinAddressRecord {
  BitcoinAddressRecord(
    super.address, {
    required super.index,
    super.isHidden,
    super.isChange = false,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required super.type,
    String? scriptHash,
    BasedUtxoNetwork? network,
  }) {
    if (scriptHash == null && network == null) {
      throw ArgumentError('either scriptHash or network must be provided');
    }

    this.scriptHash = scriptHash ?? BitcoinAddressUtils.scriptHash(address, network: network!);
  }

  factory BitcoinAddressRecord.fromJSON(String jsonSource) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinAddressRecord(
      decoded['address'] as String,
      index: decoded['index'] as int,
      isHidden: decoded['isHidden'] as bool? ?? false,
      isChange: decoded['isChange'] as bool? ?? false,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      type: decoded['type'] != null && decoded['type'] != ''
          ? BitcoinAddressType.values
              .firstWhere((type) => type.toString() == decoded['type'] as String)
          : SegwitAddresType.p2wpkh,
      scriptHash: decoded['scriptHash'] as String?,
    );
  }

  late String scriptHash;

  @override
  String toJSON() => json.encode({
        'address': address,
        'index': index,
        'isHidden': isHidden,
        'isChange': isChange,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'scriptHash': scriptHash,
      });
}

class BitcoinSilentPaymentAddressRecord extends BaseBitcoinAddressRecord {
  int get labelIndex => index;
  final String? labelHex;

  BitcoinSilentPaymentAddressRecord(
    super.address, {
    required int labelIndex,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    super.type = SilentPaymentsAddresType.p2sp,
    super.isHidden,
    this.labelHex,
  }) : super(index: labelIndex, isChange: labelIndex == 0) {
    if (labelIndex != 1 && labelHex == null) {
      throw ArgumentError('label must be provided for silent address index > 0');
    }
  }

  factory BitcoinSilentPaymentAddressRecord.fromJSON(String jsonSource,
      {BasedUtxoNetwork? network}) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinSilentPaymentAddressRecord(
      decoded['address'] as String,
      labelIndex: decoded['labelIndex'] as int,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      labelHex: decoded['labelHex'] as String?,
    );
  }

  @override
  String toJSON() => json.encode({
        'address': address,
        'labelIndex': labelIndex,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'labelHex': labelHex,
      });
}

class BitcoinReceivedSPAddressRecord extends BitcoinSilentPaymentAddressRecord {
  final ECPrivate spendKey;

  BitcoinReceivedSPAddressRecord(
    super.address, {
    required super.labelIndex,
    super.txCount = 0,
    super.balance = 0,
    super.name = '',
    super.isUsed = false,
    required this.spendKey,
    super.type = SegwitAddresType.p2tr,
    super.labelHex,
  }) : super(isHidden: true);

  factory BitcoinReceivedSPAddressRecord.fromJSON(String jsonSource, {BasedUtxoNetwork? network}) {
    final decoded = json.decode(jsonSource) as Map;

    return BitcoinReceivedSPAddressRecord(
      decoded['address'] as String,
      labelIndex: decoded['index'] as int,
      isUsed: decoded['isUsed'] as bool? ?? false,
      txCount: decoded['txCount'] as int? ?? 0,
      name: decoded['name'] as String? ?? '',
      balance: decoded['balance'] as int? ?? 0,
      labelHex: decoded['label'] as String?,
      spendKey: ECPrivate.fromHex(decoded['spendKey'] as String),
    );
  }

  @override
  String toJSON() => json.encode({
        'address': address,
        'labelIndex': labelIndex,
        'isUsed': isUsed,
        'txCount': txCount,
        'name': name,
        'balance': balance,
        'type': type.toString(),
        'labelHex': labelHex,
        'spend_key': spendKey.toString(),
      });
}
