import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';
import 'package:provider/provider.dart';

import '../models/post.dart';
import '../models/post_refrence.dart';
import '../models/user.dart';
import '../services/db.dart';
import '../shared/loader.dart';
import 'feed.dart';

class Profile extends StatefulWidget {
  const Profile({
    @required this.userID,
    @required this.username,
    Key key,
  }) : super(key: key);

  final String userID;
  final String username;

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool loading = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Post>>(
        stream:
            Collection<Post>(path: "users/${widget.userID}/posts").streamData(),
        builder: (context, postsSnapshot) {
          final self = Provider.of<User>(context);

          if (self == null) {
            return LoadingScaffold();
          }

          if (postsSnapshot.hasData) {
            final posts = postsSnapshot.data;

            return Scaffold95(
              title: widget.username,
              body: Expanded(
                child: Column(
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.only(bottom: 4, left: 5, right: 5),
                      child: !self.following.contains(widget.userID)
                          ? Button95(
                              onTap: () async {
                                setState(() => loading = true);
                                await CloudFunctions.instance
                                    .getHttpsCallable(
                                  functionName: 'followUser',
                                )
                                    .call({"userID": widget.userID});
                                setState(() => loading = false);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  loading
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Loader(size: 15),
                                        )
                                      : const SizedBox(),
                                  const Text("Follow This User",
                                      style: Flutter95.textStyle),
                                ],
                              ),
                            )
                          : Button95(
                              onTap: () async {
                                setState(() => loading = true);
                                await CloudFunctions.instance
                                    .getHttpsCallable(
                                  functionName: 'unFollowUser',
                                )
                                    .call({"userID": widget.userID});
                                setState(() => loading = false);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  loading
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: Loader(size: 15),
                                        )
                                      : const SizedBox(),
                                  const Text("Unfollow This User",
                                      style: Flutter95.textStyle),
                                ],
                              ),
                            ),
                    ),
                    PostList(
                      getFeed: () => Future.sync(
                        () => posts
                            .map((p) => PostRefrence(
                                  userID: widget.userID,
                                  postID: p.id,
                                  timestamp: p.timestamp,
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return LoadingScaffold();
          }
        },
      );
}
