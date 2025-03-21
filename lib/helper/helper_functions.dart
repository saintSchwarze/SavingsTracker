//functions used across the app or smth

import 'package:intl/intl.dart';

//convert string to double
double convertStringToDouble(String string) {
  double? amount = double.tryParse(string);
  return amount ?? 0.0;
}

//format double amount to dollar and cent
String formalAmount(double amount) {
  final format =  
    NumberFormat.currency(locale: "en_US", symbol: "\$", decimalDigits: 2);
  return format.format(amount);
}

//calc the num of months  since  the first month
int calculateMonthCount(int startYear, startMonth, currentYear, currentMonth) {
  int monthCount = 
    (currentYear - startYear) * 12 + currentMonth - startMonth + 1;
  return monthCount;
}
