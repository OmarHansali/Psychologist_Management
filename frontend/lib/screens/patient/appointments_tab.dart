import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/api_config.dart';

class AppointmentsTab extends StatefulWidget {
  final String token;
  final int userId;
  final int? psychologistId; // Ajoute ce champ pour l'id du psychologue
  final bool isPatient;
  const AppointmentsTab({
    super.key,
    required this.token,
    required this.userId,
    this.psychologistId,
    this.isPatient = false,
  });

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  List appointments = [];
  bool isLoading = false;
  String? error;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final descriptionController = TextEditingController();
  final durationController = TextEditingController(text: '60');

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Future<void> fetchAppointments() async {
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/appointments');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      setState(() {
        appointments = json.decode(response.body)['appointments'];
      });
    } else {
      setState(() {
        error = "Erreur lors du chargement des rendez-vous";
      });
    }
    setState(() { isLoading = false; });
  }

  Future<void> addAppointment() async {
    if (selectedDate == null || selectedTime == null) {
      setState(() { error = "Veuillez remplir tous les champs du rendez-vous."; });
      return;
    }
    setState(() { isLoading = true; error = null; });
    final url = Uri.parse('${ApiConfig.baseUrl}/appointments');
    final dateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
    final body = {
      'datetime': dateTime.toIso8601String(),
      'duration': int.tryParse(durationController.text) ?? 60,
      'notes': descriptionController.text,
    };
    // Ajoute l'id du psychologue si présent
    if (widget.psychologistId != null) {
      body['psychologist_id'] = widget.psychologistId as Object;
    }
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      },
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      descriptionController.clear();
      durationController.text = '60';
      selectedDate = null;
      selectedTime = null;
      await fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rendez-vous ajouté !')),
      );
    } else {
      setState(() {
        error = "Erreur lors de l'ajout du rendez-vous";
      });
    }
    setState(() { isLoading = false; });
  }

  // Annuler un rendez-vous
  Future<void> cancelAppointment(int appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment annuler ce rendez-vous ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Oui')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() { isLoading = true; });
      final url = Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        await fetchAppointments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rendez-vous annulé.')),
        );
      }
      setState(() { isLoading = false; });
    }
  }

  // Modifier un rendez-vous
  Future<void> editAppointmentDialog(Map appt) async {
    final notesController = TextEditingController(text: appt['notes'] ?? '');
    final durationEditController = TextEditingController(text: (appt['duration'] ?? 60).toString());
    DateTime? editDate = DateTime.tryParse(appt['datetime']);
    TimeOfDay? editTime = editDate != null ? TimeOfDay(hour: editDate.hour, minute: editDate.minute) : null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le rendez-vous'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 8),
              TextField(
                controller: durationEditController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Durée (minutes)'),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(editDate == null
                        ? 'Date non choisie'
                        : '${editDate!.day}/${editDate!.month}/${editDate!.year}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: editDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        editDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          editDate?.hour ?? 0,
                          editDate?.minute ?? 0,
                        );
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                    child: Text('Choisir la date'),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(editTime == null
                        ? 'Heure non choisie'
                        : '${editTime!.format(ctx)}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: editTime ?? TimeOfDay.now(),
                      );
                      if (time != null) {
                        editTime = time;
                        if (editDate != null) {
                          editDate = DateTime(
                            editDate!.year,
                            editDate!.month,
                            editDate!.day,
                            time.hour,
                            time.minute,
                          );
                        }
                        (ctx as Element).markNeedsBuild();
                      }
                    },
                    child: Text('Choisir l\'heure'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              setState(() { isLoading = true; });
              final url = Uri.parse('${ApiConfig.baseUrl}/appointments/${appt['id']}');
              final response = await http.put(
                url,
                headers: {
                  'Authorization': 'Bearer ${widget.token}',
                  'Content-Type': 'application/json'
                },
                body: json.encode({
                  'datetime': editDate?.toIso8601String() ?? appt['datetime'],
                  'duration': int.tryParse(durationEditController.text) ?? 60,
                  'notes': notesController.text,
                }),
              );
              if (response.statusCode == 200) {
                await fetchAppointments();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rendez-vous modifié.')),
                );
              }
              setState(() { isLoading = false; });
            },
            child: Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) setState(() => selectedDate = date);
  }

  Future<void> pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
          Text('Mes rendez-vous', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          appointments.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aucun rendez-vous.', style: TextStyle(color: Colors.grey)),
                )
              : Column(
                  children: appointments.map((appt) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text('Rendez-vous'),
                        subtitle: Text('${appt['datetime']} - ${appt['notes'] ?? ''}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: isLoading ? null : () => editAppointmentDialog(appt),
                              tooltip: 'Modifier',
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel, color: Colors.red[800]),
                              onPressed: isLoading ? null : () => cancelAppointment(appt['id']),
                              tooltip: 'Annuler',
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
          Divider(height: 32),
          Text('Ajouter un rendez-vous', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Row(
            children: [
              Expanded(
                child: Text(selectedDate == null
                    ? 'Date non choisie'
                    : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
              ),
              TextButton(
                onPressed: pickDate,
                child: Text('Choisir la date'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(selectedTime == null
                    ? 'Heure non choisie'
                    : '${selectedTime!.format(context)}'),
              ),
              TextButton(
                onPressed: pickTime,
                child: Text('Choisir l\'heure'),
              ),
            ],
          ),
          TextField(
            controller: descriptionController,
            decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Durée (minutes)', border: OutlineInputBorder()),
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading ? null : addAppointment,
            child: Text('Ajouter le rendez-vous'),
          ),
        ],
      ),
    );
  }
}