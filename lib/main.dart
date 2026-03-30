import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

import 'models/task.dart';
import 'screens/task_list_screen.dart';
import 'utils/ui_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(taskStatusTypeId)) {
    Hive.registerAdapter(TaskStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(taskTypeId)) {
    Hive.registerAdapter(TaskAdapter());
  }

  if (!Hive.isBoxOpen('tasks')) {
    await Hive.openBox<Task>('tasks');
  }

  runApp(const ProviderScope(child: TaskManagerApp()));
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    const saffron = Color(0xFFff9933);
    const accentGreen = Color(0xFF138808);
    const navyBlue = Color(0xFF000080);

    final colorScheme = ColorScheme.fromSeed(seedColor: saffron).copyWith(
      secondary: navyBlue,
      tertiary: accentGreen,
      surface: Colors.white,
    );

    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FB),
      cardColor: Colors.white,
      primaryColor: saffron,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: navyBlue,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: kCircularBorder12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: kCircularBorder12,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: kCircularBorder12,
          borderSide: BorderSide(color: saffron, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: kCircularBorder16),
        elevation: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return const Color(0xFFE6802A); // slightly darker saffron
            }
            if (states.contains(WidgetState.hovered)) {
              return saffron;
            }
            return saffron;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            saffron.withValues(alpha: 0.16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: kCircularBorder12,
            ),
          ),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Manager',
      theme: theme,
      home: const TaskListScreen(),
    );
  }
}

