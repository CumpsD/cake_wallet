import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/pin_code/pin_code_widget.dart';
import 'package:cake_wallet/src/screens/setup_pin_code/setup_pin_code.dart';
import 'package:flutter_test/flutter_test.dart';

import '../components/common_checks.dart';

class SetupPinCodeRobot {
  SetupPinCodeRobot(this.tester) : commonTestCases = CommonTestCases(tester);

  final WidgetTester tester;
  late CommonTestCases commonTestCases;

  Future<void> isSetupPinCodePage() async {
    await commonTestCases.isSpecificPage<SetupPinCodePage>();
  }

  void hasPinCodeWidget() {
    final pinCodeWidget = find.byType(PinCodeWidget);
    expect(pinCodeWidget, findsOneWidget);
  }

  void hasTitle() {
    commonTestCases.hasText(S.current.setup_pin);
  }

  void hasNumberButtonsVisible() {
    // Confirmation for buttons 1-9
    for (var i = 1; i < 10; i++) {
      commonTestCases.hasValueKey('pin_code_button_${i}_key');
    }

    // Confirmation for 0 button
    commonTestCases.hasValueKey('pin_code_button_0_key');
  }

  Future<void> pushPinButton(int index) async {
    await commonTestCases.tapItemByKey('pin_code_button_${index}_key');
  }

  Future<void> enterPinCode(List<int> pinCode, bool isFirstEntry) async {
    final PinCodeState pinCodeState = tester.state(find.byType(PinCodeWidget));

    for (int pin in pinCode) {
      await pushPinButton(pin);
    }

    // the state is cleared once it get's to the last entry
    expect(pinCodeState.pin, isFirstEntry ? '' : '0801');

    await commonTestCases.defaultSleepTime();
  }

  Future<void> tapSuccessButton() async {
    await commonTestCases.tapItemByKey('setup_pin_code_success_button_key');
    await commonTestCases.defaultSleepTime();
  }
}