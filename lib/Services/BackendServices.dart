import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackendServices {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  createUser({var userId, var name, var email}) async {
    await _firestore.collection('users').doc(email).set({
      'email': email,
      'username': '@' + email,
      'userId': userId,
      'name': (name == null) ? 'Name' : name,
      'bio': '',
      'gender': '',
      'interestedIn': '',
      'location': '',
      'ethnicity': '',
      'age': '',
      'height': '',
      'bodyType': '',
      'interests': '',
      'profilePic': ''
    });
  }

  createUserProfilePicsModel({var email}) async {
    await _firestore.collection('ProfilePictures').doc(email).set({
      'imagesCount': 0,
      'profilePic': '',
      'otherPics': [],
    });
  }

  updateAVI({var email, var imageAdress}) async {
    await _firestore
        .collection('ProfilePictures')
        .doc(email)
        .update({'profilePic': imageAdress});

    await _firestore
        .collection('users')
        .doc(email)
        .update({'profilePic': imageAdress});
  }

  updateOtherPics({var email, var imageAdress}) async {
    await _firestore
        .collection('ProfilePictures')
        .doc(email)
        .update({'otherPics': imageAdress});
  }

  updateConversationEmail(
      {var senderEmail, var receiverEmail, var lastMessage}) async {
    var time = DateTime.now();

    var currentTime = time;
    await _firestore
        .collection('Messages')
        .doc(senderEmail)
        .collection('AllMessages')
        .doc(receiverEmail)
        .set({
      'sentTo': receiverEmail,
      'timestamp': currentTime,
      'lastMessage': lastMessage,
      //(lastMessage == '') ? 'sent a picture' : lastMessage,
    }).whenComplete(() async {
      await _firestore
          .collection('Messages')
          .doc(receiverEmail)
          .collection('AllMessages')
          .doc(senderEmail)
          .set({
        'sentTo': senderEmail,
        'timestamp': currentTime,
        'lastMessage': lastMessage
        // (lastMessage == '') ? 'sent a picture' : lastMessage,
      });
    });
  }

  sendMessage(
      {var senderEmail,
      var receiverEmail,
      var messageText,
      var imageAdress}) async {
    bool sent = false;

    var time = DateTime.now();

    var currentTime = time;

    await _firestore
        .collection('Messages')
        .doc(senderEmail)
        .collection('AllMessages')
        .doc(receiverEmail)
        .collection('Conversation')
        .add({
      'message': messageText,
      'sender': senderEmail,
      'timestamp': currentTime,
      'imageAdress': imageAdress,
    }).whenComplete(() async {
      await _firestore
          .collection('Messages')
          .doc(receiverEmail)
          .collection('AllMessages')
          .doc(senderEmail)
          .collection('Conversation')
          .add({
        'message': messageText,
        'sender': senderEmail,
        'timestamp': currentTime,
        'imageAdress': imageAdress,
      }).whenComplete(() {
        sent = true;
      });
    });

    // return sent;
  }

  Future<bool> usernameCheck({var username, var email}) async {
    bool check = true;

    await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get()
        .then((value) {
      for (var data in value.docs) {
        if (data['username'] == username && data['email'] != email) {
          check = false;
        }
      }
    });

    return check;
  }

  updateUserProfileData(
      {var email,
      var username,
      var name,
      var bio,
      var gender,
      var interestedIn,
      var location,
      var ethnicity,
      var age,
      var height,
      var bodyType,
      var interests}) async {
    await _firestore.collection('users').doc(email).update({
      'bio': bio,
      'gender': gender,
      'interestedIn': interestedIn,
      'username': username,
      'name': name,
      'ethnicity': ethnicity,
      'age': age,
      'height': height,
      'bodyType': bodyType,
      'interests': interests,
      'location': location,
    });
  }

  createUserAdsCounterModel({email}) async {
    await _firestore
        .collection('AdsCount')
        .doc(email)
        .set({'HomeScreenCount': 0, 'FavMatchScreenCount': 0});
  }
}
