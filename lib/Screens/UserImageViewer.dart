import 'package:chat_app/Services/BackendServices.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseProfilePicsModel.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class UserImageViewer extends StatefulWidget {
  UserImageViewer({
    Key key,
    this.imageAdress,
    this.imageReference,
    //   this.condition
  }) : super(key: key);

  final imageAdress;
  final imageReference;
  // final condition;

  @override
  _UserImageViewerState createState() => _UserImageViewerState();
}

class _UserImageViewerState extends State<UserImageViewer> {
  final firebaseGetProfilePicsModel = FirebaseGetProfilePicsModel();
  final backendServices = BackendServices();
  final auth = FirebaseAuth.instance;
  bool isDeleted = false;
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;

    return StreamBuilder<FirebaseProfilePicsModel>(
        stream: firebaseGetProfilePicsModel.streamUserData(
            email: auth.currentUser.email),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return Scaffold(
              backgroundColor: Color(0xFF13293D),
              appBar: AppBar(
                backgroundColor: Color(0xFF13293D),
                title: Text('Image Viewer'),
                actions:
                    //  (widget.condition)
                    //     ? []
                    //     :
                    [
                  Padding(
                    padding: EdgeInsets.only(right: width * 7 / 100),
                    child: InkWell(
                        onTap: () async {
                          setState(() {
                            isDeleted = true;
                          });
                          List imageList = snapshot.data.otherPics;
                          try {
                            await FireStorageService.deleteImage(
                                    imageAdress: widget.imageReference)
                                .whenComplete(() {
                              if (imageList.contains(widget.imageReference))
                                imageList.remove(widget.imageReference);

                              backendServices.updateOtherPics(
                                  email: auth.currentUser.email,
                                  imageAdress: imageList);

                              setState(() {
                                isDeleted = false;
                              });

                              Navigator.pop(context);
                            });
                          } catch (e) {
                            setState(() {
                              isDeleted = false;
                            });
                            CoolAlert.show(
                              context: context,
                              type: CoolAlertType.error,
                              title: 'Sorry!',
                              text: 'An error occured.',
                            );
                          }
                        },
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        )),
                  )
                ],
              ),
              body: ModalProgressHUD(
                inAsyncCall: isDeleted,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  // crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(),
                    Container(
                      height: heigth * 70 / 100,
                      child: Center(
                        child: Image.network(widget.imageAdress,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: heigth * 4 / 100, right: width * 4 / 100),
                      child: Row(
                        children: [
                          Expanded(child: Container()),
                          Container(
                            //  alignment: Alignment.centerRight,

                            padding: EdgeInsets.symmetric(
                                horizontal: width * 4 / 100),
                            height: heigth * 5 / 100,
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.end,
                              // crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                                SizedBox(
                                  width: width * 1.5 / 100,
                                ),
                                Padding(
                                  padding:
                                      EdgeInsets.only(top: heigth * .5 / 100),
                                  child: Text(
                                    '0',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: size * 5.5 / 100),
                                  ),
                                )
                              ],
                            ),
                            decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: size * 0.45 / 100)),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ));
        });
  }
}
