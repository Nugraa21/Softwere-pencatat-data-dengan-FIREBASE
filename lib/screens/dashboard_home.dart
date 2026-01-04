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
    IdeasTab()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: StudioTheme.glassBase,
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
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
                                color:
                                    StudioTheme.accent.value.withOpacity(0.15),
                                shape: BoxShape.circle),
                            child: Icon(CupertinoIcons.lock_shield_fill,
                                size: 32, color: StudioTheme.accent.value),
                          ),
                          const SizedBox(width: 16),
                          const Text('VaultX',
                              style: TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(width: 80),
                      _tabButton(0, 'Vault', CupertinoIcons.lock_shield),
                      const SizedBox(width: 40),
                      _tabButton(1, 'Notes', CupertinoIcons.doc_text),
                      const SizedBox(width: 40),
                      _tabButton(2, 'Bookmarks', CupertinoIcons.bookmark),
                      const SizedBox(width: 40),
                      _tabButton(3, 'Ideas', CupertinoIcons.lightbulb),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: CircleAvatar(
                          backgroundColor:
                              StudioTheme.accent.value.withOpacity(0.15),
                          child: Icon(CupertinoIcons.person,
                              color: StudioTheme.accent.value),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'logout', child: Text("Logout")),
                        ],
                        onSelected: (value) {
                          if (value == 'logout') {
                            FirebaseAuth.instance.signOut();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _tabs[_selectedTab]),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final bool selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? StudioTheme.accent.value.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 26,
                color: selected
                    ? StudioTheme.accent.value
                    : StudioTheme.secondaryText),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? StudioTheme.accent.value : StudioTheme.text,
                )),
          ],
        ),
      ),
    );
  }
}
