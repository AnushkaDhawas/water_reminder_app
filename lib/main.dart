import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // Configure window settings for a small transparent floating widget
  WindowOptions windowOptions = const WindowOptions(
    size: Size(260, 400),
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    Display? primaryDisplay = await screenRetriever.getPrimaryDisplay();
    if (primaryDisplay != null) {
      double screenHeight = primaryDisplay.size.height;
      await windowManager.setPosition(Offset(20, screenHeight - 440));
    }
    
    await windowManager.setAlwaysOnTop(true);
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
      home: const BottomLeftCharacterScreen(),
    );
  }
}

class BottomLeftCharacterScreen extends StatefulWidget {
  const BottomLeftCharacterScreen({super.key});

  @override
  State<BottomLeftCharacterScreen> createState() => _BottomLeftCharacterScreenState();
}

class _BottomLeftCharacterScreenState extends State<BottomLeftCharacterScreen> with WindowListener {
  int selectedIntervalMinutes = 60; // Set to 1 hour as you preferred!
  bool isPopupVisible = false;
  bool isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _startTimer(selectedIntervalMinutes);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _startTimer(int minutes) {
    setState(() {
      isTimerRunning = true;
    });

    Future.delayed(Duration(minutes: minutes), () {
      if (isTimerRunning) {
        _showBottomLeftPopup();
      }
    });
  }

  Future<void> _showBottomLeftPopup() async {
    if (!mounted) return;

    Display? primaryDisplay = await screenRetriever.getPrimaryDisplay();
    if (primaryDisplay != null) {
      double screenHeight = primaryDisplay.size.height;
      await windowManager.setSize(const Size(260, 400));
      await windowManager.setPosition(Offset(20, screenHeight - 440));
    }

    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();

    setState(() {
      isPopupVisible = true;
    });
  }

  void _onDrinkPressed() async {
    setState(() {
      isPopupVisible = false;
    });
    _startTimer(selectedIntervalMinutes);
    await windowManager.hide();
  }

  void _onSnoozePressed() async {
    setState(() {
      isPopupVisible = false;
    });
    _startTimer(10); // Snooze 10 mins
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Keeps the entire app window background transparent
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95), // Slight glass effect, you can adjust opacity
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue.shade100, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text Cloud / Bubble
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Drink Water!",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Character GIF
              Image.asset(
                'assets/images/character.gif',
                height: 110,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),

              // Timing Selector Dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Every: ", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  DropdownButton<int>(
                    value: selectedIntervalMinutes,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 Min (Test)', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 60, child: Text('1 Hour', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 120, child: Text('2 Hours', style: TextStyle(fontSize: 11))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedIntervalMinutes = value!;
                      });
                      _startTimer(selectedIntervalMinutes);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(70, 30),
                    ),
                    onPressed: _onDrinkPressed,
                    child: const Text("I Drank", style: TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(70, 30),
                    ),
                    onPressed: _onSnoozePressed,
                    child: const Text("Snooze", style: TextStyle(fontSize: 11, color: Colors.orange)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              
              // Hide button
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                onPressed: () async {
                  await windowManager.hide();
                },
                child: const Text("Minimize", style: TextStyle(fontSize: 9, color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}