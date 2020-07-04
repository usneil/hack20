import 'dart:convert';

import 'package:animated_widgets/animated_widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:shake/shake.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:http/http.dart' as http;

import '../main.dart';
import '../models/post.dart';
import '../models/post_refrence.dart';
import '../models/user.dart';
import '../services/auth.dart';
import '../services/db.dart';
import '../shared/debounce.dart';
import '../shared/loader.dart';
import 'profile.dart';

class FeedScreen extends StatelessWidget {
  final AuthService auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold95(
      title: "Polargram - Instagram like it's 1995",
      toolbar: Toolbar95(actions: [
        Item95(
          label: 'New Polaroid',
          onTap: (context) =>
              Navigator.push(context, newPolaroidRouteBuilder()),
        ),
        const Item95(
          label: '|',
        ),
        Item95(
          label: 'Settings',
          menu: Menu95(
            items: [
              MenuItem95(
                value: 1,
                label: 'Logout',
              ),
            ],
            onItemSelected: (item) {
              if (item == 1) {
                auth.signOut();
                Navigator.pushReplacement(context, loginRouteBuilder());
              }
            },
          ),
        ),
        const Item95(
          label: '|',
        ),
        Item95(
          label: 'Search',
          onTap: (context) => Navigator.push(context, searchRouteBuilder()),
        ),
      ]),
      body: PostList(
        getFeed: () async {
          final user = await auth.getUser;

          final feeds = await Future.wait([
            CloudFunctions.instance
                .getHttpsCallable(
                  functionName: 'getFeed',
                )
                .call(),
            http.post(
              "https://crows.sh/polargramDiscover",
              body: json.encode({"user_id": user.uid}),
              headers: {
                "Accept": "application/json",
                "Content-Type": "application/json"
              },
            ),
          ]);

          final followingFeed =
              (((feeds[0] as HttpsCallableResult).data as List) ?? [])
                  .map((item) => PostRefrence(
                      postID: item["postID"] as String,
                      userID: item["userID"] as String,
                      timestamp: item["timestamp"] as int))
                  .toList();

          final discoverFeed =
              ((json.decode((feeds[1] as Response).body) as List) ?? [])
                  .map((item) => PostRefrence(
                      postID: item["postID"] as String,
                      userID: item["userID"] as String,
                      timestamp: item["timestamp"] as int))
                  .toList();

          followingFeed.addAll(discoverFeed);

          // Remove duplicates.
          return followingFeed.toSet().toList();
        },
      ),
    );
  }
}

class PostList extends StatefulWidget {
  const PostList({Key key, this.getFeed}) : super(key: key);

  final Future<List<PostRefrence>> Function() getFeed;

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  Future<List<PostRefrence>> _feedFuture;

  final Debouncer _debouncer = Debouncer(milliseconds: 700);
  ShakeDetector _detector;
  bool _shake = false;
  String _visiblePostID;
  String _visiblePostCreatorID;

  final PageController _pageController =
      PageController(initialPage: 1, keepPage: true);

  @override
  void initState() {
    _detector = ShakeDetector.autoStart(
      onPhoneShake: handleShake,
    );

    _feedFuture = widget.getFeed();

    super.initState();
  }

  @override
  void dispose() {
    _detector.stopListening();
    _pageController.dispose();
    super.dispose();
  }

  void refresh() {
    setState(() {
      _feedFuture = widget.getFeed();
    });
  }

