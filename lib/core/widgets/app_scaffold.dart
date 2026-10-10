import 'package:flutter/material.dart';

import 'aurora.dart';
import 'internet_checker_widget.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool showOfflineBanner;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.showOfflineBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    // The scaffold is transparent so the aurora shows behind the app bar too.
    return ColoredBox(
      color: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          const Positioned.fill(child: AuroraBackground()),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: appBar,
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
            body: showOfflineBanner ? InternetCheckerWidget(child: body) : body,
          ),
        ],
      ),
    );
  }
}
