import 'package:expensetracker/bar%20graph/bar_graph.dart';
import 'package:expensetracker/components/my_list_tile.dart';
import 'package:expensetracker/database/expense_database.dart';
import 'package:expensetracker/helper/helper_functions.dart';
import 'package:expensetracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //text controller
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  //futures to load graph data
  Future<Map<int, double>>? _monthlyTotalsFuture;

  @override
  void initState() {

    //read db on init startup
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();

    //loadfutures
    refreshGraphData();

    super.initState();
  }

  //refresh graph data
  void refreshGraphData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
  }

  //open new expense box
  void openNewExpenseBox() {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Text("New savings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //user input expense name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Name"),
            ),
            //user input expense amount
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: "Amount"),
            ),
          ],
        ),
        actions: [
          //cancel button
        _cancelButton(),  

        //save button
        _createNewExpenseButton()
        ],
      )
    );
  }

  //open edit box
  void openEditBox(Expense expense) {

    //pre fill existing values to textfields
    String existingName = expense.name;
    String existingAmount = expense.amount.toString();

    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title:const Text("Edit savings"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //user input expense name
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
            ),
            //user input expense amount
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingAmount),
            ),
          ],
        ),
        actions: [
          //cancel button
        _cancelButton(),  

        //save button
        _editExpenseButton(expense),
        ],
      )
    );
  }
  //open delete box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title:const Text("Delete Savings?"),
        actions: [
          //cancel button
        _cancelButton(),  

        //delete button
        _deleteExpenseButton(expense.id),
        ],
      )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) {
        //get dates
        int startMonth = value.getStartMonth();
        int startYear = value.getStartYear();
        int currentMonth = DateTime.now().month;
        int currentYear = DateTime.now().year;
        //calculate the number of months since the first month
        int monthCount = calculateMonthCount(
          startYear, startMonth, currentYear, currentMonth
        );
        //only display savings for the current month
        
        //return ui
        return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: openNewExpenseBox,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              //graph ui
              SizedBox(
                height: 250,
                child: FutureBuilder(
                  future: _monthlyTotalsFuture,
                  builder: (context, snapshot) {
                    //data is loaded
                    if (snapshot.connectionState == ConnectionState.done) {
                      final monthlyTotals = snapshot.data ?? {};
                
                      //create list of monthly summary
                      List<double> monthlySummary = List.generate(monthCount,
                        (index) => monthlyTotals[startMonth + index] ?? 0.0);
                      
                      return MyBarGraph(
                        monthlySummary: monthlySummary, startMonth: startMonth);            
                    }
                    //loading
                    else {
                      return const Center(
                        child: Text("Loading...")
                      );
                    }
                  },
                ),
              ),
              //expense list ui
              Expanded(
                child: ListView.builder(
                          itemCount: value.allExpenses.length,
                          itemBuilder: (context, index) {
                //get indiidivual expense
                Expense individualExpense = value.allExpenses[index];
                //return list tile ui
                return MyListTile(
                  title: individualExpense.name, 
                  trailing: formalAmount(individualExpense.amount),
                  onEditPressed: (context) => openEditBox(individualExpense),
                  onDeletePressed: (context) => openDeleteBox(individualExpense),
                );
                          },
                        ),
              ),
          ],),
        )
      );
      },
    );
  }
  //cancel button
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        //pop box
        Navigator.pop(context);

        //clear controllers
        nameController.clear();
        amountController.clear();
        
      },
      child: const Text("Cancel"),
    );
  } 

  //save button
  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        //only save if text fields are not empty
        if (nameController.text.isNotEmpty && 
            amountController.text.isNotEmpty) {
          //pop box
          Navigator.pop(context);

          //create new expense
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now()
          );

          //save to db
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);

          //clear controllers
          nameController.clear();
          amountController.clear();
        }
      },
    );
  }

  //save edit button
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        //save as long as one textfield has changed
        if(
          nameController.text.isNotEmpty || 
          amountController.text.isNotEmpty) {
          //pop box
          Navigator.pop(context);
          //create new updated expense
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty 
                ? nameController.text 
                : expense.name, 
            amount: amountController.text.isNotEmpty 
                  ? convertStringToDouble(amountController.text) 
                  : expense.amount, 
            date: DateTime.now(),
          );
          //old expense id
          int existingId = expense.id;

          //save to db
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense); 
          }
      },
      child: const Text("Save"),
    ); 
  }

  //delete button
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(onPressed: ()  async{
      //pop box
      Navigator.pop(context);
      //delete expense from db
      await context.read<ExpenseDatabase>().deleteExpense(id);
    },
    child: const Text("Delete"),
    );
  }

}


