import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import 'landing_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Run sync and wait for minimum splash duration (2.5s)
    await Future.wait([
      _syncNotifications(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const LandingScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  Future<void> _syncNotifications() async {
    try {
      final res = await apiService.get('/planner/notifications');
      List<dynamic> nots = res.data;
      for (var n in nots) {
        int id = n['id'];
        String sub = n['subject_name'];
        String type = n['trigger_type'];

        String title = "Exam Alert";
        String body = "";
        if (type == '1_month') {
           body = "📚 $sub exam in 30 days — prep mode started";
        } else if (type == '1_week') {
           body = "⚠️ $sub exam in 7 days — daily review time";
        } else if (type == '1_day') {
           body = "🔥 $sub exam tomorrow — review weak cards now";
        }

        await notificationService.scheduleNotification(id, title, body, DateTime.now().add(const Duration(seconds: 5)));
        await apiService.post('/planner/mark-sent', data: {"notification_id": id});
      }
    } catch (e) {
      debugPrint('Sync fail: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Theme.of(context).primaryColor, const Color(0xFF6D28D9)],
                ),
                boxShadow: [
                  BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), blurRadius: 40)
                ]
              ),
              child: const Icon(Icons.auto_awesome, size: 64, color: Colors.white),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            const Text(
              'StudyRAG',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text(
              'Your AI Study Assistant',
              style: TextStyle(color: Colors.white54, letterSpacing: 1),
            ).animate().fade(delay: 600.ms),
          ],
        ),
      ),
    );
  }
}
