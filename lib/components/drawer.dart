import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../components/routs.dart';
import '../models/home.dart';
import '../models/premium_state.dart';
import '../models/settings_state.dart';
import '../screens/homes_screen.dart';
import '../screens/pick_on_map_screen.dart';
import '../screens/documentation_screen.dart';

class AppDrawer extends StatelessWidget {
  final String version;
  final bool isTracking;
  final bool isSimulating;
  final bool isMovingFast;
  final Home? activeTarget;
  final Function onSimulate;
  final Function onNamePosition;
  final Function onChangeDestination;
  final VoidCallback? onPrepareFlight;

  const AppDrawer({
    super.key,
    required this.version,
    required this.isTracking,
    required this.isSimulating,
    required this.isMovingFast,
    this.activeTarget,
    required this.onSimulate,
    required this.onNamePosition,
    required this.onChangeDestination,
    this.onPrepareFlight,
  });

  Future<void> _launchGoogleMapsNavigation(
      BuildContext context, Home target) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${ol('error_prefix')} Could not launch $url')),
        );
      }
    }
  }

  void _showSettingsDialog(BuildContext context) {
    final isPremium = context.read<PremiumState>().isPremium;
    context.read<SettingsState>().updateCacheInfo();

    showDialog(
      context: context,
      builder: (context) {
        return Consumer<SettingsState>(
          builder: (context, settings, child) {
            return AlertDialog(
              title: const Text("Paramètres"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text("Unités de mesure", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListTile(
                      title: const Text("Kilomètres (km, km/h, m)"),
                      leading: Radio<DistanceUnit>(
                        value: DistanceUnit.kilometers,
                        groupValue: settings.unit,
                        onChanged: (val) => settings.setUnit(val!),
                      ),
                      onTap: () => settings.setUnit(DistanceUnit.kilometers),
                    ),
                    ListTile(
                      title: const Text("Milles Nautiques (NM, kt, ft)"),
                      leading: Radio<DistanceUnit>(
                        value: DistanceUnit.nauticalMiles,
                        groupValue: settings.unit,
                        onChanged: (val) => settings.setUnit(val!),
                      ),
                      onTap: () => settings.setUnit(DistanceUnit.nauticalMiles),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Ligne pointillée vers destination"),
                      subtitle: const Text("Remplace ou complète la boussole"),
                      value: settings.showDestinationLine,
                      onChanged: (val) => settings.setShowDestinationLine(val),
                    ),
                    if (isPremium) ...[
                      const Divider(),
                      const ListTile(
                        title: Text("Cache Cartes OACI", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ListTile(
                        title: Text("${settings.oaciTileCount} tuiles stockées"),
                        subtitle: Text("Espace occupé : ${settings.oaciCacheSize}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_sweep, color: Colors.red),
                          onPressed: () async {
                            await settings.clearOaciCache();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Cache OACI vidé"), duration: Duration(seconds: 1)),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fermer"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSecretCodeDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    final premiumState = context.read<PremiumState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Code Secret"),
        content: TextField(
          controller: codeController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Entrez le code"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () async {
              final success = await premiumState.checkSecretCode(codeController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success 
                      ? (premiumState.isPremium ? "Mode Premium activé !" : "Mode Premium désactivé")
                      : "Code incorrect"),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text("Valider"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premiumState = context.watch<PremiumState>();
    final isPremium = premiumState.isPremium;

    // On nettoie la version pour ne garder que le nom (ex: 1.1.0) sans le numéro de build entre parenthèses
    String cleanVersion = version;
    if (version.contains('(')) {
      cleanVersion = version.split('(')[0].trim();
    }

    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.brown),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Trackeo',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onLongPress: () => _showSecretCodeDialog(context),
                        child: Text(
                          "Version $cleanVersion",
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPremium) ...[
                  ListTile(
                    leading: const Icon(Icons.flight_takeoff, color: Colors.blue),
                    title: Text(ol('flight_preparation'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    enabled: !isTracking && !isSimulating,
                    onTap: () {
                      Navigator.pop(context);
                      if (onPrepareFlight != null) onPrepareFlight!();
                    },
                  ),
                  const Divider(),
                ],
                ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(ol('manage_destinations')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, HomesScreen.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.my_location),
                  title: Text(ol('name_current_position')),
                  enabled: !isMovingFast,
                  onTap: () => onNamePosition(),
                ),
                ListTile(
                  leading: const Icon(Icons.create),
                  title: Text(ol('create_destination_on_map')),
                  enabled: !isMovingFast,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PickOnMapScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text(ol('change_destination')),
                  onTap: () => onChangeDestination(),
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(ol('google_maps_route')),
                  enabled: activeTarget != null,
                  onTap: activeTarget != null
                      ? () => _launchGoogleMapsNavigation(context, activeTarget!)
                      : null,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text("Paramètres"),
                  onTap: () {
                    Navigator.pop(context);
                    _showSettingsDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.slideshow),
                  title: Text(ol('simulate_track')),
                  enabled: !isTracking,
                  onTap: isTracking ? null : () => onSimulate(),
                  subtitle: isTracking ? Text(ol('simulation_disabled_during_tracking')) : null,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(ol('documentation')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, DocumentationScreen.id);
                  },
                ),
              ],
            ),
          ),
          if (!isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton.icon(
                onPressed: () => premiumState.buyPremium(),
                icon: const Icon(Icons.star, color: Colors.white),
                label: Text("Passer au Pack Premium (${premiumState.formattedPrice})"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
            child: TextButton(
              onPressed: () async {
                await premiumState.restorePurchases();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Recherche d'anciens achats en cours...")),
                  );
                }
              },
              child: const Text(
                "Restaurer mes achats",
                style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
