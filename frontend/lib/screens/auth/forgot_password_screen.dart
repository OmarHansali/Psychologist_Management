import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  bool isLoading = false;
  String? message;
  String? error;

  Future<void> sendResetCode() async {
    setState(() {
      isLoading = true;
      message = null;
      error = null;
    });

    final url = Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: '{"email": "${emailController.text}"}',
    );

    if (response.statusCode == 200) {
      setState(() {
        message = response.body;
      });
      await Future.delayed(Duration(seconds: 2)); // Laisse le temps d'afficher le code

      // Redirection vers la page de réinitialisation du mot de passe
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: emailController.text),
        ),
      );
    } else {
      setState(() {
        error = "Erreur lors de l'envoi du code.";
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            if (message != null)
              Text(message!, style: TextStyle(color: Colors.green)),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : sendResetCode,
              child: isLoading
                  ? CircularProgressIndicator()
                  : Text('Envoyer le code'),
            ),
          ],
        ),
      ),
    );
  }
}