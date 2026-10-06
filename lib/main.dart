import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Configure window settings for the application
  WindowOptions windowOptions = const WindowOptions(
    size: Size(450, 450),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, 
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Show main window on start so you can see your control panel
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const WaterReminderApp());
}

class WaterReminderApp extends StatelessWidget {
  const WaterReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Reminder',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const BackgroundTimerScreen(),
    );
  }
}

class BackgroundTimerScreen extends StatefulWidget {
  const BackgroundTimerScreen({super.key});

  @override
  State<BackgroundTimerScreen> createState() => _BackgroundTimerScreenState();
}

class _BackgroundTimerScreenState extends State<BackgroundTimerScreen> with WindowListener {
  int selectedIntervalMinutes = 60; // Default 1 hour[cite: 1]
  bool isPopupActive = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _scheduleReminder(selectedIntervalMinutes);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _scheduleReminder(int minutes) {
    Future.delayed(Duration(minutes: minutes), () {
      _triggerAutomaticPopup();
    });
  }

  Future<void> _triggerAutomaticPopup() async {
    if (!mounted) return;
    await windowManager.show();
    await windowManager.focus();
    
    if (!isPopupActive) {
      _showWaterPopup();
    }
  }

  void _showWaterPopup() {
    setState(() {
      isPopupActive = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WaterPopupDialog(
          onDrink: () async {
            setState(() {
              isPopupActive = false;
            });
            _scheduleReminder(selectedIntervalMinutes);
            await windowManager.hide();
          },
          onSnooze: () async {
            setState(() {
              isPopupActive = false;
            });
            _scheduleReminder(10);
            await windowManager.hide();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Water Reminder Active 💧',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your character will pop up automatically\nbased on your selected interval!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              DropdownButton<int>(
                value: selectedIntervalMinutes,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Every 1 Minute (Test)')),
                  DropdownMenuItem(value: 60, child: Text('Every 1 Hour')),
                  DropdownMenuItem(value: 120, child: Text('Every 2 Hours')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedIntervalMinutes = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _triggerAutomaticPopup(),
                child: const Text('Test Popup Now'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  await windowManager.hide();
                },
                child: const Text('Minimize to Background'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaterPopupDialog extends StatelessWidget {
  const WaterPopupDialog({
    super.key,
    required this.onDrink,
    required this.onSnooze,
  });

  final VoidCallback onDrink;
  final VoidCallback onSnooze;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 3),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Text(
                "Drink Water!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Image.asset(
              'assets/images/character.gif',
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDrink();
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text("Yes, I drank", style: TextStyle(color: Colors.white)),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSnooze();
                  },
                  icon: const Icon(Icons.snooze, color: Colors.orange),
                  label: const Text("Snooze (10m)", style: TextStyle(color: Colors.orange)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}