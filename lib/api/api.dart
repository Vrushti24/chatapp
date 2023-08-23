import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:chatapp/model/chat_user.dart';
import 'package:chatapp/model/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class API {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;
  static FirebaseStorage firebaseStorage = FirebaseStorage.instance;
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  //return current user
  static User get user => auth.currentUser!;
  //check if user exists or not
  static Future<bool> checkUserExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  //for getting current user info
  static Future<void> getUserInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        await getFirebaseMessagingToken();
        //setting user status active
        API.updateStatus(true);
      } else {
        await createUser().then((value) => getUserInfo());
      }
    });
  }

  //store self info
  static late ChatUser me;

  //create new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final chatuser = ChatUser(
      id: user.uid,
      name: user.displayName.toString(),
      email: user.email.toString(),
      about: 'my feeling',
      image: user.photoURL.toString(),
      createdAt: time,
      isOnline: false,
      lastActive: time,
      pushToken: '',
    );
    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatuser.toJson());
  }

  //api to get all ID
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
      List<String> userId) {
    return firestore
        .collection('users')
        .where('id', whereIn: userId)
        .snapshots();
  }

  //for getting user info to check whether it is online or not
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserStatus(
      ChatUser chatUser) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  //upload profile picture
  static Future<void> updateProfilePicture(File file) async {
    //getting image file extension
    final ext = file.path.split('.').last;
    log('Extension: $ext');

    //storage file ref with path
    final ref =
        firebaseStorage.ref().child('profile_pictures/${user.uid}.$ext');

    //uploading image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$ext'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000} kb');
    });

    //updating image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore
        .collection('users')
        .doc(user.uid)
        .update({'image': me.image});
  }

  //update status of user
  static Future<void> updateStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  //update profile
  static Future<void> updateUser() async {
    return await firestore
        .collection('users')
        .doc(user.uid)
        .update({'name': me.name, 'about': me.about});
  }

  //get conversationID
  static String getConverstionID(String id) => user.uid.hashCode <= id.hashCode
      ? '${user.uid}_$id'
      : '${id}_${user.uid}';

  //api to get all messages of specific conversation
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConverstionID(user.id)}/messages/')
        .orderBy('send', descending: true)
        .snapshots();
  }

  //for sending message
  static Future<void> sendMessage(
      ChatUser chatUser, String msg, Type type) async {
    //message sending time we will use as ID
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    //message that is to be sent
    final Message message = Message(
        msg: msg,
        read: '',
        toId: chatUser.id,
        type: type,
        send: time,
        fromId: user.uid);
    final ref = firestore
        .collection('chats/${getConverstionID(chatUser.id)}/messages/');
    await ref.doc(time).set(message.toJson()).then((value) =>
        sendPushNotificaton(chatUser, type == Type.text ? msg : 'image'));
  }

  //update read icon
  static Future<void> updateReadStatus(Message message) async {
    firestore
        .collection('chats/${getConverstionID(message.fromId)}/messages/')
        .doc(message.send)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  //get last message to be shown in subtitle
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessages(
      ChatUser user) {
    return firestore
        .collection('chats/${getConverstionID(user.id)}/messages/')
        .orderBy('send', descending: true)
        .limit(1)
        .snapshots();
  }

  //send image from camera in chat
  static Future<void> sendImage(ChatUser chatUser, File file) async {
    //get image extension
    final extension = file.path.split('.').last;
    //store the file with extenion
    final ref = firebaseStorage.ref().child(
        'images/{$getConverstionID(chatuser.id)}/${DateTime.now().millisecondsSinceEpoch}.$extension');
    //upload image
    await ref
        .putFile(file, SettableMetadata(contentType: 'image/$extension'))
        .then((p0) {
      log('Data Transferred: ${p0.bytesTransferred / 1000}kb');
    });
    //updating image in firestore
    final imgUrl = await ref.getDownloadURL();
    await sendMessage(chatUser, imgUrl, Type.image);
  }

  //for getting firebase messaging token
  static Future<void> getFirebaseMessagingToken() async {
    await messaging.requestPermission();
    await messaging.getToken().then((t) {
      if (t != null) {
        me.pushToken = t;
        log('Push token: $t');
      }
    });

    //foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('Message data: ${message.data}');
      if (message.notification != null) {
        log('Message notification: ${message.notification}');
      }
    });
  }

  //for sending push notification(calling rest api)
  static Future<void> sendPushNotificaton(ChatUser chatUser, String msg) async {
    try {
      final body = {
        "to": chatUser.pushToken,
        "notification": {
          "title": chatUser.name,
          "body": msg,
          "android_channel_id": "chats"
        },
        "data": {
          "some_data": "User ID: ${me.id}",
        }
      };
      var response =
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
                HttpHeaders.authorizationHeader:
                    'key=AAAApJjtTPI:APA91bHOdvvdnAL3aQecLsIy0xYqyrxwPXz1k9bVqnrgSPIqEOodoHH7YKBla-y4r9mVSL5fi9-Nuh3HvI6OJWL5-WcDBD0FqbhCjf5wup2rTXBE7AJjx-j5gIhcEYdewS0sdnoWlN_2'
              },
              body: jsonEncode(body));
      log('Response status: ${response.statusCode}');
      log('Response body: ${response.body}');
    } catch (e) {
      log('$e');
    }
  }

  //delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConverstionID(message.toId)}/messages/')
        .doc(message.send)
        .delete();
    if (message.type == Type.image)
      await firebaseStorage.refFromURL(message.msg).delete();
  }

  //adding chat user(Add button)
  static Future<bool> addChatUser(String email) async {
    final data = await firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      //user exists
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_contacts')
          .doc(data.docs.first.id)
          .set({});

      return true;
    } else {
      return false;
    }
  }

  //api to get all ID (my contacts)
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_contacts')
        .snapshots();
  }

  //for adding user when first message is send
  static Future<void> sendFirstMessage(
      ChatUser chatUser, String msg, Type type) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_contacts')
        .doc(user.uid)
        .set({}).then((value) => sendMessage(chatUser, msg, type));
  }
}
