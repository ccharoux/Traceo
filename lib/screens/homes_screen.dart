import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:geolocator/geolocator.dart';
import '../models/home.dart';
import '../models/home_service.dart';
import '../components/routs.dart';
import '../models/settings_state.dart';

class HomesScreen extends StatefulWidget {
  static const String id = 'homes_screen';
  const HomesScreen({super.key});

  @override
  State<HomesScreen> createState() => _HomesScreenState();
}

class _HomesScreenState extends State<HomesScreen> {
  
  String _calculateRouteStats(Home home, SettingsState settings) {
    if (!home.isRoute || home.routePoints == null || home.routePoints!.length < 2) return "";
    
    double totalDistanceMeters = 0;
    for (int i = 0; i < home.routePoints!.length - 1; i++) {
      totalDistanceMeters += Geolocator.distanceBetween(
        home.routePoints![i]['lat'], home.routePoints![i]['lon'],
        home.routePoints![i+1]['lat'], home.routePoints![i+1]['lon']
      );
    }
    
    final String distanceStr = settings.formatDistance(totalDistanceMeters);
    
    // Temps à 140 km/h constant
    final double distKm = totalDistanceMeters / 1000.0;
    final double hours = distKm / 140.0;
    final int totalSeconds = (hours * 3600).round();
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    
    String timeStr = h > 0 ? "${h}h${m.toString().padLeft(2, '0')}m" : "${m}m";
    return "$distanceStr $timeStr";
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(ol('manage_destinations')),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final homeService = context.read<HomeService>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              if (value == 'export') {
                final fileName = await _showExportDialog(context);
                if (fileName != null && fileName.isNotEmpty) {
                  final msg = await homeService.exportHomes(fileName: fileName);
                  scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
                }
              } else if (value == 'import') {
                final msg = await homeService.importHomes();
                scaffoldMessenger.showSnackBar(SnackBar(content: Text(msg)));
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'export',
                  child: Row(children: [const Icon(Icons.upload, color: Colors.black54), const SizedBox(width:8), Text(ol('export_destinations'))]),
                ),
                PopupMenuItem<String>(
                  value: 'import',
                  child: Row(children: [const Icon(Icons.download, color: Colors.black54), const SizedBox(width:8), Text(ol('import_destinations'))]),
                ),
              ];
            },
          ),
        ],
      ),
      body: Consumer<HomeService>(
        builder: (context, homeService, child) {
          if (homeService.homes.isEmpty) {
            return Center(child: Text(ol('no_destination_available')));
          }
          return ListView.builder(
            itemCount: homeService.homes.length,
            itemBuilder: (context, index) {
              final Home home = homeService.homes[index];
              final String routeStats = _calculateRouteStats(home, settings);
              
              return ListTile(
                leading: home.isRoute 
                    ? const Icon(Icons.route, color: Colors.blue) 
                    : (home.isAerodrome ? const Icon(Icons.flight) : const Icon(Icons.home)),
                title: Text(home.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lat: ${home.latitude.toStringAsFixed(4)}, Lon: ${home.longitude.toStringAsFixed(4)}'),
                    if (routeStats.isNotEmpty)
                      Text(routeStats, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (home.isAerodrome)
                      IconButton(
                        icon: const Icon(Icons.description),
                        color: (home.vacUrl != null && home.vacUrl!.isNotEmpty)
                            ? Colors.green
                            : Colors.orange,
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                           if (home.vacUrl == null || home.vacUrl!.isEmpty) {
                            final newVacUrl = await _showVacDialog(context, home.vacUrl ?? "");
                            if (newVacUrl != null) {
                               final updatedHome = home.copyWith(vacUrl: newVacUrl);
                               await homeService.updateHome(updatedHome);
                            }
                           } else {
                             String path = home.vacUrl!;
                             if (path.startsWith('http')) {
                               final url = Uri.parse(path);
                               try {
                                 if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                    throw 'Could not launch $url';
                                 }
                               } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text("${ol('error_prefix')} $e")),
                                  );
                               }
                             } else {
                               final result = await OpenFilex.open(path);
                                if (result.type != ResultType.done) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(content: Text("${ol('error_prefix')} ${result.message}")),
                                  );
                                }
                             }
                           }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final newName = await _showRenameDialog(context, home.name);
                        if (newName != null && newName.isNotEmpty) {
                          final success = await homeService.renameHome(home.name, newName);
                          if (!success) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text("${ol('error_prefix')} ${ol('destination_already_exists')}"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        if (!mounted) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(ol('delete')),
                            content: Text(
                                "${ol('delete_destination_confirm_message')} '${home.name}' ?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(ol('cancel')),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(ol('delete')),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await homeService.deleteHome(home.name);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _showRenameDialog(BuildContext context, String oldName) {
    final controller = TextEditingController(text: oldName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ol('rename')),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ol('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(ol('ok')),
          ),
        ],
      ),
    );
  }

  Future<String?> _showVacDialog(BuildContext context, String currentVacUrl) {
    final controller = TextEditingController(text: currentVacUrl);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ol('vac_url_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: ol('url_label'),
            suffixIcon: IconButton(
              icon: const Icon(Icons.paste),
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                if (data?.text != null) {
                  controller.text = data!.text!;
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ol('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(ol('ok')),
          ),
        ],
      ),
    );
  }

  Future<String?> _showExportDialog(BuildContext context) {
    final controller = TextEditingController(text: 'destinations');
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ol('export_destinations')),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(ol('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(ol('ok')),
          ),
        ],
      ),
    );
  }
}
