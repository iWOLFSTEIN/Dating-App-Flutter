import 'dart:io';
import 'package:chat_app/Navigations/FadePageRoute.dart';
import 'package:chat_app/Services/BackendServices.dart';
import 'package:chat_app/Services/DataProvider.dart';
import 'package:chat_app/Services/FireStorageService.dart';
import 'package:chat_app/Services/FirebaseProfilePicsModel.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ImageHandlerScreen extends StatefulWidget {
  ImageHandlerScreen(
      {Key key,
      this.isAVI,
      this.receiverEmail,
      this.senderEmail,
      this.isMessage = false})
      : super(key: key);

  bool isAVI;
  var senderEmail;
  var receiverEmail;
  bool isMessage;

  @override
  _ImageHandlerScreenState createState() => _ImageHandlerScreenState();
}

class _ImageHandlerScreenState extends State<ImageHandlerScreen> {
  File imageFile;

  Future<void> pickImage(ImageSource source) async {
    File selectedImage = await ImagePicker.pickImage(
      source: source, imageQuality: 20,
      //  maxHeight: 512.0, maxWidth: 512.0
    );

    setState(() {
      imageFile = selectedImage;
    });
  }

  Future<void> cropImage() async {
    File croppedImage = await ImageCropper.cropImage(
        sourcePath: imageFile.path,
        compressQuality: 50,
        androidUiSettings: AndroidUiSettings(
          toolbarColor: Color(0xFF13293D),
          toolbarWidgetColor: Colors.white,
          toolbarTitle: 'Crop Image',
        ));

    setState(() {
      imageFile = croppedImage ?? imageFile;
    });
  }

  clear() {
    setState(() {
      imageFile = null;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  FirebaseGetProfilePicsModel firebaseGetProfilePicsModel =
      FirebaseGetProfilePicsModel();
  FirebaseAuth auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;
    //  var progressBar = Provider.of<DataProvider>(context);

    return Scaffold(
      backgroundColor: Color(0xFF13293D),
      appBar: AppBar(
        backgroundColor: Color(0xFF13293D),
        //primary: Icon(icon),
        title: Text("Upload Image"),
        leading: InkWell(
            onTap: () {
              Navigator.pop(context, false);
            },
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
      ),
      body: StreamBuilder<FirebaseProfilePicsModel>(
          stream: firebaseGetProfilePicsModel.streamUserData(
              email: auth.currentUser.email),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            // debugPrint('Printing the list of images adresses: ' +
            //     snapshot.data.otherPics.toString());
            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                      top: heigth * 2 / 100,
                      left: width * 3 / 100,
                      right: width * 3 / 100),
                  child: (imageFile != null)
                      ? Container(
                          height: heigth * 60 / 100,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: FileImage(imageFile),
                                  fit: BoxFit.contain),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.6))),
                        )
                      : (!widget.isAVI)
                          ? imageHint(heigth, width, size)
                          : (snapshot.data.profilePic == '')
                              ? imageHint(heigth, width, size)
                              : FutureBuilder(
                                  future: FireStorageService.loadImage(
                                      context, snapshot.data.profilePic),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        height: heigth * 60 / 100,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.white
                                                    .withOpacity(0.6))),
                                      );
                                    }

                                    return Container(
                                      height: heigth * 60 / 100,
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              image: NetworkImage(
                                                  snapshot.data.toString()),
                                              fit: BoxFit.contain),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.6))),
                                    );
                                  }),
                ),
                Row(
                  children: [
                    Expanded(child: SizedBox()),
                    Container(
                      width: width * 25 / 100,
                      height: heigth * 5 / 100,
                      child: RaisedButton(
                          color: Color(0xFF18344E),
                          child: Center(
                              child: Icon(
                            Icons.crop,
                            color: Colors.white.withOpacity(0.6),
                          )),
                          onPressed: () async {
                            await cropImage();
                          }),
                    ),
                    Expanded(child: SizedBox()),
                    Container(
                      width: width * 25 / 100,
                      height: heigth * 5 / 100,
                      child: RaisedButton(
                          color: Color(0xFF18344E),
                          child: Center(
                              child: Icon(
                            Icons.rotate_left,
                            size: size * 10 / 100,
                            color: Colors.white.withOpacity(0.6),
                          )),
                          onPressed: () async {
                            await cropImage();
                          }),
                    ),
                    Expanded(child: SizedBox()),
                  ],
                ),
                Uploader(
                  file: imageFile,
                  context: context,
                  isAVI: widget.isAVI,
                  imageAdress: snapshot.data.profilePic,
                  imageCount: snapshot.data.imageCount,
                  otherPics: snapshot.data.otherPics,
                  senderEmail: widget.senderEmail,
                  receiverEmail: widget.receiverEmail,
                  isMessage: widget.isMessage,
                ),
                Material(
                  color: Color(0xFF18344E),
                  elevation: 16,
                  child: Container(
                    height: heigth * 8.5 / 100,
                    child: Row(
                      children: [
                        Container(
                          width: width * 5 / 100,
                        ),
                        Expanded(
                          child: FlatButton(
                            onPressed: () async {
                              try {
                                await pickImage(ImageSource.camera);
                                // await cropImage();
                              } catch (e) {
                                CoolAlert.show(
                                  context: context,
                                  type: CoolAlertType.error,
                                  title: 'Sorry!',
                                  text: 'An error occured.',
                                );
                              }
                            },
                            child: Icon(
                              Icons.camera,
                              color: Colors.blue,
                              size: size * 12 / 100,
                            ),
                          ),
                        ),
                        Expanded(
                          child: FlatButton(
                            onPressed: () async {
                              try {
                                await pickImage(ImageSource.gallery);
                                // await cropImage();
                              } catch (e) {
                                CoolAlert.show(
                                  context: context,
                                  type: CoolAlertType.error,
                                  title: 'Sorry!',
                                  text: 'An error occured.',
                                );
                              }
                            },
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.pinkAccent[100],
                              size: size * 12 / 100,
                            ),
                          ),
                        ),
                        Container(
                          width: width * 5.5 / 100,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

  Container imageHint(double heigth, double width, double size) {
    return Container(
      height: heigth * 60 / 100,
      width: width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Select an Image',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: size * 10 / 100,
                fontWeight: FontWeight.w600
                // fontFamily: 'Mulish'
                ),
          ),
          SizedBox(
            height: heigth * 0.5 / 100,
          ),
          Text(
            'to upload',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: size * 10 / 100,
                fontWeight: FontWeight.w600
                // fontFamily: 'Mulish'
                ),
          ),
          SizedBox(
            height: heigth * 0.5 / 100,
          ),
          Icon(
            Icons.image,
            color: Colors.white.withOpacity(0.4),
            size: size * 16 / 100,
          )
        ],
      ),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.6))),
    );
  }
}

