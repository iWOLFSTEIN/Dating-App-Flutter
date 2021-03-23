import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/utils/FacebookAdsUtils.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:chat_app/Screens/FavMatchScreen.dart';
import 'package:chat_app/Screens/HomeScreen.dart';
import 'package:chat_app/Screens/LiveStreamingScreen.dart';
import 'package:chat_app/Services/DataProvider.dart';
import 'package:chat_app/Services/DatabaseHelper.dart';
import 'package:chat_app/pages/ReceiverScreen.dart';
import 'package:chat_app/pages/call.dart';
import 'package:chat_app/utils/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/Screens/ChatsScreen.dart';
import 'package:provider/provider.dart';

class PagesNavController extends StatefulWidget {
  PagesNavController({Key key, this.startingIndex}) : super(key: key);

  var startingIndex;

  @override
  _PagesNavControllerState createState() => _PagesNavControllerState();
}

class _PagesNavControllerState extends State<PagesNavController>
    with SingleTickerProviderStateMixin {
  var tabController;
  var indicatedColor = 0;

  Stream<QuerySnapshot> isCalling;

  Stream<QuerySnapshot> usersDataList;

  // Stream<QuerySnapshot> userMessages;

  // Stream<DocumentSnapshot> messagesSender;

  // Future localDatabaseChatUsers;

  FirebaseFirestore firestore = FirebaseFirestore.instance;

  FirebaseAuth auth = FirebaseAuth.instance;

  var callData;

  var usersDataArray;

  var receiverEmail;
  var callerEmail;

  // List<Map<String, dynamic>> chatUsers;

  @override
  void initState() {
    super.initState();
    FacebookAudienceNetwork.init(
        //testingId: "b7eced01-39d8-4929-8736-bc3a7e3df690"

        );
    tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex:
            (widget.startingIndex != null) ? widget.startingIndex : 0);

    tabController.addListener(() {
      setState(() {});
    });

    usersDataList = firestore.collection('users').snapshots();

    usersDataList.listen((event) {
      if (mounted) {
        setState(() {
          usersDataArray = event.docs;
          usersDataArray.shuffle();
        });
      }
    });

    // setState(() {});

    isCalling = firestore
        .collection('VideoCalls')
        .where('receiver', isEqualTo: auth.currentUser.email)
        .limit(1)
        .snapshots();

    if (!(isCalling == null)) {
      callerData(info: isCalling);
    }
  }

  callerData({var info}) async {
    info.listen((snapshot) {
      for (var data in snapshot.docs) {
        if (mounted) {
          setState(() {
            receiverEmail = data.data()['receiver'];
            callerEmail = data.data()['caller'];
            callData = data.data();
          });
        }
      }
    });
  }

  bool adLoaded = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    var size = (height + width) / 8;
    var dataProvider = Provider.of<DataProvider>(context);

    dataProvider.addListener(() {
      usersDataArray.shuffle();
    });

    if (!(receiverEmail == null)) {
      receiverEmail = null;

      return ReceiverScreen(
        screen: 'PagesNavController',
        callData: callData,
        callerEmail: callerEmail,
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          controller: tabController,
          children: [
            HomeScreen(
              usersDataList: usersDataArray,
            ),
            LiveStreamingScreen(),
            ChatsScreen(),
            FavMatchScreen(
              allUsersDataList: usersDataArray,
            ),
          ]),
      bottomNavigationBar: Container(
        color: Color(0xFF13293D),
        height: (adLoaded) ? height * 14.3 / 100 : height * 8 / 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Color(0xFF13293D),
                  border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.3)))),
              child: TabBar(
                  physics: NeverScrollableScrollPhysics(),
                  indicatorColor: Color(0xFF13293D),
                  controller: tabController,
                  tabs: <Widget>[
                    Padding(
                      padding: EdgeInsets.only(top: 15, bottom: 10),
                      child: Icon(
                        Icons.home,
                        color: (tabController.index == 0)
                            ? Colors.blue
                            : Colors.grey[350],
                        size: 30,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 15, bottom: 10),
                      child: Icon(
                        Icons.ondemand_video,
                        color: (tabController.index == 1)
                            ? Colors.blue
                            : Colors.grey[350],
                        size: 28,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 15, bottom: 10),
                      child: Icon(
                        Icons.chat_bubble,
                        color: (tabController.index == 2)
                            ? Colors.blue
                            : Colors.grey[350],
                        size: 27,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 15, bottom: 10),
                      child: Icon(
                        Icons.favorite,
                        color: (tabController.index == 3)
                            ? Colors.blue
                            : Colors.grey[350],
                        size: 27,
                      ),
                    ),
                  ]),
            ),
            Container(
              alignment: Alignment(0.5, 1),
              child: FacebookBannerAd(
                placementId: FacebookBannerAdsId,
                // Platform.isAndroid ? "YOUR_ANDROID_PLACEMENT_ID" : "YOUR_IOS_PLACEMENT_ID",
                bannerSize: BannerSize.STANDARD,
                listener: (result, value) {
                  switch (result) {
                    case BannerAdResult.ERROR:
                      {
                        //  if (this.mounted)
                        setState(() {
                          adLoaded = false;
                        });
                        print("Error: $value");
                        break;
                      }
                    case BannerAdResult.LOADED:
                      {
                        //  if (this.mounted)
                        setState(() {
                          adLoaded = true;
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
      ),
    );
  }
}
