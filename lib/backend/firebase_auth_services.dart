import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<User?> signUpwithEmailPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Store user data in Firestore
      // if (credential.user != null) {
      //   await _storeUserData(credential.user!);
      // }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to handle in UI
    } catch (e) {
      print("Sign up error: $e");
      rethrow;
    }
  }

  // Sign in with email and password
  Future<User?> signInwithEmailPassword(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error: ${e.code} - ${e.message}");
      rethrow; // Re-throw to handle in UI
    } catch (e) {
      print("Sign in error: $e");
      rethrow;
    }
  }

  // Sign in with Google
  // Future<User?> signInWithGoogle() async {
  //   try {
  //     // Trigger the authentication flow
  //     final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.
  //
  //     if (googleSignInAccount == null) {
  //       // User canceled the sign-in
  //       return null;
  //     }
  //
  //     // Obtain the auth details from the request
  //     final GoogleSignInAuthentication googleAuth = await googleSignInAccount.authentication;
  //
  //     // Create a new credential
  //     final OAuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     // Sign in to Firebase with the Google credential
  //     final UserCredential authResult = await _auth.signInWithCredential(credential);
  //     final User? user = authResult.user;
  //
  //     if (user != null) {
  //       // Store or update user data in Firestore
  //       await _storeUserData(user);
  //
  //       print("User signed in: ${user.email}");
  //       print("Display Name: ${user.displayName}");
  //       print("Is Anonymous: ${user.isAnonymous}");
  //     }
  //
  //     return user;
  //   } on FirebaseAuthException catch (e) {
  //     print("Firebase Auth Error: ${e.code} - ${e.message}");
  //     rethrow;
  //   } catch (e) {
  //     print("Google sign in error: $e");
  //     rethrow;
  //   }
  // }
  //
  // // Sign up with Google (same as sign in for Google)
  // Future<User?> signUpWithGoogle() async {
  //   try {
  //     final GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
  //
  //     if (googleSignInAccount == null) {
  //       return null;
  //     }
  //
  //     final GoogleSignInAuthentication googleAuth = await googleSignInAccount.authentication;
  //
  //     final OAuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     final UserCredential authResult = await _auth.signInWithCredential(credential);
  //
  //     if (authResult.user != null) {
  //       // Store user data in Firestore
  //       await _storeUserData(authResult.user!);
  //
  //       if (authResult.additionalUserInfo?.isNewUser == true) {
  //         print("New user signed up: ${authResult.user?.email}");
  //       } else {
  //         print("User already exists: ${authResult.user?.email}");
  //       }
  //     }
  //
  //     return authResult.user;
  //   } on FirebaseAuthException catch (e) {
  //     print("Firebase Auth Error: ${e.code} - ${e.message}");
  //     rethrow;
  //   } catch (e) {
  //     print("Error signing up with Google: $e");
  //     rethrow;
  //   }
  // }
  //
  // // Sign out
  // Future<void> signOut() async {
  //   try {
  //     await _googleSignIn.signOut();
  //     await _auth.signOut();
  //     print("User signed out successfully");
  //   } catch (e) {
  //     print("Error signing out: $e");
  //     rethrow;
  //   }
  // }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent to: $email");
    } on FirebaseAuthException catch (e) {
      print("Password reset error: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("Error sending password reset email: $e");
      rethrow;
    }
  }

// Store user data in Firestore
// Future<void> _storeUserData(User user) async {
//   try {
//     await _firestore.collection('users').doc(user.uid).set({
//       'uid': user.uid,
//       'email': user.email,
//       'displayName': user.displayName,
//       'photoURL': user.photoURL,
//       'createdAt': FieldValue.serverTimestamp(),
//       'lastLoginAt': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true)); // merge: true will update existing data
//
//     print("User data stored in Firestore");
//   } catch (e) {
//     print("Error storing user data: $e");
//     // Don't rethrow here as user creation was successful
//   }
// }
//
// // Get user data from Firestore
// Future<DocumentSnapshot?> getUserData(String uid) async {
//   try {
//     return await _firestore.collection('users').doc(uid).get();
//   } catch (e) {
//     print("Error getting user data: $e");
//     return null;
//   }
// }
//
// // Update user profile
// Future<void> updateUserProfile({
//   String? displayName,
//   String? photoURL,
// }) async {
//   try {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       await user.updateDisplayName(displayName);
//       await user.updatePhotoURL(photoURL);
//
//       // Also update in Firestore
//       await _firestore.collection('users').doc(user.uid).update({
//         if (displayName != null) 'displayName': displayName,
//         if (photoURL != null) 'photoURL': photoURL,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
//
//       print("User profile updated");
//     }
//   } catch (e) {
//     print("Error updating user profile: $e");
//     rethrow;
//   }
// }
}