class Uploader extends StatefulWidget {
  Uploader({
    Key key,
    this.file,
    this.context,
    this.isAVI,
    this.imageAdress,
    this.imageCount,
    this.otherPics,
    this.isMessage,
    this.receiverEmail,
    this.senderEmail,
  }) : super(key: key);

  File file;
  var context;
  bool isAVI;
  var imageAdress;
  var imageCount;
  var otherPics;

  var senderEmail;
  var receiverEmail;
  bool isMessage;

  @override
  _UploaderState createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  final FirebaseStorage firebaseStorage =
      FirebaseStorage(storageBucket: 'gs://chat-app-37730.appspot.com');

  UploadTask uploadTask;

  FirebaseAuth auth = FirebaseAuth.instance;
  BackendServices backendServices = BackendServices();
  String path;
  void startUpload() {
    String pathMaker = '${auth.currentUser.email}/${DateTime.now()}.jpg';

    setState(() {
      path = pathMaker;
      uploadTask = firebaseStorage.ref().child(path).putFile(widget.file);
    });
  }

  var previousImageAdress;
  var _progress;

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var heigth = MediaQuery.of(context).size.height;
    var size = (heigth + width) / 4;
    //  var progressBar = Provider.of<DataProvider>(context);

    if (uploadTask != null) {
      return StreamBuilder<TaskSnapshot>(
          stream: uploadTask.snapshotEvents,
          builder: (context, snapshot) {
            var event = snapshot.data;

            _progress =
                event != null ? event.bytesTransferred / event.totalBytes : 0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 5 / 100),
              child: FAProgressBar(
                currentValue: _progress.toInt() * 100,
                border:
                    Border.all(color: Colors.white, width: width * 0.2 / 100),
                borderRadius: 0.0,
                maxValue: 100,
                size: width * 12 / 100,
                direction: Axis.horizontal,
                // changeColorValue: 100 - (_progress.toInt() * 100),
                progressColor: Color(0xFF20D5B7),
                displayText: '%',
                displayTextStyle:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                // (_progress.toInt() * 100).toString(),
              ),
            );
          });
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 4 / 100),
      child: RaisedButton(
          //  padding: EdgeInsets.only(left: width * 10 / 100),

          color: Color(0xFF20D5B7),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: heigth * 1.5 / 100),
              child: Row(
                //   crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: width * 2 / 100,
                  ),
                  Text(
                    "Upload",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          onPressed: () {
            if (widget.file == null) {
              CoolAlert.show(
                context: context,
                type: CoolAlertType.warning,
                text: 'Please select a new file!',
              );
            } else {
              startUpload();
              uploadTask.whenComplete(() async {
                try {
                  if (widget.isMessage) {
                    await backendServices.sendMessage(
                      senderEmail: widget.senderEmail,
                      receiverEmail: widget.receiverEmail,
                      messageText: '',
                      imageAdress: path,
                    );
                    backendServices.updateConversationEmail(
                      senderEmail: widget.senderEmail,
                      receiverEmail: widget.receiverEmail,
                      lastMessage: 'sent a picture',
                    );
                  } else {
                    if (widget.isAVI) {
                      if (!(widget.imageAdress == '' ||
                          widget.imageAdress == null)) {
                        FireStorageService.deleteImage(
                            imageAdress: widget.imageAdress);
                      }
                      backendServices.updateAVI(
                          email: auth.currentUser.email, imageAdress: path);
                    } else {
                      List beforeUpdate = widget.otherPics;
                      List updated = List.from(beforeUpdate)..addAll([path]);
                      backendServices.updateOtherPics(
                          email: auth.currentUser.email, imageAdress: updated);
                    }
                  }

                  setState(() {
                    uploadTask = null;
                  });
                  Navigator.pop(widget.context, true);
                } catch (e) {
                  setState(() {
                    uploadTask = null;
                  });
                  CoolAlert.show(
                    context: context,
                    type: CoolAlertType.error,
                    title: 'Sorry!',
                    text: e.toString(),
                    // 'An error occured.',
                  );
                }
              }).catchError((error) {
                setState(() {
                  uploadTask = null;
                });
                CoolAlert.show(
                  context: context,
                  type: CoolAlertType.error,
                  title: 'Sorry!',
                  text: 'An error occured.',
                );
              });
            }
          }),
    );
  }
}
