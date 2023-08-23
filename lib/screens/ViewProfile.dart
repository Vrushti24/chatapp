import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/helper/dateandtime.dart';
import 'package:chatapp/model/chat_user.dart';
import 'package:chatapp/screens/ChatScreen.dart';
import 'package:chatapp/screens/HomeScreen.dart';
import 'package:chatapp/widgets/ProfileDailog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api.dart';
import '../helper/showdialog.dart';
import '../main.dart';
import 'auth/LoginScreen.dart';

class ViewProfile extends StatefulWidget {
  final ChatUser user;
  const ViewProfile({super.key, required this.user});

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.name),
        leading: IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => HomeScreen()));
            },
            icon: const Icon(Icons.arrow_back_outlined)),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Joined on: ',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            Text(
              MyDateTime.getLastMessageTime(
                  context: context,
                  time: widget.user.createdAt,
                  showYear: true),
              style: TextStyle(fontSize: 18, color: Colors.black87),
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            //for profile picture
            InkWell(
              onTap: () {
                showDialog(
                    context: context,
                    builder: (_) => ProfileDialog(user: widget.user));
              },
              child: ClipRect(
                child: Padding(
                  padding: EdgeInsets.only(top: mq.height * 0.05),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .1),
                      child: CachedNetworkImage(
                        width: mq.height * .2,
                        height: mq.height * .2,
                        fit: BoxFit.cover,
                        imageUrl: widget.user.image,
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            //space
            SizedBox(
              height: mq.height * .02,
            ),
            //show current email
            Text(
              widget.user.email,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            //space
            SizedBox(
              height: mq.height * .01,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'About: ',
                  style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.user.about,
                  style: TextStyle(fontSize: 18, color: Colors.black87),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
