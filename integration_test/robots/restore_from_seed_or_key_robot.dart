import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_from_seed_form.dart';
import 'package:cake_wallet/src/screens/restore/wallet_restore_page.dart';
import 'package:cake_wallet/src/widgets/validable_annotated_editable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_checks.dart';

class RestoreFromSeedOrKeysPageRobot {
  RestoreFromSeedOrKeysPageRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isRestoreFromSeedKeyPage() async {
    await commonTestCases.isSpecificPage<WalletRestorePage>();
  }

  Future<void> confirmViewComponentsDisplayProperlyPerPageView() async {
    commonTestCases.hasText(S.current.wallet_name);
    commonTestCases.hasText(S.current.enter_seed_phrase);
    commonTestCases.hasText(S.current.restore_title_from_seed);

    commonTestCases.hasKey('wallet_restore_from_seed_wallet_name_textfield_key');
    commonTestCases.hasKey('wallet_restore_from_seed_wallet_name_refresh_button_key');
    commonTestCases.hasKey('wallet_restore_from_seed_wallet_seeds_paste_button_key');
    commonTestCases.hasKey('wallet_restore_from_seed_wallet_seeds_textfield_key');

    commonTestCases.hasText(S.current.private_key, hasWidget: false);
    commonTestCases.hasText(S.current.restore_title_from_keys, hasWidget: false);

    await tester.drag(find.byType(PageView), Offset(-300, 0));
    await tester.pumpAndSettle();
    commonTestCases.defaultSleepTime();

    commonTestCases.hasText(S.current.wallet_name);
    commonTestCases.hasText(S.current.private_key);
    commonTestCases.hasText(S.current.restore_title_from_keys);

    commonTestCases.hasText(S.current.enter_seed_phrase, hasWidget: false);
    commonTestCases.hasText(S.current.restore_title_from_seed, hasWidget: false);

    await tester.drag(find.byType(PageView), Offset(300, 0));
    await tester.pumpAndSettle();
  }

  void confirmRestoreButtonDisplays() {
    commonTestCases.hasKey('wallet_restore_seed_or_key_restore_button_key');
  }

  void confirmAdvancedSettingButtonDisplays() {
    commonTestCases.hasKey('wallet_restore_advanced_settings_button_key');
  }

  Future<void> enterWalletNameText(String walletName) async {
    final walletNameTextField =
        find.byKey(ValueKey(('wallet_restore_from_seed_wallet_name_textfield_key')));
    await tester.enterText(walletNameTextField, walletName);
    await tester.pumpAndSettle();
  }

  Future<void> selectWalletNameFromAvailableOptions() async {
    await commonTestCases.tapItemByKey('wallet_restore_from_seed_wallet_name_refresh_button_key');
  }

  Future<void> enterSeedPhraseForWalletRestore(String text) async {
    ValidatableAnnotatedEditableTextState seedTextState =
        await tester.state(find.byType(ValidatableAnnotatedEditableText));

    seedTextState.widget.controller.text = text;
    await tester.pumpAndSettle();
  }

  Future<void> onPasteSeedPhraseButtonTapped() async {
    await commonTestCases.tapItemByKey('wallet_restore_from_seed_wallet_seeds_paste_button_key');
  }

  Future<void> onRestoreWalletButtonTapped() async {
    await commonTestCases.tapItemByKey('wallet_restore_seed_or_key_restore_button_key');
  }
}