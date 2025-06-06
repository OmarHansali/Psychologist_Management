import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'patient/choose_psychologist_tab.dart';
import 'patient/appointments_tab.dart';
import 'chat_tab.dart';
import 'patient/psychologist_tab.dart';
import '../../utils/api_config.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String token;
  final int userId;
  const PatientDashboardScreen({super.key, required this.token, required this.userId});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool hasPsychologist = false;
  bool isLoading = true;
  Map<String, dynamic>? assignedPsychologist;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkPsychologist();
  }

  Future<void> checkPsychologist() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/patient/psychologist');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          hasPsychologist = true;
          assignedPsychologist = data['psychologist'];
          isLoading = false;
        });
      } else {
        setState(() {
          hasPsychologist = false;
          assignedPsychologist = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion au serveur ${e.toString()}')),
      );
    }
  }

  Future<void> unassignPsychologist() async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/patient/psychologist');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        await checkPsychologist();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'annulation de l\'assignement')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion au serveur 2')),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Patient'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.psychology), text: hasPsychologist ? "Mon psychologue" : "Choisir un psychologue"),
            Tab(icon: Icon(Icons.event), text: "Rendez-vous"),
            Tab(icon: Icon(Icons.chat), text: "Chat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          hasPsychologist
              ? MyPsychologistTab(
                  psychologist: assignedPsychologist!,
                  onUnassign: unassignPsychologist,
                )
              : ChoosePsychologistTab(
                  token: widget.token,
                  userId: widget.userId,
                  onPsychologistChosen: () async {
                    await checkPsychologist();
                  },
                ),
          AppointmentsTab(
            token: widget.token,
            userId: widget.userId,
            isPatient: true,
            psychologistId: assignedPsychologist?['id'],
          ),
          ChatTab(token: widget.token, userId: widget.userId, isPatient: true),
        ],
      ),
    );
  }
}