import 'package:flutter/material.dart';

void main() {
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
              fontFamily: 'SF Pro Display',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: const DesktopShell(),
    );
  }
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  bool _isWindowOpen = true;
  bool _isMaximized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Wallpaper Mock
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
              color: Colors.black.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text('🍎', style: TextStyle(fontSize: 14)),
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
                      Text('Fri Aug 28 4:16 PM', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // macOS-style Window Container
          if (_isWindowOpen)
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isMaximized ? MediaQuery.of(context).size.width : 640,
                height: _isMaximized ? MediaQuery.of(context).size.height - 50 : 400,
                decoration: BoxDecoration(
                  color: const Color(0xFF25252D).withOpacity(0.92),
                  borderRadius: BorderRadius.circular(_isMaximized ? 0 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    // Window Title Bar with Traffic Lights
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
                      ),
                      child: Row(
                        children: [
                          // Traffic Light Buttons
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isWindowOpen = false),
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
                              GestureDetector(
                                onTap: () {},
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
                              GestureDetector(
                                onTap: () => setState(() => _isMaximized = !_isMaximized),
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
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Welcome to Honeycrisp OS',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white70),
                              ),
                            ),
                          ),
                          const SizedBox(width: 52), // balances out traffic lights width
                        ],
                      ),
                    ),
                    // Window Content Body
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, Rod.',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Your custom Flutter desktop environment is up and running. Native .deb app hooks and window management can be wired directly into this shell canvas.',
                              style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom macOS Dock
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDockItem('📁', 'Files', () {}),
                    _buildDockItem('⚡', 'Terminal', () {
                      setState(() => _isWindowOpen = true);
                    }),
                    _buildDockItem('🌐', 'Browser', () {}),
                    _buildDockItem('⚙️', 'Settings', () {}),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockItem(String emoji, String tooltip, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        ),
      ),
    );
  }
}