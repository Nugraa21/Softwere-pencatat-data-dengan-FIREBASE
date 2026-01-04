import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1600, 1000),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    title: 'Nugra21',
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setAsFrameless();
    await windowManager.setFullScreen(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const IVaultXDesktop());
}

// === THEME ===
class StudioTheme {
  static ValueNotifier<Color> accent = ValueNotifier(const Color(0xFF007AFF));
  static const Color glassBase = Color(0xF2FFFFFF);
  static const Color cardGlass = Color(0xE8FFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF1D1D1F);
  static const Color secondaryText = Color(0xFF64748B);
  static const double radius = 24.0;
}

class IVaultXDesktop extends StatelessWidget {
  const IVaultXDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: StudioTheme.accent,
      builder: (context, accentColor, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Nugra21',
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'SF Pro Display',
            useMaterial3: true,
            scaffoldBackgroundColor: StudioTheme.background,
            colorScheme: ColorScheme.light(primary: accentColor),
          ),
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.hasData ? const DashboardHome() : const LoginScreen();
      },
    );
  }
}

// === MODELS & FIRESTORE (sama seperti sebelumnya) ===
class Account {
  String id, title, user, pass, phone, note;
  bool isVisible;
  Account({
    required this.id,
    required this.title,
    required this.user,
    required this.pass,
    required this.phone,
    required this.note,
    this.isVisible = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'user': user,
        'pass': pass,
        'phone': phone,
        'note': note,
        'isVisible': isVisible,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        user: json['user'] ?? '',
        pass: json['pass'] ?? '',
        phone: json['phone'] ?? '',
        note: json['note'] ?? '',
        isVisible: json['isVisible'] ?? false,
      );
}

class Note {
  String id, title, content;
  DateTime createdAt;
  bool isPinned;
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isPinned': isPinned,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        createdAt: DateTime.parse(
            json['createdAt'] ?? DateTime.now().toIso8601String()),
        isPinned: json['isPinned'] ?? false,
      );
}

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static CollectionReference? get vaultRef => currentUser == null
      ? null
      : _db.collection('users').doc(currentUser!.uid).collection('vault');

  static CollectionReference? get notesRef => currentUser == null
      ? null
      : _db.collection('users').doc(currentUser!.uid).collection('notes');

  static Future<List<Account>> loadAccounts() async {
    if (vaultRef == null) return [];
    final snap = await vaultRef!.orderBy('title').get();
    return snap.docs
        .map((d) => Account.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addAccount(Account a) async =>
      await vaultRef?.doc(a.id).set(a.toJson());
  static Future<void> updateAccount(Account a) async =>
      await vaultRef?.doc(a.id).update(a.toJson());
  static Future<void> deleteAccount(String id) async =>
      await vaultRef?.doc(id).delete();

  static Future<List<Note>> loadNotes() async {
    if (notesRef == null) return [];
    final snap = await notesRef!.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => Note.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addNote(Note n) async =>
      await notesRef?.doc(n.id).set(n.toJson());
  static Future<void> updateNote(Note n) async =>
      await notesRef?.doc(n.id).update(n.toJson());
  static Future<void> deleteNote(String id) async =>
      await notesRef?.doc(id).delete();
}

// === LOGIN SCREEN (tetap cantik) ===
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  bool _isRegister = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 20).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _auth() async {
    final username = _user.text.trim();
    final password = _pass.text;
    if (username.isEmpty || password.isEmpty) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Isi username dan password")));
      return;
    }

    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: "$username@nugra21.app", password: password);
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: "$username@nugra21.app", password: password);
    } on FirebaseAuthException catch (e) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Gagal autentikasi")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: StudioTheme.background),
          BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent)),
          Center(
            child: AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(
                      _shakeAnimation.value *
                          (_shakeAnimation.value > 10 ? -1 : 1),
                      0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          padding: const EdgeInsets.all(64),
                          decoration: BoxDecoration(
                            color: StudioTheme.glassBase,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 50,
                                  offset: const Offset(0, 20))
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                      color: StudioTheme.accent.value
                                          .withOpacity(0.15),
                                      shape: BoxShape.circle),
                                  child: Icon(CupertinoIcons.lock_shield_fill,
                                      size: 90,
                                      color: StudioTheme.accent.value),
                                ),
                                const SizedBox(height: 48),
                                const Text('Nugra21',
                                    style: TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                Text(
                                    _isRegister
                                        ? 'Buat Akun Baru'
                                        : 'Secure Vault & Notes',
                                    style: TextStyle(
                                        fontSize: 22,
                                        color: StudioTheme.secondaryText)),
                                const SizedBox(height: 64),
                                CupertinoTextField(
                                  controller: _user,
                                  placeholder: "Username",
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 22),
                                  prefix: const Padding(
                                      padding: EdgeInsets.only(left: 28),
                                      child: Icon(CupertinoIcons.person)),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20)),
                                  style: const TextStyle(fontSize: 19),
                                ),
                                const SizedBox(height: 28),
                                CupertinoTextField(
                                  controller: _pass,
                                  placeholder: "Password",
                                  obscureText: true,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 22),
                                  prefix: const Padding(
                                      padding: EdgeInsets.only(left: 28),
                                      child: Icon(CupertinoIcons.lock)),
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(20)),
                                  style: const TextStyle(fontSize: 19),
                                  onSubmitted: (_) => _auth(),
                                ),
                                const SizedBox(height: 48),
                                SizedBox(
                                  width: double.infinity,
                                  height: 68,
                                  child: CupertinoButton.filled(
                                    borderRadius: BorderRadius.circular(20),
                                    onPressed: _auth,
                                    child: Text(
                                        _isRegister ? "Register" : "Sign In",
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                CupertinoButton(
                                  child: Text(
                                      _isRegister
                                          ? "Sudah punya akun? Sign In"
                                          : "Belum punya akun? Register",
                                      style: const TextStyle(fontSize: 17)),
                                  onPressed: () => setState(
                                      () => _isRegister = !_isRegister),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// === DASHBOARD UTAMA - Top Navigation Profesional ===
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});
  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _selectedTab = 0;
  final List<Widget> _tabs = const [VaultTab(), NotesTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top Navigation Bar dengan Glass Effect
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
                      // Logo & Title
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
                          const Text('Nugra21',
                              style: TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(width: 80),
                      // Tab Buttons
                      _tabButton(0, 'Vault', CupertinoIcons.lock_shield),
                      const SizedBox(width: 40),
                      _tabButton(1, 'Notes', CupertinoIcons.doc_text),
                      const Spacer(),
                      // Profile & Logout
                      PopupMenuButton(
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
          // Content Area
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

// === VAULT TAB & NOTES TAB (tetap sama, hanya sedikit penyesuaian spacing) ===
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
