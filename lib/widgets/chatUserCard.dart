import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/api/api.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/model/message.dart';
import 'package:chatapp/widgets/ProfileDailog.dart';
import 'package:flutter/material.dart';

import '../helper/dateandtime.dart';
import '../model/chat_user.dart';
import '../screens/ChatScreen.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  Message? _message;
  @override
  Widget build(BuildContext context) {
    return Card(
        color: Color.fromARGB(255, 254, 248, 194),
        margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          onTap: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          user: widget.user,
                        )));
          },
          child: StreamBuilder(
              stream: API.getLastMessages(widget.user),
              builder: (context, snapshot) {
                final data = snapshot.data?.docs;
                final _list =
                    data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
                if (_list.isNotEmpty) {
                  _message = _list[0];
                }
                return ListTile(
                    leading: InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (_) => ProfileDialog(user: widget.user));
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .03),
                        child: CachedNetworkImage(
                          width: mq.height * .055,
                          height: mq.height * .055,
                          imageUrl: widget.user.image,
                          errorWidget: (context, url, error) =>
                              const CircleAvatar(child: Icon(Icons.person)),
                        ),
                      ),
                    ),
                    title: Text(widget.user.name),
                    //last message typed
                    subtitle: Text(
                      _message != null
                          ? _message!.type == Type.image
                              ? 'Image'
                              : _message!.msg
                          : widget.user.about,
                      maxLines: 1,
                    ),
                    //last message time
                    trailing: _message == null
                        //show nthg when no message send
                        ? null
                        : _message!.read.isEmpty &&
                                _message!.fromId != API.user.uid
                            //unread message
                            ? Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                    color: Colors.lightGreen,
                                    borderRadius: BorderRadius.circular(10)),
                              )
                            : Text(
                                MyDateTime.getLastMessageTime(
                                    context: context, time: _message!.send),
                                style: TextStyle(color: Colors.grey),
                              ));
              }),
        ));
  }
}
