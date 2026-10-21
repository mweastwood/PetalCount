part of '../firebase_database_service.dart';

mixin _FirebaseAuthUserOps on _FirebaseDatabaseServiceBase {
  @override
  User? get currentUser => _auth.currentUser;

  @override
  String? get currentChartId => _cachedChartId;

  @override
  Stream<User?> get authStateChanges => _buildAuthStream();

  Stream<User?> _buildAuthStream() async* {
    final user = currentUser;
    if (user != null) {
      _cachedChartId ??= await _fetchChartId(user.uid);
    } else {
      _cachedChartId = null;
    }
    yield user;
    yield* _authController.stream;
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final User? user;
      if (kIsWeb) {
        final UserCredential userCredential = await _auth.signInWithPopup(
          GoogleAuthProvider(),
        );
        user = userCredential.user;
      } else {
        if (!_googleSignInInitialized) {
          await _googleSignIn.initialize(
            serverClientId: AppConfig.googleServerClientId,
          );
          _googleSignInInitialized = true;
        }

        final GoogleSignInAccount googleUser = await _googleSignIn
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        user = userCredential.user;
      }

      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (!userDoc.exists) {
          await _db.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email ?? '',
            'chartId': null,
          });
        }
        _cachedChartId = await _fetchChartId(user.uid);
      }
    } catch (e) {
      if (!kIsWeb &&
          e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        debugPrint('Google Sign-In canceled: $e');
        throw GoogleSignInException(
          code: e.code,
          description:
              'Sign-in was canceled or failed due to configuration. If you selected '
              'an account and this happened, it is likely due to a developer configuration '
              'mismatch (e.g., missing SHA-1 signature fingerprint in the Firebase Console).',
          details: e.details,
        );
      }
      debugPrint('Error signing in with Google: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    _cachedChartId = null;
    _cachedRole = null;
    _cachedPreferencesByChart.clear();
  }

  @override
  Future<void> updateUserRole(String role) async {
    _cachedRole = role;
    final user = currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).set({
        'role': role,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user role: $e');
    }
  }

  @override
  Stream<String?> streamUserRole() {
    return _buildUserGatedStream<String?>(
      emptyValue: null,
      debugLabel: 'userRole',
      subscribe: (uid) =>
          _db.collection('users').doc(uid).snapshots().map((doc) {
            final role = doc.data()?['role'] as String? ?? 'wife';
            _cachedRole = role;
            return role;
          }),
    );
  }

  @override
  Future<void> saveFcmToken(String token) async {
    final user = currentUser;
    if (user == null || token.isEmpty) return;
    try {
      await _db.collection('users').doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  @override
  Future<void> removeFcmToken(String token) async {
    final user = currentUser;
    if (user == null || token.isEmpty) return;
    try {
      await _db.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  @override
  Future<void> updateUserTimezone(String timezone) async {
    final user = currentUser;
    if (user == null || timezone.isEmpty) return;
    try {
      await _db.collection('users').doc(user.uid).set({
        'timezone': timezone,
      }, SetOptions(merge: true));

      final chartId = currentChartId;
      if (chartId != null) {
        await _db.collection('charts').doc(chartId).set({
          'timezone': timezone,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error updating user timezone: $e');
    }
  }
}
