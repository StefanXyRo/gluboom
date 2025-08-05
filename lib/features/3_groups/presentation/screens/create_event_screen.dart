 FILE libfeatures3_groupspresentationscreenscreate_event_screen.dart
 Creează acest fișier nou în locația specificată.

import 'packagefluttermaterial.dart';
import 'packagecloud_firestorecloud_firestore.dart';
import 'packagefirebase_authfirebase_auth.dart' as firebase_auth;
import 'packageiconsaxiconsax.dart';

class CreateEventScreen extends StatefulWidget {
  final String groupId;
  const CreateEventScreen({super.key, required this.groupId});

  @override
  StateCreateEventScreen createState() = _CreateEventScreenState();
}

class _CreateEventScreenState extends StateCreateEventScreen {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate;
  bool _isLoading = false;

  Futurevoid _pickDate() async {
    DateTime pickedDate = await showDatePicker(
      context context,
      initialDate DateTime.now(),
      firstDate DateTime.now(),
      lastDate DateTime.now().add(const Duration(days 365)),
    );
    if (pickedDate != null) {
      TimeOfDay pickedTime = await showTimePicker(
        context context,
        initialTime TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Futurevoid _createEvent() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null  _titleController.text.isEmpty  _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content Text(Titlul și data evenimentului sunt obligatorii.)),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      await FirebaseFirestore.instance.collection('events').add({
        'groupId' widget.groupId,
        'creatorId' user.uid,
        'title' _titleController.text.trim(),
        'description' _descriptionController.text.trim(),
        'location' _locationController.text.trim().isNotEmpty  _locationController.text.trim()  'Online',
        'eventDate' Timestamp.fromDate(_selectedDate!),
        'attendees' [],
        'createdAt' Timestamp.now(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content Text(A apărut o eroare $e)));
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar AppBar(
        title const Text('Creează un eveniment nou'),
      ),
      body SingleChildScrollView(
        padding const EdgeInsets.all(16.0),
        child Column(
          children [
            TextField(controller _titleController, decoration const InputDecoration(labelText 'Numele evenimentului')),
            const SizedBox(height 16),
            TextField(controller _descriptionController, decoration const InputDecoration(labelText 'Descriere'), maxLines 4),
            const SizedBox(height 16),
            TextField(controller _locationController, decoration const InputDecoration(labelText 'Locație (ex Online, Nume Locație)')),
            const SizedBox(height 24),
            ListTile(
              leading const Icon(Iconsax.calendar),
              title Text(_selectedDate == null  'Selectează data și ora'  '${_selectedDate!.toLocal()}'.split(' ')[0]),
              subtitle _selectedDate != null  Text('${_selectedDate!.hour}${_selectedDate!.minute.toString().padLeft(2, '0')}')  null,
              onTap _pickDate,
            ),
            const SizedBox(height 32),
            SizedBox(
              width double.infinity,
              child ElevatedButton(
                onPressed _isLoading  null  _createEvent,
                child _isLoading  const CircularProgressIndicator()  const Text('Creează Evenimentul'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
