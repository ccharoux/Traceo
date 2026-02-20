import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:geolocator/geolocator.dart';
import '../components/routs.dart';
import 'dart:io' show Platform;

class PermissionHelper {
  static void _showOpenSettingsDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(ol('permission_required_title')),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text(ol('cancel')),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(ol('open_settings_button')),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ph.openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  static Future<bool> handleTrackingPermissions(BuildContext context) async {
    // 1. Vérification de base du service GPS
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez activer le GPS de votre appareil"))
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    // 2. Demande initiale (Doit être "Pendant l'utilisation")
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    // 3. Si l'utilisateur a bloqué définitivement
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showOpenSettingsDialog(
            context, ol('permission_location_permanently_denied_message'));
      }
      return false;
    }

    // 4. Succès : On accepte "whileInUse" ou "always"
    // Comme on a retiré BACKGROUND_LOCATION de l'AndroidManifest, 
    // le système ne proposera que "whileInUse".
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      if (Platform.isAndroid) {
        // Demande de permission pour les notifications (obligatoire pour le Foreground Service)
        ph.PermissionStatus notificationStatus = await ph.Permission.notification.status;
        if(notificationStatus.isDenied){
          await ph.Permission.notification.request();
        }
      }
      return true;
    }
    
    return false;
  }
}
