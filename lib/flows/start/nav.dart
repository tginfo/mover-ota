import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sticker_import/flows/settings/about.dart';
import 'package:sticker_import/flows/start/start.dart';
import 'package:sticker_import/flows/user/actions.dart';
import 'package:sticker_import/generated/l10n.dart';
import 'package:sticker_import/utils/check_support.dart';
import 'package:sticker_import/utils/check_updates.dart';

enum StartRouteScreen { start, login, about }

class StartRoute extends StatefulWidget {
  const StartRoute({this.tab = StartRouteScreen.start, Key? key})
      : super(key: key);

  final StartRouteScreen tab;

  @override
  StartRouteState createState() => StartRouteState();
}

class StartRouteState extends State<StartRoute> {
  late int _selectedIndex;

  static const List<Widget> _widgetOptions = <Widget>[
    ImportByLinkRoute(),
    VkUserMenuRoute(
      intent: null,
    ),
    AboutRoute(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    _selectedIndex = widget.tab.index;
    super.initState();

    if (widget.tab == StartRouteScreen.start) {
      Timer.run(() async {
        if (await checkUpdates(context)) return;

        checkSupport(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.link_rounded),
            label: S.of(context).by_link,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: S.of(context).vk_account,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.info_rounded),
            label: S.of(context).about_program,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
