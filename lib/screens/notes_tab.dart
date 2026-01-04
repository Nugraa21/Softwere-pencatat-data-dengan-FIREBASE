import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Added this import
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
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              color: StudioTheme.cardGlass,
              child: CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  middle: Text(note == null ? "Catatan Baru" : "Edit Catatan"),
                  trailing: CupertinoButton(
                    child: const Icon(CupertinoIcons.checkmark_alt),
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty && contentCtrl.text.isEmpty)
                        return;
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
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(50),
                      child: CupertinoTextField(
                        controller: titleCtrl,
                        placeholder: "Judul Catatan",
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.w700),
                        decoration: const BoxDecoration(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: CupertinoTextField(
                          controller: contentCtrl,
                          placeholder: "Tulis catatanmu di sini...",
                          style: const TextStyle(fontSize: 20, height: 1.8),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const BoxDecoration(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteCard(Note note) {
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
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 30)
            ],
          ),
          child: InkWell(
            onTap: () => _showEditor(note: note),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.isPinned)
                  Icon(CupertinoIcons.pin_fill,
                      color: StudioTheme.accent.value, size: 28),
                Text(note.title,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                if (note.content.isNotEmpty)
                  Text(note.content,
                      style: TextStyle(
                          fontSize: 19,
                          color: StudioTheme.text.withOpacity(0.85)),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(CupertinoIcons.clock,
                        color: StudioTheme.secondaryText),
                    const SizedBox(width: 10),
                    Text(
                        "${note.createdAt.day}/${note.createdAt.month}/${note.createdAt.year}",
                        style: TextStyle(
                            color: StudioTheme.secondaryText, fontSize: 17)),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.delete,
                        color: Colors.red, size: 28),
                    onPressed: () async {
                      final confirm = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                    title: const Text("Hapus catatan?"),
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
                        await FirestoreService.deleteNote(note.id);
                        _loadNotes();
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
                const Text("Catatan",
                    style:
                        TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                const Spacer(),
                FloatingActionButton.large(
                  onPressed: _showEditor,
                  backgroundColor: StudioTheme.accent.value,
                  child: const Icon(CupertinoIcons.pencil, size: 36),
                ),
              ],
            ),
          ),
          Expanded(
            child: _notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.doc_text,
                            size: 140,
                            color: StudioTheme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 40),
                        const Text("Belum ada catatan",
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        Text("Buat catatan pertama dengan tombol pensil",
                            style: TextStyle(
                                fontSize: 20,
                                color: StudioTheme.secondaryText)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    children: _notes.map((note) => _noteCard(note)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
