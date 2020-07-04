import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';

import '../../shared/loader.dart';
import '../../shared/no_back_scaffold95.dart';

class UserInfoForm extends StatefulWidget {
  @override
  _UserInfoEntryState createState() => _UserInfoEntryState();
}

class _UserInfoEntryState extends State<UserInfoForm> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();

  bool loading = false;

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NoBackScaffold95(
        title: "Set Account Details",
        body: Builder(
          builder: (context) => Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: Column(
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Username:", style: Flutter95.textStyle),
                      ),
                      TextField95(
                        key: const Key("Username Input"),
                        controller: usernameController,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  alignment: Alignment.center,
                  child: Button95(
                    key: const Key("Sign Up Button"),
                    onTap: () async {
                      // Remove keyboard focus (dismiss the keyboard so they see the SnackBar).
                      final FocusScopeNode currentFocus =
                          FocusScope.of(context);
                      if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                      }

                      if (formKey.currentState.validate()) {
                        setState(() => loading = true);

                        final setUsername =
                            CloudFunctions.instance.getHttpsCallable(
                          functionName: 'setUsername',
                        );

                        // Attempt to set the username of this user, but this will fail if the server detects that an account already has registered this username.
                        // We will show a Snackbar message if this is the case.
                        try {
                          await setUsername
                              .call({"username": usernameController.text});
                        } catch (error) {
                          setState(() => loading = false);

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
                                          "An error occured while signing up!",
                                          style: TextStyle(
                                            color: Flutter95.black,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        error.details['message'],
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          return;
                        }

                        // If no errors occured with setting their main & Riot ID, pop back to the login page.
                        Navigator.of(context).pop();
                      }
                    },
                    child: SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          loading
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Loader(size: 15),
                                )
                              : const SizedBox(),
                          const Text('Sign Up'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
