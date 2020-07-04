import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';

import '../../services/auth.dart';

class EmailLoginForm extends StatefulWidget {
  @override
  _EmailLoginFormState createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<EmailLoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold95(
        title: "Login with Email",
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Email", style: Flutter95.textStyle),
                  ),
                  TextField95(
                    key: const Key("Email Input"),
                    controller: emailController,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Password", style: Flutter95.textStyle),
                    ),
                  ),
                  TextField95(
                    key: const Key("Password Input"),
                    controller: passwordController,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Button95(
                    key: const Key("Sign In Button"),
                    onTap: () {
                      Navigator.pop(context, {
                        "email": emailController.text,
                        "password": passwordController.text,
                        "method": AuthMethod.SIGN_IN,
                      });
                    },
                    child: const Text("Sign In"),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Button95(
                      key: const Key("Sign Up Button"),
                      onTap: () {
                        Navigator.pop(context, {
                          "email": emailController.text,
                          "password": passwordController.text,
                          "method": AuthMethod.SIGN_UP,
                        });
                      },
                      child: const Text("Sign Up"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
