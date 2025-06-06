import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_config.dart';

class PatientsTab extends StatefulWidget {
  final String token;
  final int userId;
  const PatientsTab({super.key, required this.token, required this.userId});

  @override
  State<PatientsTab> createState() => _PatientsTabState();
}

class _PatientsTabState extends State<PatientsTab> {
  List patients = [];
  List allPatients = [];
  List filteredPatients = [];
  bool isLoading = false;
  bool isLoadingAllPatients = false;
  String? error;
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
    fetchAllPatients();
    searchController.addListener(() {
      filterPatients(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchPatients() async {
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/psychologist/patients');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        patients = json.decode(response.body)['patients'];
      });
    } else {
      setState(() {
        try {
          final data = json.decode(response.body);
          error = data['error'] ?? "Erreur lors du chargement des patients";
        } catch (e) {
          error = "Erreur lors du chargement des patients (${response.statusCode}) : ${response.body}";
        }
      });
    }
    setState(() { isLoading = false; });
  }

  Future<void> fetchAllPatients() async {
    setState(() { isLoadingAllPatients = true; });
    final url = Uri.parse('${ApiConfig.baseUrl}/psychologist/search-patients?q=');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        allPatients = json.decode(response.body)['patients'];
        filteredPatients = allPatients;
      });
    } else {
      setState(() {
        allPatients = [];
        filteredPatients = [];
      });
    }
    setState(() { isLoadingAllPatients = false; });
  }

  void filterPatients(String query) {
    setState(() {
      filteredPatients = allPatients.where((patient) {
        final name = (patient['name'] ?? '').toLowerCase();
        final email = (patient['email'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> assignExistingPatient(int patientId) async {
    setState(() { isLoading = true; });
    final url = Uri.parse('${ApiConfig.baseUrl}/psychologist/patients');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: json.encode({'id': patientId}),
    );
    if (response.statusCode == 200) {
      // Création automatique du chat
      final convUrl = Uri.parse('${ApiConfig.baseUrl}/chat/conversations');
      final chatResponse = await http.post(
        convUrl,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'patient_id': patientId
        }),
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
      await fetchPatients();
      await fetchAllPatients();
    }
    setState(() { isLoading = false; });
  }

  Future<void> deleteAssignedPatient(int patientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer ce patient de votre liste ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Supprimer')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() { isLoading = true; });
      final url = Uri.parse('${ApiConfig.baseUrl}/psychologist/patient/$patientId');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        await fetchPatients();
        await fetchAllPatients();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patient supprimé de votre liste.')),
        );
      }
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0), // Ajoute un padding autour du contenu
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Mes patients", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
          patients.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun patient assigné.', style: TextStyle(color: Colors.grey)),
                )
              : Expanded(
                  child: ListView(
                    children: patients.map<Widget>((patient) => Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (patient['name'] ?? '?').isNotEmpty
                                ? patient['name'][0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(patient['name']),
                        subtitle: Text(patient['email']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: isLoading
                              ? null
                              : () => deleteAssignedPatient(patient['id']),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
          Divider(height: 32),
          Text("Assigner un patient existant", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Recherche par nom ou email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 8),
          if (isLoadingAllPatients)
            Center(child: CircularProgressIndicator()),
          if (!isLoadingAllPatients && filteredPatients.isEmpty)
            Text('Aucun patient trouvé.', style: TextStyle(color: Colors.grey)),
          if (!isLoadingAllPatients && filteredPatients.isNotEmpty)
            Expanded(
              child: ListView(
                children: filteredPatients.map<Widget>((patient) => Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (patient['name'] ?? '?').isNotEmpty
                            ? patient['name'][0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(patient['name']),
                    subtitle: Text(patient['email']),
                    trailing: ElevatedButton(
                      onPressed: isLoading ? null : () => assignExistingPatient(patient['id']),
                      child: Text('Assigner'),
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