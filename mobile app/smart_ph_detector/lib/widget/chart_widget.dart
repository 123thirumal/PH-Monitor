import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key,required this.tempList});

  final List<MapEntry<DateTime, double>> tempList;

  @override
  _ChartWidgetState createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  List<FlSpot> flSpots = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData(){
    // Convert to FlSpot (x = index, y = pH)
    final spots = <FlSpot>[];
    for (int i = 0; i < widget.tempList.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.tempList[i].value));
    }

    setState(() {
      flSpots = spots;
      isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: Text("Loading...",style: TextStyle(color: Colors.white,fontSize: 15,fontFamily: 'Nothing',fontWeight: FontWeight.w500,),))
        : flSpots.isEmpty
        ? const Center(child: Text("No data available",style: TextStyle(color: Colors.white,fontSize: 15,fontFamily: 'Nothing',fontWeight: FontWeight.w500,),))
        : LineChart(
          LineChartData(
            borderData: FlBorderData(
              show: false, // This hides the entire border
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) {
                  return const Color.fromRGBO(37, 37, 37, 1.0);
                },
                tooltipRoundedRadius: 12,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                tooltipPadding: const EdgeInsets.all(12),
                tooltipMargin: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    return LineTooltipItem(
                      "pH: ${touchedSpot.y.toStringAsFixed(2)}",
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nothing'
                      ),
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,

            ),


            minY: 0,               // Y-axis minimum
            maxY: 14,              // Y-axis maximum
            gridData: FlGridData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                spots: flSpots.length > 10
                    ? flSpots.sublist(flSpots.length - 10)
                    : flSpots,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (FlSpot spot, double percent, LineChartBarData barData, int index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 0,
                      strokeColor: Colors.transparent,
                    );
                  },
                ),
                color: Color.fromRGBO(216, 216, 216, 1.0),
                barWidth: 4,
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Hide X-axis labels
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Hide Y-axis labels
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Hide X-axis labels
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false, // Hide Y-axis labels
                ),
              ),
            ),

          ),
    );
  }
}
