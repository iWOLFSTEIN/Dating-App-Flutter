import 'package:chat_app/Services/BackendServices.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:reward_app/Services/DatabaseServices.dart';

class SignInServies {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  // DatabaseServices databaseServices = new DatabaseServices();

  BackendServices backendServices = BackendServices();

  Future<bool> signInWithGoogle() async {
    bool isNewUser = false;
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final authResult = await _auth.signInWithCredential(credential);

    if (authResult.additionalUserInfo.isNewUser) {
      // databaseServices.createUser(email: authResult.user.email);

      backendServices.createUser(
          email: authResult.user.email,
          name: authResult.user.displayName,
          userId: authResult.user.uid);

      backendServices.createUserProfilePicsModel(
        email: authResult.user.email,
      );

      backendServices.createUserAdsCounterModel(email: authResult.user.email);

      isNewUser = true;
    }

    final User user = authResult.user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final User currentUser = await _auth.currentUser;
    assert(user.uid == currentUser.uid);

    return isNewUser;
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();

    print("User Sign Out");
  }
}
