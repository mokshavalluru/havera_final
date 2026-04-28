# Havera Flutter Integration Guide

This guide provides everything you need to connect your Flutter frontend to the Havera Node.js backend. The code uses `setState` for simplicity as requested.

## 1. Add Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  socket_io_client: ^3.0.0-beta.2
```

## 2. API Documentation & Events

### REST Endpoints
Base URL: `http://localhost:3000` (Use `http://10.0.2.2:3000` for Android Emulator)

- **POST `/incident/create`**: Creates an incident.
  - Body: `{ "roomNumber": "101", "hotelName": "Grand Plaza", "description": "Fire in kitchen", "location": "Main Kitchen" }`
- **GET `/incident/all`**: Gets all incidents.
- **GET `/incident/:id`**: Gets a single incident.
- **PUT `/incident/update-status`**: Updates status.
  - Body: `{ "id": "incident_id", "status": "DISPATCHED" }` (Statuses: `NEW`, `DISPATCHED`, `ON_THE_WAY`, `RESOLVED`)

### Socket.io Events
- **`incidentCreated`**: Fired when a new incident is created (or when AI finishes processing its initial analysis).
- **`incidentUpdated`**: Fired when status changes, AI analysis is completed, or during the dispatch simulation (ETA updates).

---

## 3. Flutter Integration Code

### Incident Model (`incident.dart`)
```dart
class Incident {
  final String id;
  final String roomNumber;
  final String hotelName;
  final String description;
  final String location;
  final String status;
  final String severity;
  final String aiSummary;
  final List<String> recommendedActions;
  final String? responseTeamId;
  final int? eta;

  Incident({
    required this.id,
    required this.roomNumber,
    required this.hotelName,
    required this.description,
    required this.location,
    required this.status,
    required this.severity,
    required this.aiSummary,
    required this.recommendedActions,
    this.responseTeamId,
    this.eta,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'],
      roomNumber: json['roomNumber'],
      hotelName: json['hotelName'],
      description: json['description'],
      location: json['location'],
      status: json['status'],
      severity: json['severity'] ?? 'PENDING',
      aiSummary: json['aiSummary'] ?? '',
      recommendedActions: List<String>.from(json['recommendedActions'] ?? []),
      responseTeamId: json['responseTeamId'],
      eta: json['eta'],
    );
  }
}
```

### Guest Screen API Call Example (`guest_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GuestScreen extends StatefulWidget {
  @override
  _GuestScreenState createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final String baseUrl = 'http://10.0.2.2:3000'; // Change for real device

  Future<void> sendEmergencyAlert() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/incident/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "roomNumber": "104",
          "hotelName": "Havera Hotel",
          "description": "Guest collapsed in hallway",
          "location": "3rd Floor Hallway"
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency Alert Sent!')),
        );
      }
    } catch (e) {
      print('Error sending alert: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guest App')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: sendEmergencyAlert,
          child: Text('🚨 EMERGENCY ALERT', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
```

### Admin Dashboard (Socket.io + HTTP) (`admin_screen.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';
import 'incident.dart'; // Import the model from above

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final String baseUrl = 'http://10.0.2.2:3000'; // Change to localhost on iOS/Web
  List<Incident> incidents = [];
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    fetchIncidents();
    setupSocket();
  }

  Future<void> fetchIncidents() async {
    final response = await http.get(Uri.parse('$baseUrl/incident/all'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        incidents = data.map((json) => Incident.fromJson(json)).toList();
      });
    }
  }

  void setupSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) => print('Connected to Socket.io'));

    socket.on('incidentCreated', (data) {
      setState(() {
        incidents.insert(0, Incident.fromJson(data));
      });
    });

    socket.on('incidentUpdated', (data) {
      final updatedIncident = Incident.fromJson(data);
      setState(() {
        int index = incidents.indexWhere((inc) => inc.id == updatedIncident.id);
        if (index != -1) {
          incidents[index] = updatedIncident;
        }
      });
    });
  }

  Future<void> updateStatus(String id, String newStatus) async {
    await http.put(
      Uri.parse('$baseUrl/incident/update-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"id": id, "status": newStatus}),
    );
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard')),
      body: ListView.builder(
        itemCount: incidents.length,
        itemBuilder: (context, index) {
          final inc = incidents[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('Room ${inc.roomNumber} - ${inc.severity} Severity'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${inc.status}'),
                  if (inc.eta != null) Text('ETA: ${inc.eta} mins'),
                  if (inc.aiSummary.isNotEmpty) 
                    Text('AI Summary: ${inc.aiSummary}', style: TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
              trailing: inc.status == 'NEW'
                  ? ElevatedButton(
                      onPressed: () => updateStatus(inc.id, 'DISPATCHED'),
                      child: Text('Dispatch'),
                    )
                  : inc.status != 'RESOLVED'
                      ? ElevatedButton(
                          onPressed: () => updateStatus(inc.id, 'RESOLVED'),
                          child: Text('Resolve'),
                        )
                      : Icon(Icons.check_circle, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
```
