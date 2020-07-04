import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';
import '../models/user.dart';

final _models = {
  User: (snapshot) => User.fromSnapshot(snapshot),
  Post: (snapshot) => Post.fromSnapshot(snapshot),
};

class UserDocument<T> {
  UserDocument({this.collection = "users"});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection;

  Stream<T> get documentStream {
    StreamSubscription<T> docStream;
    StreamSubscription<FirebaseUser> authStream;
    StreamController<T> controller;

    controller = StreamController<T>(
      onListen: () {
        authStream = _auth.onAuthStateChanged.listen((user) {
          if (user != null) {
            final Document<T> doc =
                Document<T>(path: '$collection/${user.uid}');
            docStream = doc.streamData().listen(
              (event) {
                controller.add(event);
              },
            );
          } else {
            docStream?.cancel();
            controller.add(null);
          }
        });
      },
      onCancel: () {
        docStream?.cancel();
        authStream?.cancel();
      },
    );

    return controller.stream;
  }

  Future<T> getDocument() async {
    final FirebaseUser user = await _auth.currentUser();

    if (user != null) {
      final Document doc = Document<T>(path: '$collection/${user.uid}');
      return doc.getData();
    } else {
      return null;
    }
  }

  Future<void> updateOrSetData(Map data) async {
    final FirebaseUser user = await _auth.currentUser();
    final Document<T> ref = Document(path: '$collection/${user.uid}');
    return ref.updateOrSetData(data);
  }

  Future<void> update(Map data) async {
    final FirebaseUser user = await _auth.currentUser();
    final Document<T> ref = Document(path: '$collection/${user.uid}');
    return ref.update(data);
  }
}

class UserCollection<T> {
  UserCollection({this.collection = "users", this.subCollection});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String collection;
  final String subCollection;

  Stream<List<T>> get documentStream {
    StreamSubscription<List<T>> colStream;
    StreamSubscription<FirebaseUser> authStream;
    StreamController<List<T>> controller;

    controller = StreamController<List<T>>(
      onListen: () {
        authStream = _auth.onAuthStateChanged.listen((user) {
          if (user != null) {
            final Collection<T> col =
                Collection<T>(path: '$collection/${user.uid}/$subCollection');

            colStream = col.streamData().listen(
              (event) {
                controller.add(event);
              },
            );
          } else {
            colStream?.cancel();
            controller.add(null);
          }
        });
      },
      onCancel: () {
        colStream?.cancel();
        authStream?.cancel();
      },
    );

    return controller.stream;
  }

  Future<List<T>> getCollection() async {
    final FirebaseUser user = await _auth.currentUser();

    if (user != null) {
      final Collection<T> col =
          Collection<T>(path: '$collection/${user.uid}/$subCollection');
      return col.getData();
    } else {
      return null;
    }
  }
}

class Document<T> {
  Document({this.path}) {
    ref = _db.document(path);
  }

  final Firestore _db = Firestore.instance;
  final String path;

  DocumentReference ref;

  Future<T> getData() => ref.get().then((v) => _models[T](v) as T);

  Stream<T> streamData() => ref.snapshots().map((v) => _models[T](v) as T);

  Future<void> updateOrSetData(Map data) => ref
      .setData(Map<String, dynamic>.from(data), merge: true)
      .catchError(print);

  Future<void> update(Map data) =>
      ref.updateData(Map<String, dynamic>.from(data)).catchError(print);
}

class Collection<T> {
  Collection({this.path}) {
    ref = _db.collection(path);
  }

  final Firestore _db = Firestore.instance;
  final String path;
  CollectionReference ref;

  Future<List<T>> getData() async {
    final snapshots = await ref.getDocuments();
    return snapshots.documents.map((doc) => _models[T](doc) as T).toList();
  }

  Stream<List<T>> streamData() => ref.snapshots().map((snapshot) =>
      snapshot.documents.map((doc) => _models[T](doc) as T).toList());
}
