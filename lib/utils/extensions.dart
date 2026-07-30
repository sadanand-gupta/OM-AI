import 'package:flutter/material.dart';
import 'package:om_ai/resources/st_colors.dart';
import 'package:om_ai/resources/st_strings.dart';
import 'package:om_ai/resources/st_styles.dart';

extension ExtendedString on String {
  String morphingString() {
    if (length <= 3) {
      return this;
    }
    String lastThreeDigits = substring(length - 3);
    String maskedValue = lastThreeDigits.padLeft(length, '*');
    return maskedValue;
  }
}

extension StringEmailValidation on String {
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'''^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+\.[a-z]+$''',
    );
    return emailRegex.hasMatch(this);
  }
}

extension StringNRICValidation on String {
  bool isValidNRIC() {
    RegExp nricPattern = RegExp(r'^[STFGstfg]\d{7}[A-Za-z]$');
    return nricPattern.hasMatch(this);
  }
}

extension StringPasswordValidation on String {
  bool isValidPassword() {
    RegExp passwordPattern = RegExp(
        r'''^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$''');
    return passwordPattern.hasMatch(this);
  }
}

extension StringExtension on String {
  bool isValidPhone() {
    final phoneRegex =
        RegExp(r'''^(\+?\d{1,4}[\s-])?(?!0+\s+,?$)\d{8}\s*,?$''');
    return phoneRegex.hasMatch(this);
  }

  bool isNumeric({bool allowDecimal = false}) {
    return int.tryParse(this) != null;
  }
}

extension SnackBarExtension on BuildContext {
  void showSnackBar(String message,
      {Duration duration = const Duration(seconds: 1)}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
      ),
    );
  }
}

extension CurrencyFormat on double {
  String formatCurrency() {
    String formattedAmount = '';
    String sign = this < 0 ? '-' : '';
    final amount = abs();
    String amountString = amount.toStringAsFixed(2);
    List<String> parts = amountString.split('.');
    String wholePartString = parts[0];
    for (int i = wholePartString.length - 1, count = 0; i >= 0; i--, count++) {
      if (count != 0 && count % 3 == 0) {
        formattedAmount = ',$formattedAmount';
      }
      formattedAmount = wholePartString[i] + formattedAmount;
    }
    formattedAmount = '${StStrings.sgd}$sign$formattedAmount';
    return formattedAmount;
  }
}

extension LoaderWidget on BuildContext {
  Widget loader() => const CircularProgressIndicator(color: StColors.stOrange);

  showOkAlert({String? message,Widget? customWidget}) {
    Widget okButton = ElevatedButton(
      style: StStyles.confirmButton,
      child: Text(StStrings.ok.toUpperCase()),
      onPressed: () {
        Navigator.of(this, rootNavigator: true).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      shape: StStyles.dialogShape,
      content: customWidget ?? Text(message ?? "", style: StStyles.textRegular16),
      actions: [
        okButton,
      ],
    );

    return showDialog(
        context: this,
        builder: (context) {
          return alert;
        });
  }
}


enum FeedbackType {
  SERVICES,
  LOAN_STATUS,
  TECHNICAL;

  @override
  String toString() {
    switch (this) {
      case SERVICES:
        return StStrings.services;
      case LOAN_STATUS:
        return StStrings.loans;
      case TECHNICAL:
        return StStrings.technical;
    }
  }
}

enum SchedulePaymentType {
  SC,
  PL,
  EL,
  HL,
  RL;

  @override
  String toString() {
    switch (this) {
      case SC:
        return StStrings.selectCategory;
      case PL:
        return StStrings.personalLoan;
      case EL:
        return StStrings.educationLoan;
      case HL:
        return StStrings.housingLoan;
      case RL:
        return StStrings.renovationLoan;
    }
  }
}
