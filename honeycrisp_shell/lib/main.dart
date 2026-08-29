import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:battery_plus/battery_plus.dart';

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

class SystemApp {
  final String id;
  final String name;
  final String execCommand;

  SystemApp({
    required this.id,
    required this.name,
    required this.execCommand,
  });
}

class WindowModel {
  final String id;
  final String title;
  bool isOpen;
  bool isMaximized;
  Offset position;
  Size size;

  WindowModel({
    required this.id,
    required this.title,
    this.isOpen = false,
    this.isMaximized = false,
    this.position = const Offset(150, 100),
    this.size = const Size(720, 480),
  });
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  List<SystemApp> _installedApps = [];
  bool _isLauncherOpen = false;
  final List<WindowModel> _windows = [
    WindowModel(id: 'welcome', title: 'Welcome - Honeycrisp OS', isOpen: true),
  ];

  @override
  void initState() {
    super.initState();
    _scanInstalledApps();
  }

  void _scanInstalledApps() {
    final List<String> searchPaths = [
      '/usr/share/applications',
      '/usr/local/share/applications',
    ];

    final Map<String, SystemApp> appsMap = {};

    for (var path in searchPaths) {
      final dir = Directory(path);
      if (dir.existsSync()) {
        try {
          for (var entity in dir.listSync()) {
            if (entity is File && entity.path.endsWith('.desktop')) {
              _parseDesktopFile(entity, appsMap);
            }
          }
        } catch (e) {
          debugPrint('Error scanning path $path: $e');
        }
      }
    }

    setState(() {
      _installedApps = appsMap.values.toList();
      _installedApps.sort((a, b) => a.name.compareTo(b.name));
    });
  }

  void _parseDesktopFile(File file, Map<String, SystemApp> appsMap) {
    try {
      String? name;
      String? exec;
      bool noDisplay = false;

      for (var line in file.readAsLinesSync()) {
        line = line.trim();
        if (line.startsWith('Name=')) {
          name ??= line.substring(5);
        } else if (line.startsWith('Exec=')) {
          exec ??= line.substring(5).replaceAll(RegExp(r' %[fFuUdDnNpk%]'), '').trim();
        } else if (line == 'NoDisplay=true') {
          noDisplay = true;
        }
      }

      if (name != null && exec != null && !noDisplay) {
        final id = file.uri.pathSegments.last;
        appsMap[id] = SystemApp(
          id: id,
          name: name,
          execCommand: exec,
        );
      }
    } catch (_) {}
  }

  void _launchApp(SystemApp app) {
    try {
      Process.start(app.execCommand, [], mode: ProcessStartMode.detached);
      setState(() => _isLauncherOpen = false);
    } catch (e) {
      debugPrint('Failed to launch ${app.name}: $e');
    }
  }

  void _openWindow(String id, String title) {
    setState(() {
      final existing = _windows.firstWhere(
        (w) => w.id == id,
        orElse: () => WindowModel(id: id, title: title),
      );
      if (!_windows.contains(existing)) {
        _windows.add(existing);
      }
      existing.isOpen = true;
      _isLauncherOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2C2C35), Color(0xFF121216)],
              ),
            ),
          ),
          for (var window in _windows)
            if (window.isOpen)
              MacOsWindowFrame(
                window: window,
                onClose: () => setState(() => window.isOpen = false),
                onMaximize: () => setState(() => window.isMaximized = !window.isMaximized),
                onMinimize: () => setState(() => window.isOpen = false),
                onDrag: (delta) {
                  if (!window.isMaximized) {
                    setState(() {
                      window.position += delta;
                    });
                  }
                },
                child: _buildWindowBody(window.id),
              ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopMenuBar(
              onLogoTap: () => setState(() => _isLauncherOpen = !_isLauncherOpen),
            ),
          ),
          if (_isLauncherOpen)
            AppLauncherOverlay(
              apps: _installedApps,
              onAppSelected: _launchApp,
              onClose: () => setState(() => _isLauncherOpen = false),
            ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: DesktopDock(
              onOpenLauncher: () => setState(() => _isLauncherOpen = !_isLauncherOpen),
              onOpenWelcome: () => _openWindow('welcome', 'Welcome - Honeycrisp OS'),
              onLaunchTerminal: () => Process.start('xterm', [], mode: ProcessStartMode.detached).catchError((_) {
                Process.start('gnome-terminal', [], mode: ProcessStartMode.detached);
              }),
              onLaunchFiles: () => Process.start('thunar', [], mode: ProcessStartMode.detached).catchError((_) {
                Process.start('nautilus', [], mode: ProcessStartMode.detached);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBody(String id) {
    if (id == 'welcome') {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Hello, Rod.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text(
              'Your custom Linux desktop shell is running with modular window compositing, authentic macOS traffic-light controls, and zero emoji clutter.',
              style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
            ),
          ],
        ),
      );
    }
    return const Center(child: Text('Window content active'));
  }
}

