import 'dart:io';
import 'dart:math';
import 'package:chat_app/utils/FacebookAdsUtils.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/ImageHandlerScreen.dart';
import 'package:chat_app/Screens/ImageViewerScreen.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Services/BackendServices.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/pages/CallerScreen1.dart';
import 'package:chat_app/pages/ReceiverScreen.dart';
import 'package:chat_app/utils/AdmobAdsUtils.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class ConversationScreen extends StatefulWidget {
  ConversationScreen({
    Key key,
    this.userData,
    this.conversationEmail,
  }) : super(key: key);

  final userData;
  final conversationEmail;

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> isCalling;
  Stream<DocumentSnapshot> iBlockedStream;
  Stream<DocumentSnapshot> gotBlockedStream;

  bool iBlocked = false;
  bool gotBlocked = false;

  var receiverEmail;

  var callData;

  @override
  void initState() {
    super.initState();

    FacebookAudienceNetwork.init(
        // testingId: "b7eced01-39d8-4929-8736-bc3a7e3df690"

        );

    isCalling = _firestore
        .collection('VideoCalls')
        .where('receiver', isEqualTo: _auth.currentUser.email)
        .limit(1)
        .snapshots();

    if (!(isCalling == null)) {
      callerData(info: isCalling);
    }

    iBlockedStream = firestore
        .collection('Blocking')
        .doc(auth.currentUser.email)
        .collection('iBlocked')
        .doc(widget.userData['email'])
        .snapshots();

    iBlockedStreamData(iBlockedStreamEvent: iBlockedStream);

    gotBlockedStream = firestore
        .collection('Blocking')
        .doc(auth.currentUser.email)
        .collection('gotBlocked')
        .doc(widget.userData['email'])
        .snapshots();

    gotBlockedStreamData(gotBlockedStreamEvent: gotBlockedStream);
  }

  callerData({var info}) async {
    info.listen((snapshot) {
      for (var data in snapshot.docs) {
        setState(() {
          receiverEmail = data.data()['receiver'];
          callData = data.data();
        });
      }
    });
  }

  iBlockedStreamData({iBlockedStreamEvent}) {
    iBlockedStreamEvent.listen((event) {
      if (event.data() != null) {
        if (mounted) {
          setState(() {
            iBlocked = true;
          });
        }
      }
    });
  }

  gotBlockedStreamData({gotBlockedStreamEvent}) {
    gotBlockedStreamEvent.listen((event) {
      if (event.data() != null) {
        if (mounted) {
          setState(() {
            gotBlocked = true;
          });
        }
      }
    });
  }

  BackendServices backendServices = BackendServices();

  var messageText = TextEditingController();

  var textStyle = TextStyle(
    color: Colors.white,
  );

  bool isCallingTo = false;
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  lastMessageUpdate({message, chatPartner}) async {
    // if (message == '') {
    //   await firestore
    //       .collection('LastMessage')
    //       .doc(auth.currentUser.email)
    //       .collection('AllChatsLastMessages')
    //       .doc(chatPartner)
    //       .set({'lastMessage': ''});
    // } else
    if (message != null) {
      await firestore
          .collection('LastMessage')
          .doc(auth.currentUser.email)
          .collection('AllChatsLastMessages')
          .doc(chatPartner)
          .set({'lastMessage': message});
    }
  }

  bool doPadding = false;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    if (!(receiverEmail == null)) {
      receiverEmail = null;

      return ReceiverScreen(
        screen: 'ConversationScreen',
        callData: callData,
      );
    }
    return ModalProgressHUD(
      inAsyncCall: isCallingTo,
      child: Scaffold(
        backgroundColor: Color(0xFF13293D),
        appBar: AppBar(
          title: Text(
            widget.userData['name'],
          ),
          backgroundColor: Color(0xFF13293D),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: width * 6 / 100),
              child: InkWell(
                onTap: (iBlocked || gotBlocked)
                    ? () {}
                    : () async {
                        var chennelId = generateRandomString(16);

                        setState(() {
                          isCallingTo = true;
                        });

                        try {
                          await firestore
                              .collection('VideoCalls')
                              .doc(chennelId)
                              .set({
                            'caller': auth.currentUser.email,
                            'receiver': widget.userData['email'],
                            'chennelId': chennelId,
                            'isPicked': false,
                            'isDeclined': false,
                            'isAudio': false,
                            // 'isCalling': true
                          });
                        } catch (e) {
                          setState(() {
                            isCallingTo = false;
                          });

                          CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              title: 'Sorry!',
                              text: 'An error occurred.');
                        }

                        setState(() {
                          isCallingTo = false;
                        });

                        await _handleCameraAndMic(Permission.camera);
                        await _handleCameraAndMic(Permission.microphone);

                        Navigator.push(
                            context,
                            FadePageRoute(CallerScreen1(
                              chennelId: chennelId,
                              userData: widget.userData,
                            )));
                      },
                child: Icon(
                  Icons.videocam,
                  color: (iBlocked || gotBlocked) ? Colors.grey : Colors.white,
                  //  size: size * 10 / 100,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: width * 6 / 100),
              child: InkWell(
                onTap: (iBlocked || gotBlocked)
                    ? () {}
                    : () async {
                        var chennelId = generateRandomString(16);

                        setState(() {
                          isCallingTo = true;
                        });

                        try {
                          await firestore
                              .collection('VideoCalls')
                              .doc(chennelId)
                              .set({
                            'caller': auth.currentUser.email,
                            'receiver': widget.userData['email'],
                            'chennelId': chennelId,
                            'isPicked': false,
                            'isDeclined': false,
                            'isAudio': true,
                            // 'isCalling': true,
                          });
                        } catch (e) {
                          setState(() {
                            isCallingTo = false;
                          });

                          CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              title: 'Sorry!',
                              text: 'An error occurred.');
                        }
                        setState(() {
                          isCallingTo = false;
                        });

                        //  await _handleCameraAndMic(Permission.camera);
                        await _handleCameraAndMic(Permission.microphone);

                        Navigator.push(
                            context,
                            FadePageRoute(CallerScreen1(
                              chennelId: chennelId,
                              userData: widget.userData,
                            )));
                      },
                child: Icon(
                  Icons.phone,
                  color: (iBlocked || gotBlocked) ? Colors.grey : Colors.white,
                  //  size: size * 10 / 100,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: width * 6 / 100),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      FadePageRoute(UserProfile(
                        userData: widget.userData,
                      )));
                },
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  //  size: size * 10 / 100,
                ),
              ),
            ),
          ],
        ),
        body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('Messages')
                      .doc(_auth.currentUser.email)
                      .collection('AllMessages')
                      .doc(widget.conversationEmail)
                      .collection('Conversation')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                          child: Center(
                              child: Padding(
                        padding: EdgeInsets.only(top: heigth * 2 / 100),
                        child: Text(
                          'Loading...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            //  fontSize: size * 3 / 100
                          ),
                        ),
                      )));
                    }

                    User currentUser = _auth.currentUser;
                    var messages = snapshot.data.docs;
                    List<MessageText> messageWidget = [];
                    //  var lastMessage;
                    var counter = 0;
                    for (var message in messages) {
                      final sender = message.data()['sender'];
                      final text = message.data()['message'];
                      final imageAdress = message.data()['imageAdress'];

                      messageWidget.add(MessageText(
                          text: text,
                          sender: sender,
                          height: heigth,
                          width: width,
                          imageAdress: imageAdress,
                          userCheck:
                              sender == currentUser.email ? true : false));
                      if (counter == 0) {
                        lastMessageUpdate(
                          message: text,
                          chatPartner: widget.conversationEmail,
                        );
                      }
                      counter++;
                    }

                    return Expanded(
                      child: ListView(
                        reverse: true,
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 4 / 100,
                            vertical: heigth * 2.5 / 100),
                        children: messageWidget,
                      ),
                    );
                  }),
              (iBlocked || gotBlocked)
                  ? Container(
                      height: heigth * 9 / 100,
                      width: width,
                      decoration: BoxDecoration(
                          color: Color(0xFF18344E),
                          border: Border(
                              top: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ))),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "You can't reply to this conversation",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: size * 5.25 / 100),
                          ),
                          SizedBox(height: heigth * 0.25 / 100),
                          InkWell(
                            onTap: () async {
                              var url =
                                  "https://www.quora.com/What-can-I-do-when-I-can-t-reply-to-a-messenger-conversation";

                              try {
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  CoolAlert.show(
                                    context: context,
                                    type: CoolAlertType.warning,
                                    title: "Invalid Url!",
                                    text: "The url is not valid to launch.",
                                  );
                                }
                              } catch (e) {}
                            },
                            child: Text(
                              "Learn more",
                              style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                  fontSize: size * 5.25 / 100),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: EdgeInsets.only(
                          bottom:
                              // 0,
                              (doPadding) ? 0 : heigth * 1 / 100,
                          top: heigth * 0.5 / 100),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              SizedBox(width: width * 4 / 100),
                              Expanded(
                                child: Container(
                                  height: heigth * 6 / 100,
                                  width: width * 70 / 100,
                                  decoration: BoxDecoration(
                                      color: Color(0xFF18344E),
                                      borderRadius: BorderRadius.circular(50)),
                                  child: TextField(
                                    controller: messageText,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 3,
                                    minLines: 1,
                                    style: textStyle,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        hintText: 'Text',
                                        hintStyle: textStyle.copyWith(
                                          color: Colors.white.withOpacity(0.6),
                                        ),
                                        prefixIcon: IconButton(
                                          icon: Icon(Icons.image),
                                          onPressed: () async {
                                            try {
                                              var imageUploader =
                                                  await Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: (context) =>
                                                              ImageHandlerScreen(
                                                                senderEmail: _auth
                                                                    .currentUser
                                                                    .email,
                                                                receiverEmail:
                                                                    widget.userData[
                                                                        'email'],
                                                                isMessage: true,
                                                                isAVI: false,
                                                              )));

                                              if (imageUploader == true) {}
                                            } catch (e) {
                                              CoolAlert.show(
                                                  context: context,
                                                  type: CoolAlertType.error,
                                                  text: 'An error occured.'
                                                  //  e.toString()
                                                  );
                                            }
                                          },
                                          color: Colors.white.withOpacity(0.6),
                                        )),
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 2 / 100),
                              InkWell(
                                onTap: () async {
                                  try {
                                    if (messageText.text != null &&
                                        messageText.text != '') {
                                      var message = messageText.text;
                                      messageText.text = '';

                                      await backendServices.sendMessage(
                                        senderEmail: _auth.currentUser.email,
                                        receiverEmail: widget.userData['email'],
                                        messageText: message,
                                        imageAdress: '',
                                      );

                                      backendServices.updateConversationEmail(
                                        senderEmail: _auth.currentUser.email,
                                        receiverEmail: widget.userData['email'],
                                        lastMessage: message,
                                      );
                                      // if (messageSent) {}
                                    }
                                  } catch (e) {
                                    CoolAlert.show(
                                        context: context,
                                        type: CoolAlertType.error,
                                        text: 'An error occured.'
                                        //  e.toString()
                                        );
                                  }
                                },
                                child: Icon(Icons.send,
                                    color: Colors.white.withOpacity(0.6)),
                              ),
                              SizedBox(width: width * 4 / 100),
                            ],
                          ),
                          Container(
                            alignment: Alignment(0.5, 1),
                            child: FacebookBannerAd(
                              placementId: FacebookBannerAdsId,
                              bannerSize: BannerSize.STANDARD,
                              listener: (result, value) {
                                switch (result) {
                                  case BannerAdResult.ERROR:
                                    {
                                      setState(() {
                                        doPadding = false;
                                      });
                                      print("Error: $value");
                                      break;
                                    }
                                  case BannerAdResult.LOADED:
                                    {
                                      setState(() {
                                        doPadding = true;
                                      });
                                      print("Loaded: $value");
                                      break;
                                    }
                                  case BannerAdResult.CLICKED:
                                    print("Clicked: $value");
                                    break;
                                  case BannerAdResult.LOGGING_IMPRESSION:
                                    print("Logging Impression: $value");
                                    break;
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    )
            ]),
      ),
    );
  }

  String generateRandomString(int len) {
    var r = Random();
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(len, (index) => _chars[r.nextInt(_chars.length)])
        .join();
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}

