import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    final titleCtrl = TextEditingController(text: item?.title ?? "");
    final descCtrl = TextEditingController(text: item?.description ?? "");
    final tagCtrl = TextEditingController(text: item?.tag ?? "Ide");

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
                          item == null ? "Ide Baru" : "Edit Ide",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Icon(CupertinoIcons.checkmark_alt,
                              color: StudioTheme.accent.value),
                          onPressed: () async {
                            if (titleCtrl.text.isEmpty) return;

                            final now = DateTime.now();
                            final idea = Idea(
                              id: item?.id ??
                                  now.millisecondsSinceEpoch.toString(),
                              title: titleCtrl.text,
                              description: descCtrl.text,
                              tag: tagCtrl.text.isEmpty ? "Ide" : tagCtrl.text,
                              createdAt: now,
                            );

                            if (item == null) {
                              await FirestoreService.addIdea(idea);
                            } else {
                              await FirestoreService.updateIdea(idea);
                            }

                            _loadIdeas();
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
                            placeholder: "Judul ide",
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w700),
                            decoration: const BoxDecoration(),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: descCtrl,
                            placeholder: "Deskripsi ide...",
                            maxLines: null,
                            minLines: 8,
                            textAlignVertical: TextAlignVertical.top,
                            style: const TextStyle(fontSize: 16, height: 1.6),
                            decoration: const BoxDecoration(),
                          ),
                          const SizedBox(height: 16),
                          CupertinoTextField(
                            controller: tagCtrl,
                            placeholder: "Tag (opsional)",
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

  Widget _ideaCard(Idea item) {
    return GestureDetector(
      onTap: () => _showForm(item: item),
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
            /// Tag
            Row(
              children: [
                Icon(CupertinoIcons.lightbulb_fill,
                    size: 18, color: StudioTheme.accent.value),
                const SizedBox(width: 6),
                Text(
                  item.tag,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: StudioTheme.accent.value),
                ),
              ],
            ),
            const SizedBox(height: 8),

            /// Title
            Text(
              item.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            /// Desc
            if (item.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14, color: StudioTheme.text.withOpacity(0.85)),
              ),
            ],

            const SizedBox(height: 12),

            /// Footer
            Row(
              children: [
                Text(
                  "${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}",
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
                            title: const Text("Hapus ide?"),
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
                      await FirestoreService.deleteIdea(item.id);
                      _loadIdeas();
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
        onPressed: _showForm,
        child: const Icon(CupertinoIcons.lightbulb),
      ),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                "Ide & Inspirasi",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),

            /// Content
            Expanded(
              child: _ideas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.lightbulb,
                              size: 96,
                              color:
                                  StudioTheme.secondaryText.withOpacity(0.4)),
                          const SizedBox(height: 16),
                          const Text("Belum ada ide",
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text("Tekan tombol lampu untuk menambah ide",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: StudioTheme.secondaryText)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      children: _ideas.map((i) => _ideaCard(i)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
