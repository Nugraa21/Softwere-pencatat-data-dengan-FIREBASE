import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/studio_theme.dart';
import '../services/firestore_service.dart';
import '../models/note.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final list = await FirestoreService.loadNotes();
    setState(() => _notes = list);
  }

  void _showEditor({Note? note}) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');

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
                          note == null ? "Catatan Baru" : "Edit Catatan",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.checkmark_alt,
                              color: StudioTheme.accent.value),
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty &&
                                contentCtrl.text.isEmpty) return;

                            final now = DateTime.now();
                            if (note != null) {
                              note.title = titleCtrl.text;
                              note.content = contentCtrl.text;
                              await FirestoreService.updateNote(note);
                            } else {
                              await FirestoreService.addNote(Note(
                                id: now.millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text.isEmpty
                                    ? "Tanpa Judul"
                                    : titleCtrl.text,
                                content: contentCtrl.text,
                                createdAt: now,
                              ));
                            }

                            _loadNotes();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  /// Editor
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CupertinoTextField(
                            controller: titleCtrl,
                            placeholder: "Judul",
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700),
                            decoration: const BoxDecoration(),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: contentCtrl,
                            placeholder: "Tulis catatan...",
                            maxLines: null,
                            minLines: 12,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                            decoration: const BoxDecoration(),
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

  Widget _noteCard(Note note) {
    return GestureDetector(
      onTap: () => _showEditor(note: note),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: StudioTheme.cardGlass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.isPinned)
              Icon(CupertinoIcons.pin_fill,
                  size: 18, color: StudioTheme.accent.value),
            Text(
              note.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (note.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, color: StudioTheme.text.withOpacity(0.85)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(CupertinoIcons.clock,
                    size: 14, color: StudioTheme.secondaryText),
                const SizedBox(width: 6),
                Text(
                  "${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}",
                  style:
                      TextStyle(fontSize: 12, color: StudioTheme.secondaryText),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.delete,
                      color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await showCupertinoDialog<bool>(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text("Hapus catatan?"),
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
                      await FirestoreService.deleteNote(note.id);
                      _loadNotes();
                    }
                  },
                ),
              ],
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

      /// FAB Mobile
      floatingActionButton: FloatingActionButton(
        backgroundColor: StudioTheme.accent.value,
        onPressed: _showEditor,
        child: const Icon(CupertinoIcons.pencil),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                "Catatan",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),

            /// Content
            Expanded(
              child: _notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.doc_text,
                              size: 96,
                              color:
                                  StudioTheme.secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text("Belum ada catatan",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text("Tekan tombol pensil untuk mulai",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: StudioTheme.secondaryText)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      children: _notes.map((note) => _noteCard(note)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
