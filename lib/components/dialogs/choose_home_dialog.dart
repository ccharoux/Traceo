import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/home.dart';
import '../../models/home_service.dart';
import '../routs.dart';

class ChooseHomeDialog extends StatefulWidget {
  final List<Home> homes;
  final Function(Home) onDelete;
  final String? title;
  final String? subtitle;
  final bool onlyAerodromes;

  const ChooseHomeDialog({
    super.key, 
    required this.homes, 
    required this.onDelete,
    this.title,
    this.subtitle,
    this.onlyAerodromes = false,
  });

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
    
    // Filtrage des homes si demandé
    final displayedHomes = widget.onlyAerodromes 
        ? widget.homes.where((h) => h.isAerodrome).toList()
        : widget.homes;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title ?? ol('choose_destination')),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: displayedHomes.isEmpty
            ? Text(ol('no_destination_available'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: displayedHomes.length,
                itemBuilder: (context, index) {
                  final home = displayedHomes[index];
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
                      onPressed: () async {
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(ol('delete')),
                            content: Text("${ol('delete_destination_confirm_message')} '${home.name}' ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(ol('cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(ol('delete'), style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          widget.onDelete(home);
                        }
                      },
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
