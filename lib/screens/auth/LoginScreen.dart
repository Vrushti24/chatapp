import 'dart:developer';
import 'dart:io';
import 'package:chatapp/api/api.dart';
import 'package:chatapp/screens/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool animate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2), () {
      setState(() {
        animate = true;
      });
    });
  }

  _handleGoogleButton() {
    _signInWithGoogle().then((user) async {
      if (user != null) {
        log('User: ${user.user}');
        if (await API.checkUserExists()) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          await API.createUser().then((value) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          });
        }
      }
    });
  }

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      //when internet is not available we use this
      await InternetAddress.lookup('google.com');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('_signInWithGoogle: $e');
      // showDialog.showSnackBar(
      //     context: context, 'Something wrong check connection');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat App'),
      ),
      body: Stack(children: [
        AnimatedPositioned(
            top: mq.height * .15,
            left: animate ? mq.width * .25 : -mq.width * .5,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            child: Image.asset('images/chat.png')),
        AnimatedPositioned(
            bottom: mq.height * .45,
            right: animate ? mq.width * .11 : -mq.width * .70,
            width: mq.width * .5,
            duration: const Duration(seconds: 1),
            child: const Text(
              "Let's Chat",
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )),
        Positioned(
            bottom: mq.height * .15,
            left: mq.width * .05,
            width: mq.width * .9,
            height: mq.height * .07,
            child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(225, 219, 255, 178),
                  shape: const StadiumBorder(),
                  elevation: 1,
                ),
                onPressed: () {
                  _handleGoogleButton();
                },
                icon: Image.asset(
                  'images/google.png',
                  height: mq.height * .04,
                ),
                label: RichText(
                    text: const TextSpan(
                        style: TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        children: [
                      TextSpan(
                        text: 'Log in with Google',
                      ),
                    ]))))
      ]),
    );
  }
}
