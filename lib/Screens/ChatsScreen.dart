import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Screens/AppDrawer.dart';
import 'package:chat_app/Services/BackendServices.dart';
import 'package:chat_app/Services/DatabaseHelper.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/utils/FacebookAdsUtils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/Screens/ConversationScreen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:widget_animator/widget_animator.dart';

class ChatsScreen extends StatefulWidget {
  ChatsScreen({
    Key key,
    //  this.userMessagesList
  }) : super(key: key);

  // final userMessagesList;

  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with AutomaticKeepAliveClientMixin<ChatsScreen> {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  bool isDeleting = false;
  Stream<QuerySnapshot> userMessages;

  Stream<DocumentSnapshot> messagesSender;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 2;

    return ModalProgressHUD(
      inAsyncCall: isDeleting,
      child: Scaffold(
        backgroundColor: Color(0xFF13293D),
        appBar: AppBar(
          title: Text("Chats"),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: width * 5 / 100),
              child: InkWell(
                onTap: () async {
                  try {
                    setState(() {
                      isDeleting = true;
                    });

                    await firestore
                        .collection('Messages')
                        .doc(auth.currentUser.email)
                        .collection('AllMessages')
                        .orderBy('timestamp', descending: true)
                        .get()
                        .then((value) async {
                      for (var data in value.docs) {
                        await firestore
                            .collection('Messages')
                            .doc(auth.currentUser.email)
                            .collection('AllMessages')
                            .doc(data.data()['sentTo'])
                            .collection('Conversation')
                            .get()
                            .then((snapshot) {
                          for (DocumentSnapshot ds in snapshot.docs) {
                            ds.reference.delete();
                          }
                        });
                      }
                      await firestore
                          .collection('LastMessage')
                          .doc(auth.currentUser.email)
                          .collection('AllChatsLastMessages')
                          .get()
                          .then((snapshot) {
                        for (DocumentSnapshot ds in snapshot.docs) {
                          ds.reference.delete();
                        }
                      });
                    }).whenComplete(() async {
                      await firestore
                          .collection('Messages')
                          .doc(auth.currentUser.email)
                          .collection('AllMessages')
                          .get()
                          .then((snapshot) {
                        for (DocumentSnapshot ds in snapshot.docs) {
                          ds.reference.delete();
                        }
                      });
                    });

                    setState(() {
                      isDeleting = false;
                    });
                  } catch (e) {
                    CoolAlert.show(
                        context: context,
                        type: CoolAlertType.error,
                        text: 'An error occurred while deleting chats');
                  }
                },
                child: Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
            )
          ],
          backgroundColor: Color(0xFF13293D),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
                child: StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('Messages')
                        .doc(auth.currentUser.email)
                        .collection('AllMessages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          child: Center(
                              child: Text(
                            'Loading chats...',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: size * 3 / 100),
                          )),
                        );
                      }

                      int counterForAds = 0;
                      List<Widget> userWidgetList = [];
                      for (var user in snapshot.data.docs) {
                        userWidgetList.add(UserMessageWidget(
                          userData: user,
                        ));
                        counterForAds++;
                        if (counterForAds == 3) {
                          counterForAds = 0;
                          userWidgetList.add(
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 4 / 100,
                                  vertical: height * 1 / 100),
                              child: FacebookNativeAd(
                                placementId: FacebookNativeAdId,
                                // "236180364658625_236181534658508",
                                adType: NativeAdType.NATIVE_AD,
                                width: double.infinity,
                                height: 300,
                                backgroundColor: Colors.blue,
                                titleColor: Colors.white,
                                descriptionColor: Colors.white,
                                buttonColor: Colors.deepPurple,
                                buttonTitleColor: Colors.white,
                                buttonBorderColor: Colors.white,
                                keepAlive:
                                    true, //set true if you do not want adview to refresh on widget rebuild
                                keepExpandedWhileLoading:
                                    false, // set false if you want to collapse the native ad view when the ad is loading
                                expandAnimationDuraion:
                                    300, //in milliseconds. Expands the adview with animation when ad is loaded
                                listener: (result, value) {
                                  print("Native Ad: $result --> $value");
                                },
                              ),
                            ),
                          );
                        }
                      }

                      return (userWidgetList == [] || userWidgetList == null)
                          ? Container(
                              height: height,
                              child: Center(
                                child: Text(
                                  'No Chats Found!',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: size * 5 / 100),
                                ),
                              ))
                          : Column(
                              children: userWidgetList,
                            );
                    }))),
        drawer: AppDrawer(),
      ),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class UserMessageWidget extends StatefulWidget {
  UserMessageWidget({Key key, this.userData}) : super(key: key);

  var userData;

  @override
  _UserMessageWidgetState createState() => _UserMessageWidgetState();
}

