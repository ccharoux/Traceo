import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';

import '../models/home.dart';
import '../models/home_service.dart';
import '../components/routs.dart';
import '../models/track_data.dart';
import '../components/map_type_dialog.dart';
import '../models/premium_state.dart';

class PickOnMapScreen extends StatefulWidget {
  static const String id = 'pick_on_map';
  const PickOnMapScreen({super.key});

  @override
  State<PickOnMapScreen> createState() => _PickOnMapScreenState();
}

class _PickOnMapScreenState extends State<PickOnMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _initialPosition;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialPosition();
  }

  Future<void> _fetchInitialPosition() async {
    LatLng? pos;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 2),
          onTimeout: () async => (await Geolocator.getLastKnownPosition()) ?? Position(
            latitude: 45.75, longitude: 4.85, timestamp: DateTime.now(),
            accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0,
          ),
        );
        pos = LatLng(position.latitude, position.longitude);
      } else {
        final position = await Geolocator.getLastKnownPosition();
        if (position != null) {
          pos = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (e) {
      debugPrint("Error fetching position: $e");
    }

    if (mounted) {
      setState(() {
        _initialPosition = pos ?? const LatLng(45.75, 4.85); // Lyon par défaut
      });
    }
  }

  Future<void> _searchAndGoToAddress() async {
    final String address = _searchController.text;
    if (address.isEmpty) return;

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        final latLng = LatLng(location.latitude, location.longitude);

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        _onMapTapped(latLng);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ol('address_not_found'))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ol('error_prefix')} $e')),
        );
      }
    }
  }

  void _onMapTapped(LatLng tappedPoint) {
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('picked_location'),
        position: tappedPoint,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ));
    });

    _promptForHomeDetails(tappedPoint);
  }

  Future<void> _promptForHomeDetails(LatLng position) async {
    final isPremium = context.read<PremiumState>().isPremium;
    final result = await showDialog<Home>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final nameController = TextEditingController();
        final vacController = TextEditingController();
        bool isAerodrome = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(ol('create_destination')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: "${ol('name')} (${ol('namereq')})", 
                      ),
                    ),
                    if (isPremium)
                      TextField(
                        controller: vacController,
                        decoration: InputDecoration(
                          labelText: "URL Carte VAC",
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste),
                            onPressed: () async {
                              final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                              if (clipboardData != null && clipboardData.text != null) {
                                vacController.text = clipboardData.text!;
                              }
                            },
                          ),
                        ),
                      ),
                    if (isPremium)
                      CheckboxListTile(
                        title: Text(ol('is_aerodrome')),
                        value: isAerodrome,
                        onChanged: (bool? value) {
                          setDialogState(() {
                            isAerodrome = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      )
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(ol('cancel')),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(ol('ok')),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.of(context).pop(
                      Home(
                        name: nameController.text.trim(),
                        latitude: position.latitude,
                        longitude: position.longitude,
                        vacUrl: vacController.text.trim(),
                        isAerodrome: isAerodrome,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (result != null) {
      final homeService = context.read<HomeService>();
      final success = await homeService.addHome(result);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${ol('destination')} '${result.name}' ${ol('home_saved')}")),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${ol('error_prefix')} ${ol('destination_already_exists')}"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _markers.clear());
      }
    } else {
      setState(() => _markers.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ol('pick_destination_title')),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () =>
                _showMapTypeDialog(context, context.read<TrackData>()),
            tooltip: ol('map_type_tooltip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: ol('search_address_hint'),
                      border: const OutlineInputBorder(),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _searchAndGoToAddress(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.search),
                  onPressed: _searchAndGoToAddress,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.brown,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _initialPosition == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Consumer<TrackData>(
                          builder: (context, trackData, child) {
                        return GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _initialPosition!,
                            zoom: 14,
                          ),
                          mapType: trackData.mapType,
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                          },
                          onTap: _onMapTapped,
                          markers: _markers,
                          myLocationButtonEnabled: true,
                          myLocationEnabled: true,
                          zoomControlsEnabled: false,
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showMapTypeDialog(BuildContext context, TrackData trackData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return MapTypeDialog(trackData: trackData);
      },
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      final Position position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ol('error_prefix')} $e')),
        );
      }
    }
  }
}
