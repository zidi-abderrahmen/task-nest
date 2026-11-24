import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'theme/app_theme.dart';

// -----------------------------------------------------------------------------
// Configuration
// -----------------------------------------------------------------------------

/// Supabase runtime configuration supplied via `--dart-define`.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Returns a human-readable reason if config is incomplete, else `null`.
  static String? get validationError {
    if (url.isEmpty) return 'SUPABASE_URL is not set.';
    if (publishableKey.isEmpty) return 'SUPABASE_PUBLISHABLE_KEY is not set.';
    return null;
  }
}

// -----------------------------------------------------------------------------
// Entry point
// -----------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _configureSystemChrome();

  final configError = SupabaseConfig.validationError;
  if (configError != null) {
    runApp(FatalErrorApp(
      title: 'Configuration error',
      message: configError,
      hint: 'Run with:\n'
          'flutter run --dart-define-from-file=env.json',
    ));
    return;
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  } catch (error, stack) {
    debugPrint('Supabase init failed: $error\n$stack');
    runApp(const FatalErrorApp(
      title: "Couldn't connect",
      message: 'We were unable to reach the server. '
          'Please check your connection and restart the app.',
    ));
    return;
  }

  runApp(const TaskNestApp());
}

Future<void> _configureSystemChrome() async {
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light, // iOS
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

// -----------------------------------------------------------------------------
// App
// -----------------------------------------------------------------------------

class TaskNestApp extends StatelessWidget {
  const TaskNestApp({super.key});

  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskNest',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      scrollBehavior: const _AppScrollBehavior(),
      builder: (context, child) => _TextScaleLimiter(child: child),
      home: const HomePage(),
    );
  }
}

/// Mouse/trackpad dragging for scrollables — the default behavior only
/// supports touch, which makes lists feel unresponsive on desktop & web.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

/// Keeps accessibility text scaling within a range the layout can handle.
class _TextScaleLimiter extends StatelessWidget {
  const _TextScaleLimiter({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child == null) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.4,
        ),
      ),
      child: child!,
    );
  }
}

// -----------------------------------------------------------------------------
// Fatal error UI (rendered before the main app boots)
// -----------------------------------------------------------------------------

class FatalErrorApp extends StatelessWidget {
  const FatalErrorApp({
    super.key,
    required this.title,
    required this.message,
    this.hint,
  });

  final String title;
  final String message;

  /// Optional code-style hint, e.g. the command needed to supply config.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          hint!,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}