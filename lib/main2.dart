// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// import 'screens/login_screen.dart';
// import 'screens/note_screen.dart';
// import 'screens/note_scan_qr.dart';
// import 'screens/timetable_screen.dart';
// import 'screens/youtube_screen.dart';
// import 'screens/profile_screen.dart';

// /// -----------------------------
// /// 🌈 Minimal Global UI System
// /// -----------------------------
// class AppColors {
//   static const Color primary = Color(0xFF3F51B5); // Muted Indigo
//   static const Color accent = Color(0xFF009688); // Teal accent
//   static const Color background = Color(0xFFF8F9FB); // Subtle off-white
//   static const Color surface = Colors.white;
//   static const Color textDark = Color(0xFF212121);
//   static const Color textLight = Color(0xFF757575);
//   static const Color border = Color(0xFFE0E0E0);
// }

// class AppTextStyles {
//   static TextStyle get wordmark => GoogleFonts.poppins(
//         fontSize: 22,
//         fontWeight: FontWeight.w700,
//         letterSpacing: 0.5,
//         color: AppColors.textDark,
//       );

//   static TextStyle get headline => GoogleFonts.poppins(
//         fontSize: 20,
//         fontWeight: FontWeight.w600,
//         color: AppColors.textDark,
//       );

//   static TextStyle get title => GoogleFonts.poppins(
//         fontSize: 16,
//         fontWeight: FontWeight.w500,
//         color: AppColors.textDark,
//       );

//   static TextStyle get body => GoogleFonts.nunitoSans(
//         fontSize: 15,
//         height: 1.5,
//         color: AppColors.textDark,
//       );

//   static TextStyle get hint => GoogleFonts.nunitoSans(
//         fontSize: 14,
//         color: AppColors.textLight,
//       );

//   static TextStyle get button => GoogleFonts.poppins(
//         fontSize: 15,
//         fontWeight: FontWeight.w600,
//         color: Colors.white,
//       );
// }

// class AppTheme {
//   static ThemeData lightTheme() {
//     final colorScheme = ColorScheme.fromSeed(
//       seedColor: AppColors.primary,
//       brightness: Brightness.light,
//     ).copyWith(
//       primary: AppColors.primary,
//       secondary: AppColors.accent,
//       background: AppColors.background,
//       onPrimary: Colors.white,
//       onSurface: AppColors.textDark,
//     );

//     return ThemeData(
//       useMaterial3: true,
//       colorScheme: colorScheme,
//       scaffoldBackgroundColor: AppColors.background,
//       appBarTheme: AppBarTheme(
//         backgroundColor: Colors.white,
//         foregroundColor: AppColors.textDark,
//         elevation: 0.5,
//         shadowColor: Colors.black12,
//         centerTitle: true,
//         titleTextStyle: AppTextStyles.wordmark,
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: AppColors.border),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: AppColors.border),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(16),
//           borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//         hintStyle: AppTextStyles.hint,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           elevation: 2,
//           textStyle: AppTextStyles.button,
//         ),
//       ),
//       textTheme: TextTheme(
//         headlineSmall: AppTextStyles.headline,
//         titleMedium: AppTextStyles.title,
//         bodyMedium: AppTextStyles.body,
//       ),
//     );
//   }
// }

// /// 🌈 Subtle Gradient Background
// class GradientBackground extends StatelessWidget {
//   final Widget child;
//   const GradientBackground({super.key, required this.child});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Color(0xFFFDFDFD), Color(0xFFF2F4F8)],
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//         ),
//       ),
//       child: child,
//     );
//   }
// }

// /// -----------------------------
// /// 🔹 Backend Config
// /// -----------------------------
// String backendUrl = dotenv.env['BACKEND_URL'] ?? "http://127.0.0.1:8000";
// String notesApiUrl =
//     dotenv.env['NOTES_API_URL'] ?? "$backendUrl/generate-note";

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env").catchError((_) {});

//   // 🔹 Try auto-detect backend using /ping
//   try {
//     final resp = await http
//         .get(Uri.parse("$backendUrl/ping"))
//         .timeout(const Duration(seconds: 3));
//     if (resp.statusCode == 200) {
//       final data = jsonDecode(resp.body);
//       final serverIp = data["server_ip"];
//       final serverPort = data["server_port"] ?? 8000;

//       backendUrl = "http://$serverIp:$serverPort";
//       notesApiUrl = "$backendUrl/generate-note";
//     }
//   } catch (_) {
//     // Fallback to .env or default 127.0.0.1
//   }

//   runApp(const MyApp());
// }

// /// -----------------------------
// /// 🔹 Root Widget
// /// -----------------------------
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Vidhyarthi',
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.lightTheme(),
//       home: const SplashOrHome(),
//     );
//   }
// }

// /// -----------------------------
// /// 🔹 Splash Or Home
// /// -----------------------------
// class SplashOrHome extends StatefulWidget {
//   const SplashOrHome({super.key});

//   @override
//   State<SplashOrHome> createState() => _SplashOrHomeState();
// }

// class _SplashOrHomeState extends State<SplashOrHome> {
//   bool _loading = true;
//   bool _guest = false;
//   bool _loggedIn = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkPrefs();
//   }

//   Future<void> _checkPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('token');
//     final guest = prefs.getBool('guest') ?? false;

//     setState(() {
//       _loggedIn = token != null;
//       _guest = guest;
//       _loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     if (_loggedIn || _guest) {
//       return const GradientBackground(child: HomeScreenWrapper());
//     } else {
//       return const GradientBackground(child: LoginScreen());
//     }
//   }
// }

// /// -----------------------------
// /// 🔹 Home Screen Wrapper
// /// -----------------------------
// class HomeScreenWrapper extends StatefulWidget {
//   const HomeScreenWrapper({super.key});

//   @override
//   State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
// }

// class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
//   int _currentIndex = 0;

//   final List<Widget> _screens = const [
//     NoteScreen(),
//     TimetableScreen(),
//     YouTubeScreen(),
//     NoteScanQR(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         title: const Text("Vidhyarthi"),
//         centerTitle: true,
//       ),
//       body: _screens[_currentIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: const Border(
//             top: BorderSide(color: AppColors.border, width: 0.5),
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 6,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: BottomNavigationBar(
//           currentIndex: _currentIndex,
//           onTap: (index) => setState(() => _currentIndex = index),
//           selectedItemColor: AppColors.primary,
//           unselectedItemColor: AppColors.textLight,
//           type: BottomNavigationBarType.fixed,
//           backgroundColor: Colors.white,
//           elevation: 0,
//           items: const [
//             BottomNavigationBarItem(icon: Icon(Icons.notes), label: "Notes"),
//             BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Timetable"),
//             BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "YouTube"),
//             BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: "Scan QR"),
//           ],
//         ),
//       ),
//     );
//   }
// }
