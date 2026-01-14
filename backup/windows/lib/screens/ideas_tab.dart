import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'; // Added this import
import 'dart:ui';
import '../theme/studio_theme.dart';
import '../services/firestore_service.dart';
import '../models/idea.dart';

class IdeasTab extends StatefulWidget {
  const IdeasTab({super.key});

  @override
  State<IdeasTab> createState() => _IdeasTabState();
}

class _IdeasTabState extends State<IdeasTab> {
  List<Idea> _ideas = [];

  @override
  void initState() {
    super.initState();
    _loadIdeas();
  }

  Future<void> _loadIdeas() async {
    final list = await FirestoreService.loadIdeas();
    setState(() => _ideas = list);
  }

  void _showForm({Idea? item}) {
    String title = item?.title ?? "";
    String desc = item?.description ?? "";
    String tag = item?.tag ?? "Ide";
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              color: StudioTheme.cardGlass,
              child: CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  middle: Text(item == null ? "Ide Baru" : "Edit Ide"),
                  trailing: CupertinoButton(
                    child: const Icon(CupertinoIcons.checkmark_alt),
                    onPressed: () async {
                      if (title.isNotEmpty) {
                        final id = item?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString();
                        final idea = Idea(
                            id: id,
                            title: title,
                            description: desc,
                            tag: tag,
                            createdAt: DateTime.now());
                        if (item == null) {
                          await FirestoreService.addIdea(idea);
                        } else {
                          await FirestoreService.updateIdea(idea);
                        }
                        _loadIdeas();
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
                          placeholder: "Judul Ide",
                          controller: TextEditingController(text: title),
                          onChanged: (v) => title = v,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20))),
                      const SizedBox(height: 24),
                      CupertinoTextField(
                          placeholder: "Deskripsi",
                          controller: TextEditingController(text: desc),
                          onChanged: (v) => desc = v,
                          maxLines: 8,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20))),
                      const SizedBox(height: 24),
                      CupertinoTextField(
                          placeholder: "Tag (opsional)",
                          controller: TextEditingController(text: tag),
                          onChanged: (v) => tag = v,
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

  Widget _ideaCard(Idea item) {
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
            onTap: () => _showForm(item: item),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.lightbulb_fill,
                        size: 32, color: StudioTheme.accent.value),
                    const SizedBox(width: 12),
                    Text(item.tag,
                        style: TextStyle(
                            fontSize: 18,
                            color: StudioTheme.accent.value,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Text(item.description,
                    style: TextStyle(
                        fontSize: 19, color: StudioTheme.text.withOpacity(0.9)),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.delete,
                        color: Colors.red, size: 28),
                    onPressed: () async {
                      final confirm = await showCupertinoDialog<bool>(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                    title: const Text("Hapus ide?"),
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
                        await FirestoreService.deleteIdea(item.id);
                        _loadIdeas();
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
                const Text("Ide & Inspirasi",
                    style:
                        TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                const Spacer(),
                FloatingActionButton.large(
                  onPressed: _showForm,
                  backgroundColor: StudioTheme.accent.value,
                  child: const Icon(CupertinoIcons.lightbulb, size: 36),
                ),
              ],
            ),
          ),
          Expanded(
            child: _ideas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.lightbulb,
                            size: 140,
                            color: StudioTheme.secondaryText.withOpacity(0.4)),
                        const SizedBox(height: 40),
                        const Text("Belum ada ide",
                            style: TextStyle(
                                fontSize: 36, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        Text("Catat ide brilianmu dengan tombol lampu",
                            style: TextStyle(
                                fontSize: 20,
                                color: StudioTheme.secondaryText)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    children: _ideas.map((i) => _ideaCard(i)).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
