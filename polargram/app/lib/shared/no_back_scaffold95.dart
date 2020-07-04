import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';

class NoBackScaffold95 extends StatelessWidget {
  const NoBackScaffold95({
    @required this.title,
    @required this.body,
    this.toolbar,
    Key key,
  }) : super(key: key);

  final String title;
  final Widget body;
  final Toolbar95 toolbar;

  @override
  Widget build(BuildContext context) => Elevation95(
        child: Column(
          children: <Widget>[
            WindowHeaderCustom95(title: title),
            const SizedBox(height: 4),
            if (toolbar != null) toolbar,
            if (toolbar != null) const SizedBox(height: 4),
            body,
          ],
        ),
      );
}

class WindowHeaderCustom95 extends StatefulWidget {
  const WindowHeaderCustom95({
    @required this.title,
    Key key,
  }) : super(key: key);

  final String title;

  @override
  _WindowHeader95State createState() => _WindowHeader95State();
}

class _WindowHeader95State extends State<WindowHeaderCustom95> {
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Container(
            height: 33,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Flutter95.headerDark,
                  Flutter95.headerLight,
                ],
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: Flutter95.headerTextStyle,
                ),
                const Spacer(),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      );
}
