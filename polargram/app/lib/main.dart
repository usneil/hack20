import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';
import 'package:provider/provider.dart';

import 'models/user.dart';
import 'pages/feed.dart';
import 'pages/login.dart';
import 'pages/new_polaroid.dart';
import 'pages/search.dart';
import 'services/db.dart';

typedef RouteBuilder = MaterialPageRoute Function();

final RouteBuilder newPolaroidRouteBuilder =
    () => MaterialPageRoute(builder: (ctx) => NewPolaroidScreen());

final RouteBuilder feedRouteBuilder =
    () => MaterialPageRoute(builder: (ctx) => FeedScreen());

final RouteBuilder loginRouteBuilder =
    () => MaterialPageRoute(builder: (ctx) => LoginScreen());

final RouteBuilder searchRouteBuilder =
    () => MaterialPageRoute(builder: (ctx) => SearchScreen());

void main() {
  runApp(Flutter95App());
}

class Flutter95App extends StatelessWidget {
  @override
  Widget build(BuildContext context) => StreamProvider.value(
        value: UserDocument<User>().documentStream,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          color: Flutter95.background,
          home: LoginScreen(),
        ),
      );
}
