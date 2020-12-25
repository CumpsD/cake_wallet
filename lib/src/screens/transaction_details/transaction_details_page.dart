import 'package:cake_wallet/entities/transaction_description.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/bitcoin/bitcoin_transaction_info.dart';
import 'package:cake_wallet/monero/monero_transaction_info.dart';
import 'package:cake_wallet/entities/transaction_info.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/src/screens/transaction_details/standart_list_item.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/utils/date_formatter.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:hive/hive.dart';

String stripURLToTXID(String inputString) {
  final RegExp txidRegex = new RegExp('[a-z0-9]{64}');
  return txidRegex.allMatches(inputString).first.group(0);
}

String blockExplorerName(String inputName) {
  if (inputName.contains("xmrchain")) {
    return "XMRChain.net";
  } else {
    return "Blockchain.com";
  }
}

class TransactionDetailsPage extends BasePage {
  TransactionDetailsPage(this.transactionInfo, bool showRecipientAddress,
      Box<TransactionDescription> transactionDescriptionBox)
      : _items = [] {
    final dateFormat = DateFormatter.withCurrentLocal();
    final tx = transactionInfo;

    if (tx is MoneroTransactionInfo) {
      final items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        StandartListItem(title: S.current.send_fee, value: tx.feeFormatted())
      ];

      if (showRecipientAddress) {
        final recipientAddress = transactionDescriptionBox.values
            .firstWhere((val) => val.id == transactionInfo.id,
                orElse: () => null)
            ?.recipientAddress;

        if (recipientAddress?.isNotEmpty ?? false) {
          items.add(StandartListItem(
              title: S.current.transaction_details_recipient_address,
              value: recipientAddress));
        }
      }

      if (tx.key?.isNotEmpty ?? null) {
        // FIXME: add translation
        items.add(StandartListItem(title: 'Transaction Key', value: tx.key));
      }

      _items.addAll(items);
      _items.add(StandartListItem(
          title: "View in Block Explorer",
          value: "https://xmrchain.net/search?value=${tx.id}"));
    }

    if (tx is BitcoinTransactionInfo) {
      final items = [
        StandartListItem(
            title: S.current.transaction_details_transaction_id, value: tx.id),
        StandartListItem(
            title: S.current.transaction_details_date,
            value: dateFormat.format(tx.date)),
        StandartListItem(
            title: 'Confirmations', value: tx.confirmations?.toString()),
        StandartListItem(
            title: S.current.transaction_details_height, value: '${tx.height}'),
        StandartListItem(
            title: S.current.transaction_details_amount,
            value: tx.amountFormatted()),
        if (tx.feeFormatted()?.isNotEmpty)
          StandartListItem(title: S.current.send_fee, value: tx.feeFormatted())
      ];

      _items.addAll(items);
      _items.add(StandartListItem(
          title: "View in Block Explorer",
          value: "https://www.blockchain.com/btc/tx/${tx.id}"));
    }

    if (showRecipientAddress) {
      final recipientAddress = transactionDescriptionBox.values
          .firstWhere((val) => val.id == transactionInfo.id, orElse: () => null)
          ?.recipientAddress;

      if (recipientAddress?.isNotEmpty ?? false) {
        _items.add(StandartListItem(
            title: S.current.transaction_details_recipient_address,
            value: recipientAddress));
      }
    }
  }

  @override
  String get title => S.current.transaction_details_title;

  final TransactionInfo transactionInfo;

  final List<StandartListItem> _items;

  @override
  Widget body(BuildContext context) {
    return Container(
      child: ListView.separated(
          separatorBuilder: (context, index) => Container(
                height: 1,
                padding: EdgeInsets.only(left: 24),
                color: Theme.of(context).backgroundColor,
                child: Container(
                  height: 1,
                  color:
                      Theme.of(context).primaryTextTheme.title.backgroundColor,
                ),
              ),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final isFinalBlockExplorerItem =
                index == _items.length - 1 ? true : false;
            if (isFinalBlockExplorerItem == false) {
              return GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.value));
                  showBar<void>(context,
                      S.of(context).transaction_details_copied(item.title));
                },
                child: StandartListRow(
                    title: '${item.title}:',
                    value: item.value,
                    isDrawBottom: isFinalBlockExplorerItem),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  launch(item.value);
                },
                child: StandartListRow(
                    title: '${item.title}:',
                    value:
                        "View transaction on ${blockExplorerName(item.value)}",
                    isDrawBottom: isFinalBlockExplorerItem),
              );
            }
          }),
    );
  }
}
