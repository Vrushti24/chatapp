import 'package:chatapp/screens/HomeScreen.dart';
import 'package:chatapp/screens/auth/LoginScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../api/api.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (API.auth.currentUser != null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(children: [
      Positioned(
          top: mq.height * 35,
          left: mq.width * .25,
          width: mq.width * .5,
          child: Image.asset(
            'images/chat.png',
            height: mq.height * .15,
            width: .5,
          )),
      Positioned(
          bottom: mq.height * .35,
          right: mq.width * .11,
          width: mq.width * .5,
          child: const Text(
            "Let's Chat",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          )),
    ]));
  }
}
