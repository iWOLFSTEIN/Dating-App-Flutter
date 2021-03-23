import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/AppDrawer.dart';
import 'package:chat_app/Screens/UserProfile.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/utils/AdmobAdsUtils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavMatchScreen extends StatefulWidget {
  FavMatchScreen({Key key, this.allUsersDataList}) : super(key: key);

  final allUsersDataList;

  @override
  _FavMatchScreenState createState() => _FavMatchScreenState();
}

class _FavMatchScreenState extends State<FavMatchScreen>
    with AutomaticKeepAliveClientMixin<FavMatchScreen> {
  List allUserDataArray = [];

  List myFavoritesList = [];

  Stream<QuerySnapshot> myFavorites;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    for (var data in widget.allUsersDataList) {
      if (counter == 300) {
        break;
      }
      allUserDataArray.add(data);
      counter++;
    }
    counter = 0;
    allUserDataArray.shuffle();

    myFavorites = firestore
        .collection('Favorites')
        .doc(auth.currentUser.email)
        .collection('MyFavorites')
        .snapshots();

    myFavorites.listen((event) {
      for (var data in event.docs) {
        myFavoritesList.add(data.data()['email']);
      }
    });
    RewardedVideoAd.instance.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.failedToLoad) {
        myInterstitial
          ..load()
          ..show(
            anchorType: AnchorType.bottom,
            anchorOffset: 0.0,
            horizontalCenterOffset: 0.0,
          );
      }
    };
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
      if (mounted)
        setState(() {
          adsCount = event.data()['FavMatchScreenCount'];
        });
    });
  }

  showAd() async {
    try {
      var myad = RewardedVideoAd.instance;
      await myad.load(
          adUnitId:

              // RewardedVideoAd.testAdUnitId,

              AdmobRewardedAdsId,
          targetingInfo: TargetingInfo);

      await myad.show();
    } catch (e) {}
  }

  InterstitialAd myInterstitial = InterstitialAd(
    adUnitId: AdmobInterstitialAdsId,
    // InterstitialAd.testAdUnitId,
    targetingInfo: TargetingInfo,
    listener: (MobileAdEvent event) {
      print("InterstitialAd event is $event");
    },
  );

  int counter = 0;
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  var index = 0;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;

    var size = (height + width) / 2;

    List<Widget> list = [];

    for (var data in allUserDataArray) {
      if (data.data()['email'] != auth.currentUser.email &&
          !(data.data()['profilePic'] == '' ||
              data.data()['profilePic'] == null) &&
          !myFavoritesList.contains(data.data()['email'])) {
        var dataWidget = Container(
          alignment: Alignment.center,
          child: Material(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            elevation: 16,
            color:
                // Color(0xFF18344E),
                // Color(0xFF13293D),
                Colors.grey,
            child: Container(
                width: width * 90 / 100,
                height: height * 70 / 100,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  // border: Border.all(
                  //     width: width * 1 / 100,
                  //     color: Colors.white.withOpacity(0.4))
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        FutureBuilder(
                            future: FireStorageService.loadImage(
                                context, data.data()['profilePic']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Container(
                                  height: height * 55 / 100,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return Container(
                                height: height * 55 / 100,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                    image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: CachedNetworkImageProvider(
                                            snapshot.data.toString()))),
                              );
                            }),
                        InkWell(
                          onTap: () async {
                            try {
                              Navigator.push(
                                  context,
                                  FadePageRoute(UserProfile(
                                    userData: data.data(),
                                  )));
                              if (adsCount == 5) {
                                showAd();
                                await firestore
                                    .collection('AdsCount')
                                    .doc(auth.currentUser.email)
                                    .update({
                                  'FavMatchScreenCount': 0,
                                });
                              } else {
                                await firestore
                                    .collection('AdsCount')
                                    .doc(auth.currentUser.email)
                                    .update({
                                  'FavMatchScreenCount': adsCount + 1,
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
                              height: height * 55 / 100,
                              width: width * 90 / 100,
                              alignment: Alignment.bottomLeft,
                              padding: EdgeInsets.only(
                                  bottom: height * 3 / 100,
                                  left: width * 2 / 100,
                                  right: width * 2 / 100),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data.data()['name'],
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: size * 7 / 100),
                                  ),
                                  Text(
                                    (data.data()['age'] == '' ||
                                            data.data()['age'] == null)
                                        ? "unknown"
                                        : data.data()['age'],
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: size * 3.3 / 100),
                                  ),
                                ],
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.grey.withOpacity(0.0),
                                      Colors.grey.withOpacity(0.1),
                                      Colors.grey,
                                      // Color(0xFF18344E).withOpacity(0.0),
                                      // Color(0xFF18344E).withOpacity(0.1),
                                      // Color(0xFF18344E),
                                    ]),
                                //  color: Colors.green,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(5),
                                  topRight: Radius.circular(5.0),
                                ),
                              )),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: width * 4 / 100,
                        ),
                        Expanded(
                          child: RawMaterialButton(
                              splashColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 1.5 / 100,
                                  vertical: height * 0.75 / 100),
                              child: Material(
                                color: Colors.red,
                                elevation: 0,
                                shape: CircleBorder(),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: width * 4 / 100,
                                        vertical: height * 2 / 100),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: size * 8 / 100,
                                    ),
                                  ),
                                ),
                              ),
                              shape: CircleBorder(),
                              onPressed: () async {
                                setState(() {
                                  index++;
                                });
                                try {
                                  if (adsCount == 5) {
                                    showAd();
                                    await firestore
                                        .collection('AdsCount')
                                        .doc(auth.currentUser.email)
                                        .update({
                                      'FavMatchScreenCount': 0,
                                    });
                                  } else {
                                    await firestore
                                        .collection('AdsCount')
                                        .doc(auth.currentUser.email)
                                        .update({
                                      'FavMatchScreenCount': adsCount + 1,
                                    });
                                  }
                                } catch (e) {
                                  CoolAlert.show(
                                      context: context,
                                      type: CoolAlertType.error,
                                      text: 'An error occured.');
                                }
                              }),
                        ),
                        Expanded(
                          child: RawMaterialButton(
                              splashColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 1.5 / 100,
                                  vertical: height * 0.75 / 100),
                              child: Material(
                                color: Colors.blue,
                                elevation: 0,
                                shape: CircleBorder(),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: width * 4 / 100,
                                        vertical: height * 2 / 100),
                                    child: Icon(
                                      Icons.favorite_border,
                                      color: Colors.white,
                                      size: size * 8 / 100,
                                    ),
                                  ),
                                ),
                              ),
                              shape: CircleBorder(),
                              onPressed: () async {
                                setState(() {
                                  index++;
                                });

                                await firestore
                                    .collection('Favorites')
                                    .doc(auth.currentUser.email)
                                    .collection('MyFavorites')
                                    .doc(data.data()['email'])
                                    .set(data.data());

                                try {
                                  if (adsCount == 5) {
                                    showAd();
                                    await firestore
                                        .collection('AdsCount')
                                        .doc(auth.currentUser.email)
                                        .update({
                                      'FavMatchScreenCount': 0,
                                    });
                                  } else {
                                    await firestore
                                        .collection('AdsCount')
                                        .doc(auth.currentUser.email)
                                        .update({
                                      'FavMatchScreenCount': adsCount + 1,
                                    });
                                  }
                                } catch (e) {
                                  CoolAlert.show(
                                      context: context,
                                      type: CoolAlertType.error,
                                      text: 'An error occured.');
                                }
                              }),
                        ),
                        SizedBox(
                          width: width * 4 / 100,
                        ),
                      ],
                    )
                  ],
                )),
          ),
        );
        list.add(dataWidget);
        // counter++;
      }
    }

    //  counter = 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF13293D),
        title: Text('Find A Match'),
      ),
      backgroundColor: Color(0xFF13293D),
      body: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child: Container(
            key: ValueKey<int>(index),
            child: (index == list.length)
                ? Container(
                    child: Center(
                      child: Text(
                        'No Match Found!',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: size * 5 / 100),
                      ),
                    ),
                  )
                : list[index],
          )

          //  ),
          ),
      drawer: AppDrawer(),
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}
