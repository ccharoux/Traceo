import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/home.dart';
import '../../models/home_service.dart';
import '../routs.dart';

class ChooseHomeDialog extends StatefulWidget {
  final List<Home> homes;
  final Function(Home) onDelete;

  const ChooseHomeDialog({super.key, required this.homes, required this.onDelete});

  @override
  State<ChooseHomeDialog> createState() => _ChooseHomeDialogState();
}

class _ChooseHomeDialogState extends State<ChooseHomeDialog> {
  Home? _selectedHome;

  @override
  void initState() {
    super.initState();
    _loadChosenHome();
  }

  Future<void> _loadChosenHome() async {
    final homeService = Provider.of<HomeService>(context, listen: false);
    final chosenHome = await homeService.getChosenHome();
    if (chosenHome != null && mounted) {
      if (widget.homes.any((h) => h.name == chosenHome.name)) {
        setState(() {
          _selectedHome = chosenHome;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeService = Provider.of<HomeService>(context, listen: false);
    return AlertDialog(
      title: Text(ol('choose_destination')),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.homes.isEmpty
            ? Text(ol('no_destination_available'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.homes.length,
                itemBuilder: (context, index) {
                  final home = widget.homes[index];
                  final isSelected =
                      _selectedHome != null && _selectedHome!.name == home.name;
                  return ListTile(
                    leading: Icon(
                      home.isRoute ? Icons.route : (home.isAerodrome ? Icons.local_airport : Icons.place),
                      color: home.isRoute ? Colors.blue : (home.isAerodrome ? Colors.green : Colors.grey),
                    ),
                    title: Text(home.name),
                    subtitle: home.isRoute ? const Text("Route préparée", style: TextStyle(fontSize: 12)) : null,
                    selected: isSelected,
                    selectedTileColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    onTap: () {
                      homeService.saveChosenHome(home);
                      Navigator.of(context).pop(home);
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => widget.onDelete(home),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(ol('cancel')),
        ),
      ],
    );
  }
}
