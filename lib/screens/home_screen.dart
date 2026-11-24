import 'package:flutter/material.dart';

import '../theme/quran_theme.dart';
import 'saved_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'surah_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  double _pull = 0;
  bool _searchOpen = false;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification &&
        notification.overscroll < 0 &&
        notification.dragDetails != null) {
      _pull -= notification.overscroll;
      if (_pull > 72 && !_searchOpen) _openSearch();
    } else if (notification is ScrollEndNotification) {
      _pull = 0;
    }
    return false;
  }

  void _openSearch() {
    _searchOpen = true;
    _pull = 0;
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SearchScreen()))
        .then((_) => _searchOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScrollNotification,
        child: IndexedStack(
          index: _index,
          children: const [SurahListScreen(), SavedScreen(), SettingsScreen()],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: QColors.rule)),
        ),
        child: NavigationBar(
          backgroundColor: QColors.surface,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0x33009E49),
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => capsStyle(
              size: 10,
              color: states.contains(WidgetState.selected)
                  ? QColors.accentBright
                  : QColors.dim,
            ),
          ),
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt, color: QColors.accentBright),
              label: 'SURAHS',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_outlined),
              selectedIcon: Icon(Icons.bookmark, color: QColors.accentBright),
              label: 'SAVED',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune, color: QColors.accentBright),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
