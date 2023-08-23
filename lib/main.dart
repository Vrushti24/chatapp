import 'dart:developer';

import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/screens/SplashScreen.dart';
import 'package:chatapp/screens/auth/LoginScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:notification_channel_manager/notification_channel_manager.dart';

//global object for accessing device on different screen
late Size mq;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initializeFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
        backgroundColor: Colors.white,
      )),
      home: const SplashScreen(),
    );
  }
}

_initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  var result = await const NotificationChannel(
      description: 'To show Message notification',
      id: 'chats',
      importance: NotificationChannelImportance.high,
      name: 'Chats');
  log('Notification: $result');
}