class _UserMessageWidgetState extends State<UserMessageWidget> {
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 2;

    return WidgetAnimator(
        curve: Curves.easeIn,
        duration: Duration(milliseconds: 300),
        child: StreamBuilder<DocumentSnapshot>(
            stream: firestore
                .collection('users')
                .doc(widget.userData['sentTo'])
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container();
              }

              var userData = snapshot.data.data();

              return FutureBuilder(
                  future: FireStorageService.loadImage(
                      context, userData['profilePic']
                      //  profilePic
                      ),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    return InkWell(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ConversationScreen(
                              userData: userData,
                              conversationEmail: userData['email']);
                        }));
                      },
                      child: Container(
                        width: double.infinity,
                        height: height * 11 / 100,
                        child: Row(
                          children: [
                            SizedBox(
                              width: width * 5 / 100,
                            ),
                            CircleAvatar(
                                radius: size * 4.8 / 100,
                                backgroundColor: Colors.white,
                                backgroundImage: CachedNetworkImageProvider(
                                    snapshot.data.toString())),
                            SizedBox(
                              width: width * 3 / 100,
                            ),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['name'],
                                    style: TextStyle(
                                        fontSize: size * 3.3 / 100,
                                        color: Colors.white),
                                  ),
                                  SizedBox(height: height * 1 / 100),
                                  Text(
                                    (widget.userData['lastMessage'].length < 18)
                                        ? widget.userData['lastMessage']
                                            .toLowerCase()
                                        : widget.userData['lastMessage']
                                                .substring(0, 17)
                                                .toLowerCase() +
                                            '...',
                                    // 'hello',
                                    style: TextStyle(
                                        fontSize: size * 2.7 / 100,
                                        color: Colors.white.withOpacity(0.4)),
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              width: width * 1 / 100,
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "12:30 PM",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: size * 2 / 100),
                                  ),
                                  SizedBox(height: 15),
                                  CircleAvatar(
                                    radius: size * 1.5 / 100,
                                    backgroundColor: Color(0xFF13293D),
                                    child: StreamBuilder<DocumentSnapshot>(
                                        stream: firestore
                                            .collection('LastMessage')
                                            .doc(auth.currentUser.email)
                                            .collection('AllChatsLastMessages')
                                            .doc(widget.userData['sentTo'])
                                            .snapshots(),
                                        builder: (context, snapshot) {
                                          if (!snapshot.hasData) {
                                            return Opacity(
                                              opacity: 0.0,
                                              child: CircleAvatar(
                                                radius: size * 1.5 / 100,
                                                child: Text(
                                                  "1",
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          size * 1.8 / 100),
                                                ),
                                                backgroundColor:
                                                    Color(0xFF0DE75A),
                                              ),
                                            );
                                          }
                                          return Opacity(
                                            opacity: (snapshot.data.data() ==
                                                    null)
                                                ? 1.0
                                                : (snapshot.data
                                                            .data()[
                                                                'lastMessage']
                                                            .compareTo(widget
                                                                    .userData[
                                                                'lastMessage']) !=
                                                        0)
                                                    ? 1.0
                                                    : 0.0,
                                            child: CircleAvatar(
                                              radius: size * 1.5 / 100,
                                              child: Text(
                                                "1",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: size * 1.8 / 100),
                                              ),
                                              backgroundColor:
                                                  Color(0xFF0DE75A),
                                            ),
                                          );
                                        }),
                                  )
                                ]),
                            SizedBox(
                              width: width * 5 / 100,
                            ),
                          ],
                        ),
                      ),
                    );
                  });
            }));
  }
}
