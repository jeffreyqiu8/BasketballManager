import 'package:flutter/material.dart';
import 'package:BasketballManager/data/notifiers.dart';
import 'package:BasketballManager/views/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:  isDarkModeNotifier,
      builder: (BuildContext context, dynamic isDarkMode, Widget? child) {
        return  MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color.fromARGB(255, 29, 29, 29),
          colorScheme: ColorScheme.dark(
            primary: const Color.fromARGB(255, 82, 50, 168),
            secondary: const Color.fromARGB(255, 63, 18, 71),
          ),
          cardColor: const Color(0xFF1E1E1E),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color.fromARGB(255, 29, 29, 29),
          ),
        ),
        home: LoginPage(),
      );
      },
    );
  }
}