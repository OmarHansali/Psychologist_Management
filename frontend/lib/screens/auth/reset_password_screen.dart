import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_config.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? error;
  String? message;

  Future<void> resetPassword() async {
    setState(() {
      isLoading = true;
      error = null;
      message = null;
    });

    final url = ApiConfig.baseUrl;

    // Vérifier le code
    final codeResponse = await http.post(
      Uri.parse('$url/auth/verify-reset-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "email": widget.email,
        "code": codeController.text,
      }),
    );

    if (codeResponse.statusCode == 200) {
      // Code correct, on tente la réinitialisation
      final resetResponse = await http.post(
        Uri.parse('$url/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": widget.email,
          "code": codeController.text,
          "new_password": passwordController.text,
        }),
      );
      final resetData = json.decode(resetResponse.body);
      if (resetResponse.statusCode == 200) {
        setState(() {
          message = resetData['message'] ?? "Mot de passe réinitialisé";
        });
        await Future.delayed(Duration(seconds: 2));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        setState(() {
          error = resetData['error'] ?? "Erreur lors de la réinitialisation du mot de passe.";
        });
      }
    } else {
      final codeData = json.decode(codeResponse.body);
      setState(() {
        error = codeData['error'] ?? "Code incorrect.";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Réinitialiser le mot de passe')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Un code a été envoyé à ${widget.email}'),
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: 'Code'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Nouveau mot de passe'),
              obscureText: true,
            ),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            if (message != null)
              Text(message!, style: TextStyle(color: Colors.green)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : resetPassword,
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Réinitialiser'),
            ),
          ],
        ),
      ),
    );
  }
}