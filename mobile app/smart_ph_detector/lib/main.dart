import 'package:flutter/material.dart';
import 'package:smart_ph_detector/screen/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
      home: HomeScreen(),
  ));
}