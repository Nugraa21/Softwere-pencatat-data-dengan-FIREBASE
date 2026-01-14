import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Added this import
import 'dart:ui';
import '../theme/studio_theme.dart';
import '../services/firestore_service.dart';
import '../models/bookmark.dart';

class BookmarksTab extends StatefulWidget {
  const BookmarksTab({super.key});

  @override
  State<BookmarksTab> createState() => _BookmarksTabState();
}

class _BookmarksTabState extends State<BookmarksTab> {
  List<Bookmark> _bookmarks = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _loadBookmarks() async {
    final list = await FirestoreService.loadBookmarks();
    setState(() => _bookmarks = list);
  }

  void _filter() {
    setState(() {
      _bookmarks = _bookmarks
          .where((e) =>
              e.title.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
              e.url.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
          .toList();
    });
  }

  void _showForm({Bookmark? item}) {
    String title = item?.title ?? "";
    String url = item?.url ?? "";
    String category = item?.category ?? "Umum";
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              color: StudioTheme.cardGlass,
              child: CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  middle:
                      Text(item == null ? "Tambah Bookmark" : "Edit Bookmark"),
                  trailing: CupertinoButton(
                    child: const Icon(CupertinoIcons.checkmark_alt),
                    onPressed: () async {
                      if (title.isNotEmpty && url.isNotEmpty) {
                        final id = item?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString();
                        final bookmark = Bookmark(
                            id: id,
                            title: title,
                            url: url,
                            category: category,
                            createdAt: DateTime.now());
                        if (item == null) {
                          await FirestoreService.addBookmark(bookmark);
                        } else {
                          await FirestoreService.updateBookmark(bookmark);
                        }
                        _loadBookmarks();
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(
                    children: [
                      CupertinoTextField(
                          placeholder: "Judul",
                          controller: TextEditingController(text: title),
                          onChanged: (v) => title = v,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20))),
                      const SizedBox(height: 24),
                      CupertinoTextField(
                          placeholder: "URL",
                          controller: TextEditingController(text: url),
                          onChanged: (v) => url = v,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20))),
                      const SizedBox(height: 24),
                      CupertinoTextField(
                          placeholder: "Kategori (opsional)",
                          controller: TextEditingController(text: category),
                          onChanged: (v) => category = v,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20))),
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

  Widget _bookmarkCard(Bookmark item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(36),
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            color: StudioTheme.cardGlass,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30)
            ],
          ),
          child: InkWell(
            onTap: () => _showForm(item: item),
            child: Row(
              children: [
                Icon(CupertinoIcons.link,
                    size: 36, color: StudioTheme.accent.value),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontSize: 26, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text(item.url,
                          style: TextStyle(
                              fontSize: 18, color: StudioTheme.accent.value)),
                      const SizedBox(height: 8),
                      Text("Kategori: ${item.category}",
                          style: TextStyle(
                              fontSize: 16, color: StudioTheme.secondaryText)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.delete,
                      color: Colors.red, size: 28),
                  onPressed: () async {
                    final confirm = await showCupertinoDialog<bool>(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                                  title: const Text("Hapus bookmark?"),
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
                      await FirestoreService.deleteBookmark(item.id);
                      _loadBookmarks();
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
                    placeholder: "Cari bookmark...",
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
            child: _bookmarks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.bookmark,
                            size: 140,
                            color: StudioTheme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 40),
                        const Text("Belum ada bookmark",
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        Text("Simpan link penting dengan tombol +",
                            style: TextStyle(
                                fontSize: 20,
                                color: StudioTheme.secondaryText)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    children: _bookmarks.map((b) => _bookmarkCard(b)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
