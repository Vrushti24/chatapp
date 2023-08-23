import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/model/message.dart';
import 'package:chatapp/screens/HomeScreen.dart';
import 'package:chatapp/screens/ViewProfile.dart';
import 'package:chatapp/widgets/messageCard.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api.dart';
import '../helper/dateandtime.dart';
import '../main.dart';
import '../model/chat_user.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all message
  List<Message> _list = [];

  //text controller
  final textController = TextEditingController();

  bool _showemoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        //if emojis are shown and back button is clicked then hide emojis
        child: WillPopScope(
          onWillPop: () {
            if (_showemoji) {
              setState(() => _showemoji = !_showemoji);
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
              backgroundColor: Color.fromRGBO(249, 242, 181, 1),
              appBar: AppBar(
                backgroundColor: Color.fromARGB(255, 245, 235, 238),
                automaticallyImplyLeading: false,
                flexibleSpace: _appBar(),
              ),
              body: Column(
                children: [
                  _chatArea(),
                  //loading
                  if (_isUploading)
                    Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(),
                        )),
                  _messageButton(),
                  //emoji box
                  if (_showemoji)
                    SizedBox(
                      height: mq.height * .35,
                      child: EmojiPicker(
                        textEditingController: textController,
                        config: Config(
                          columns: 7,
                          emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
                        ),
                      ),
                    )
                ],
              )),
        ),
      ),
    );
  }

  _appBar() {
    return InkWell(
        onTap: () {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => ViewProfile(user: widget.user)));
        },
        child: StreamBuilder(
          stream: API.getUserStatus(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
            return Row(
              children: [
                //back button
                Padding(
                  padding: EdgeInsets.only(top: mq.height * 0.01),
                  child: IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()));
                      },
                      icon: const Icon(Icons.arrow_back_outlined)),
                ),
                //profile button
                Padding(
                  padding: EdgeInsets.only(top: mq.height * 0.01),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(mq.height * .1),
                    child: CachedNetworkImage(
                      width: mq.height * .05,
                      height: mq.height * .05,
                      fit: BoxFit.cover,
                      imageUrl: widget.user.image,
                      errorWidget: (context, url, error) =>
                          const CircleAvatar(child: Icon(Icons.person)),
                    ),
                  ),
                ),

                //space
                SizedBox(
                  width: 12,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: mq.height * 0.010),
                      child: Text(
                        list.isNotEmpty ? list[0].name : widget.user.name,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),

                    //last seen time
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Text(
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? 'Online'
                                : MyDateTime.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MyDateTime.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ));
  }

  //widget for typing and other buttons at bottom of screen
  _messageButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  //emoji icon
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _showemoji = !_showemoji;
                        });
                      },
                      icon: const Icon(
                        Icons.emoji_emotions,
                        color: Colors.blueAccent,
                        size: 27,
                      )),

                  //Text Field
                  Expanded(
                    child: TextFormField(
                      onTap: () {
                        if (_showemoji)
                          setState(() {
                            _showemoji = !_showemoji;
                          });
                      },
                      controller: textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'type something ..',
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  //gallery icon
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        //pick multple image
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);
                        //send image one by one
                        for (var i in images) {
                          setState(() {
                            _isUploading = true;
                          });
                          await API.sendImage(widget.user, File(i.path));
                          setState(() {
                            _isUploading = false;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.image,
                        color: Colors.blueAccent,
                        size: 27,
                      )),

                  //camera icon
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();

                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);

                        if (image != null) {
                          setState(() {
                            _isUploading = true;
                          });
                          API.sendImage(widget.user, File(image.path));
                          setState(() {
                            _isUploading = false;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.blueAccent,
                        size: 27,
                      )),
                ],
              ),
            ),
          ),

          //send button
          MaterialButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  //on first message add user to my contacts
                  API.sendFirstMessage(
                      widget.user, textController.text, Type.text);
                } else {
                  API.sendMessage(widget.user, textController.text, Type.text);
                }
                textController.text = '';
              }
            },
            minWidth: 0,
            shape: CircleBorder(),
            color: Colors.green,
            child: const Icon(
              Icons.send,
              color: Colors.white,
              size: 22,
            ),
          )
        ],
      ),
    );
  }

  //chat area
  _chatArea() {
    return //chatting area
        Expanded(
      child: StreamBuilder(
          stream: API.getAllMessages(widget.user),
          builder: ((context, snapshot) {
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
                final data = snapshot.data?.docs;
                //log('Data: ${jsonEncode(data![0].data())}');
                _list =
                    data?.map((e) => Message.fromJson(e.data())).toList() ?? [];

                if (_list.isNotEmpty) {
                  return ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.only(top: mq.height * .01),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _list.length,
                      itemBuilder: (context, index) {
                        return MessageCard(message: _list[index]);
                      });
                } else {
                  return Center(
                    child: Text('Say Hello',
                        style: TextStyle(
                          fontSize: 20,
                        )),
                  );
                }
            }
          })),
    );
  }
}
