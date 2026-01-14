import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account.dart';
import '../models/note.dart';
import '../models/bookmark.dart';
import '../models/idea.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  static CollectionReference? get vaultRef => currentUser == null
      ? null
      : _db.collection('users').doc(currentUser!.uid).collection('vault');

  static CollectionReference? get notesRef => currentUser == null
      ? null
      : _db.collection('users').doc(currentUser!.uid).collection('notes');

  static CollectionReference? get bookmarksRef => currentUser == null
      ? null
      : _db.collection('users').doc(currentUser!.uid).collection('bookmarks');

  static CollectionReference? get ideasRef => currentUser == null
      ? null
      : _db.collection('users').doc(currentUser!.uid).collection('ideas');

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

  static Future<List<Bookmark>> loadBookmarks() async {
    if (bookmarksRef == null) return [];
    final snap =
        await bookmarksRef!.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => Bookmark.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addBookmark(Bookmark b) async =>
      await bookmarksRef?.doc(b.id).set(b.toJson());

  static Future<void> updateBookmark(Bookmark b) async =>
      await bookmarksRef?.doc(b.id).update(b.toJson());

  static Future<void> deleteBookmark(String id) async =>
      await bookmarksRef?.doc(id).delete();

  static Future<List<Idea>> loadIdeas() async {
    if (ideasRef == null) return [];
    final snap = await ideasRef!.orderBy('createdAt', descending: true).get();
    return snap.docs
        .map((d) => Idea.fromJson(d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<void> addIdea(Idea i) async =>
      await ideasRef?.doc(i.id).set(i.toJson());

  static Future<void> updateIdea(Idea i) async =>
      await ideasRef?.doc(i.id).update(i.toJson());

  static Future<void> deleteIdea(String id) async =>
      await ideasRef?.doc(id).delete();
}
