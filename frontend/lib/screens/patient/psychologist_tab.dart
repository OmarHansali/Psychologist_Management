import 'package:flutter/material.dart';

class MyPsychologistTab extends StatelessWidget {
  final Map<String, dynamic> psychologist;
  final Future<void> Function() onUnassign;

  const MyPsychologistTab({
    super.key,
    required this.psychologist,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Votre psychologue assigné :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: IconButton(
                icon: Icon(Icons.cancel, color: Colors.red),
                tooltip: "Annuler l'assignement",
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Confirmation'),
                      content: Text('Voulez-vous vraiment annuler l\'assignement à ce psychologue ?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non')),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Oui')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await onUnassign();
                  }
                },
              ),
              title: Text(psychologist['name'] ?? ''),
              subtitle: Text(psychologist['email'] ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}