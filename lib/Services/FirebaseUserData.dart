import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUserData {
  final email;
  final username;
  final userId;
  final name;
  final bio;
  final gender;
  final interestedIn;
  final location;
  final ethnicity;
  final age;
  final height;
  final bodyType;
  final interests;
  final profilePic;

  FirebaseUserData(
      {this.age,
      this.bio,
      this.bodyType,
      this.email,
      this.ethnicity,
      this.gender,
      this.height,
      this.interestedIn,
      this.interests,
      this.location,
      this.name,
      this.userId,
      this.profilePic,
      this.username});

  factory FirebaseUserData.fromMap(Map data) {
    return FirebaseUserData(
        age: data['age'],
        bio: data['bio'],
        bodyType: data['bodyType'],
        email: data['email'],
        ethnicity: data['ethnicity'],
        gender: data['gender'],
        height: data['height'],
        interestedIn: data['interestedIn'],
        interests: data['interests'],
        location: data['location'],
        name: data['name'],
        userId: data['userId'],
        profilePic: data['profilePic'],
        username: data['username']);
  }
}

class FirebaseGetUserData {
  var firebaseUser = FirebaseAuth.instance.currentUser;
  var firestoreInstance = FirebaseFirestore.instance;

  Stream<FirebaseUserData> streamUserData({String email}) {
    return firestoreInstance
        .collection('users')
        .doc(email)
        .snapshots()
        .map((event) => FirebaseUserData.fromMap(event.data()));
  }
}
