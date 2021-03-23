import 'dart:core';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Navigations/PagesNavController.dart';
import 'package:chat_app/Screens/HomeScreen.dart';
import 'package:chat_app/Screens/ImageHandlerScreen.dart';
import 'package:chat_app/Screens/UserImageViewer.dart';
import 'package:chat_app/Services/BackendServices.dart';
import 'package:chat_app/Services/DataProvider.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseProfilePicsModel.dart';
import 'package:chat_app/Services/FirebaseUserData.dart';
import 'package:chat_app/Services/LocationServices.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:provider/provider.dart';
import 'package:country_list_pick/country_list_pick.dart';

class EditProfileScreen extends StatefulWidget {
  EditProfileScreen({Key key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // UserLocation userLocation = new UserLocation();

  var ageFormKey = GlobalKey<FormState>();
  var heightFormKey = GlobalKey<FormState>();

  // var userCurrentLocation;

  // userLocationFunc() async {
  //   var location;
  //   try {
  //     location = await userLocation.getUserLocation();
  //   } catch (e) {
  //     CoolAlert.show(
  //         context: context, type: CoolAlertType.error, text: e.toString());
  //   }

  //   setState(() {
  //     userCurrentLocation = location;
  //   });
  // }

  Stream<FirebaseUserData> currentUserData;
  FirebaseGetUserData db = FirebaseGetUserData();

  FirebaseGetProfilePicsModel storage = FirebaseGetProfilePicsModel();
  FirebaseAuth auth = FirebaseAuth.instance;
  var name;
  // = TextEditingController();
  var username;
  // = TextEditingController();
  var bio;
  // = TextEditingController();
  var gender;
  var interestedIn;
  var location;
  var ethnicity;
  var age;
  // = TextEditingController();
  var bodyHeight;
  // = TextEditingController();
  var bodyType;
  var interests = TextEditingController();

  userDataToVariables(dataStream) async {
    try {
      // var location = await userLocation.getUserLocation();
      dataStream.listen((event) {
        setState(() {
          name = event.name;
          username = event.username;

          bio = event.bio;
          gender = event.gender;

          interestedIn = event.interestedIn;
          location = event.location;

          ethnicity = event.ethnicity;
          age = event.age;

          bodyHeight = event.height;
          bodyType = event.bodyType;

          interests.text = event.interests;

          //  userCurrentLocation = (location != null) ? location : event.location;

          location = event.location;
        });
      });
    } catch (e) {
      CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: 'Sorry!',
          text: 'An error occurred.');
    }
  }

  BackendServices backendServices = BackendServices();
  @override
  void initState() {
    super.initState();

    currentUserData = db.streamUserData(email: auth.currentUser.email);
    userDataToVariables(currentUserData);
    //  userLocationFunc();
    // userCurrentLocation =
    //     (userCurrentLocation == null) ? location : userCurrentLocation;
  }

  warningMessage({context, warning}) {
    CoolAlert.show(
      context: context,
      type: CoolAlertType.warning,
      text: warning,
    );
    setState(() {
      isSaving = false;
    });
  }

  List<FutureBuilder> list = [];
  var imageCount = 0;
  bool isSaving = false;
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    debugPrint(auth.currentUser.email.toString());

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      body: StreamBuilder<FirebaseProfilePicsModel>(
          stream: storage.streamUserData(email: auth.currentUser.email),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            var imagesFromFirebaseStorage = snapshot.data.otherPics.length;
            imageCount = imagesFromFirebaseStorage;
            List<FutureBuilder> imageList = [
              FutureBuilder(
                  future: null,
                  builder: (context, snapshot) {
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: width * 0.4 / 100),
                      child: InkWell(
                        onTap: () async {
                          if (!(imageCount < 10)) {
                            CoolAlert.show(
                              context: context,
                              type: CoolAlertType.info,
                              text:
                                  'You are using free version of this app, so you can upload only 10 pics. To upload more switch to premium, or try deleting some pics.',
                            );
                          } else {
                            var check = await Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return ImageHandlerScreen(
                                isAVI: false,
                              );
                            }));
                            if (check == true) {
                              CoolAlert.show(
                                context: context,
                                type: CoolAlertType.success,
                                text: 'Image Uploaded Successfully.',
                              );
                            }
                          }
                        },
                        child: Container(
                          color: Color(0xFF18344E),
                          width: width * 22.5 / 100,
                          height: heigth * 11 / 100,
                          child: Center(
                            child: Icon(Icons.add_a_photo,
                                color: Colors.white.withOpacity(0.3),
                                size: size * 12 / 100),
                          ),
                        ),
                      ),
                    );
                  }),
            ];

            if (!(snapshot.data.otherPics == []))
              for (var image in snapshot.data.otherPics) {
                var imageWidget = FutureBuilder(
                    future: FireStorageService.loadImage(context, image),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.4 / 100),
                          child: Container(
                              width: width * 22.5 / 100,
                              child: Center(
                                child: CircularProgressIndicator(),
                              )),
                        );
                      }

                      return Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: width * 0.4 / 100),
                        child: Container(
                            color: Colors.black,
                            width: width * 22.5 / 100,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    FadePageRoute(UserImageViewer(
                                      imageAdress: snapshot.data.toString(),
                                      imageReference: image,
                                      // condition: false,
                                    )));
                              },
                              child: Image.network(
                                snapshot.data.toString(),
                                fit: BoxFit.cover,
                              ),
                            )),
                      );
                    });
                //setState(() {
                imageList.add(imageWidget);
                //});
              }
            //  imageList = list;

            list = imageList;
            return ModalProgressHUD(
              inAsyncCall: isSaving,
              child: CustomScrollView(slivers: [
                SliverAppBar(
                  title: Text("Edit Screen"),
                  // floating: true,
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(
                          top: heigth * 2.25 / 100, right: width * 8 / 100),
                      child: InkWell(
                        onTap: () async {
                          setState(() {
                            isSaving = true;
                          });
                          try {
                            bool isUsernameValid =
                                await backendServices.usernameCheck(
                                    username: username,
                                    email: auth.currentUser.email);

                            if (snapshot.data.profilePic == '') {
                              warningMessage(
                                  context: context,
                                  warning:
                                      "Please select a profile pic first.");
                            } else if (!isUsernameValid) {
                              warningMessage(
                                  context: context,
                                  warning:
                                      "Username already exist. Please choose another one.");
                            } else if (username == '') {
                              warningMessage(
                                  context: context,
                                  warning: "please choose a valid username.");
                            } else if (bio == '') {
                              warningMessage(
                                  context: context,
                                  warning: "please write something in bio.");
                            } else if (gender == '') {
                              warningMessage(
                                  context: context,
                                  warning: "please select your gender.");
                            } else {
                              backendServices.updateUserProfileData(
                                  email: auth.currentUser.email,
                                  bio: bio,
                                  gender: gender,
                                  interestedIn: interestedIn,
                                  ethnicity: ethnicity,
                                  age: age,
                                  height: bodyHeight,
                                  bodyType: bodyType,
                                  interests: interests.text,
                                  name: name,
                                  location: location,
                                  // userCurrentLocation,
                                  username: username);
                              setState(() {
                                isSaving = false;
                              });
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  FadePageRoute(PagesNavController(
                                    startingIndex: 0,
                                  )),
                                  (route) => false);
                            }
                          } catch (e) {
                            CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              title: 'Sorry!',
                              text:
                                  // e.toString(),
                                  'An error occurred.',
                            );
                            setState(() {
                              isSaving = false;
                            });
                          }
                        },
                        child: Text(
                          "Save",
                          style: TextStyle(
                              color: Color(0xFF0DE75A),
                              fontSize: size * 6.5 / 100,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                    //sfjldfsadfalkjfasjjjj
                  ],
                  pinned: true,
                  expandedHeight: heigth / 2.3,
                  backgroundColor: Color(0xFF13293D),

                  flexibleSpace: FlexibleSpaceBar(
                    background: Padding(
                      padding: EdgeInsets.only(top: heigth * 11.7 / 100),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: width * 5 / 100),
                              child: Row(
                                children: [
                                  // Expanded(child: Container()),
                                  InkWell(
                                    onTap: () async {
                                      var showUploaded = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ImageHandlerScreen(
                                                    isAVI: true,
                                                  )));
                                      if (showUploaded == true) {
                                        CoolAlert.show(
                                          context: context,
                                          type: CoolAlertType.success,
                                          text: 'Image Uploaded Successfully.',
                                        );
                                      }
                                    },
                                    child: (snapshot.data.profilePic == '')
                                        ? CircleAvatar(
                                            backgroundImage:
                                                AssetImage('images/user.png'),
                                            radius: size * 17 / 100,
                                            backgroundColor: Color(0xFF13293D),
                                            child: Container(
                                              child: Center(
                                                  child: Opacity(
                                                      opacity: 0.4,
                                                      child: Icon(
                                                          Icons.photo_camera,
                                                          size: size *
                                                              12 /
                                                              100))),
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      width: width * 0.2 / 100,
                                                      color: Colors.white),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          75)),
                                            ),
                                          )

                                        // AssetImage('images/user.png')
                                        : FutureBuilder(
                                            future:
                                                FireStorageService.loadImage(
                                                    context,
                                                    snapshot.data.profilePic),
                                            builder: (context, snapshot) {
                                              if (!(snapshot.hasData)) {
                                                // debugPrint(
                                                //     'Attention please this is image adress: ' +
                                                //         snapshot.data.toString());
                                                return CircleAvatar(
                                                  backgroundColor:
                                                      Color(0xFF13293D),
                                                  radius: size * 17 / 100,
                                                  child: Container(
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            width: width *
                                                                0.2 /
                                                                100,
                                                            color:
                                                                Colors.white),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(75)),
                                                  ),
                                                );
                                              }
                                              return CircleAvatar(
                                                backgroundImage: NetworkImage(
                                                    snapshot.data.toString()),
                                                radius: size * 17 / 100,
                                                backgroundColor:
                                                    Color(0xFF13293D),
                                                child: Container(
                                                  child: Center(
                                                      child: Opacity(
                                                          opacity: 0.4,
                                                          child: Icon(
                                                              Icons
                                                                  .photo_camera,
                                                              size: size *
                                                                  12 /
                                                                  100))),
                                                  decoration: BoxDecoration(
                                                      border: Border.all(
                                                          width:
                                                              width * 0.2 / 100,
                                                          color: Colors.white),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              75)),
                                                ),
                                              );
                                            }),
                                  ),

                                  SizedBox(width: width * 3 / 100),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                          onTap: () {
                                            showAlertDialogue(context,
                                                name: 'Edit Name',
                                                widget: TextField(
                                                  //  controller: name,
                                                  maxLength: 30,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      name = value;
                                                    });
                                                  },
                                                  // maxLines: 3,
                                                  minLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Mulish'),
                                                ));
                                          },
                                          child: Text(
                                              //   "Alison Hazzard"
                                              (name == '')
                                                  ? "Name"
                                                  : (name == null)
                                                      ? 'Unavailable'
                                                      : (name.length > 12)
                                                          ? name.substring(
                                                                  0, 12) +
                                                              '...'
                                                          : name,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: size * 8.5 / 100,
                                                  fontFamily: 'Mulish'))),
                                      SizedBox(
                                        height: heigth * 2 / 100,
                                      ),
                                      InkWell(
                                          onTap: () {
                                            showAlertDialogue(context,
                                                name: 'Edit Username',
                                                widget: TextField(
                                                  //   controller: username,
                                                  maxLength: 40,
                                                  keyboardType:
                                                      TextInputType.multiline,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      username = '@' +
                                                          value
                                                              .replaceAll(
                                                                  " ", "")
                                                              .toLowerCase();
                                                    });
                                                  },
                                                  minLines: 1,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Mulish'),
                                                ));
                                          },
                                          child: Text(
                                              // "@alison_hazzard1234"
                                              (username == '')
                                                  ? '@' + auth.currentUser.email
                                                  : (username == null)
                                                      ? 'Unavailable'
                                                      : (username.length > 23)
                                                          ? username.substring(
                                                                  0, 23) +
                                                              '...'
                                                          : username,
                                              style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  fontSize: size * 5.5 / 100)))
                                    ],
                                  ),
                                  //  Expanded(child: Container()),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: heigth * 3.5 / 100,
                            ),
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding:
                                        EdgeInsets.only(left: width * 5 / 100),
                                    child: Text("Photos",
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.4),
                                            fontSize: size * 7 / 100)),
                                  ),
                                  SizedBox(
                                    height: heigth * 2 / 100,
                                  ),
                                  Container(
                                    //color: Colors.orange,
                                    height: heigth * 11 / 100,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: list,
                                    ),
                                  ),
                                ])
                          ]),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: width * 4 / 100,
                        right: width * 4 / 100,
                        bottom: heigth * 2 / 100,
                        top: heigth * 2 / 100),
                    child: Column(
                      children: [
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Edit Bio',
                                  widget: TextField(
                                    // controller: bio,
                                    maxLength: 300,
                                    keyboardType: TextInputType.multiline,
                                    onChanged: (value) {
                                      setState(() {
                                        bio = value;
                                      });
                                    },
                                    maxLines: 3,
                                    minLines: 1,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'Mulish'),
                                  ));
                            },
                            child: buildColumnText(
                              'Bio',
                              size,
                              heigth,
                              width,
                              data: (bio == '')
                                  ? 'write something about you'
                                  : bio,
                            )),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Gender',
                                  check: true,
                                  widget: Container(
                                    height: heigth * 10 / 100,
                                    child: Column(children: [
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            gender = "Male";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Male",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            gender = 'Female';
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Female",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                    ]),
                                  ));
                            },
                            child: buildColumnText(
                              'Gender',
                              size,
                              heigth,
                              width,
                              data: (gender == '')
                                  ? 'choose your gender'
                                  : gender,
                            )),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Interested In',
                                  check: true,
                                  widget: Container(
                                    height: heigth * 10 / 100,
                                    child: Column(children: [
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            interestedIn = "Men";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Men",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            interestedIn = "Women";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Women",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            interestedIn = 'Men and Women';
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Men and Women",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      ))
                                    ]),
                                  ));
                            },
                            child: buildColumnText(
                              'Interested In',
                              size,
                              heigth,
                              width,
                              data: (interestedIn == '')
                                  ? 'select your audience'
                                  : interestedIn,
                            )),
                        SizedBox(height: heigth * 2 / 100),
                        buildColumnLocation(
                          'Location',
                          size,
                          heigth,
                          width,
                          // data: (location == '' ||
                          //         location == null)
                          //     ? 'unavailable'
                          //     : location,
                          //  Container(),
                          //  (userCurrentLocation == '' ||
                          //     userCurrentLocation == null)
                          // ? 'unavailable'
                          // : userCurrentLocation,
                        ),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Ethnicity',
                                  check: true,
                                  widget: Container(
                                    height: heigth * 20 / 100,
                                    child: Column(children: [
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            ethnicity = "Asian";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Asian",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            ethnicity = "Europian";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Europian",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            ethnicity = "American";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("American",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            ethnicity = "East American";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("East American",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            ethnicity = "African";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("African",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            ethnicity = "Australian";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Astralian",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                    ]),
                                  ));
                            },
                            child: buildColumnText(
                                'Ethnicity', size, heigth, width,
                                data: (ethnicity == '')
                                    ? "choose your region"
                                    : ethnicity)),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Age',
                                  widget: Form(
                                    key: ageFormKey,
                                    child: TextFormField(
                                        maxLength: 2,
                                        // controller: age,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          // if (ageFormKey.currentState.validate()) {
                                          setState(() {
                                            age = value.toString() + " years";
                                          });
                                          //}
                                        },
                                        validator: (value) {
                                          // int integerType = 0000;
                                          if (value.isEmpty) {
                                            return "This field can't be empty";
                                          } else if (!(int.parse(value) >= 16 &&
                                              int.parse(value) <= 80)) {
                                            return 'Age must be between 16 and 80';
                                          }
                                        },
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Mulish',
                                        ),
                                        decoration: InputDecoration(
                                            hintText: 'write age in years',
                                            hintStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.4),
                                              fontFamily: 'Mulish',
                                            ))),
                                  ));
                            },
                            child: buildColumnText('Age', size, heigth, width,
                                data:
                                    (age == '') ? 'write age in years' : age)),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Height',
                                  widget: Form(
                                    key: heightFormKey,
                                    child: TextFormField(
                                        //  controller: bodyHeight,
                                        maxLength: 3,
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {
                                            bodyHeight =
                                                value.toString() + " cm";
                                          });
                                        },
                                        validator: (value) {
                                          if (value.isEmpty) {
                                            return "This field can't be empty";
                                          } else if (!(int.parse(value) >= 60 &&
                                              int.parse(value) <= 300)) {
                                            return 'Age must be between 60 and 300';
                                          }
                                        },
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'Mulish',
                                        ),
                                        decoration: InputDecoration(
                                            hintText: 'write height in cm',
                                            hintStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.4),
                                              fontFamily: 'Mulish',
                                            ))),
                                  ));
                            },
                            child: buildColumnText(
                                'Height', size, heigth, width,
                                data: (bodyHeight == '')
                                    ? 'write height in cm'
                                    : bodyHeight)),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                            onTap: () {
                              showAlertDialogue(context,
                                  name: 'Gender',
                                  check: true,
                                  widget: Container(
                                    height: heigth * 18 / 100,
                                    child: Column(children: [
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            bodyType = "Bottom HourGlass";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Bottom HourGlass",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            bodyType = "Inverted Triangle";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Inverted Triangle",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            bodyType = "Round";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Round",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            bodyType = "Diamond Shaped";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Diamond Shaped",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                      SizedBox(height: heigth * 1 / 100),
                                      Expanded(
                                          child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            bodyType = "Athletic";
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text("Athletic",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Mulish')),
                                      )),
                                    ]),
                                  ));
                            },
                            child: buildColumnText(
                                'Body Type', size, heigth, width,
                                data: (bodyType == '')
                                    ? 'select body type'
                                    : bodyType)),
                        SizedBox(height: heigth * 2 / 100),
                        InkWell(
                          onTap: () {
                            showAlertDialogue(context,
                                name: 'Interests',
                                widget: TextField(
                                  controller: interests,
                                  maxLength: 300,
                                  keyboardType: TextInputType.multiline,
                                  // onChanged: (value) {
                                  //   setState(() {
                                  //     bio = value;
                                  //   });
                                  // },
                                  maxLines: 3,
                                  minLines: 1,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Mulish'),
                                ));
                          },
                          child: buildColumnText(
                            'Interests', size, heigth, width,
                            // '#Travelling #Swimming #Skating #BookWorm #Programmer #BodyBuilder'
                            data: (interests.text == '')
                                ? 'write interests with one space apart'
                                : '#' + interests.text.replaceAll(' ', ' #'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            );
          }),
    );
    // });
  }

  // showWarningDialogue({context, warninig}) {}

  Column buildColumnText(var name, double size, double heigth, var width,
      {String data}) {
    return Column(
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((name == null) ? 'Unavailable' : name,
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: size * 5 / 100,
                  color: Colors.white.withOpacity(0.4))),
          SizedBox(height: heigth * 1.0 / 100),
          Row(
            children: [
              Expanded(
                child: Text((data == null) ? 'Unavailable' : data,

                    ///  'i am data',
                    style: TextStyle(
                        fontFamily: 'Mulish',
                        fontSize: size * 6 / 100,
                        color: Colors.white)),
              ),
              SizedBox(width: width * 2 / 100),
              Icon(
                Icons.edit,
                color: Colors.white.withOpacity(0.2),
                size: ((heigth + width) / 4) * 10 / 100,
              )
            ],
          )
        ]);
  }

  Column buildColumnLocation(
    var name,
    double size,
    double heigth,
    var width,
    //  {String data}
  ) {
    return Column(
        // mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((name == null) ? 'unavailable' : name,
              style: TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: size * 5 / 100,
                  color: Colors.white.withOpacity(0.4))),
          SizedBox(height: heigth * 1.0 / 100),

          Row(
            children: [
              Expanded(
                child: Container(
                  //  padding: EdgeInsets.symmetric(horizontal: width * 5 / 100),
                  height: heigth * 2.75 / 100,
                  //  width: width * 50 / 100,
                  child: CountryListPick(
                      appBar: AppBar(
                        backgroundColor: Color(0xFF13293D),
                        title: Text('Location'),
                      ),

                      //  Container(),
                      // if you need custome picker use this
                      pickerBuilder: (context, CountryCode countryCode) {
                        return Row(
                          children: [
                            // Image.asset(
                            //   countryCode.flagUri,
                            //   package: 'country_list_pick',
                            // ),
                            Text(
                                (location == null || location == '')
                                    ? countryCode.name
                                    : location,
                                style: TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: size * 6 / 100,
                                    color: Colors.white)),
                            // Text(countryCode.code),
                            // Text(countryCode.dialCode),
                          ],
                        );
                      },

                      // To disable option set to false
                      theme: CountryTheme(
                        isShowFlag: true,
                        isShowTitle: true,
                        isShowCode: true,
                        isDownIcon: true,
                        showEnglishName: true,
                      ),
                      // Set default value
                      initialSelection: '+92',
                      onChanged: (CountryCode code) {
                        // print(code.name);
                        // print(code.code);
                        // print(code.dialCode);
                        // print(code.flagUri);

                        setState(() {
                          location = code.name;
                        });
                      },
                      // Whether to allow the widget to set a custom UI overlay
                      useUiOverlay: true,
                      // Whether the country list should be wrapped in a SafeArea
                      useSafeArea: false),
                ),
              ),
              SizedBox(width: width * 2 / 100),
              Icon(
                Icons.edit,
                color: Colors.white.withOpacity(0.2),
                size: ((heigth + width) / 4) * 10 / 100,
              )
            ],
          )

          // SizedBox(width: width * 2 / 100),
          // Icon(
          //   Icons.edit,
          //   color: Colors.white.withOpacity(0.2),
          //   size: ((heigth + width) / 4) * 10 / 100,
          // )
        ]);
  }

  showAlertDialogue(BuildContext context,
      {String name, var widget, bool check = true}) {
    var alertDialogue = AlertDialog(
        backgroundColor: Color(0xFF13293D),
        title: Text(name,
            style: TextStyle(color: Colors.white, fontFamily: 'Mulish')),
        content: widget,
        // Text('This is alert dialogue'),
        actionsPadding: EdgeInsets.only(right: 20, bottom: 20),
        actions:
            //  (check)
            //     ?
            [
          InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white, fontFamily: 'Mulish'))),
        ]);

    showDialog(
        context: context,
        builder: (context) {
          return alertDialogue;
        });
  }
}
