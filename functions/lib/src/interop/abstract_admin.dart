import 'dart:async';
import 'package:meta/meta.dart';

/// Sentinel representation for `FieldValue.arrayRemove(...)` operations.
@immutable
class FieldValueArrayRemove {
  final List<String> elements;

  const FieldValueArrayRemove(this.elements);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FieldValueArrayRemove) return false;
    if (elements.length != other.elements.length) return false;
    for (var i = 0; i < elements.length; i++) {
      if (elements[i] != other.elements[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(elements);

  @override
  String toString() => 'FieldValue.arrayRemove($elements)';
}

/// Sentinel class for Firestore FieldValue operations.
class FieldValue {
  static const deleteToken = '__FIELD_VALUE_DELETE__';
  static dynamic delete() => deleteToken;
  static FieldValueArrayRemove arrayRemove(List<String> elements) =>
      FieldValueArrayRemove(List<String>.unmodifiable(elements));
}

/// Firebase Auth error.
class FirebaseAuthException implements Exception {
  final String code;
  final String message;

  const FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => 'FirebaseAuthException($code): $message';
}

/// Decoded Firebase ID Token.
class DecodedIdToken {
  final String uid;
  final String? email;
  final bool? admin;

  const DecodedIdToken({
    required this.uid,
    this.email,
    this.admin,
  });
}

/// Abstract Firebase Auth service.
abstract class AuthService {
  Future<DecodedIdToken> verifyIdToken(String idToken);
  Future<void> deleteUser(String uid);
}

/// Individual FCM send response within a multicast batch.
class SendResponse {
  final bool success;
  final String? errorCode;
  final String? errorMessage;

  const SendResponse({
    required this.success,
    this.errorCode,
    this.errorMessage,
  });
}

/// FCM multicast batch response.
class BatchResponse {
  final int successCount;
  final int failureCount;
  final List<SendResponse> responses;

  const BatchResponse({
    required this.successCount,
    required this.failureCount,
    required this.responses,
  });
}

/// Abstract Firebase Cloud Messaging service.
abstract class MessagingService {
  Future<BatchResponse> sendEachForMulticast(Map<String, dynamic> message);
  dynamic get rawMessaging => null;
}

/// Abstract Firestore Database.
abstract class FirestoreDatabase {
  CollectionReference collection(String path);
  Query collectionGroup(String collectionId);
  Future<List<DocumentSnapshot>> getAll(List<DocumentReference> refs);
  WriteBatch batch();
  Future<void> recursiveDelete(DocumentReference ref);
  dynamic get rawDb => null;
}

/// Abstract Firestore Collection Reference.
abstract class CollectionReference extends Query {
  DocumentReference doc([String? id]);
}

/// Abstract Firestore Query.
abstract class Query {
  Query where(String field, String op, dynamic value);
  Query orderBy(String field, [String direction = 'asc']);
  Query limit(int count);
  Future<QuerySnapshot> get();
}

/// Abstract Firestore Query Snapshot.
abstract class QuerySnapshot {
  bool get empty;
  int get size;
  List<DocumentSnapshot> get docs;
}

/// Abstract Firestore Document Reference.
abstract class DocumentReference {
  String get id;
  CollectionReference collection(String path);
  Future<DocumentSnapshot> get();
  Future<void> set(Map<String, dynamic> data, {bool merge = false});
  Future<void> update(Map<String, dynamic> data);
  Future<void> delete();
}

/// Abstract Firestore Document Snapshot.
abstract class DocumentSnapshot {
  String get id;
  bool get exists;
  Map<String, dynamic>? data();
  DocumentReference? get ref;
}

/// Abstract Firestore WriteBatch.
abstract class WriteBatch {
  void set(
    DocumentReference ref,
    Map<String, dynamic> data, {
    bool merge = false,
  });
  void update(DocumentReference ref, Map<String, dynamic> data);
  void delete(DocumentReference ref);
  Future<void> commit();
}
