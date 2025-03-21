import 'package:expensetracker/bar%20graph/individual_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MyBarGraph extends StatefulWidget {
  final List<double> monthlySummary;
  final int startMonth;

  const MyBarGraph({
    super.key, 
    required this.monthlySummary, 
    required this.startMonth
  });

  @override
  State<MyBarGraph> createState() => _MyBarGraphState();
}

class _MyBarGraphState extends State<MyBarGraph> {
  //this list will hold the data of individual bars
  List<IndividualBar> barData = [];

  //init bar data-user our monthly summary to create a list of bars
void initalizeBarData() {
  barData = List.generate(
    widget.monthlySummary.length,
    (index) => IndividualBar(
      x: index,
      y: widget.monthlySummary[index]
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
      )
    );
  }
}