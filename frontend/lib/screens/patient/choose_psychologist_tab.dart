import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_config.dart';

class ChoosePsychologistTab extends StatefulWidget {
  final String token;
  final int userId;
  final VoidCallback onPsychologistChosen;
  const ChoosePsychologistTab({super.key, required this.token, required this.userId, required this.onPsychologistChosen});

  @override
  State<ChoosePsychologistTab> createState() => _ChoosePsychologistTabState();
}

class _ChoosePsychologistTabState extends State<ChoosePsychologistTab> {
  List psychologists = [];
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? assignedPsychologist;

  @override
  void initState() {
    super.initState();
    fetchAllPsychologists();
  }

  Future<void> fetchAllPsychologists() async {
    setState(() { isLoading = true; });
    final url = Uri.parse('${ApiConfig.baseUrl}/patient/psychologists');
    final response = await http.get(url, headers: {'Authorization': 'Bearer ${widget.token}'});
    if (response.statusCode == 200) {
      setState(() {
        psychologists = json.decode(response.body)['psychologists'];
        isLoading = false;
      });
    } else {
      setState(() {
        error = response.body;
        isLoading = false;
      });
    }
  }

  Future<void> choosePsychologist(int psychologistId) async {
    setState(() { isLoading = true; });
    final url = Uri.parse('${ApiConfig.baseUrl}/patient/psychologist');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: json.encode({'psychologist_id': psychologistId}),
    );
    if (response.statusCode == 200) {
      // Crée la conversation chat après l'assignation
      final chatUrl = Uri.parse('${ApiConfig.baseUrl}/chat/conversations');
      final chatResponse = await http.post(
        chatUrl,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({'psychologist_id': psychologistId}),
      );
      // vérifier si la création du chat a réussi
      if (chatResponse.statusCode == 200 || chatResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient assigné avec succès et chat créé !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient assigné, mais échec de la création du chat.')),
        );
      }
      widget.onPsychologistChosen();
    } else {
      setState(() {
        error = "Erreur lors de l'attribution";
        isLoading = false;
      });
    }
    setState(() {
      isLoading = false;
      error = response.body;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (assignedPsychologist != null) {
      // Affiche le psychologue assigné
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Votre psychologue assigné :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Card(
              child: ListTile(
                title: Text(assignedPsychologist!['name'] ?? ''),
                subtitle: Text(assignedPsychologist!['email'] ?? ''),
              ),
            ),
          ],
        ),
      );
    }
    // Sinon, affiche la liste des psychologues à choisir
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choisir un psychologue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
          Expanded(
            child: ListView(
              children: psychologists.map<Widget>((psy) => Card(
                child: ListTile(
                  title: Text(psy['name']),
                  subtitle: Text(psy['email']),
                  trailing: ElevatedButton(
                    onPressed: () => choosePsychologist(psy['id']),
                    child: Text('Choisir'),
                  ),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}