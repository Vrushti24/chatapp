import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatapp/api/api.dart';
import 'package:chatapp/helper/dateandtime.dart';
import 'package:chatapp/main.dart';
import 'package:chatapp/model/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';

import '../helper/showdialog.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  const MessageCard({super.key, required this.message});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = API.user.uid == widget.message.fromId;
    return InkWell(
        onLongPress: () {
          _bottomSheet(isMe);
        },
        child: isMe ? _greenMessage() : _blueMessage());
  }

  //Sender
  _blueMessage() {
    //update last seen message
    if (widget.message.read.isEmpty) {
      API.updateReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
              padding: EdgeInsets.all(mq.width * .04),
              //making box move right side of the screen
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 221, 245, 255),
                  border: Border.all(color: Colors.lightBlue),
                  //giving curve effect
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  )),
              child: widget.message.type == Type.text
                  ? Text(
                      widget.message.msg,
                      style: TextStyle(color: Colors.black87, fontSize: 18),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(mq.height * .03),
                      child: CachedNetworkImage(
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        imageUrl: widget.message.msg,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image,
                          size: 70,
                        ),
                      ),
                    )),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDateTime.getFormattedTime(
                context: context, time: widget.message.send),
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        )
      ],
    );
  }

//user message(ME)
  _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (widget.message.read.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: mq.width * .01),
                child: Icon(
                  Icons.done_all_rounded,
                  color: Colors.blue,
                ),
              ),
            Padding(
              padding: EdgeInsets.only(left: mq.width * .01),
              child: Text(
                MyDateTime.getFormattedTime(
                    context: context, time: widget.message.send),
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ],
        ),
        Flexible(
          child: Container(
              padding: EdgeInsets.all(mq.width * .04),
              //making box move right side of the screen
              margin: EdgeInsets.symmetric(
                  horizontal: mq.width * .04, vertical: mq.height * .01),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 218, 255, 176),
                  border: Border.all(color: Colors.lightBlue),
                  //giving curve effect
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                  )),
              child: widget.message.type == Type.text
                  ? Text(
                      widget.message.msg,
                      style: TextStyle(color: Colors.black87, fontSize: 18),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: CachedNetworkImage(
                        imageUrl: widget.message.msg,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image,
                          size: 70,
                        ),
                      ),
                    )),
        ),
      ],
    );
  }

//bottom widget for message
  _bottomSheet(bool isMe) {
    showModalBottomSheet(
        elevation: 1,
        enableDrag: true,
        backgroundColor: Color.fromARGB(255, 192, 243, 246),
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              widget.message.type == Type.text
                  ?
                  //copy text
                  _OptionItem(
                      icon: Icon(
                        Icons.copy_all_outlined,
                        color: Colors.black87,
                        size: 25,
                      ),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          Navigator.pop(context);
                          ShowDialog.showSnackBar(
                              context, 'Text copied to clipboard');
                        });
                      })
                  :
                  //save image
                  _OptionItem(
                      icon: Icon(
                        Icons.save_alt_outlined,
                        color: Colors.black87,
                        size: 25,
                      ),
                      name: 'Save image',
                      onTap: () async {
                        try {
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'Chat-App')
                              .then((success) {
                            Navigator.pop(context);
                            if (success != null && success) {
                              ShowDialog.showSnackBar(
                                  context, 'Image Saved to gallery');
                            }
                          });
                        } catch (e) {
                          print('Error $e');
                        }
                      }),

              //delete
              if (widget.message.type == Type.text ||
                  widget.message.type == Type.image && isMe)
                _OptionItem(
                    icon: Icon(
                      Icons.delete_forever_outlined,
                      color: Colors.black87,
                      size: 25,
                    ),
                    name: 'Delete ',
                    onTap: () {
                      API.deleteMessage(widget.message).then((value) {
                        Navigator.pop(context);
                        ShowDialog.showSnackBar(context, 'Deleted');
                      });
                    }),
              //divider
              Divider(
                color: Colors.grey,
                endIndent: mq.width * .04,
                indent: mq.height * .04,
              ),
              //sent time
              _OptionItem(
                  icon: Icon(
                    Icons.send_outlined,
                    color: Colors.black87,
                    size: 25,
                  ),
                  name:
                      'Sent at: ${MyDateTime.getFormattedMessageTime(context: context, time: widget.message.send)}',
                  onTap: () {}),
              //read time
              _OptionItem(
                  icon: Icon(
                    Icons.remove_red_eye_outlined,
                    color: Colors.black87,
                    size: 25,
                  ),
                  name: widget.message.read.isEmpty
                      ? 'Read At: Not seen'
                      : 'Read at: ${MyDateTime.getFormattedMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;
  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .05,
            top: mq.height * .025,
            bottom: mq.height * .025),
        child: Row(
          children: [
            icon,
            Flexible(
                child: Text(
              '  $name',
              style: TextStyle(fontSize: 18),
            ))
          ],
        ),
      ),
    );
  }
}
