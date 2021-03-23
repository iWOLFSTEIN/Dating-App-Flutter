import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Screens/ConfirmEmaiScreen.dart';
import 'package:chat_app/Screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class SignupScreen extends StatefulWidget {
  SignupScreen({Key key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  var fullName = TextEditingController();
  var email = TextEditingController();
  var pass = TextEditingController();
  var confirmPass = TextEditingController();

  var showSpinner = false;

  final _auth = FirebaseAuth.instance;

  var _formKey = GlobalKey<FormState>();

  var textStyle = TextStyle(
    color: Colors.white,
    fontFamily: 'Mulish',
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    textFieldDecoration = InputDecoration(
        hintText: 'Email',
        hintStyle: textStyle.copyWith(
          color: Colors.white.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          Icons.mail_outline,
          color: Colors.white.withOpacity(0.6),
        ));

    passwordFieldDecoration = InputDecoration(
        hintText: 'Password',
        hintStyle: textStyle.copyWith(
          color: Colors.white.withOpacity(0.6),
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: Colors.white.withOpacity(0.6),
        ));
  }

  var textFieldDecoration;
  var passwordFieldDecoration;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    return Scaffold(
        // resizeToAvoidBottomPadding: false,
        backgroundColor: Color(0xFF13293D),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: SingleChildScrollView(
            child: SizedBox(
              height: heigth,
              width: width,
              child: Padding(
                padding: EdgeInsets.only(
                    left: width * 6 / 100, right: width * 6 / 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(),
                    Container(),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    Container(),
                    textMethod(size / 8, text: "Get on board!"),
                    Container(),
                    Container(),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          TextFormField(
                              controller: fullName,
                              style: textStyle,
                              autocorrect: false,
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "Name field can't be empty";
                                }
                              },
                              decoration: textFieldDecoration.copyWith(
                                hintText: 'Full Name',
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              )),
                          SizedBox(
                            height: heigth * 5 / 100,
                          ),
                          TextFormField(
                              controller: email,
                              keyboardType: TextInputType.emailAddress,
                              style: textStyle,
                              autocorrect: false,
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "Email field can't be empty";
                                } else if (!(value.contains("@gmail.com")))
                                  return "Please enter a valid email adress";
                              },
                              decoration: textFieldDecoration),
                          SizedBox(
                            height: heigth * 5 / 100,
                          ),
                          TextFormField(
                              controller: pass,
                              style: textStyle,
                              autocorrect: false,
                              obscureText: true,
                              validator: (value) {
                                if (value.isEmpty) {
                                  return "Password field can't be empty";
                                } else if (value.length < 6) {
                                  return "Password must be of atleast 6 characters";
                                }
                              },
                              decoration: passwordFieldDecoration),
                          SizedBox(
                            height: heigth * 5 / 100,
                          ),
                          TextFormField(
                              controller: confirmPass,
                              style: textStyle,
                              autocorrect: false,
                              obscureText: true,
                              decoration: passwordFieldDecoration.copyWith(
                                  hintText: 'Confirm Password')),
                          SizedBox(
                            height: heigth * 5 / 100,
                          ),
                          textRowMethod(size, text: "Already have an account? ",
                              voidCallBack: () {
                            Navigator.push(
                                context, FadePageRoute(LoginScreen()));
                          }),
                        ],
                      ),
                    ),
                    Container(),
                    Container(),
                    Container(
                      height: heigth * 7 / 100,
                      color: Color(0xFF20D5B7),
                      child: FlatButton(
                          onPressed: () async {
                            try {
                              if (_formKey.currentState.validate()) {
                                if (pass.text == confirmPass.text) {
                                  setState(() {
                                    showSpinner = true;
                                  });
                                  // try {
                                  final newUser = await _auth
                                      .createUserWithEmailAndPassword(
                                          email: email.text,
                                          password: pass.text)
                                      //     .whenComplete(() {
                                      //   Navigator.pushReplacement(
                                      //       context,
                                      //       FadePageRoute(ConfirmEmailScreen(
                                      //         name: fullName.text,
                                      //       )));
                                      //   setState(() {
                                      //     showSpinner = false;
                                      //   });
                                      // })
                                      .catchError((value) {
                                    CoolAlert.show(
                                        context: context,
                                        type: CoolAlertType.error,
                                        title: 'Invalid Email!',
                                        text: "The email already exists!");
                                    setState(() {
                                      showSpinner = false;
                                    });
                                  });

                                  if (newUser != null) {
                                    Navigator.pushReplacement(
                                        context,
                                        FadePageRoute(ConfirmEmailScreen(
                                          name: fullName.text,
                                        )));
                                    setState(() {
                                      showSpinner = false;
                                    });
                                  }
                                  // else {
                                  //   CoolAlert.show(
                                  //       context: context,
                                  //       type: CoolAlertType.error,
                                  //       title: 'Invalid Email!',
                                  //       text: "The email already exists!");
                                  //   setState(() {
                                  //     showSpinner = false;
                                  //   });
                                  // }
                                  //     setState(() {
                                  //       showSpinner = false;
                                  //     });
                                  // } catch (e) {
                                  // CoolAlert.show(
                                  //     context: context,
                                  //     type: CoolAlertType.error,
                                  //     text: e.toString());
                                  //  }
                                  // } else {
                                  // CoolAlert.show(
                                  //     context: context,
                                  //     type: CoolAlertType.error,
                                  //     text: "Passwords didn't match!");
                                  // }
                                  // setState(() {
                                  //   showSpinner = false;
                                  // });
                                } else {
                                  setState(() {
                                    showSpinner = false;
                                  });
                                  CoolAlert.show(
                                      context: context,
                                      type: CoolAlertType.error,
                                      text: "Passwords didn't match!");
                                }
                              }
                            } catch (e) {
                              setState(() {
                                showSpinner = false;
                              });
                              CoolAlert.show(
                                context: context,
                                type: CoolAlertType.error,
                                title: 'Sorry!',
                                text: e.toString(),
                                //"An error occurred!"
                              );
                            }
                          },
                          child: Center(
                              child: Text(
                            "SIGN UP",
                            style: TextStyle(
                              fontFamily: 'Mulish',
                              fontSize: size / 14.5,
                            ),
                          ))),
                    ),
                    Container()
                  ],
                ),
              ),
            ),
          ),
        ));
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