class MacOsWindowFrame extends StatelessWidget {
  final WindowModel window;
  final VoidCallback onClose;
  final VoidCallback onMaximize;
  final VoidCallback onMinimize;
  final Function(Offset) onDrag;
  final Widget child;

  const MacOsWindowFrame({
    super.key,
    required this.window,
    required this.onClose,
    required this.onMaximize,
    required this.onMinimize,
    required this.onDrag,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: window.isMaximized ? 0 : window.position.dx,
      top: window.isMaximized ? 28 : window.position.dy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: window.isMaximized ? screenSize.width : window.size.width,
        height: window.isMaximized ? screenSize.height - 28 : window.size.height,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24).withOpacity(0.94),
          borderRadius: BorderRadius.circular(window.isMaximized ? 0 : 10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            GestureDetector(
              onPanUpdate: (details) => onDrag(details.delta),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF282830).withOpacity(0.6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(window.isMaximized ? 0 : 10)),
                  border: const Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(6),
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
                        InkWell(
                          onTap: onMinimize,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFBD2E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: onMaximize,
                          borderRadius: BorderRadius.circular(6),
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
                          window.title,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 52),
                  ],
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class TopMenuBar extends StatelessWidget {
  final VoidCallback onLogoTap;

  const TopMenuBar({super.key, required this.onLogoTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: Colors.black.withOpacity(0.55),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onLogoTap,
                child: Image.asset(
                  'assets/images/honeycrisp_logo.png',
                  width: 18,
                  height: 18,
                  errorBuilder: (context, error, stackTrace) => const Icon(CupertinoIcons.square_grid_2x2, size: 16, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Honeycrisp OS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 16),
              const Text('File', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(width: 16),
              const Text('Edit', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(width: 16),
              const Text('View', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          Row(
            children: const [
              BatteryIndicatorWidget(),
              SizedBox(width: 12),
              Text('Sat Aug 29', style: TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
  }
}

class BatteryIndicatorWidget extends StatefulWidget {
  const BatteryIndicatorWidget({super.key});

  @override
  State<BatteryIndicatorWidget> createState() => _BatteryIndicatorWidgetState();
}

class _BatteryIndicatorWidgetState extends State<BatteryIndicatorWidget> {
  final Battery _battery = Battery();
  int? _batteryLevel;
  bool _hasBattery = true;

  @override
  void initState() {
    super.initState();
    _checkBattery();
  }

  Future<void> _checkBattery() async {
    try {
      final level = await _battery.batteryLevel;
      setState(() {
        _batteryLevel = level;
        _hasBattery = true;
      });
    } catch (_) {
      setState(() {
        _hasBattery = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasBattery || _batteryLevel == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$_batteryLevel%', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(width: 4),
        const Icon(CupertinoIcons.battery_25, size: 16, color: Colors.white70),
      ],
    );
  }
}

class AppLauncherOverlay extends StatelessWidget {
  final List<SystemApp> apps;
  final Function(SystemApp) onAppSelected;
  final VoidCallback onClose;

  const AppLauncherOverlay({
    super.key,
    required this.apps,
    required this.onAppSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onClose,
        child: Container(
          color: Colors.black.withOpacity(0.65),
          padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
          child: Center(
            child: Container(
              width: 800,
              height: 500,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E26).withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('Installed Applications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  Expanded(
                    child: apps.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: apps.length,
                            itemBuilder: (context, index) {
                              final app = apps[index];
                              return InkWell(
                                onTap: () => onAppSelected(app),
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(CupertinoIcons.app_badge, size: 30, color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      app.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DesktopDock extends StatelessWidget {
  final VoidCallback onOpenLauncher;
  final VoidCallback onOpenWelcome;
  final VoidCallback onLaunchTerminal;
  final VoidCallback onLaunchFiles;

  const DesktopDock({
    super.key,
    required this.onOpenLauncher,
    required this.onOpenWelcome,
    required this.onLaunchTerminal,
    required this.onLaunchFiles,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDockItem(CupertinoIcons.square_grid_2x2, onOpenLauncher),
            _buildDockItem(CupertinoIcons.home, onOpenWelcome),
            _buildDockItem(CupertinoIcons.folder, onLaunchFiles),
            _buildDockItem(CupertinoIcons.device_laptop, onLaunchTerminal),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem(IconData icon, VoidCallback onTap) {
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
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 2)),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}