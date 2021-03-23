import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Navigations/PagesNavController.dart';
import 'package:chat_app/Screens/EditProfileScreen.dart';
import 'package:chat_app/Services/BackendServices.dart';
import 'package:chat_app/Services/UserState.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class ConfirmEmailScreen extends StatefulWidget {
  ConfirmEmailScreen({Key key, this.name}) : super(key: key);
  String name;
  @override
  _ConfirmEmailScreenState createState() => _ConfirmEmailScreenState();
}

class _ConfirmEmailScreenState extends State<ConfirmEmailScreen>
    with SingleTickerProviderStateMixin {
  BackendServices _backendServices = new BackendServices();

  var counterController;

  var textStyle = TextStyle(
    color: Color(0xFF13293D),
    fontFamily: 'Mulish',
  );

  final _auth = FirebaseAuth.instance;
  UserState userState = UserState();
  User user;

  currentLoggedInUser() async {
    try {
      user = _auth.currentUser;

      if (user != null) {
        await user.sendEmailVerification();

        debugPrint("A verification email is sent to " + user.email);
        return user.uid;
      }
    } catch (e) {
      CoolAlert.show(
          context: context, type: CoolAlertType.error, text: e.toString());
    }
  }

  var showSpinner = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentLoggedInUser();

    counterController = AnimationController(
        duration: Duration(seconds: 120),
        vsync: this,
        lowerBound: 0.0,
        upperBound: 120.0);
    counterController.reverse(from: 120.0);
    counterController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;
    // var textInputDecoration = InputDecoration(
    //   hintText: '0',
    //   hintStyle: textStyle.copyWith(
    //       color: Color(0xFF13293D).withOpacity(0.2), fontSize: size * 15 / 100),
    // );

    return Scaffold(
        body: ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: SingleChildScrollView(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.only(
                      top: heigth * 7 / 100,
                      left: width * 6 / 100,
                      right: width * 6 / 100),
                  color: Color(0xFF13293D),
                  //Color(0xFF20D5B7),
                  // Color(0xFF13293D),
                  height: heigth / 3,
                  width: width,
                  child: Column(
                    children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {},
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: heigth * 2 / 100,
                      ),
                      textMethod(size / 8,
                          text: "Confirm Email", color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(
                      top: heigth * 8 / 100,
                      left: width * 6 / 100,
                      right: width * 6 / 100),
                  color: Color(0xFF18344E),
                  //Color(0xFF13293D),
                  // Color(0xFFFBF9FF),
                  height: heigth - (heigth / 3),
                  width: width,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        textMethod(
                          size / 16.5,
                          text:
                              "We have sent you a verification email. Click on the link in the email to continue!",
                          color: Colors.white.withOpacity(0.4),
                        ),
                        Text(
                          counterController.value.toInt().toString(),
                          style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: size / 3,
                              color: Colors.grey.withOpacity(0.4)),
                        ),
                        Builder(
                          builder: (context) => textRowMethod(size,
                              text: "Didn't recieve the code? ",
                              voidCallBack: () async {
                            showSnackBar(context);
                            counterController.reverse(from: 120.0);
                            await user.sendEmailVerification();
                            counterController.reverse(from: 60.0);
                          }),
                        ),
                        Container(
                          height: heigth * 7 / 100,
                          color:
                              //Color(0xFF13293D),
                              Color(0xFF0DE75A),
                          //   Color(0xFF20D5B7),
                          child: FlatButton(
                              onPressed: () async {
                                setState(() {
                                  showSpinner = true;
                                });
                                try {
                                  User user1 = await _auth.currentUser;
                                  await user1.reload();
                                  user1.emailVerified;
                                  User user2 = await _auth.currentUser;

                                  await user2.reload();

                                  if (user2.emailVerified && user != null) {
                                    if (counterController.value.toInt() != 0) {
                                      debugPrint(widget.name);
                                      _backendServices.createUser(
                                          name: widget.name,
                                          userId: user2.uid,
                                          email: user2.email);
                                      _backendServices
                                          .createUserProfilePicsModel(
                                              email: user2.email);
                                      _backendServices
                                          .createUserAdsCounterModel(
                                              email: user2.email);

                                      Navigator.pushAndRemoveUntil(
                                          context,
                                          FadePageRoute(EditProfileScreen()),
                                          (route) => false);
                                      userState.setVisitingFlag(value: 2);

                                      setState(() {
                                        showSpinner = false;
                                      });
                                    } else {
                                      CoolAlert.show(
                                          context: context,
                                          type: CoolAlertType.error,
                                          text: "Request Timeout!");
                                    }
                                  } else {
                                    CoolAlert.show(
                                        context: context,
                                        type: CoolAlertType.error,
                                        text: "An error occurred!");
                                  }
                                } catch (e) {
                                  CoolAlert.show(
                                      context: context,
                                      type: CoolAlertType.error,
                                      text: e.toString());
                                }
                                setState(() {
                                  showSpinner = false;
                                });
                              },
                              child: Center(
                                  child: Text(
                                "CONTINUE",
                                style: TextStyle(
                                    fontFamily: 'Mulish',
                                    fontSize: size / 14.5,
                                    color: Colors.white),
                              ))),
                        )
                      ]),
                )
              ],
            ),
            Container(
                // color: Colors.orange.withOpacity(0.4),
                margin: EdgeInsets.only(
                    top: heigth * 21.5 / 100,
                    left: width / 2 - ((width * 28 / 100) / 2)),
                child: Image.asset(
                  'images/mail.png',
                  height: heigth * 24 / 100,
                  width: width * 32 / 100,
                ))
          ],
        ),
      ),
    ));
  }

  Row textRowMethod(double size, {var text, var voidCallBack}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        textMethod(size / 17.5, text: text, color: Colors.white),
        GestureDetector(
          onTap: voidCallBack,
          child: Text(
            "Click here!",
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: size / 17.5,
              color: Color(0xFF0DE75A),
            ),
          ),
        )
      ],
    );
  }

  Text textMethod(double size, {var text, var color}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Mulish',
        fontSize: size,
        color: color,
      ),
    );
  }

  void showSnackBar(BuildContext context) {
    var snackbar = SnackBar(
        duration: Duration(milliseconds: 1000),
        backgroundColor: Color(0xFF13293D),
        content: Text(
          "Verification email is sent!",
          style: TextStyle(fontFamily: 'Mulish'),
        ));
    Scaffold.of(context).showSnackBar(snackbar);
  }
}
