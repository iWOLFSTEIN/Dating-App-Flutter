import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FireStorageService {
  static Future<dynamic> loadImage(BuildContext context, String image) async {
    return await FirebaseStorage.instance.ref().child(image).getDownloadURL();
  }

  static dynamic deleteImage({imageAdress}) async {
    return await FirebaseStorage.instance.ref().child(imageAdress).delete();
  }
}
