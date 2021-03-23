import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/AppDrawer.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Services/DataProvider.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseProfilePicsModel.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/Services/SignInServices.dart';
import 'package:chat_app/utils/AdmobAdsUtils.dart';
import 'package:chat_app/utils/FacebookAdsUtils.dart';
import 'package:chat_app/utils/settings.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:facebook_audience_network/facebook_audience_network.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//enum Gender { Male, Female, Both }

class HomeScreen extends StatefulWidget {
  HomeScreen({
    Key key,
    this.usersDataList,
  }) : super(key: key);

  var usersDataList;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen> {
  Random rnd = Random();
  int counter = 0;

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final db = FirebaseGetUserData();

  List dataList = [];

  dynamic gender = 'Both';
  @override
  void initState() {
    super.initState();
    FacebookAudienceNetwork.init(
        //  testingId: "b7eced01-39d8-4929-8736-bc3a7e3df690"

        );

    getAdsCount();
  }

  Stream<DocumentSnapshot> streamAdsCount;

  int adsCount = 0;

  getAdsCount() {
    streamAdsCount = firestore
        .collection('AdsCount')
        .doc(auth.currentUser.email)
        .snapshots();

    streamAdsCount.listen((event) {
      if (mounted) {
        setState(() {
          adsCount = event.data()['HomeScreenCount'];
        });
      }
    });
  }

  showAd() {
    FacebookRewardedVideoAd.loadRewardedVideoAd(
      placementId: FacebookRewardedAdsId,
      listener: (result, value) {
        if (result == RewardedVideoAdResult.LOADED)
          FacebookRewardedVideoAd.showRewardedVideoAd();
        if (result == RewardedVideoAdResult.VIDEO_COMPLETE)
          print("Video completed");
        if (result == RewardedVideoAdResult.ERROR) {
          FacebookInterstitialAd.loadInterstitialAd(
            placementId: FacebookInterstitialAdsId,
            listener: (result, value) {
              if (result == InterstitialAdResult.LOADED)
                FacebookInterstitialAd.showInterstitialAd(delay: 5000);
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    //   debugPrint(gender.toString() + 'This is my gender');
    List<Stack> widgetsContainerList = [];

    if (widget.usersDataList == null) {
      return Container(
          color: Color(0xFF13293D),
          child: Center(child: CircularProgressIndicator()));
    }

    for (var data in widget.usersDataList) {
      if (counter == 120) {
        break;
      }

      if (data.data()['gender'] == gender) {
        if (data.data()['email'] != auth.currentUser.email &&
            !(data.data()['profilePic'] == '' ||
                data.data()['profilePic'] == null)) {
          var userData = data.data();

          var widget = Stack(
            children: [
              (data.data()['profilePic'] == '' ||
                      data.data()['profilePic'] == null)
                  ? Container(
                      decoration: BoxDecoration(
                          color: Colors.black,
                          border:
                              Border.all(color: Color(0xFF13293D), width: 1.25),
                          image: DecorationImage(
                              image: AssetImage('images/user1.png'),
                              fit: BoxFit.cover)),
                    )
                  : FutureBuilder(
                      future: FireStorageService.loadImage(
                          context, data.data()['profilePic']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(
                                  color: Color(0xFF13293D), width: 1.25),
                            ),
                          );
                        }
                        return InkWell(
                          onTap: () async {
                            try {
                              Navigator.push(
                                  context,
                                  FadePageRoute(UserProfile(
                                    userData: userData,
                                  )));
                              if (adsCount == 5) {
                                showAd();
                                await firestore
                                    .collection('AdsCount')
                                    .doc(auth.currentUser.email)
                                    .update({
                                  'HomeScreenCount': 0,
                                });
                              } else {
                                await firestore
                                    .collection('AdsCount')
                                    .doc(auth.currentUser.email)
                                    .update({
                                  'HomeScreenCount': adsCount + 1,
                                });
                              }
                            } catch (e) {
                              CoolAlert.show(
                                  context: context,
                                  type: CoolAlertType.error,
                                  text: 'An error occured.');
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                    color: Color(0xFF13293D), width: 1.25),
                                image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        snapshot.data.toString()),
                                    fit: BoxFit.cover)),
                          ),
                        );
                      }),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: width * 1 / 100, bottom: heigth * 0.3 / 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF0DE75A),
                        radius: size * 1.5 / 100,
                      ),
                      SizedBox(
                        width: width * 0.5 / 100,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 1.5 / 100,
                            vertical: heigth * 0.2 / 100),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: Text(
                          // "Alison",
                          data.data()['name'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 4.5 / 100,
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          );

          widgetsContainerList.add(widget);
          counter++;
        }
      } else if (gender == 'Both') {
        if (data.data()['email'] != auth.currentUser.email &&
            !(data.data()['profilePic'] == '' ||
                data.data()['profilePic'] == null)) {
          var userData = data.data();

          var widget = Stack(
            children: [
              (data.data()['profilePic'] == '' ||
                      data.data()['profilePic'] == null)
                  ? Container(
                      decoration: BoxDecoration(
                          color: Colors.black,
                          border:
                              Border.all(color: Color(0xFF13293D), width: 1.25),
                          image: DecorationImage(
                              image: AssetImage('images/user1.png'),
                              fit: BoxFit.cover)),
                    )
                  : FutureBuilder(
                      future: FireStorageService.loadImage(
                          context, data.data()['profilePic']),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: Border.all(
                                  color: Color(0xFF13293D), width: 1.25),
                            ),
                          );
                        }
                        return InkWell(
                          onTap: () async {
                            try {
                              Navigator.push(
                                  context,
                                  FadePageRoute(UserProfile(
                                    userData: userData,
                                  )));
                              if (adsCount == 5) {
                                showAd();
                                await firestore
                                    .collection('AdsCount')
                                    .doc(auth.currentUser.email)
                                    .update({
                                  'HomeScreenCount': 0,
                                });
                              } else {
                                await firestore
                                    .collection('AdsCount')
                                    .doc(auth.currentUser.email)
                                    .update({
                                  'HomeScreenCount': adsCount + 1,
                                });
                              }
                            } catch (e) {
                              CoolAlert.show(
                                  context: context,
                                  type: CoolAlertType.error,
                                  text: 'An error occured.');
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                    color: Color(0xFF13293D), width: 1.25),
                                image: DecorationImage(
                                    image: CachedNetworkImageProvider(
                                        snapshot.data.toString()),
                                    fit: BoxFit.cover)),
                          ),
                        );
                      }),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: width * 1 / 100, bottom: heigth * 0.3 / 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Color(0xFF0DE75A),
                        radius: size * 1.5 / 100,
                      ),
                      SizedBox(
                        width: width * 0.5 / 100,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 1.5 / 100,
                            vertical: heigth * 0.2 / 100),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                        child: Text(
                          // "Alison",
                          data.data()['name'],
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: size * 4.5 / 100,
                              fontFamily: 'Mulish',
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          );

          widgetsContainerList.add(widget);
          counter++;
        }
      }
    }

    counter = 0;

    var dataProvider = Provider.of<DataProvider>(context);
    //  dataProvider.addListener(() {
    //   widget.usersDataList.shuffle();
    // });

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      appBar: AppBar(
          backgroundColor: Color(0xFF13293D),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                  top: heigth * 2.7 / 100, right: width * 4 / 100),
              child: GestureDetector(
                onTap: () {
                  dataProvider.refresher = !dataProvider.refresher;
                  //  setState(() {});
                },
                child: Text(
                  'Refresh',
                  style: TextStyle(
                      color: Color(0xFF0DE75A),
                      fontWeight: FontWeight.bold,
                      fontSize: size * 5.5 / 100),
                ),
              ),
            )
          ],
          title: Text(
            "Meet People",
          )),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
                top: heigth * 1 / 100,
                bottom: heigth * 1 / 100,
                left: width * 2 / 100),
            child: Container(
              height: heigth * 5 / 100,
              width: width * 60 / 100,
              child: Row(
                children: [
                  Expanded(
                      child: InkWell(
                    onTap: () {
                      setState(() {
                        gender = 'Both';
                      });
                    },
                    child: Container(
                      child: Center(
                          child: Text(
                        'Both',
                        style: TextStyle(
                            color: (gender == 'Both')
                                ? Colors.white
                                : Colors.white.withOpacity(0.4)),
                      )),
                      decoration: BoxDecoration(
                          color: (gender == 'Both')
                              ? Color(0xFF20D5B7)
                              : Color(0xFF20D5B7).withOpacity(0.0),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              bottomLeft: Radius.circular(20))),
                    ),
                  )),
                  Expanded(
                      child: InkWell(
                    onTap: () {
                      setState(() {
                        gender = 'Female';
                      });

                      // changeProvider.incrementer = 0;
                    },
                    child: Container(
                        child: Center(
                            child: Text(
                          'Female',
                          style: TextStyle(
                            color: (gender == 'Female')
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        )),
                        decoration: BoxDecoration(
                          color: (gender == 'Female')
                              ? Color(0xFF20D5B7)
                              : Color(0xFF20D5B7).withOpacity(0.0),
                          border: Border(
                            left: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                            ),
                            right: BorderSide(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                        )),
                  )),
                  Expanded(
                      child: InkWell(
                    onTap: () {
                      setState(() {
                        gender = 'Male';
                      });
                    },
                    child: Container(
                      child: Center(
                          child: Text(
                        'Male',
                        style: TextStyle(
                            color: (gender == 'Male')
                                ? Colors.white
                                : Colors.white.withOpacity(0.4)),
                      )),
                      decoration: BoxDecoration(
                          color: (gender == 'Male')
                              ? Color(0xFF20D5B7)
                              : Color(0xFF20D5B7).withOpacity(0.0),
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20),
                              bottomRight: Radius.circular(20))),
                    ),
                  )),
                ],
              ),
              decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20))),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: widgetsContainerList,
            ),
          ),
        ],
      ),
      drawer: AppDrawer(),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
