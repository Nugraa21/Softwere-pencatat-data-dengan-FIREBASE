import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'theme/studio_theme.dart';
import 'dart:io' show Platform;

// DESKTOP ONLY
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase aman untuk Android & Desktop
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ HANYA JALAN DI WINDOWS / LINUX / MAC
  if (!Platform.isAndroid && !Platform.isIOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1600, 1000),
      center: true,
      backgroundColor: Colors.transparent,
      title: 'iVaultX',
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const IVaultXApp());
}

class IVaultXApp extends StatelessWidget {
  const IVaultXApp({super.key});

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