  Null handleShake() {
    // Ensure we are viewing a post currently before we update the DB.
    if (_visiblePostID != null && _visiblePostCreatorID != null) {
      _debouncer.run(() {
        final self = Provider.of<User>(context, listen: false);

        if (self == null) {
          print("self was null!");
          return;
        }

        if ((self?.shakenPosts["$_visiblePostCreatorID+$_visiblePostID"] ?? 0) <
            4) {
          setState(() {
            _shake = true;
          });

          Document<Post>(
            path: "users/$_visiblePostCreatorID/posts/$_visiblePostID",
          ).update(
            {
              "shakes.${self.id}": FieldValue.increment(1),
            },
          );

          UserDocument<User>().update(
            {
              "shaken_posts.$_visiblePostCreatorID+$_visiblePostID":
                  FieldValue.increment(1),
            },
          );

          Future.delayed(const Duration(milliseconds: 700), () {
            setState(() {
              _shake = false;
            });
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final self = Provider.of<User>(context);

    if (self == null) {
      return ExpandedCenterLoader();
    }

    return FutureBuilder<List<PostRefrence>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final feed = snapshot.data
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: PageView.builder(
                onPageChanged: (index) {
                  if (index == 0) {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    refresh();
                  }
                },
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: feed.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Loader(size: 40),
                        ),
                      ],
                    );
                  }

                  // If at the end of feed, allow users to refresh.
                  if (index == feed.length + 1) {
                    return Center(
                      child: GestureDetector(
                        onTap: () => {
                          _pageController.animateToPage(
                            0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          )
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "This is the end of your feed!",
                              style: TextStyle(
                                color: Flutter95.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            Text(
                              "Follow users or 'shake' posts to get more recommendations (or click this screen to refresh)",
                              textAlign: TextAlign.center,
                              style: Flutter95.textStyle,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final feedItem = feed[index - 1];

                  final feedUserID = feedItem.userID;
                  final feedPostID = feedItem.postID;

                  return StreamBuilder<User>(
                    stream:
                        Document<User>(path: "users/$feedUserID").streamData(),
                    builder: (context, userSnapshot) {
                      return StreamBuilder<Post>(
                        stream: Document<Post>(
                          path: "users/$feedUserID/posts/$feedPostID",
                        ).streamData(),
                        builder: (context, postSnapshot) {
                          if (userSnapshot.hasData && postSnapshot.hasData) {
                            final Post post = postSnapshot.data;
                            final User user = userSnapshot.data;

                            final int shakes = post.shakes.values.isNotEmpty
                                ? post.shakes.values
                                    .reduce((value, element) => value + element)
                                : 0;

                            final String timestamp =
                                DateTime.fromMillisecondsSinceEpoch(
                                        post.timestamp)
                                    .toLocal()
                                    .toString()
                                    .split(" ")[0];

                            String image;

                            switch (shakes) {
                              case 0:
                                image = post.image_0;
                                break;

                              case 1:
                                image = post.image_1;
                                break;

                              case 2:
                                image = post.image_2;
                                break;

                              case 3:
                                image = post.image_3;
                                break;

                              default:
                                image = post.image_4;
                                break;
                            }

                            return GestureDetector(
                              onDoubleTap: handleShake,
                              child: VisibilityDetector(
                                key: Key(post.id),
                                onVisibilityChanged: (visibilityInfo) {
                                  if (visibilityInfo.visibleFraction >= 0.8) {
                                    setState(() {
                                      _visiblePostID = post.id;
                                      _visiblePostCreatorID = user.id;
                                    });

                                    for (final imageURL in post.images) {
                                      precacheImage(
                                        NetworkImage(imageURL),
                                        context,
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.only(top: 60),
                                  alignment: Alignment.topCenter,
                                  child: ShakeAnimatedWidget(
                                    enabled: _shake,
                                    duration: const Duration(milliseconds: 700),
                                    shakeAngle: Rotation.deg(z: 20, x: 70),
                                    curve: Curves.bounceOut,
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: 291,
                                          height: 355,
                                          child: Image.asset(
                                            "assets/polaroid.png",
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 23,
                                            left: 25,
                                          ),
                                          child: SizedBox(
                                            width: 245,
                                            height: 255,
                                            child: Image.network(
                                              image,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 244,
                                          height: 70,
                                          margin: const EdgeInsets.only(
                                            left: 25,
                                            top: 276,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                post.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Flutter95.black,
                                                  fontSize: 17,
                                                  decoration:
                                                      TextDecoration.none,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Text("by ",
                                                      style:
                                                          Flutter95.textStyle),
                                                  GestureDetector(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (ctx) =>
                                                            Profile(
                                                                userID: user.id,
                                                                username: user
                                                                    .username),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      user.username,
                                                      style: const TextStyle(
                                                        color: Flutter95
                                                            .headerLight,
                                                        fontSize: 14,
                                                        decoration:
                                                            TextDecoration.none,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(" - $timestamp - ",
                                                      style:
                                                          Flutter95.textStyle),
                                                  Flexible(
                                                    child: Text(
                                                      "$shakes shakes",
                                                      softWrap: false,
                                                      overflow:
                                                          TextOverflow.fade,
                                                      style: const TextStyle(
                                                        color: Flutter95
                                                            .headerDark,
                                                        fontSize: 14,
                                                        decoration:
                                                            TextDecoration.none,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return CenterLoader();
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          );
        } else {
          return ExpandedCenterLoader();
        }
      },
    );
  }
}
