import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setFullScreen(true);
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const HoneycrispOSApp());
}

class HoneycrispOSApp extends StatelessWidget {
  const HoneycrispOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honeycrisp OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E24),
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Inter',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: const DesktopShell(),
    );
  }
}

class WindowAppModel {
  final String id;
  final String title;
  final IconData icon;
  bool isOpen;
  bool isMaximized;
  Offset position;
  Size size;

  WindowAppModel({
    required this.id,
    required this.title,
    required this.icon,
    this.isOpen = false,
    this.isMaximized = false,
    this.position = const Offset(150, 100),
    this.size = const Size(700, 450),
  });
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  final List<WindowAppModel> _apps = [
    WindowAppModel(id: 'files', title: 'Files', icon: Icons.folder_rounded),
    WindowAppModel(id: 'terminal', title: 'Terminal', icon: Icons.terminal_rounded),
    WindowAppModel(id: 'settings', title: 'System Settings', icon: Icons.settings_rounded),
  ];

  void _toggleApp(String id) {
    setState(() {
      final app = _apps.firstWhere((a) => a.id == id);
      app.isOpen = !app.isOpen;
    });
  }

  void _launchSystemProcess(String executable) {
    // Spawns native host applications directly from the shell interface
    Process.run(executable, []).catchError((e) {
      print('Failed to launch process: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Wallpaper Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2C35), Color(0xFF121216)],
              ),
            ),
          ),

          // Top macOS-style Menu Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 28,
              color: Colors.black.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.apple, size: 16, color: Colors.white70),
                      SizedBox(width: 16),
                      Text('Honeycrisp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      SizedBox(width: 16),
                      Text('File', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      SizedBox(width: 16),
                      Text('Edit', style: TextStyle(fontSize: 13, color: Colors.white70)),
                      SizedBox(width: 16),
                      Text('View', style: TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                  Row(
                    children: const [
                      Text('100% 🔋', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 12),
                      Text('Sat Aug 29', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Render Active Floating Windows inside the Desktop Canvas
          for (var app in _apps)
            if (app.isOpen)
              Positioned(
                left: app.isMaximized ? 0 : app.position.dx,
                top: app.isMaximized ? 28 : app.position.dy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: app.isMaximized ? MediaQuery.of(context).size.width : app.size.width,
                  height: app.isMaximized ? MediaQuery.of(context).size.height - 28 : app.size.height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22222A).withOpacity(0.96),
                    borderRadius: BorderRadius.circular(app.isMaximized ? 0 : 12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    children: [
                      // Window Header / Title Bar
                      GestureDetector(
                        onPanUpdate: (details) {
                          if (!app.isMaximized) {
                            setState(() {
                              app.position += details.delta;
                            });
                          }
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() => app.isOpen = false),
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF5F56),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFBD2E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => setState(() => app.isMaximized = !app.isMaximized),
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF27C93F),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    app.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 52),
                            ],
                          ),
                        ),
                      ),
                      // Window Body Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _buildWindowContent(app.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

          // Bottom macOS Dock with Real Icons
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDockItem(Icons.folder_rounded, 'Files', Colors.blueAccent, () => _toggleApp('files')),
                    _buildDockItem(Icons.terminal_rounded, 'Terminal', Colors.grey[900]!, () => _toggleApp('terminal')),
                    _buildDockItem(Icons.settings_rounded, 'Settings', Colors.blueGrey, () => _toggleApp('settings')),
                    const VerticalDivider(color: Colors.white24, indent: 10, endIndent: 10, width: 20),
                    _buildDockItem(Icons.launch_rounded, 'Launch Native App', Colors.orangeAccent, () {
                      _launchSystemProcess('thunar'); // Example system call hook
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowContent(String appId) {
    switch (appId) {
      case 'files':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('File Manager', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('/usr/lib/honeycrisp_shell', style: TextStyle(color: Colors.white60, fontFamily: 'monospace')),
            Divider(color: Colors.white24),
            Expanded(child: Center(child: Text('Storage path initialized.', style: TextStyle(color: Colors.white60)))),
          ],
        );
      case 'terminal':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Honeycrisp Terminal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.all(Radius.circular(8))),
                child: Text('honeycrisp@debian:~$ uname -r\n6.1.0-18-amd64\nhoneycrisp@debian:~$', 
                  style: TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13)),
              ),
            ),
          ],
        );
      case 'settings':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Custom Window Compositor Engine Active.', style: TextStyle(color: Colors.white60)),
          ],
        );
      default:
        return const Center(child: Text('App running'));
    }
  }

  Widget _buildDockItem(IconData icon, String tooltip, Color bg, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}