import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _auth() async {
    if (_user.text.isEmpty || _pass.text.isEmpty) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username & password wajib diisi")),
      );
      return;
    }

    try {
      if (_isRegister) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: "${_user.text}@vaultx.app",
          password: _pass.text,
        );
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "${_user.text}@vaultx.app",
        password: _pass.text,
      );
    } on FirebaseAuthException catch (e) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Autentikasi gagal")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            /// Background
            Container(color: StudioTheme.background),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),

            /// Content
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (_, __) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeAnimation.value *
                          (_shakeAnimation.value > 8 ? -1 : 1),
                      0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: StudioTheme.glassBase,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              /// Logo
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: StudioTheme.accent.value
                                      .withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  size: 56,
                                  color: StudioTheme.accent.value,
                                ),
                              ),

                              const SizedBox(height: 24),

                              /// Title
                              const Text(
                                'VaultX',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                _isRegister
                                    ? "Buat akun baru"
                                    : "Personal Digital Fortress",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: StudioTheme.secondaryText,
                                ),
                              ),

                              const SizedBox(height: 36),

                              /// Username
                              CupertinoTextField(
                                controller: _user,
                                placeholder: "Username",
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(CupertinoIcons.person),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// Password
                              CupertinoTextField(
                                controller: _pass,
                                placeholder: "Password",
                                obscureText: true,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Icon(CupertinoIcons.lock),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                onSubmitted: (_) => _auth(),
                              ),

                              const SizedBox(height: 32),

                              /// Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: CupertinoButton.filled(
                                  borderRadius: BorderRadius.circular(16),
                                  onPressed: _auth,
                                  child: Text(
                                    _isRegister ? "Register" : "Sign In",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              /// Switch
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () =>
                                    setState(() => _isRegister = !_isRegister),
                                child: Text(
                                  _isRegister
                                      ? "Sudah punya akun? Sign In"
                                      : "Belum punya akun? Register",
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: StudioTheme.accent.value,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
