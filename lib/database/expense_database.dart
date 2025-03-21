import 'package:expensetracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier{
  static late Isar isar;
  List<Expense> _allExpenses = [];

  /*

  SETUP

  */

  //init db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  /*

  GETTERS

  */

  List<Expense> get allExpenses => _allExpenses;

  /*

  OPERATIONS

  */

  //create expense
  Future<void> createNewExpense(Expense newExpense) async {
    // add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    //re-read from db
    await readExpenses();
  }
  //read expense from db
  Future<void> readExpenses() async {
    //fetch all existing expenses
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();

    //give to local expense list
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);

    //update UI
    notifyListeners();
  }
  //update expense from db
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    //make sure new expense same id as existing one
    updatedExpense.id = id;

    //update in db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));

    //re-read from db
    await readExpenses();
  }

  //delete expense
  Future<void> deleteExpense(int id) async {
    //delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));

    //re-read from db
    await readExpenses();
  }

  /*

  HELPER

  */

  //calculate total savings for each month
  Future<Map<int,double>> calculateMonthlyTotals() async {
    //ensure the savings are read from db
    await readExpenses();

    //create a map to hold the monthly totals
    Map<int,double> monthlyTotals = {}; 

    //iterate over all savings
    for (var expense in _allExpenses) {
      //extract the month  from the date of the saving
      int month = expense.date.month;
      //if month is not yet on map, init to 0
      if(!monthlyTotals.containsKey(month)) {
        monthlyTotals[month] = 0;
      }

      //add the savings ammount to the month total
      monthlyTotals[month] = monthlyTotals[month]! + expense.amount;
    }

    return monthlyTotals;
  }

  //get start month
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().month;
    } 
    //sort expenses by date  to find the earliest
    _allExpenses.sort(
      (a,b) => a.date.compareTo(b.date)
    );
    return _allExpenses.first.date.month;
  }
  //get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
    } 
    //sort expenses by date  to find the earliest
    _allExpenses.sort(
      (a,b) => a.date.compareTo(b.date)
    );
    return _allExpenses.first.date.year;
  }
}