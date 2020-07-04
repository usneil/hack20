import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

import '../shared/loader.dart';
import 'profile.dart';

Future<List<User>> searchQuery(String user) => Firestore.instance
    .collection("users")
    .where("username", isGreaterThanOrEqualTo: user)
    .limit(20)
    .getDocuments()
    .then((snapshot) =>
        snapshot.documents.map((d) => User.fromSnapshot(d)).toList());

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController usernameController = TextEditingController();

  Future<List<User>> query;

  @override
  void initState() {
    query = searchQuery("Ben");
    usernameController.addListener(() {
      setState(
        () {
          query = searchQuery(usernameController.text);
        },
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final self = Provider.of<User>(context);

    if (self == null) {
      return LoadingScaffold();
    }

    return FutureBuilder<List<User>>(
      future: query,
      builder: (context, usersSnapshot) {
        if (usersSnapshot.hasData) {
          final users = usersSnapshot.data;

          return Scaffold95(
            title: "Search",
            body: Expanded(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    TextField95(
                      key: const Key("Search Input"),
                      controller: usernameController,
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];

                          return Button95(
                            height: 60,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Profile(
                                    username: user.username, userID: user.id),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    user.username,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Flutter95.headerLight,
                                      fontSize: 40,
                                      decoration: TextDecoration.none,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: self.following.contains(user.id)
                                        ? const Text(
                                            "(Following)",
                                            style: TextStyle(
                                              color: Flutter95.headerLight,
                                              fontSize: 15,
                                              decoration: TextDecoration.none,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : const SizedBox(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        } else {
          return LoadingScaffold();
        }
      },
    );
  }
}
