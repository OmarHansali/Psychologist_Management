import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String token;
  const AdminDashboardScreen({super.key, required this.token});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List users = [];
  bool isLoading = false;
  String? error;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String role = 'patient';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body)['users'];
      });
    } else {
      setState(() {
        error = "Erreur lors du chargement des utilisateurs";
      });
    }
    setState(() { isLoading = false; });
  }

  Future<void> addUser() async {
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/users');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'email': emailController.text,
        'password': passwordController.text,
        'role': role,
        'name': nameController.text,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      fetchUsers();
      emailController.clear();
      passwordController.clear();
      nameController.clear();
    } else {
      setState(() {
        error = "Erreur lors de l'ajout";
      });
    }
    setState(() { isLoading = false; });
  }

  Future<void> updateUser(Map user) async {
    final updateNameController = TextEditingController(text: user['name']);
    final updatePasswordController = TextEditingController();
    String updateRole = user['role'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier utilisateur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: updateNameController,
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: updatePasswordController,
              decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: updateRole,
              items: [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'psychologist', child: Text('Psychologue')),
                DropdownMenuItem(value: 'patient', child: Text('Patient')),
              ],
              onChanged: (value) {
                if (value != null) {
                  updateRole = value;
                  setState(() {});
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() { isLoading = true; });
              final url = Uri.parse('${ApiConfig.baseUrl}/admin/users/${user['id']}');
              final body = {
                'name': updateNameController.text,
                'role': updateRole,
              };
              if (updatePasswordController.text.isNotEmpty) {
                body['password'] = updatePasswordController.text;
              }
              final response = await http.put(
                url,
                headers: {
                  'Authorization': 'Bearer ${widget.token}',
                  'Content-Type': 'application/json'
                },
                body: json.encode(body),
              );
              if (response.statusCode == 200) {
                fetchUsers();
              } else {
                setState(() {
                  error = "Erreur lors de la modification";
                });
              }
              setState(() { isLoading = false; });
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDeleteUser(int userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer cet utilisateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      deleteUser(userId);
    }
  }

  Future<void> deleteUser(int userId) async {
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      fetchUsers();
    } else {
      setState(() {
        error = "Erreur lors de la suppression";
      });
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Utilisateurs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return ListTile(
                          title: Text('${user['name']} (${user['role']})'),
                          subtitle: Text(user['email']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => updateUser(user),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => confirmDeleteUser(user['id']),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Divider(),
            Text('Ajouter un utilisateur', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nom'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            DropdownButton<String>(
              value: role,
              items: [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'psychologist', child: Text('Psychologue')),
                DropdownMenuItem(value: 'patient', child: Text('Patient')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => role = value);
              },
            ),
            ElevatedButton(
              onPressed: isLoading ? null : addUser,
              child: Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}