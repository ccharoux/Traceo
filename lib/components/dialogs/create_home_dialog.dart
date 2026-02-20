import 'package:flutter/material.dart';
import '../../components/routs.dart';
import '../../models/home.dart';

class CreateHomeDialog extends StatefulWidget {
  const CreateHomeDialog({super.key});

  @override
  State<CreateHomeDialog> createState() => _CreateHomeDialogState();
}

class _CreateHomeDialogState extends State<CreateHomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newHome = Home(
        name: _nameController.text,
        latitude: double.parse(_latController.text),
        longitude: double.parse(_lonController.text),
      );
      Navigator.of(context).pop(newHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(ol('create_destination')),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(labelText: ol('name')),
              validator: (value) => (value == null || value.isEmpty) ? ol('namereq') : null,
            ),
            TextFormField(
              controller: _latController,
              decoration: InputDecoration(labelText: ol('lat')),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return ol('latreq');
                if (double.tryParse(value) == null) return ol('inval');
                return null;
              },
            ),
            TextFormField(
              controller: _lonController,
              decoration: InputDecoration(labelText: ol('lon')),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return ol('lonreq');
                if (double.tryParse(value) == null) return ol('invlon');
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(child: Text(ol('cancel')), onPressed: () => Navigator.of(context).pop()),
        TextButton(onPressed: _submit, child: Text(ol('ok'))),
      ],
    );
  }
}
