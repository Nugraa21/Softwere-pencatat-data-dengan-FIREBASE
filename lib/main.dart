import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:ui';
import 'theme/studio_theme.dart';
import 'widgets/auth_wrapper.dart';
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
    title: 'iVaultX',
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

class IVaultXDesktop extends StatelessWidget {
  const IVaultXDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: StudioTheme.accent,
      builder: (context, accentColor, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'iVaultX',
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
