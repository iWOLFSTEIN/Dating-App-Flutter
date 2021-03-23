import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Navigations/PagesNavController.dart';
import 'package:chat_app/Screens/EditProfileScreen.dart';
import 'package:chat_app/Screens/HomeScreen.dart';
import 'package:chat_app/Screens/SignupScreen.dart';
import 'package:chat_app/Services/SignInServices.dart';
import 'package:chat_app/Services/UserState.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var showSpinner = false;

  var email = TextEditingController();
  var password = TextEditingController();

  final _auth = FirebaseAuth.instance;
  var _formKey = GlobalKey<FormState>();

  SignInServies signInServies = SignInServies();
  UserState userState = UserState();

  var textStyle = TextStyle(
    color: Colors.white,
    fontFamily: 'Mulish',
  );

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      resizeToAvoidBottomPadding: false,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          child: Padding(
            padding:
                EdgeInsets.only(left: width * 6 / 100, right: width * 6 / 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    Expanded(child: Container()),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, FadePageRoute(SignupScreen()));
                      },
                      child: Text(
                        "Sign up",
                        style: TextStyle(
                            fontFamily: 'Mulish',
                            color: Color(0xFF20D5B7),
                            fontSize: size / 16),
                      ),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    textMethod(size / 8, text: "Login to continue!"),
                    SizedBox(
                      height: heigth * 3 / 100,
                    ),
                    textMethod(size / 16.5,
                        text:
                            "To continue enter your login credential or login with google!"),
                  ],
                ),
                Container(),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: email,
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Email field can't be empty";
                          } else if (!value.contains("@gmail.com")) {
                            return "Invalid Email!";
                          }
                        },
                        style: textStyle,
                        autocorrect: false,
                        decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: textStyle.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.mail_outline,
                              color: Colors.white.withOpacity(0.6),
                            )),
                      ),
                      SizedBox(
                        height: heigth * 7 / 100,
                      ),
                      TextFormField(
                        controller: password,
                        validator: (value) {
                          if (value.isEmpty) {
                            return "Password field can't be empty";
                          }
                        },
                        style: textStyle,
                        autocorrect: false,
                        obscureText: true,
                        decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: textStyle.copyWith(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Colors.white.withOpacity(0.6),
                            )),
                      ),
                    ],
                  ),
                ),
                textRowMethod(size, text: "New to Chatoo? ", voidCallBack: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignupScreen()));
                }),
                Container(),
                Column(
                  children: [
                    Container(
                      height: heigth * 7 / 100,
                      color: Color(0xFF20D5B7),
                      child: FlatButton(
                          onPressed: () async {
                            try {
                              if (_formKey.currentState.validate()) {
                                setState(() {
                                  showSpinner = true;
                                });

                                UserCredential userCredential;

                                userCredential =
                                    await _auth.signInWithEmailAndPassword(
                                        email: email.text,
                                        password: password.text);

                                if (userCredential != null) {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      FadePageRoute(PagesNavController(
                                        startingIndex: 0,
                                      )),
                                      (route) => false);

                                  userState.setVisitingFlag(value: 2);
                                  setState(() {
                                    showSpinner = false;
                                  });
                                } else {
                                  setState(() {
                                    showSpinner = false;
                                  });
                                  CoolAlert.show(
                                    context: context,
                                    type: CoolAlertType.error,
                                    title: 'Invalid Credentials!',
                                    text:
                                        'Your email or password is incorrect.',
                                  );
                                }
                              }
                            } catch (e) {
                              setState(() {
                                showSpinner = false;
                              });
                              CoolAlert.show(
                                  context: context,
                                  type: CoolAlertType.error,
                                  text: 'An error occurred.');
                            }
                          },
                          child: Center(
                              child: Text(
                            "LOG IN",
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: size / 14.5,
                            ),
                          ))),
                    ),
                    SizedBox(
                      height: heigth * 3 / 100,
                    ),
                    Container(
                      height: heigth * 7 / 100,
                      color: Color(0xFFECE5F0),
                      child: FlatButton(
                          onPressed: () async {
                            setState(() {
                              showSpinner = true;
                            });

                            try {
                              await signInServies
                                  .signInWithGoogle()
                                  .then((value) {
                                if (value) {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      FadePageRoute(EditProfileScreen()),
                                      (route) => false);
                                } else {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      FadePageRoute(PagesNavController(
                                        startingIndex: 0,
                                      )),
                                      (route) => false);
                                }
                                setState(() {
                                  showSpinner = false;
                                });
                              });
                              userState.setVisitingFlag(value: 2);
                            } catch (e) {
                              setState(() {
                                showSpinner = false;
                              });
                              CoolAlert.show(
                                  context: context,
                                  type: CoolAlertType.error,
                                  text: 'An error occurred.');
                            }
                          },
                          child: Center(
                              child: Row(
                            children: <Widget>[
                              Expanded(child: Container()),
                              Expanded(child: Container()),
                              Image.asset(
                                'images/googleIcon.png',
                                height: heigth * 4.5 / 100,
                                width: width * 6 / 100,
                              ),
                              Expanded(child: Container()),
                              Text(
                                "Continue with Google",
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: size / 14.5,
                                ),
                              ),
                              Expanded(child: Container()),
                              Expanded(child: Container()),
                              Expanded(child: Container()),
                            ],
                          ))),
                    ),
                  ],
                ),
                Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row textRowMethod(double size, {var text, var voidCallBack}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        textMethod(size / 17.5, text: text),
        GestureDetector(
          onTap: voidCallBack,
          child: Text(
            "Click here!",
            style: TextStyle(
              fontFamily: 'Mulish',
              fontSize: size / 17.5,
              color: Color(0xFF20D5B7),
            ),
          ),
        )
      ],
    );
  }

  Text textMethod(double size, {var text}) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Mulish',
        fontSize: size,
        color: Colors.white,
      ),
    );
  }
}