class MessageText extends StatelessWidget {
  MessageText({
    Key key,
    @required this.text,
    @required this.sender,
    this.height,
    this.width,
    this.userCheck,
    this.imageAdress,
  }) : super(key: key);

  final text;
  final sender;
  final height;
  final width;
  final userCheck;
  final imageAdress;

  @override
  Widget build(BuildContext context) {
    if (!(imageAdress == null || imageAdress == '')) {
      return Column(
        crossAxisAlignment:
            userCheck ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Padding(
            padding: userCheck
                ? EdgeInsets.only(
                    top: height * .5 / 100,
                    bottom: height * .5 / 100,
                    right: width * 10 / 100)
                : EdgeInsets.only(
                    top: height * .5 / 100,
                    bottom: height * .5 / 100,
                    left: width * 10 / 100),
            child: Material(
              elevation: 8,
              borderRadius: userCheck
                  ? BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20))
                  : BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20)),
              color: userCheck ? Color(0xFF18344E) : Colors.blue,
              child: Container(
                height: height * 30 / 100,
                width: width * 60 / 100,
                padding: EdgeInsets.all(12),
                child: FutureBuilder(
                    future: FireStorageService.loadImage(context, imageAdress),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ImageViewerScreen(
                                        imageUrl: snapshot.data.toString(),
                                      )));
                        },
                        child: Container(
                          alignment: Alignment.bottomRight,
                          padding: EdgeInsets.only(
                              right: width * 3 / 100, bottom: height * 1 / 100),
                          child: Text(
                            'sent  ✓',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF13293D),
                                fontSize: ((width + height) / 4) * 4 / 100),
                          ),
                          decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              image: DecorationImage(
                                fit: BoxFit.cover,
                                image: CachedNetworkImageProvider(
                                    snapshot.data.toString()),
                              )),
                        ),
                      );
                    }),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment:
          userCheck ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Padding(
          padding: userCheck
              ? EdgeInsets.only(
                  top: height * .5 / 100,
                  bottom: height * .5 / 100,
                  right: width * 10 / 100)
              : EdgeInsets.only(
                  top: height * .5 / 100,
                  bottom: height * .5 / 100,
                  left: width * 10 / 100),
          child: Material(
            color: userCheck ? Color(0xFF18344E) : Colors.blue,
            elevation: 8,
            borderRadius: userCheck
                ? BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20))
                : BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: width * 5 / 100, vertical: height * 1.5 / 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$text",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: height * .5 / 100),
                  Text(
                    'sent  ✓',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: ((width + height) / 4) * 4 / 100),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
