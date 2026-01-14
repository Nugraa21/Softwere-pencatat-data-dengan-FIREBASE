import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import '../theme/studio_theme.dart';
import 'vault_tab.dart';
import 'notes_tab.dart';
import 'bookmarks_tab.dart';
import 'ideas_tab.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _selectedTab = 0;

  final List<Widget> _tabs = const [
    VaultTab(),
    NotesTab(),
    BookmarksTab(),
    IdeasTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    // 🚫 JIKA ADA BUG ORIENTASI (CADANGAN AMAN)
    if (orientation == Orientation.landscape && size.width < 900) {
      return Scaffold(
        backgroundColor: StudioTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.rotate_left,
                size: 120,
                color: StudioTheme.secondaryText.withOpacity(0.4),
              ),
              const SizedBox(height: 24),
              const Text(
                "Mode landscape tidak didukung",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                "Silakan gunakan mode portrait",
                style: TextStyle(
                  fontSize: 18,
                  color: StudioTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isMobile = size.width < 700;

    return Scaffold(
      backgroundColor: StudioTheme.background,

      /// 🔹 MOBILE APP BAR
      appBar: isMobile ? _mobileAppBar() : null,

      /// 🔹 MOBILE BOTTOM NAV
      bottomNavigationBar: isMobile ? _mobileBottomNav() : null,

      body: isMobile
          ? _tabs[_selectedTab]
          : Column(
              children: [
                _desktopTopBar(),
                Expanded(child: _tabs[_selectedTab]),
              ],
            ),
    );
  }

  // =========================
  // DESKTOP TOP BAR
  // =========================
  Widget _desktopTopBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: StudioTheme.glassBase,
            border: Border(
              bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StudioTheme.accent.value.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.lock_shield_fill,
                        size: 32,
                        color: StudioTheme.accent.value,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'VaultX',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 80),
                _desktopTabButton(0, 'Vault', CupertinoIcons.lock_shield),
                const SizedBox(width: 40),
                _desktopTabButton(1, 'Notes', CupertinoIcons.doc_text),
                const SizedBox(width: 40),
                _desktopTabButton(2, 'Bookmarks', CupertinoIcons.bookmark),
                const SizedBox(width: 40),
                _desktopTabButton(3, 'Ideas', CupertinoIcons.lightbulb),
                const Spacer(),
                _profileMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _desktopTabButton(int index, String label, IconData icon) {
    final bool selected = _selectedTab == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? StudioTheme.accent.value.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 26,
              color: selected
                  ? StudioTheme.accent.value
                  : StudioTheme.secondaryText,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? StudioTheme.accent.value : StudioTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // MOBILE UI
  // =========================
  PreferredSizeWidget _mobileAppBar() {
    return AppBar(
      backgroundColor: StudioTheme.background,
      elevation: 0,
      title: Row(
        children: [
          Icon(
            CupertinoIcons.lock_shield_fill,
            color: StudioTheme.accent.value,
          ),
          const SizedBox(width: 8),
          const Text(
            'VaultX',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.person),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }

  Widget _mobileBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (i) => setState(() => _selectedTab = i),
      backgroundColor: StudioTheme.background,
      selectedItemColor: StudioTheme.accent.value,
      unselectedItemColor: StudioTheme.secondaryText,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lock_shield), label: 'Vault'),
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.doc_text), label: 'Notes'),
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bookmark), label: 'Bookmarks'),
        BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lightbulb), label: 'Ideas'),
      ],
    );
  }

  // =========================
  // PROFILE MENU
  // =========================
  Widget _profileMenu() {
    return PopupMenuButton<String>(
      icon: CircleAvatar(
        backgroundColor: StudioTheme.accent.value.withOpacity(0.15),
        child: Icon(
          CupertinoIcons.person,
          color: StudioTheme.accent.value,
        ),
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'logout', child: Text("Logout")),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          FirebaseAuth.instance.signOut();
        }
      },
    );
  }
}
