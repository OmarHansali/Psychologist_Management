import 'package:flutter/material.dart';
import 'psychologist/patients_tab.dart';
import 'psychologist/appointments_tab.dart';
import 'chat_tab.dart';

class PsychologistDashboardScreen extends StatefulWidget {
  final String token;
  final int userId;
  const PsychologistDashboardScreen({super.key, required this.token, required this.userId});

  @override
  State<PsychologistDashboardScreen> createState() => _PsychologistDashboardScreenState();
}

class _PsychologistDashboardScreenState extends State<PsychologistDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Psychologue'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Patients"),
            Tab(icon: Icon(Icons.event), text: "Rendez-vous"),
            Tab(icon: Icon(Icons.chat), text: "Chat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PatientsTab(token: widget.token, userId: widget.userId),
          AppointmentsTab(token: widget.token, userId: widget.userId),
          ChatTab(token: widget.token, userId: widget.userId),
        ],
      ),
    );
  }
}