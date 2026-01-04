import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Added this import
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

  void _showForm({Account? item}) {
    String t = item?.title ?? "";
    String u = item?.user ?? "";
    String p = item?.pass ?? "";
    String ph = item?.phone ?? "";
    String n = item?.note ?? "";
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              color: StudioTheme.cardGlass,
              child: CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  middle: Text(item == null ? "Tambah Entri" : "Edit Entri"),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Simpan"),
                    onPressed: () async {
                      if (t.isNotEmpty) {
                        final id = item?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString();
                        final acc = Account(
                            id: id,
                            title: t,
                            user: u,
                            pass: p,
                            phone: ph,
                            note: n);
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
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    children: [
                      _field("Title/App", t, (v) => t = v),
                      const SizedBox(height: 24),
                      _field("Username", u, (v) => u = v),
                      const SizedBox(height: 24),
                      _field("Password", p, (v) => p = v, obscure: true),
                      const SizedBox(height: 24),
                      _field("Phone", ph, (v) => ph = v),
                      const SizedBox(height: 24),
                      _field("Notes", n, (v) => n = v, maxLines: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String placeholder, String initial, Function(String) onChange,
      {bool obscure = false, int maxLines = 1}) {
    return CupertinoTextField(
      placeholder: placeholder,
      controller: TextEditingController(text: initial),
      onChanged: onChange,
      obscureText: obscure,
      maxLines: maxLines,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20)),
      style: const TextStyle(fontSize: 19),
    );
  }

  Widget _buildCard(Account item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            color: StudioTheme.cardGlass,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12))
            ],
          ),
          child: InkWell(
            onTap: () => _showForm(item: item),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 30, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),
                      Text("User: ${item.user}",
                          style: TextStyle(
                              fontSize: 19, color: StudioTheme.secondaryText)),
                      const SizedBox(height: 10),
                      Text("Phone: ${item.phone.isEmpty ? '-' : item.phone}",
                          style: TextStyle(
                              fontSize: 19, color: StudioTheme.secondaryText)),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Icon(CupertinoIcons.lock,
                              size: 24, color: StudioTheme.secondaryText),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Text(
                                  item.isVisible ? item.pass : "••••••••••",
                                  style: const TextStyle(fontSize: 19))),
                          IconButton(
                              icon: const Icon(CupertinoIcons.doc_on_clipboard,
                                  size: 26),
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: item.pass))),
                          IconButton(
                            icon: Icon(
                                item.isVisible
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
                                size: 26),
                            onPressed: () => setState(
                                () => item.isVisible = !item.isVisible),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.delete,
                      color: Colors.red, size: 32),
                  onPressed: () async {
                    final confirm = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                                  title: const Text("Hapus?"),
                                  actions: [
                                    CupertinoDialogAction(
                                        child: const Text("Batal"),
                                        onPressed: () =>
                                            Navigator.pop(context)),
                                    CupertinoDialogAction(
                                        isDestructiveAction: true,
                                        child: const Text("Hapus"),
                                        onPressed: () =>
                                            Navigator.pop(context, true)),
                                  ],
                                )) ??
                        false;
                    if (confirm) {
                      await FirestoreService.deleteAccount(item.id);
                      _loadData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 40, 60, 20),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSearchTextField(
                    controller: _searchCtrl,
                    placeholder: "Cari vault entries...",
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 20),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24)),
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
                const SizedBox(width: 32),
                FloatingActionButton.large(
                  onPressed: _showForm,
                  backgroundColor: StudioTheme.accent.value,
                  child: const Icon(CupertinoIcons.add, size: 36),
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lock_shield,
                            size: 140,
                            color: StudioTheme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 40),
                        const Text("Vault kosong",
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        Text("Tambah entri pertama dengan tombol +",
                            style: TextStyle(
                                fontSize: 20,
                                color: StudioTheme.secondaryText)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    children:
                        _filtered.map((item) => _buildCard(item)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
