import 'package:flutter/material.dart';
import 'package:smart_ph_detector/widget/chart_widget.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  double? _latestPh;
  List<MapEntry<DateTime, double>> tempList = [];
  String _currState="Acidic";

  @override
  void initState() {
    super.initState();
    _listenToFirebaseChanges(); // Start listening to changes
  }

  void _listenToFirebaseChanges() {
    final dbRef = FirebaseDatabase.instance.refFromURL("https://smart-ph-detector-default-rtdb.firebaseio.com/ph_data");

    // Listen for any changes at the "ph_data" reference
    dbRef.onValue.listen((event) {
      // This method is called whenever there's a change in the database.
      final snapshot = event.snapshot;

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        DateTime? latestTime;
        double? latestPh;
        final List<MapEntry<DateTime, double>> entries = [];

        data.forEach((key, value) {
          final timestampStr = value['timestamp']?.toString();
          final phStr = value['pH']?.toString();

          final timestamp = DateTime.tryParse(timestampStr ?? '');
          final ph = double.tryParse(phStr ?? '');

          if (timestamp != null && ph != null) {
            entries.add(MapEntry(timestamp, ph));
            if (latestTime == null || timestamp.isAfter(latestTime!)) {
              latestTime = timestamp;
              latestPh = ph;
            }
          }
        });

        entries.sort((a, b) => a.key.compareTo(b.key));

        setState(() {
          _latestPh = latestPh;
          tempList = entries;
          if(_latestPh!>=5.5 && _latestPh!<=7.5){
            _currState="Normal";
          }
          else if(_latestPh!>7.5){
            _currState="Basic";
          }
          else{
            _currState="Acidic";
          }
        });
      }
    });
  }

  void sendCommand(String command) async {
    try {
      final socket = await Socket.connect('192.168.34.151', 12345);
      socket.write(command);
      await socket.flush();
      await socket.close();
      print('✅ Sent: $command');
    } catch (e) {
      print('❌ Error: $e');
    }
  }


  // Future<void> _fetchPh() async {
  //   final dbRef = FirebaseDatabase.instance.refFromURL("https://smart-ph-detector-default-rtdb.firebaseio.com/ph_data");
  //
  //   try {
  //     final snapshot = await dbRef.get();
  //
  //     if (snapshot.exists) {
  //       final data = snapshot.value as Map<dynamic, dynamic>;
  //
  //       DateTime? latestTime;
  //       double? latestPh;
  //       final List<MapEntry<DateTime, double>> entries = [];
  //
  //       data.forEach((key, value) {
  //         final timestampStr = value['timestamp']?.toString();
  //         final phStr = value['pH']?.toString();
  //
  //         final timestamp = DateTime.tryParse(timestampStr ?? '');
  //         final ph = double.tryParse(phStr ?? '');
  //
  //         if (timestamp != null && ph != null) {
  //           entries.add(MapEntry(timestamp, ph));
  //           if (latestTime == null || timestamp.isAfter(latestTime)) {
  //             latestTime = timestamp;
  //             latestPh = ph;
  //           }
  //         }
  //       });
  //
  //       entries.sort((a, b) => a.key.compareTo(b.key));
  //
  //       setState(() {
  //         _latestPh = latestPh;
  //         tempList = entries;
  //       });
  //     }
  //   } catch (e) {
  //     print("❌ Error fetching latest pH: $e");
  //   }
  // }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text(
            "PH Control",
            style: TextStyle(
              fontFamily: 'Nothing',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.black,
        ),
        body: PageView(
          scrollDirection: Axis.vertical,
          children: [
            // Screen 1
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 400,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        (_latestPh != null && _latestPh!>0)?"pH - ${_latestPh!.toStringAsFixed(2)}":"Loading...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50,
                          fontFamily: 'Nothing',
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 160,
                        width: 160,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(234, 232, 232, 0.81),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Center(
                          child: Text(
                            _currState,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              fontFamily: 'Nothing',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              sendCommand("Increase");
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(180, 70),
                              backgroundColor: const Color.fromRGBO(25, 25, 25, 1.0),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              "Increase pH",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Nothing',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              sendCommand("Reduce");
                            },
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size(180, 70),
                              backgroundColor: const Color.fromRGBO(25, 25, 25, 1.0),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              "Reduce pH",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: 'Nothing',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),

            // Screen 2
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(18, 18, 18, 1.0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(20),
                    child: ChartWidget(tempList: tempList),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 160,
                        width: 160,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(18, 18, 18, 1.0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Acidic",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontFamily: 'Nothing',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "0-5.5",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontFamily: 'Nothing',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 160,
                        width: 160,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(18, 18, 18, 1.0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Normal",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontFamily: 'Nothing',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "5.5-7.5",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontFamily: 'Nothing',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        height: 160,
                        width: 160,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(18, 18, 18, 1.0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Basic",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontFamily: 'Nothing',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "7.5-14",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontFamily: 'Nothing',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 160,
                        width: 160,
                        margin: const EdgeInsets.all(16),
                        // padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(234, 232, 232, 0.81),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: PageView(
                          scrollDirection: Axis.horizontal,
                          // The PageView widget allows horizontal scrolling, showing one item at a time
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/img1.svg', // Path to your SVG asset
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/img2.svg', // Path to your SVG asset
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/img3.svg', // Path to your SVG asset
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: SvgPicture.asset(
                                'assets/images/img4.svg', // Path to your SVG asset
                                fit: BoxFit.scaleDown,
                              ),
                            ),
                          ],
                        ),
                      )


                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
