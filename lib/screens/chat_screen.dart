import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:record/record.dart';

final _firestore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static const String screenRoute = 'chat_screen';

  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late User signedInUser;
  String? messageText;
  final record = Record();


  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        signedInUser = user;
        print(signedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }
   bool isPressed =false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow[900],
        title: Row(
          children: [
            Image.asset('images/logo.png', height: 25),
            SizedBox(width: 10),
            Text('MessageMe')
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pop(context);
            },
            icon: Icon(Icons.close),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MessageStreamBuilder(),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.orange,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;

                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        hintText: 'Write your message here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  TextButton(
                      onPressed: () async {
                        if(!isPressed){
                          isPressed = true;
                        }
                        if(isPressed){
                          await record.stop();
                          isPressed = false;
                        }
                        if (await record.hasPermission()) {
                          // Start recording
                          try {
                            await record.start(
                              path: 'E:/Study/Year 4 - SEM 8/Graduation Project/gp_chat_flutter/lib/records/myFile.m4a',
                              encoder: AudioEncoder.aacLc, // by default
                              bitRate: 128000, // by default
                              samplingRate: 44100, // by default
                            );
                          }
                          catch(err){
                            print(err);
                          }
                        }

                      },
                      child: Icon(
                          Icons.mic
                      )
                  ),
                  TextButton(
                    onPressed: () {
                      messageTextController.clear();
                      _firestore.collection('messages').add({
                        'text':messageText,
                        'sender':signedInUser.email,
                        'time':FieldValue.serverTimestamp(),
                        
                      });
                      print('${messageText}   ${signedInUser.email}');
                    },
                    child: Text(
                      'send',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageLine extends StatelessWidget {
  const MessageLine({this.text,this.sender,Key?key}) : super(key: key);

  final String? text;
  final String? sender;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            elevation: 5,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              bottomLeft:  Radius.circular(30),
              bottomRight:  Radius.circular(30)
            ),
            color: Colors.blue[800],
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10,horizontal: 20),
              child: Text(
                '${text}',
                style: TextStyle(fontSize: 15,color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageStreamBuilder extends StatelessWidget {
  const MessageStreamBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('messages').orderBy('time').snapshots(),
        builder: (context,snapshot) {
          List<MessageLine>  messageWidgets =[];
          if(!snapshot.hasData){
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.blue,
              ),
            );
          }
          final messages  = snapshot.data!.docs.reversed;
          for(var message in messages){
            final messageText = message.get('text');
            final messageSender = message.get('sender');
            final messageWidget = MessageLine( text:messageText,sender:messageSender);
            messageWidgets.add(messageWidget);
          }

          return Expanded(
            child: ListView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 10,vertical: 20),
              children: messageWidgets,
            ),
          );
        }
    );
  }
}
