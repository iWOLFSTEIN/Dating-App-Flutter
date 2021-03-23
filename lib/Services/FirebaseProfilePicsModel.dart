import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseProfilePicsModel {
  final imageCount;
  final profilePic;
  final otherPics;

  FirebaseProfilePicsModel({this.imageCount, this.otherPics, this.profilePic});

  factory FirebaseProfilePicsModel.fromMap(Map data) {
    return FirebaseProfilePicsModel(
      imageCount: data['imageCount'] ?? 0,
      profilePic: data['profilePic'] ?? '',
      otherPics: data['otherPics'] ?? [],
    );
  }
}

class FirebaseGetProfilePicsModel {
  var firebaseUser = FirebaseAuth.instance.currentUser;
  var firestoreInstance = FirebaseFirestore.instance;

  Stream<FirebaseProfilePicsModel> streamUserData({String email}) {
    return firestoreInstance
        .collection('ProfilePictures')
        .doc(email)
        .snapshots()
        .map((event) => FirebaseProfilePicsModel.fromMap(event.data()));
  }
}
