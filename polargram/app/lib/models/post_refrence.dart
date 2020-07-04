class PostRefrence {
  PostRefrence({this.userID, this.postID, this.timestamp});

  final String userID;
  final String postID;
  final int timestamp;

  @override
  bool operator ==(Object other) {
    // Dart ensures that operator== isn't called with null
    // if(other == null) {
    //   return false;
    // }

    if (other is! PostRefrence) {
      return false;
    }

    return timestamp == (other as PostRefrence).timestamp;
  }

  int _hashCode;
  @override
  int get hashCode {
    _hashCode ??= timestamp.hashCode;
    return _hashCode;
  }
}
