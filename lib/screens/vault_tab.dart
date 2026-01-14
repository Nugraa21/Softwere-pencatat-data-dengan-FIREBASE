import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../theme/studio_theme.dart';
import '../services/firestore_service.dart';
import '../models/account.dart';

class VaultTab extends StatefulWidget {
  const VaultTab({super.key});

  @override
  State<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<VaultTab> {
  List<Account> _data = [];
  List<Account> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _loadData() async {
    final list = await FirestoreService.loadAccounts();
    setState(() {
      _data = list;
      _filtered = list;
    });
  }

  void _filter() {
    setState(() {
      _filtered = _data
          .where((e) =>
              e.title.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
          .toList();
    });
  }

  // =========================
  // FORM (BOTTOM SHEET)
  // =========================
  void _showForm({Account? item}) {
    String t = item?.title ?? "";
    String u = item?.user ?? "";
    String p = item?.pass ?? "";
    String ph = item?.phone ?? "";
    String n = item?.note ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: StudioTheme.cardGlass,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Text(
                        item == null ? "Tambah Entri" : "Edit Entri",
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text("Simpan"),
                        onPressed: () async {
                          if (t.isNotEmpty) {
                            final id = item?.id ??
                                DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString();
                            final acc = Account(
                              id: id,
                              title: t,
                              user: u,
                              pass: p,
                              phone: ph,
                              note: n,
                            );

                            if (item == null) {
                              await FirestoreService.addAccount(acc);
                            } else {
                              await FirestoreService.updateAccount(acc);
                            }

                            _loadData();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _field("Title / App", t, (v) => t = v),
                        const SizedBox(height: 16),
                        _field("Username", u, (v) => u = v),
                        const SizedBox(height: 16),
                        _field("Password", p, (v) => p = v, obscure: true),
                        const SizedBox(height: 16),
                        _field("Phone", ph, (v) => ph = v),
                        const SizedBox(height: 16),
                        _field("Notes", n, (v) => n = v, maxLines: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String placeholder,
    String initial,
    Function(String) onChange, {
    bool obscure = false,
    int maxLines = 1,
  }) {
    return CupertinoTextField(
      controller: TextEditingController(text: initial),
      placeholder: placeholder,
      obscureText: obscure,
      maxLines: maxLines,
      onChanged: onChange,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }

  // =========================
  // CARD
  // =========================
  Widget _buildCard(Account item, bool isMobile) {
    return GestureDetector(
      onTap: () => _showForm(item: item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            margin: EdgeInsets.only(bottom: isMobile ? 16 : 32),
            decoration: BoxDecoration(
              color: StudioTheme.cardGlass,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "User: ${item.user}",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    color: StudioTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Phone: ${item.phone.isEmpty ? '-' : item.phone}",
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 18,
                    color: StudioTheme.secondaryText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(CupertinoIcons.lock, size: isMobile ? 18 : 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.isVisible ? item.pass : "••••••••••",
                        style: TextStyle(fontSize: isMobile ? 14 : 18),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.doc_on_clipboard),
                      onPressed: () =>
                          Clipboard.setData(ClipboardData(text: item.pass)),
                    ),
                    IconButton(
                      icon: Icon(
                        item.isVisible
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                      ),
                      onPressed: () =>
                          setState(() => item.isVisible = !item.isVisible),
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(
                      CupertinoIcons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      final confirm = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Hapus entri?"),
                              actions: [
                                CupertinoDialogAction(
                                    child: const Text("Batal"),
                                    onPressed: () =>
                                        Navigator.pop(context, false)),
                                CupertinoDialogAction(
                                    isDestructiveAction: true,
                                    child: const Text("Hapus"),
                                    onPressed: () =>
                                        Navigator.pop(context, true)),
                              ],
                            ),
                          ) ??
                          false;

                      if (confirm) {
                        await FirestoreService.deleteAccount(item.id);
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // BUILD
  // =========================
  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              backgroundColor: StudioTheme.accent.value,
              onPressed: _showForm,
              child: const Icon(CupertinoIcons.add),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 16 : 60,
              isMobile ? 16 : 40,
              isMobile ? 16 : 60,
              16,
            ),
            child: CupertinoSearchTextField(
              controller: _searchCtrl,
              placeholder: "Cari vault...",
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 28,
                vertical: isMobile ? 14 : 20,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              style: TextStyle(
                fontSize: isMobile ? 15 : 18,
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lock_shield,
                            size: isMobile ? 80 : 140,
                            color: StudioTheme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 24),
                        Text(
                          "Vault kosong",
                          style: TextStyle(
                            fontSize: isMobile ? 22 : 36,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tambah entri dengan tombol +",
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 20,
                            color: StudioTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding:
                        EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60),
                    children:
                        _filtered.map((e) => _buildCard(e, isMobile)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
