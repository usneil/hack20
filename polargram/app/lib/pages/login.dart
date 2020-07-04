import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter95/flutter95.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../main.dart';
import '../services/auth.dart';
import '../shared/loader.dart';

class LoginScreen extends StatefulWidget {
  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  AuthService auth = AuthService();

  @override
  void initState() {
    super.initState();
    auth.getUser.then(
      (user) {
        if (user != null) {
          Navigator.pushReplacement(context, feedRouteBuilder());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold95(
        title: "Login/Sign Up",
        body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              LoginButton(
                text: 'LOGIN WITH GOOGLE',
                loginMethod: auth.googleSignIn,
                icon: FontAwesomeIcons.google,
              ),
              LoginButton(
                text: 'LOGIN WITH EMAIL',
                loginMethod: auth.emailSignIn,
                icon: FontAwesomeIcons.mailBulk,
              ),
              FutureBuilder(
                future: auth.appleSignInAvailable,
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return LoginButton(
                      text: 'LOGIN WITH APPLE',
                      loginMethod: auth.appleSignIn,
                      icon: FontAwesomeIcons.apple,
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ],
          ),
        ),
      );
}

/// A resuable login button for multiple auth methods
class LoginButton extends StatelessWidget {
  LoginButton({Key key, this.text, this.icon, this.loginMethod})
      : super(key: key);

  final IconData icon;
  final String text;
  final Future<AuthResponse> Function(BuildContext) loginMethod;

  bool loading = false;

  @override
  Widget build(BuildContext context) => StatefulBuilder(
        builder: (context, setState) => Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Button95(
            height: 40,
            key: Key(text),
            onTap: () async {
              setState(() => loading = true);
              final authResponse = await loginMethod(context);
              setState(() => loading = false);

              // If authResponse is null, then the user closed the sign-in window, so don't alert them of an error.
              if (authResponse != null) {
                if (authResponse.user != null) {
                  // If the authResponse user is not null, then they successfully signed in.
                  Navigator.pushReplacement(context, feedRouteBuilder());
                } else {
                  // If the authResponse user is  null, then an error occured in the login proccess.
                  showModalBottomSheet(
                    context: context,
                    builder: (ctx) => Elevation95(
                      child: SizedBox(
                        height: 100,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  "An error occured while signing/logging in!",
                                  style: TextStyle(
                                    color: Flutter95.black,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                authResponse?.error is PlatformException
                                    ? authResponse?.error?.message ??
                                        "An unknown error occured!"
                                    : "An unknown error occured!",
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: loading ? const Loader(size: 18) : Icon(icon),
                ),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
