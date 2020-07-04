import 'package:flutter/material.dart';
import 'package:flutter95/flutter95.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Loader extends StatelessWidget {
  const Loader({this.size = 250, this.color = Colors.black});

  /// The size of the loader
  final double size;

  /// The color of the loader
  final Color color;

  @override
  Widget build(BuildContext context) => SpinKitWave(
        color: color,
        size: size,
      );
}

class CenterLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Center(child: Loader(size: 70));
}

class ExpandedCenterLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Expanded(child: Center(child: Loader(size: 70)));
}

class LoadingScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold95(
        title: "Loading...",
        body: ExpandedCenterLoader(),
      );
}
