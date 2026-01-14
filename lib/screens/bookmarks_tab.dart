import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  List<Bookmark> _all = [];
  List<Bookmark> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
    _searchCtrl.addListener(_filter);
  }

  Future<void> _loadBookmarks() async {
    final list = await FirestoreService.loadBookmarks();
    setState(() {
      _all = list;
      _filtered = list;
    });
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.url.toLowerCase().contains(q))
          .toList();
    });
  }

  void _showForm({Bookmark? item}) {
    final titleCtrl = TextEditingController(text: item?.title ?? "");
    final urlCtrl = TextEditingController(text: item?.url ?? "");
    final catCtrl = TextEditingController(text: item?.category ?? "Umum");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.95,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: StudioTheme.cardGlass,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  /// Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          item == null ? "Bookmark Baru" : "Edit Bookmark",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.checkmark_alt,
                              color: StudioTheme.accent.value),
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty || urlCtrl.text.isEmpty)
                              return;

                            final now = DateTime.now();
                            final bookmark = Bookmark(
                              id: item?.id ??
                                  now.millisecondsSinceEpoch.toString(),
                              title: titleCtrl.text,
                              url: urlCtrl.text,
                              category:
                                  catCtrl.text.isEmpty ? "Umum" : catCtrl.text,
                              createdAt: now,
                            );

                            if (item == null) {
                              await FirestoreService.addBookmark(bookmark);
                            } else {
                              await FirestoreService.updateBookmark(bookmark);
                            }

                            _loadBookmarks();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  /// Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CupertinoTextField(
                            controller: titleCtrl,
                            placeholder: "Judul bookmark",
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700),
                            decoration: const BoxDecoration(),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: urlCtrl,
                            placeholder: "URL (https://...)",
                            style: const TextStyle(fontSize: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(14),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: catCtrl,
                            placeholder: "Kategori (opsional)",
                            style: const TextStyle(fontSize: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.all(14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookmarkCard(Bookmark item) {
    return GestureDetector(
      onTap: () => _showForm(item: item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: StudioTheme.cardGlass,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(CupertinoIcons.link,
                size: 22, color: StudioTheme.accent.value),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, color: StudioTheme.accent.value),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.category,
                    style: TextStyle(
                        fontSize: 12, color: StudioTheme.secondaryText),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.delete,
                  size: 20, color: Colors.red),
              onPressed: () async {
                final confirm = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text("Hapus bookmark?"),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text("Batal"),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text("Hapus"),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    ) ??
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,

      /// FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: StudioTheme.accent.value,
        onPressed: _showForm,
        child: const Icon(CupertinoIcons.add),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header + Search
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bookmarks",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  CupertinoSearchTextField(
                    controller: _searchCtrl,
                    placeholder: "Cari bookmark...",
                  ),
                ],
              ),
            ),

            /// Content
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.bookmark,
                              size: 96,
                              color:
                                  StudioTheme.secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text("Belum ada bookmark",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text("Simpan link penting dengan tombol +",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: StudioTheme.secondaryText)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      children: _filtered.map((b) => _bookmarkCard(b)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
