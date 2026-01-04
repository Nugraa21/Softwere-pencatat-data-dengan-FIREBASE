import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../theme/studio_theme.dart';

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
            email: "$username@nugraforge.app", password: password);
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: "$username@nugraforge.app", password: password);
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
                                const Text('NugraForge',
                                    style: TextStyle(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                Text(
                                    _isRegister
                                        ? 'Buat Akun Baru'
                                        : 'Personal Digital Fortress',
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
