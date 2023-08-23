import 'dart:convert';
import 'dart:developer';

import 'package:chatapp/helper/showdialog.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/model/chat_user.dart';
import 'package:chatapp/screens/auth/LoginScreen.dart';
import 'package:chatapp/screens/profilescreen.dart';
import 'package:chatapp/widgets/HomeInfo.dart';
import 'package:chatapp/widgets/chatUserCard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../api/api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  List<ChatUser> _searchlist = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    API.getUserInfo();
    SystemChannels.lifecycle.setMessageHandler((message) {
      log('Message: $message');
      if (API.auth.currentUser != null) {
        if (message.toString().contains('resumed')) API.updateStatus(true);
      }

      if (message.toString().contains('pause')) API.updateStatus(false);
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // backgroundColor: const Color.fromARGB(255, 240, 213, 222),
        appBar: AppBar(
          //backgroundColor: const Color.fromARGB(255, 254, 248, 194),
          title: _searching
              ? TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Search name',
                  ),
                  onChanged: (value) {
                    _searchlist.clear();

                    for (var i in _list) {
                      if (i.name.toLowerCase().contains(value.toLowerCase()) ||
                          i.email.toLowerCase().contains(value.toLowerCase())) {
                        _searchlist.add(i);
                      }
                      setState(() {
                        _searchlist;
                      });
                    }
                  },
                )
              : Text(
                  'Chat App',
                ),
          leading: IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => HomeInfo(),
                );
              },
              icon: const Icon(Icons.home)),
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    _searching = !_searching;
                  });
                },
                icon: Icon(_searching ? Icons.clear : Icons.search)),
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                                user: API.me,
                              )));
                },
                icon: const Icon(Icons.more_vert))
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(20),
          child: FloatingActionButton(
            onPressed: () {
              _addUserDialog();
            },
            child: const Icon(Icons.add_sharp),
          ),
        ),
        //main body where we load the card
        body: StreamBuilder(
            //known user ID only
            stream: API.getAllUsersId(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                //data loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                //data loaded
                case ConnectionState.active:
                case ConnectionState.done:
                  return StreamBuilder(
                      //get users whos ID are provided
                      stream: API.getAllUsers(
                          snapshot.data?.docs.map((e) => e.id).toList() ?? []),
                      builder: ((context, snapshot) {
                        switch (snapshot.connectionState) {
                          //data loading
                          case ConnectionState.waiting:
                          case ConnectionState.none:
                            // return const Center(
                            //   child: CircularProgressIndicator(),
                            // );
                            return Center(
                                child: Text(
                              'No connections!',
                              style: TextStyle(fontSize: 20),
                            ));
                          //data loaded
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data?.docs;
                            _list = data
                                    ?.map((e) => ChatUser.fromJson(e.data()))
                                    .toList() ??
                                [];
                            if (_list.isNotEmpty) {
                              return ListView.builder(
                                  padding:
                                      EdgeInsets.only(top: mq.height * .01),
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _searching
                                      ? _searchlist.length
                                      : _list.length,
                                  itemBuilder: (context, index) {
                                    return ChatUserCard(
                                        user: _searching
                                            ? _searchlist[index]
                                            : _list[index]);
                                  });
                            } else {
                              return const Center(
                                child: Text('No connections found',
                                    style: TextStyle(
                                      fontSize: 20,
                                    )),
                              );
                            }
                        }
                      }));
              }
            }));
  }

  void _addUserDialog() {
    String email = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
          backgroundColor: const Color.fromARGB(255, 238, 232, 178),
          contentPadding: EdgeInsets.only(
              left: mq.width * .04,
              top: mq.height * 0.02,
              right: mq.width * .04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),

          //title
          title: Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.black,
                size: 25,
              ),
              Center(child: Text('  Add user')),
            ],
          ),
          content: TextFormField(
            maxLines: null,
            onChanged: (value) => email = value,
            decoration: InputDecoration(
                label: Text('Enter Email'),
                prefixIcon: Icon(
                  Icons.mail,
                  color: Colors.black,
                  size: 25,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                )),
          ),
          //actions
          actions: [
            //cancel button
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: MaterialButton(
                color: const Color.fromARGB(255, 250, 153, 147),
                onPressed: () {},
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
              ),
            ),
            //Add button
            Padding(
              padding: EdgeInsets.only(right: mq.width * .04),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: MaterialButton(
                  color: Colors.black38,
                  onPressed: () async {
                    Navigator.pop(context);
                    if (email.isNotEmpty) {
                      await API.addChatUser(email).then((value) {
                        if (!value) {
                          ShowDialog.showSnackBar(context,
                              'User does not exist Please check again!');
                        }
                      });
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            )
          ]),
    );
  }
}
