import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import '../admin/dashboard_screen.dart';
import '../psychologist_dashboard_screen.dart';
import '../patient_dashboard_screen.dart';
import '../../utils/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'patient'; // ou 'admin', 'psychologist', 'patient'

  bool isLoading = false;
  String? error;

  void login() async {
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      
      body: '{"email": "${emailController.text}", "password": "${passwordController.text}", "role": "$role"}',
      // body: '{"email": "pat", "password": "pat123", "role": "patient"}',
      // body: '{"email": "psy", "password": "psy123", "role": "psychologist"}',
    );
    if (response.statusCode == 200) {
      // Succès : traite la réponse et navigue
      final data = jsonDecode(response.body);
    final userRole = data['user']['role'];
    final token = data['access_token'];
    final userId = data['user']['id'];
    if (userRole == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(token: token),
        ),
      );
    } else if (userRole == 'psychologist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PsychologistDashboardScreen(token: token, userId: userId),
        ),
      );
    } else if (userRole == 'patient') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientDashboardScreen(token: token, userId: userId),
        ),
      );
    } else {
      setState(() { error = "Accès réservé à l'admin."; });
    }
    } else {
      setState(() { error = "Erreur de connexion"; });
    }
    setState(() { isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            DropdownButton<String>(
              value: role,
              items: ['admin', 'psychologist', 'patient'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => role = v!),
            ),
            if (error != null) Text(error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : login,
              child: isLoading ? CircularProgressIndicator() : Text('Se connecter'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ForgotPasswordScreen()));
              },
              child: Text('Mot de passe oublié ?'),
            ),
          ],
        ),
      ),
    );
  }
}