import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/model/chat_user.dart';
import 'package:flutter/material.dart';

class HomeInfo extends StatelessWidget {
  const HomeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color.fromARGB(255, 246, 191, 209),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      content: SizedBox(
        width: mq.width * .5,
        height: mq.height * .3,
        child: Stack(alignment: Alignment.center, children: [
          ClipRect(
            child: Padding(
              padding:
                  EdgeInsets.only(top: mq.height * 0.01, left: mq.width * .02),
              child: Center(
                child: ClipRRect(
                    child: Center(
                        child: Text(
                  'Welcome to my Demo Chat Application!',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                ))),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
