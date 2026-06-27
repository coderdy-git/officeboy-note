import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/navigation/main_screen.dart';
import 'features/attendance/screens/attendance_screen.dart';
import 'features/staff/screens/staff_list_screen.dart';
import 'features/staff/screens/staff_detail_screen.dart';
import 'features/staff/screens/staff_debt_screen.dart';
import 'features/settings/screens/whatsapp_settings_screen.dart';
import 'features/tasks/screens/tasks_screen.dart';
import 'features/tasks/screens/add_task_screen.dart';
import 'features/tasks/screens/task_detail_screen.dart';

/// Root widget aplikasi Office Boy Note.
class OfficeBoyApp extends StatelessWidget {
  const OfficeBoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Office Boy Note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Professional Blue
          surface: const Color(0xFFF8F9FA),
        ),
        useMaterial3: true,
        brightness: Brightness.light,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/attendance': (context) => const AttendanceScreen(),
        '/staff': (context) => const StaffListScreen(),
        '/staff-detail': (context) => const StaffDetailScreen(),
        '/staff-debt': (context) => const StaffDebtScreen(),
        '/whatsapp-settings': (context) => const WhatsappSettingsScreen(),
        '/tasks': (context) => const TasksScreen(),
        '/add-task': (context) => const AddTaskScreen(),
        '/task-detail': (context) => const TaskDetailScreen(),
      },
    );
  }
}
