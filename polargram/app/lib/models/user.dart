import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/db.dart';
import 'post.dart';

class User {
  User({this.id, this.username, this.posts, this.following, this.shakenPosts});

  factory User.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data;

    return User(
      id: snap.documentID,
      username: data["username"] ?? "USERNAME_MISSING",
      posts: Collection(path: "users/${snap.documentID}/posts"),
      following: ((data["following"] as List) ?? [])
          .map((item) => item.toString())
          .toList(),
      shakenPosts: ((data["shaken_posts"] as Map) ?? {})
          .map((key, value) => MapEntry(key, value as int)),
    );
  }

  final String id;
  final String username;
  final Collection<Post> posts;
  final List<String> following;
  final Map<String, int> shakenPosts;
}
