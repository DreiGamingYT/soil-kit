import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatelessWidget {

  final int n;
  final int p;
  final int k;

  DashboardScreen(this.n,this.p,this.k);

  @override
  Widget build(BuildContext context){

    return Scaffold(
      appBar: AppBar(title: Text("NPK Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: BarChart(
          BarChartData(
            barGroups: [

              BarChartGroupData(x: 0, barRods: [
                BarChartRodData(toY: n.toDouble())
              ]),

              BarChartGroupData(x: 1, barRods: [
                BarChartRodData(toY: p.toDouble())
              ]),

              BarChartGroupData(x: 2, barRods: [
                BarChartRodData(toY: k.toDouble())
              ]),
            ],
          ),
        ),
      ),
    );
  }
}