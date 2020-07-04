import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Post {
  Post({
    this.id,
    this.title,
    this.timestamp,
    this.shakes,
    this.image_0,
    this.image_1,
    this.image_2,
    this.image_3,
    this.image_4,
  });

  factory Post.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data;

    return Post(
      id: snap.documentID ?? "ID_MISSING",
      image_0: data["image_0"] ?? "IMAGE0_MISSING",
      image_1: data["image_1"] ?? "IMAGE1_MISSING",
      image_2: data["image_2"] ?? "IMAGE2_MISSING",
      image_3: data["image_3"] ?? "IMAGE3_MISSING",
      image_4: data["image_4"] ?? "IMAGE4_MISSING",
      title: data["title"] ?? "TITLE_MISSING",
      timestamp: data["timestamp"] as int ?? 0,
      shakes: ((data["shakes"] as Map) ?? {})
          .map((key, value) => MapEntry(key, value as int)),
    );
  }

  final String id;
  final String image_0;
  final String image_1;
  final String image_2;
  final String image_3;
  final String image_4;

  List<String> get images => [image_0, image_1, image_2, image_3, image_4];

  final String title;
  final int timestamp;
  final Map<String, int> shakes;
}
