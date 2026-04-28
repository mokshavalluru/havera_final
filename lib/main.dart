import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const HaveraApp());
}

class HaveraApp extends StatelessWidget {
  const HaveraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Havera',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F7F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B6C8F),
          brightness: Brightness.light,
        ),
        fontFamily: 'Arial',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- SOCKET ENGINE ---
  late IO.Socket socket;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    // For Chrome, use localhost. For Emulator, use 10.0.2.2
    socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      debugPrint('✅ Connected to Havera Server');
      setState(() => isConnected = true);
    });

    socket.onDisconnect((_) {
      debugPrint('❌ Disconnected');
      setState(() => isConnected = false);
    });

    // Listen for the "SOS Received" event from server
    socket.on('sos_received', (data) {
      _showConfirmationDialog(data['id'] ?? "PENDING");
    });
  }

  void _sendSOS() {
    if (isConnected) {
      socket.emit('send_sos', {
        "roomNumber": "301",
        "hotelName": "Havera Grand",
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connecting to safety network...")),
      );
    }
  }

  void _showConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("🚨 Emergency Dispatched"),
        content: Text("ID: $id\nHotel security has been notified and is on the way."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
        ],
      ),
    );
  }

  // --- YOUR ORIGINAL UI WIDGETS (UNTOUCHED) ---

  Widget actionCard(IconData icon, String title, String subtitle, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(IconData icon, String title, String subtitle, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: isConnected ? const Color(0xFFEAF4EC) : const Color(0xFFFCECEC),
            child: Icon(
              isConnected ? Icons.check_circle_outline : Icons.error_outline,
              color: isConnected ? const Color(0xFF6B8F71) : const Color(0xFFC94C4C),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? "System Ready" : "System Offline",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected 
                    ? "Emergency channels are active and available."
                    : "Connecting to the safety server...",
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "HAVERA",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Safety assistance when you need it",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                
                // --- SOS ALERT SECTION ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFFCECEC),
                        child: Icon(
                          Icons.support_agent,
                          size: 34,
                          color: Color(0xFFC94C4C),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        "Need Help?",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Immediate assistance is available.\nTap below to alert emergency support.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          height: 1.6,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- THE LIVE SOS BUTTON ---
                      GestureDetector(
                        onTap: _sendSOS,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isConnected ? const Color(0xFFC94C4C) : Colors.grey,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              "SEND SOS ALERT",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text(
                  "Quick Help",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    actionCard(Icons.call_outlined, "Call", "Contact support", const Color(0xFF5B6C8F)),
                    actionCard(Icons.location_on_outlined, "Location", "Share live location", const Color(0xFF6B8F71)),
                    actionCard(Icons.security_outlined, "Security", "Hotel assistance", const Color(0xFF8A7B60)),
                  ],
                ),
                const SizedBox(height: 28),
                infoRow(Icons.flash_on_rounded, "Instant Dispatch", "Connects hotel security directly to emergency services in seconds.", Colors.deepPurple),
                infoRow(Icons.analytics_outlined, "AI Incident Analysis", "Automatically categorizes emergencies for faster action.", Colors.teal),
                
                // --- THE LIVE STATUS CARD ---
                statusCard(),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}