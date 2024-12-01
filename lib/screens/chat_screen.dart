import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flash_chat_flutter/constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

late final DatabaseReference ref;
late User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final FirebaseDatabase rtdb;
  final messageTextController = TextEditingController();
  bool _isFirebaseInitialized = false;

  Future<void> initializeFirebase() async {
    final firebaseApp = await Firebase.initializeApp();
    rtdb = FirebaseDatabase.instanceFor(
      app: firebaseApp,
      databaseURL:
          'https://flash-chat-a66ae-default-rtdb.asia-southeast1.firebasedatabase.app/',
    );
    ref = rtdb.ref();
    setState(() {
      _isFirebaseInitialized = true;
    });
  }

  late String messageText;
  final _auth = FirebaseAuth.instance;

  void getMessages() async {
    var snapshots = await ref.child('messages');
    snapshots.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      var messages = data;
      if (messages != null) {
        print(messages);
      } else {
        print('No value here');
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    initializeFirebase();
  }

  void getCurrentUser() async {
    try {
      var user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white,
              ),
              onPressed: () {
                // _auth.signOut();
                // Navigator.pop(context);
                getMessages();
              }),
        ],
        title: Text(
          '⚡️Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: !_isFirebaseInitialized
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  MessageStram(),
                  Container(
                    decoration: kMessageContainerDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: messageTextController,
                            onChanged: (value) {
                              messageText = value;
                            },
                            decoration: kMessageTextFieldDecoration,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            messageTextController.clear();
                            await ref.child('messages').push().set({
                              'text': messageText,
                              'sender': loggedInUser.email,
                            });
                          },
                          child: Text(
                            'Send',
                            style: kSendButtonTextStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class MessageStram extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ref.child('messages').onValue,
      builder: (context, snapshot) {
        List<Text> messageWidets = [];
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return Center(
            child: Text('No messages available'),
          );
        }
        final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        final messages = data.entries.toList().reversed;

        return Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages.toList()[index].value;
              final messageText = message['text'] ?? 'No text';
              final messageSender = message['sender'] ?? 'Unknown sender';

              final currentUser = loggedInUser.email;

              return MessagesBuble(
                sender: messageSender,
                text: messageText,
                isMe: currentUser == messageSender,
              );
            },
          ),
        );
      },
    );
  }
}

class MessagesBuble extends StatelessWidget {
  const MessagesBuble({
    this.sender,
    this.text,
    this.isMe,
  });

  final String? sender;
  final String? text;
  final bool? isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe! ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(sender!),
          Material(
            borderRadius: isMe!
                ? BorderRadius.only(
                    topLeft: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30))
                : BorderRadius.only(
                    topRight: Radius.circular(30),
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
            elevation: 5,
            color: isMe! ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              child: Text(
                text!,
                style: TextStyle(
                  color: isMe! ? Colors.white : Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
