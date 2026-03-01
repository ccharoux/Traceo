import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

int olp = 0;

String ol(String key) {
  if (allTexts.containsKey(key)) {
    return allTexts[key]![olp];
  } else {
    return '???';
  }
}

void updateLanguage(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final lang = locale.languageCode;
  if (lang == 'fr') {
    olp = 0;
  } else if (lang == 'es') {
    olp = 2;
  } else {
    olp = 1;
  }
}

String affKms(double distance) {
  if (distance < 1000) {
    return '${distance.toStringAsFixed(0)} m';
  } else {
    return '${(distance / 1000).toStringAsFixed(2)} km';
  }
}

String affTime(String time, bool withSeconds) {
  final int seconds = int.tryParse(time) ?? 0;
  final int h = seconds ~/ 3600;
  final int m = (seconds % 3600) ~/ 60;
  final int s = seconds % 60;

  if (h > 0) {
    if (withSeconds) {
      return '${h}h${m.toString().padLeft(2, '0')}m${s.toString().padLeft(2, '0')}s';
    } else {
      return '${h}h${m.toString().padLeft(2, '0')}m';
    }
  } else {
    if (withSeconds) {
      return '${m}m${s.toString().padLeft(2, '0')}s';
    } else {
      return '${m}m';
    }
  }
}

Map<int, String> languages = {
  0: 'Français',
  1: 'English',
  2: 'Español',
};

Future<String> formatTrackName(DateTime time) async {
  String locale = 'en_US';
  if (olp == 0) locale = 'fr_FR';
  if (olp == 2) locale = 'es_ES';
  
  var dateFormat = DateFormat("d MMMM yyyy HH'h'mm", locale);
  return dateFormat.format(time);
}

const Map<String, List<String>> allTexts = {
  // General
  'ok': ["OK", 'OK', 'OK'],
  'yes': ["Oui", 'Yes', 'Sí'],
  'no': ["Non", 'No', 'No'],
  'cancel': ["Annuler", 'Cancel', 'Cancelar'],
  'close': ["Fermer", 'Close', 'Cerrar'],
  'save': ["Sauver", 'Save', 'Guardar'],
  'delete': ["Supprimer", 'Delete', 'Eliminar'],
  'stop': ['Arrêt', 'Stop', 'Parada'],
  'warning': ["Attention", 'Warning', 'Advertencia'],
  'confirm': ["Confirmer", 'Confirm', 'Confirmar'],
  'version': ["Version", 'Version', 'Versión'],
  'wait': ["Patientez...", 'Wait...', 'Espere...'],
  'info':["Information",'Information','Información'],
  'rename':["Renommer",'Rename','Renombrar'],
  'rename_prompt_title':["Renommer la trace", "Rename track", "Renombrar la pista"],
  'rename_prompt_hint':["Nouveau nom", "New name", "Nuevo nombre"],
  'track_renamed_snackbar':["Trace renommée :", "Track renamed:", "Pista renonbrada:"],
  'enter_new_name':["Saisir un nom",'Enter a name','Introduzca un nombre'],
  'name_exists_error': ["Ce nom existe déjà", 'This name already exists', 'Este nombre ya existe'],
  'track_not_found': ["Trace non trouvée", 'Track found', 'Pista non encontrada'],
  'no_track_selected': ["Aucune trace sélectionnée", 'No track selected', 'Ninguna pista seleccionada'],
  'track_image_share':["Partage de la trace",'Share the track','Compartir la pista'],
  'track_image_share_text':["Regarde cette image",'See that image','Mira esta imagen'],
  'generic_error_starting_track': [
    "Une erreur est survenue au démarrage du suivi",
    'An error occurred when starting the tracking',
    'Se ha producido un error al iniciar le seguimiento'
  ],
  'loading': ["Chargement...", 'Loading...', 'Cargando...'],
  'error': ["Erreur", 'Error', 'Error'],
  'share_map_image': ["Partager la carte", 'Share map image', 'Compartir mapa'],
  'share_failed_snackbar': ["Échec du partage", 'Share failed', 'Error al compartir'],
  'no_track_to_display': ["Aucune trace à afficher", 'No track to display', 'No hay pista pour mostrar'],
  'no_coordinates_found_snackbar': ["Aucune coordonnée trouvée pour cette trace", "No coordinates found for this track", "No se encontraron coordenadas pour esta pista"],
  'documentation': ["Documentation", 'Documentation', 'Documentación'],
  'menu': ["Menu", "Menu", "Menú"],
  'google_maps_route': ["Itinéraire Google Maps", "Google Maps route", "Ruta de Google Maps"],

  // Photo & Vignette
  'take_photo': ["Prendre une photo", "Take a photo", "Tomar una photo"],
  'from_gallery': ["Choisir depuis la galerie", "Choose from gallery", "Elegir de la galería"],
  'photo_added': ["Photo ajoutée à la trace", "Photo added to track", "Foto añadida a la pista"],
  'photo': ["Photo", "Photo", "Foto"],
  'pick_point_for_photo': ["Touchez la trace pour placer la photo", "Tap the track to place the photo", "Toca la pista para colocar la foto"],

  // Documentation
  'doc_intro_1': ["L'application  vous permet d'enregistrer et de gérer vos parcours. Pour démarrer une trace, appuyez sur le bouton",
    "The application allows you to record and manage your tracks. To start a track, press the button",
    "La aplicación  le permite grabar y gestionar sus recorridos. Para iniciar una traza, pulse le bouton"],
  'doc_stop_1': ["et pour l'arrêter, appuyez sur le bouton", "and to stop it, press the button", "y para detenerla, pulse le bouton"],
  'doc_intro_2': [". Une fois la trace terminée, vous la retrouverez dans la liste des traces, accessible depuis le menu principal via l'icône", ". Once the track is finished, you will find it in the list of tracks, accessible from the main menu via the icon", ". Una vez finalizada la traza, la encontrará en la lista de trazas, accesible desde le menú principal a través del icono"],
  'doc_intro_3': [".", ".", "."],

  'doc_bottom_bar_title': ["Barre d'informations", "Information bar", "Barra de información"],
  'doc_bottom_bar_body': ["Pendant le suivi, une barre d'informations s'affiche en bas de l'écran. Elle vous donne des informations utiles comme la distance parcourue et la vitesse actuelle. Deux boutons sont également disponibles :", "During tracking, an information bar is displayed at the bottom of the screen. Elle vous donne des informations utiles comme la distance parcourue et la vitesse actuelle. Deux boutons sont également disponibles :", "Durante le seguimiento, se muestra una barra de información en la parte inferior de la pantalla. Le proporciona información utile comme la distancia recorrida y la vitesse actual. También hay dos botones disponibles:"],
  'doc_bottom_bar_compass': [" pour afficher le cap à suivre pour rejoindre votre destination.", " to display the heading to follow to reach your destination.", " para mostrar le rumbo a suivre pour rejoindre votre destination."],
  'doc_bottom_bar_stats': [" pour afficher des statistiques détaillées sur votre parcours.", " to display detailed statistics about your track.", " para mostrar estadísticas detalladas de su recorrido."],
  'doc_bottom_bar_pause': [" pour mettre en pause le suivi.", " to pause tracking.", " para pausar le seguimiento."],

  // tracks
  'doc_tracks_title': ["Les traces", "Tracks", "Trazas"],
  'doc_tracks_button':   ["Le bouton (","The button (","El botón ("],
  'doc_tracks_button_2':   [") appelle la liste des traces.",") calls the tracks list.",") llama a la lista de trazas."],
  'doc_single_intro': ["En sélectionnant une seule trace, vous pouvez l'afficher sur la carte avec le bouton ",
    "By selecting a single track, you can view it on the map with the button ",
    "Al seleccionar una sola traza, puede verla en le mapa con le botón "],
  'doc_single_view': [", la supprimer avec le bouton ", ", delete it with the button ", ", eliminarla con le botón "],
  'doc_single_delete': [" et la partager. Le bouton ", " and share it. The button ", ", y compartirla. El botón "],
  'doc_single_plus': [" offre d'autres options : ", " offers other options: ", " ofrece otras opciones: "],
  'doc_single_plus_merge': [" fusionner, ", " merge, ", " fusionar, "],
  'doc_single_plus_rename': [" renommer, ", " rename, ", " renombrar, "],
  'doc_single_plus_archive': [" archiver, ", " archive, ", " archivar, "],
  'doc_single_plus_sort': [" trier ou ", " sort or ", " ordenar o "],
  'doc_single_plus_cut': [" couper.", " cut.", " cortar."],
  'doc_single_plus_share': [" partager.", " sort.", " ordenar."],
  'doc-single_to_cut':["Pour couper une trace, il suffit de taper sur la trace à l'endroit voulu.",
    "To cut a track, simply tap on the track at the desired location.",
    "Para cortar una pista, simplemente toque la pista en la ubicación désirée."],
  'doc_multi_intro': ["En sélectionnant plusieurs traces, vous pouvez les afficher simultanément sur la carte avec le bouton ",
    "By selecting multiple tracks, you can view them simultaneously on the map with the button ",
    "Al seleccionar varias trazas, peut verla simultáneamente en le mapa con el botón "],
  'doc_multi_delete': [", les supprimer avec le bouton ", ", delete them with the button ", ", eliminarlas con el botón "],
  'doc_multi_merge': [". Le bouton ", ". The button ", ". El botón "],
  'doc_multi_plus': [" vous permet de les ", " allows you to ", " le permite "],
  'doc_multi_plus_merge': [" fusionner, ", " merge, ", " fusionar, "],
  'doc_multi_plus_archive': [" archiver ou ", " archive, or ", " archivar o "],
  'doc_multi_plus_sort': [" trier.", " sort them.", " ordenarlas."],
  // Notes
  'doc_notes_title': ["Les notes et les photos", "Notes and photos", "Notas y fotos"],
  'doc_notes_intro': ["Pendant la marche il est possible de noter ses impressions en cliquant sur le bouton ",
    "During the walk, it is possible to note your impressions by clicking on the button ",
    "Durante le paseo, es posible anotar sus impresiones haciendo clic en le bouton "],
  'doc_photos_intro':["On peut aussi prendre des photos avec le bouton ",
    "You can also take photos with the button ",
    "También peut tomar photos con el botón ","",""],
  'doc_notes_display':["Les notes sont signalées à l'affichage de la trace par un marqueur orange et les photos par un marqueur violet.",
    "Notes are indicated on the track display by an orange marker and the photos marked with a purple marker.",
    "Las notas se indican en la pantalla de la pista mediante un marcador naranja y las fotos marcadas con un marcador morado."],
  'doc_notes_update':["Vous pouvez mettre à jour une note en tapant dessus",
    "You can update a note by taping on it",
    "Puede actualizar una nota tocándola"],
  'doc_photos_tile':["La première photo sur la trace sera installée sur la tuile de la trace.",
    "The first photo on the track will be installed on the track tile.",
    "La primera photo de la pista se instalará en el mosaico de la pista."],
  'add_note': ["Ajouter une note", 'Add note', 'Añadir nota'],
  'note_hint': ["Votre note...", 'Your note...', 'Su nota...'],
  'note_added': ["Note ajoutée", 'Note added', 'Nota añadida'],
  'note': ["Note", 'Note', 'Nota'],

  // Archives
  'doc_archives_title': ["Les archives", "Archives", "Archivos"],
  'doc_archives_intro': ["La section des archives, accessible depuis l'écran des traces via l'icône",
    "The archives section, accessible from the tracks screen via the icon",
    "La sección de archivos, accesible desde la pantalla de trazas a través del icono"],
  'doc_archives_usage': [", vous permet de store les traces que vous ne souhaitez plus voir dans la liste principale, sans les supprimer. Vous pouvez également y exporter ou importer toutes vos archives.",
    ", allows you to store the tracks you no longer want to see in the main list, without deleting them. You can also export or import all your archives there.",
    ", le permite almacenar las trazas que ya no desea ver en la lista principal, sin eliminarlas. También puede exportar ou importar todos sus archivos allí."],
  'doc_dest_title': ["Les destinations", "Destinations", "Destinos"],
  'doc_dest_create': ["Le bouton ", "The button ", "El botón "],
  'doc_dest_create_body': [" vous présente une carte. Dans la zone de recherche, entrez une adresse, et sur Entrée l'application demande à entrer un nom. Sur OK les coordonnées de l'adresse seront gardées par l'appli.",
    " shows you a map. In the search area, enter an address, and on Enter the app asks for a name. On OK, the address's coordinates will be saved by the app.",
    " le muestra un mapa. En le área de búsqueda, ingrese una dirección, y al presionar Enter, la aplicación solicita un nombre. Al presionar OK, las coordenadas de la dirección serán guardadas por la aplicación."],
  'doc_dest_name_pos': ["Nommer votre position actuelle (", "Name your current position (", "Nombrar su posición actual ("],
  'doc_dest_manage': [") ou gérer vos destinations existantes (", ") or manage your existing destinations (", ") o gestionar sus destinos existentes ("],
  'doc_dest_change': ["). Vous pouvez également changer de destination à tout moment (", "). You can also change your destination at any time (", "). también peut cambiar su destino en cualquier momento ("],
  'doc_dest_gmaps': ["), obtenir un itinéraire Google Maps vers votre destination (", "), get a Google Maps route to your destination (", "), obtener una ruta de Google Maps a su destino ("],
  'doc_dest_export': ["), exporter vos destinations (", "), export your destinations (", "), exportar sus destinos ("],
  'doc_dest_import': [") ou importer des destinations partagées (", ") or import shared destinations (", ") o importar destinos compartidos ("],
  'doc_dest_outro': [").", ").", ")."],

  // VAC cards
  'doc_vac_title': ["Cartes VAC et aérodromes", "VAC maps and aerodromes", "Mapas VAC y aeródromos"],
  'doc_vac_body_1': ["L'application permet de gérer des destinations qui peuvent être des aérodromes. Avec le Pack Premium, vous pourrez associer et afficher les cartes VAC correspondantes.",
    "The application allows you to manage destinations that can be aerodromes. With the Premium Pack, you will be able to associate and display the corresponding VAC maps.",
    "La aplicación le permite gestionar destinos que pueden ser aeródromos. Con le Pack Premium, podrá asociar y visualizar los mapas VAC correspondientes."],
  'doc_vac_body_2':
  ["Les cartes VAC sont des cartes d'approche à vue qui fournissent des informations essentielles aux pilotes. Une icône (",
    "VAC maps are visual approach charts that provide essential information to pilots. An icon (",
    "Los mapas VAC son cartas de aproximación visual que proporcionan información esencial a los pilotes. An icono ("],
  'doc_vac_body_3': [") s'affichera à côté des destinations qui sont des aérodromes.", ") will be displayed next to destinations that are aerodromes.", ") se mostrará junto a los destinos que son aeródromos."],
  'doc_vac_body_4': ["Le pointeur vers la carte VAC d'un aérodrome est renseigné par l'utilisateur (réservé au Pack Premium) lors de la création de la destination ou sur appui de l'icône orange.", "The pointer to the VAC chart of an aerodrome is provided by the user (Premium Pack only) when creating the destination or by clicking the orange icon.", "El puntero a la carta VAC de un aeródromo lo proporciona el usuario (sólo Pack Premium), al crear le destino o al hacer clic en le icono naranja."],
  'doc_vac_body_5': ["L'icône devient alors verte, indiquant que la carte VAC est insérée dans le téléphone.",
    "The icon then turns green, indicating that the VAC card is loaded in the phone.",
    "Luego, le icono se vuelve verde, lo que indica que la tarjeta VAC está cargada en le téléphone."],
  'doc_vac_body_6': ["Sur l'écran des statistiques, l'icône (",
    "On the statistics screen, the icon (",
    "En la pantalla de statistiques, le icono ("],
  'doc_vac_body_7': [") permet en vol, à la prise de terrain, d'afficher la carte VAC.",
    ") allows you to display the VAC chart during flight, upon landing.",
    ") permite visualizar le gráfico VAC durante le vuelo, al aterrizar."],

  // Parametres (V16)
  'doc_settings_title': ["Réglages et Unités", "Settings and Units", "Ajustes y Unidades"],
  'doc_settings_intro': [
    "Accessibles via l'icône roue dentée dans le menu, les paramètres vous permettent de personnaliser votre expérience.",
    "Accessible via the gear icon in the menu, settings allow you to customize your experience.",
    "Accesibles a través del icono de engranaje en le menú, los ajustes le permiten personalizar su experiencia."
  ],
  'doc_settings_units': [
    "Unités de mesure : Basculez entre le système métrique (Kilomètres/Mètres) et le système nautique (Milles Nautiques/Nœuds/Pieds) pour l'aviation.",
    "Measurement units: Switch between the metric system (Kilometers/Meters) and the nautical system (Nautical Miles/Knots/Feet) for aviation.",
    "Unidades de medida: cambie entre le sistema métrico (Kilómetros/Metros) y le sistema náutico (Millas náuticas/Nudos/Pies) para aviación."
  ],
  'doc_settings_destline': [
    "Ligne de mire : Activez la ligne rouge pointillée pour visualiser en permanence la trajectoire directe vers votre objectif sur la carte.",
    "Bearing line: Enable the red dotted line to constantly visualize the direct trajectory to your objective on the map.",
    "Línea de rumbo: active la línea punteada roja para visualizar permanentemente la trayectoria directa a su objetivo en le mapa."
  ],
  'parameters':["Paramètres",'Parameters','Parámetros'],
  'measurements':["Unités de mesures","Units of Measurement","Unidades de medida"],
  'km_unit': ["Kilomètres (km, km/h, m)", "Kilometers (km, km/h, m)", "Kilómetros (km, km/h, m)"],
  'nm_unit': ["Milles Nautiques (NM, kt, ft)", "Nautical Miles (NM, kt, ft)", "Millas náuticas (NM, kt, ft)"],
  'destination_line': ["Ligne vers destination", "Line to destination", "Línea al destino"],
  'destination_line_sub': ["Ligne rouge pointillée", "Red dotted line", "Línea de puntos roja"],
  'stop_time': ["Temps d'arrêt", "Stop time", "Tiempo de parada"],
  'stop_time_sub': ["Marqueurs bleus sur la trace", "Blue markers on the track", "Marcadores azules en la pista"],
  'oaci_cache_title': ["Cache Cartes OACI", "OACI Map Cache", "Caché de mapas OACI"],
  'tiles_stored': ["%s tuiles stockées", "%s tiles stored", "%s mosaicos almacenados"],
  'space_occupied': ["Espace occupé : %s", "Space occupied: %s", "Espacio ocupado: %s"],
  'cache_cleared_msg': ["Cache OACI vidé", "OACI cache cleared", "Caché OACI vaciado"],

  // Pack Premium
  'doc_premium_title': ["Pack Premium : Navigation & Aviation", "Premium Pack: Navigation & Aviation", "Pack Premium: Navegación y Aviación"],
  'doc_premium_intro': [
    "Le Pack Premium débloque des outils avancés pour la précision et la sécurité, que ce soit au sol ou en vol.",
    "The Premium Pack unlocks advanced tools for precision and safety, whether on the ground or in the air.",
    "El Pack Premium desbloquea herramientas avanzadas para la précision y la seguridad, ya sea en tierra o en el aire."
  ],
  'doc_premium_oaci': [
    "Cartographie OACI : Accédez aux cartes aéronautiques dynamiques. Grâce au cache, vos cartes restent consultables même sans réseau (mode hors-ligne).",
    "OACI Mapping: Access dynamic aeronautical charts. Thanks to the cache, your maps remain accessible even without a network (offline mode).",
    "Cartografía OACI: Acceda a cartas aeronáuticas dinámicas. Gracias a la caché, sus mapas permanecen accesibles incluso sin red (modo fuera de línea)."
  ],
  'doc_premium_planning': [
    "Planification de routes : Préparez vos itinéraires avec plusieurs points de passage. L'application calcule automatiquement les distances et les temps de vol estimés.",
    "Route planning: Prepare your routes with multiple waypoints. The app automatically calculates distances and estimated flight times.",
    "Planificación de rutas: organice sus rutas con múltiples puntos de referencia. La aplicación calcula automáticamente las distancias y los tiempos de vuelo estimados."
  ],
  'doc_premium_vac': [
    "Cartes VAC : Gérez et visualisez les cartes d'approche à vue directement dans l'application pour vos destinations aérodromes.",
    "VAC Charts: Manage and view visual approach charts directly in the app for your aerodrome destinations.",
    "Cartas VAC: Gestione y visualice cartas de aproximación visual directamente en la aplicación para sus destinos de aeródromos."
  ],

  'doc_final_title': ["Consommation et batterie", "Consumption and battery", "Consumo y batería"],
  'doc_final_body_1': ["L'application est conçue pour être économe en énergie. Cependant, l'utilisation continue du GPS peut diminuer la durée de vie de la batterie.", "The application is designed to be energy efficient. However, continuous use of GPS can decrease battery life.", "La aplicación está diseñada para ser eficiente en le consumo de energía. Sin embargo, le uso continuo del GPS peut diminuer la duración de la batterie."],
  'doc_final_body_2': ["Assurez-vous de désactiver le suivi lorsque vous ne l'utilisez pas pour préserver la batterie.", "Be sure to turn off tracking when not in use to conserve battery.", "Asegúrese de desactivar le seguimiento cuando no lo esté utilizando para conservar la batería."],
  'doc_final_body_3': ["Le suivi GPS fonctionne grâce à une notification permanente. Vous pouvez éteindre votre écran ou utiliser d'autres applications, le tracé continuera normalement.", "GPS tracking works thanks to a permanent notification. You can turn off your screen or use other apps, the track will continue normally.", "El seguimiento GPS funciona gracias a una notification permanente. Puede apagar su pantalla o utilizar otras aplicaciones, la traza continuará normalement."],
  'doc_final_body_4': ["Bon vol !", "Good flight!", "¡Buen vole!"],
  'doc_close_app': [
    "Pour arrêter complètement l'application et le suivi, vous pouvez la fermer depuis le gestionnaire de tâches de votre téléphone (en la balayant vers le haut).",
    "To completely stop the application and tracking, you can close it from your phone's task manager (by swiping it up).",
    "Para detener completamente la aplicación y el seguimiento, puede cerrarla desde el administrador de tareas de su teléfono (deslizándola hacia arriba)."
  ],


  // simulation
  'simulation_disabled_during_tracking': [
    "La simulation est désactivée pendant le suivi.",
    'Simulation is disabled during tracking.',
    'La simulación está desactivada durante le seguimiento.'
  ],
  'start_simulation':["Simulation",'Simulation','Simulación'],
  'stop_simulation': ["Arrêter la simulation", 'Stop simulation', 'Detener simulación'],
  'simulation_speed_increase': ["Augmenter la vitesse", 'Increase speed', 'Aumentar la velocidad'],
  'simulation_speed_decrease': ["Diminue la vitesse", 'Decrease speed', 'Disminuir la velocidad'],

  'no_simulation_data': [
    "Aucune donnée de simulation dans cette trace",
    'No simulation data in this track',
    'No hay datos de simulación en esta pista'
  ],
  'select_track_to_simulate': [
    "Sélectionnez une trace",
    'Select a track','Seleccione una pista'],
  'simulation_finished': ["Simulation terminée", 'Simulation finished', 'Simulación terminada'],
  'simulation_stopped': ["Simulation arrêtée", 'Simulation stopped', 'Simulación detenida'],

  // Stats Screen
  'trip_stats': ["Statistiques du parcours", 'Trip Statistics', 'Estadísticas del viaje'],
  'flying_to': ["Vol vers", "Flying to", "Volando a"],
  'destination': ["Destination", "Destination", "Destino"],
  'start_point': ["Point de départ", "Start point", "Punto de partida"],
  'vac_url_title': ["Afficher la carte VAC", "Show VAC map", "Mostrar mapa VAC"],
  'url_label': ["Chemin vers le fichier ou URL", "Path to file or URL", "Ruta al archivo ou URL"],
  'error_prefix': ["Erreur :", "Error:", "Error:"],
  'to': ["Vers", "To", "A"],
  'distance': ["Distance", "Distance", "Distancia"],
  'target_distance': ["Distance cible", "Target distance", "Distancia al objetivo"],
  'departure': ["Départ à", 'Departure at', 'Salida a las'],
  'arrival':["Arrivée à",'Arrival at','Llegada a las'],
  'straight_distance': ["Distance à vol d'oiseau", 'Straight line distance', 'Distancia en línea recta'],
  'speed': ["Vitesse", 'Speed', 'Velocidad'],
  'altitude': ["Altitude", 'Altitude', 'Altitud'],
  'duration': ["Durée", 'Duration', 'Duración'],
  'target_bearing': ["Cap de la cible", 'Target bearing', 'Rumbo al objetivo'],
  'course_followed': ["Cap suivi", 'Course followed', 'Rumbo seguido'],
  'traveled': ["Parcouru", 'Traveled', 'Recorrido'],
  'moving': ["En mouvement", 'Moving', 'En mouvement'],
  'right': ["droite", 'right', 'derecha'],
  'left': ["gauche", 'left', 'izquierda'],
  'tracking': ["Trace en cours", 'Tracking', 'Rastreando'],
  'pause': ["Pause", 'Pause', 'Pausa'],
  'track_saved': ["enregistré", 'saved', 'guardado'],
  'cut_button': ["Couper", 'Cut', 'Cortar'],

// Tracks Screen
  'tracks_title': ["Liste des traces", 'Tracks list', 'Lista de pistas'],
  'view_tracks': ["Voir les traces", "View tracks", "Ver pistas"],
  'selected_tracks': ["traces sélectionnées", 'selected tracks', 'pistas seleccionnées'],
  'delete_prompt_title': [
    "Supprimer les traces sélectionnées ?",
    'Delete selected tracks?',
    '¿Eliminar las pistas seleccionadas?'
  ],
  'delete_prompt_body': [
    "Cette action est irréversible.",
    'This action is irreversible.',
    'Esta acción est irreversible.'
  ],
  'tracks_deleted_snackbar': [
    "Trace(s) sélectionnée(s) supprimée(s).",
    'Selected track(s) deleted.',
    'Pista(s) seleccionada(s) eliminada(s).'
  ],

  'merge_success_snackbar': ["Traces fusionnées ->", 'Tracks merged ->',
    'Pistas fusionadas ->'],
  'merge_failed_snackbar': [
    "Erreur pendant la fusion",
    'Error during merge',
    'Error durante la fusión'
  ],
  'merge_ask_body':["Fusionner",'Merge','Fusionar'],
  'merge_delete_sources': ["Supprimer les traces sources ?", "Delete source tracks?", "¿Eliminar las pistas de origen?"],
  'group_view_title':["Vue de groupe",'Group view','Vista de groupe'],
  'no_tracks_found': ["Aucune trace trouvée", 'No tracks found', 'No se encontraron pistas'],
  'distance_label':["distance:",'distance:','distancia:'],
  'duration_label':["durée:",'duration:','duración:'],
  'moving_time_label_short':["mouvement:",'movement:','movimiento:'],
  'share_tracks': ["Partager les traces", 'Share tracks', 'Compartir pistas'],
  'share_tracks_text': ["Voici mes traces ", 'Here are my  tracks', 'Aquí están mis pistas'],
  'error_sharing_tracks': ["Erreur lors de la préparation du partage", "Error preparing tracks for sharing", "Error al preparar las pistas para compartir"],
  'import_shared_tracks': ["Importer des traces", 'Import tracks', 'Importar pistas'],
  'tracks_imported_success': ["Trace(s) importée(s) avec succès", 'Track(s) imported successfully', 'Pista(s) importada(s) con éxito'],
  'new_tracks': ["nouvelle(s) trace(s)", 'new track(s)', 'nuevas(s) pista(s)'],
  'error_importing_tracks': ["Erreur lors de l'importation", "Error during import", "Error durante la importación"],
  'traces_list_banner': ["Les traces", "Traces", "Las huellas"],
  'view_button': ["Voir", "View", "Ver"],
  'delete_button': ["Supprimer", "Delete", "Eliminar"],
  'share_button': ["Partage", "Share", "Compartir"],
  'archives_button': ["Archives", "Archives", "Archivos"],
  'word_more_button': ["Plus", "More", "Más"],
  'receive_field': ["Recevoir", "Receive", "Recibir"],
  'send_field': ["Envoi", "Send", "Enviar"],
  'merge_button': ["Fusion", "Merge", "Fusión"],
  'rename_button': ["Renommer", "Rename", "Renombrar"],
  'archive_button': ["Archiver", "Archive", "Archivar"],
  'sort_button': ["Trier", "Sort", "Ordenar"],

  // Archives
  'archive': ["Archiver", 'Archive', 'Archivar'],
  'unarchive': ["Désarchiver", 'Unarchive', 'Desarchivar'],
  'archives': ["Archives", 'Archives', 'Archivos'],
  'archive_tracks': ["Archiver les traces", 'Archive tracks', 'Archivar pistas'],
  'unarchive_tracks': ["Désarchiver les traces", 'Unarchive tracks',
    'Desarchivar pistas'],
  'delete_archives_prompt': ["Supprimer les archives", 'Delete archives', 'Eliminar archivos'],
  'archives_deleted_snackbar': ["Archive(s) supprimée(s).", 'Archive(s) deleted.', 'Archivo(s) eliminado(s)'],
  'tracks_archived_snackbar': ["Trace(s) archivée(s).", 'Track(s) archived.', 'Pista(s) archivada(s)'],
  'tracks_unarchived_snackbar': ["Trace(s) restaurée(s).", 'Track(s) restored.', 'Pista(s) restaurada(s)'],
  'no_archives_found': ["Aucune archive trouvée", 'No archives found', 'No se encontraron archivos'],
  'export_archives': ["Exporter les archives", "Export archives", "Exportar archivos"],
  'import_archives': ["Importer les archives", "Import archives", "Importar archivos"],
  'export_success':["Exportation réussie",'Export successful','Exportación exitosa'],
  'error_exporting_archives':["Erreur à l'exportation",'Export error','Error de exportación'],
  'archives_imported_success':["Importation réussie",'Import successful','Importación exitosa'],
  'new_archives':["nouvelles archives",'new archives','nuevos archivos'],
  'import_cancelled': ["Importation annulée", "Import cancelled", "Importación cancelada"],
  'empty_archive': ["L'archive est vide", "Archive is empty", "El archive está vacío"],
  'error_creating_zip': ["Erreur lors de la création du zip", "Error creating zip", "Error al crear le zip"],
  'export_size_warning': [
    "Attention: le fichier est volumineux (%s Mo) et pourrait dépasser la limite de certains envois par mail.",
    "Warning: the file is large (%s MB) and might exceed the limit for some email providers.",
    "Atención: el archivo es grande (%s MB) et podría superar le límite de algunos proveedores de correo electrónico."
  ],

  // Premium / Paywall
  'premium_title': ["Pack Premium", 'Premium Pack', 'Pack Premium'],
  'premium_desc': [
    "Débloquez les fonctionnalités avancées pour la navigation et l'aviation.",
    "Unlock advanced features for navigation and aviation.",
    "Desbloquea funciones avanzadas de navegación y aviación."
  ],
  'premium_buy': ["Débloquer pour 9.99€", 'Unlock for 9.99€', 'Desbloquear por 9.99€'],
  'premium_buy_label': ["Débloquer pour", "Unlock for", "Desbloquear por"],
  'premium_success': ["Merci ! Le Pack Premium est débloqué.", 'Thank you! Premium Pack is unlocked.', '¡Gracias! El Pack Premium está desbloqueado.'],
  'premium_reset': ["Réinitialiser achat (Test)", 'Reset purchase (Test)', 'Restablecer compra (Prueba)'],

  // Sorting
  'sort_by': ["Trier par", 'Sort by', 'Ordenar por'],
  'sort_date': ["Date", 'Date', 'Fecha'],
  'sort_name': ["Nom", 'Name', 'Nombre'],
  'sort_distance': ["Distance", 'Distance', 'Distancia'],
  'sort_duration': ["Durée", 'Duration', 'Duración'],

  // GPS & Permissions
  'gps_poor': ["Signal GPS faible", 'Poor GPS signal', 'Señal GPS débil'],
  'gps_error': ["Erreur GPS", 'GPS Error', 'Error de GPS'],
  'acquiring_gps': ["Acquisition du signal GPS...", 'Acquiring GPS signal...', 'Adquiriendo señal GPS...'],
  'gps_error_start': [
    "Impossible de démarrer : signal GPS introuvable.",
    'Could not start: GPS signal not found.',
    'No se pudo iniciar: no se encontró la señal de GPS.'
  ],
  'permissions_checking': [
    "Vérification des permissions",
    'Checking permissions',
    'Comprobando permisos'
  ],
  'background_location_disabled': [
    "Le mode arrière-plan n'est pas activé",
    'Background mode is disabled',
    'El modo de fondo está desactivado'
  ],
  'notification_permission_required': [
    "La permission de notifier est requise pour le suivi.",
    'Notification permission is required for tracking.',
    'Se requiere permiso de notificación para le seguimiento.'
  ],
  'notification_permission_permanently_denied_message': [
    "Permission de notifier bloquée. Activez-la dans les réglages de l'application, section Permissions ou Notifications.",
    'Notification permission blocked. Please enable it in the app settings, under Permissions or Notifications.',
    'Permiso de notificación bloqueado. Habilítelo en la configuración de la application, en la sección Permisos ou Notificaciones.'
  ],
  'tracking_error': ["Erreur du suivi GPS", 'GPS Tracking Error', 'Error de suivi de GPS'],
  //'tracking_in_progress': ["Suivi en cours", 'Tracking in progress', 'Seguimiento en curso'],
  'foreground_notification_title': ["Suivi en cours", 'Tracking in progress', 'Seguimiento en curso'],
  'foreground_notification_text': [
    "L'application enregistre votre trace",
    'The application is recording your track',
    'La aplicación está grabando su pista'
  ],
  'background_location_rationale_message': [
    "Pour enregistrer votre trace en arrière-plan (écran éteint), vous devez régler l'autorisation sur \"Pendant l'utilisation\".\n\nSur l'écran suivant :\n1. Cliquez sur 'Autorisations'\n2. Cliquez sur 'Position'\n3. Sélectionnez 'Autoriser seulement si l'appli est en cours d'utilisation'",
    "To record your track in the background (screen off), you must set the permission to \"While using the app\".\n\nOn the next screen:\n1. Click on 'Permissions'\n2. Click on 'Location'\n3. Select 'Allow only while using the app'",
    "Para registrar su pista en segundo plano (pantalla apagada), debe configurar el permiso en \"Durante le uso\".\n\nEn la siguiente pantalla:\n1. Haga clic en 'Permisos'\n2. Haga clic en 'Ubicación'\n3. Seleccione 'Permitir solo durante le uso de la aplicación'"
  ],
  'permissions_required': ["Permissions requises", "Permissions required", "Permisos requeridos"],
  'restart_tracking_after_permission': [
    "Relancez le suivi après avoir activé la position",
    "Restart tracking after enabling location",
    "Reinicie el seguimiento después de habilitar la ubicación"
  ],
  'allow_always_button': ["Autoriser la position", "Allow location", "Permitir ubicación"],
  'background_location_permanently_denied': [
    "Les permissions de localisation sont refusées de manière permanente.",
    'Location permissions are permanently denied.',
    'Los permisos de ubicación se deniegan permanentemente.'
  ],
  'permission_required_title': ["Permission Requise", 'Permission Required', 'Permiso requerido'],
  'permission_location_permanently_denied_message': [
    "Les permissions de localisation ont été bloquées. Veuillez les activer manuellement dans les paramètres pour continuer.",
    'Location permissions have been blocked. Please enable them manually in the settings to continue.',
    'Se han bloqueado los permisos de ubicación. Habilítelos manualmente en la configuración para continuar.'
  ],
  'open_settings_button': ["Ouvrir les Paramètres", 'Open Settings', 'Abrir configuración'],
  'permission_location_needed_snackbar': [
    "La permission de localisation est nécessaire pour démarrer le suivi.",
    'Location permission is required to start tracking.',
    'Se requiere permiso de ubicación para iniciar le seguimiento.'
  ],
  'permission_location_always_recommended_snackbar': [
    "Pour un suivi fiable, la permission de localisation est nécessaire.",
    "For reliable tracking, location permission is required.",
    "Para un seguimiento fiable, se requiere le permiso de ubicación."
  ],

  // Map Screen & Drawer
  'start_tracking_prompt': [
    "Appuyez sur le bouton vert pour démarrer la trace",
    'Click on the green button to start the track',
    'Haga clic en le bouton verde para iniciar la pista'
  ],
  'zoom_in': ["Zoom avant", 'Zoom in', 'Acercar'],
  'zoom_out': ["Zoom arrière", 'Zoom out', 'Alejar'],
  'my_location': ["Ma position", 'My location', 'Mi ubicación'],
  'map_type': ["Type de carte", 'Map type', 'Tipo de mapa'],
  'normal': ["Normal", "Normal", "Normal"],
  'satellite': ["Satellite", "Satellite", "Satélite"],
  'terrain': ["Terrain", "Terrain", "Terreno"],
  'hybrid': ["Hybride", "Hybrid", "Híbrido"],
  'map_type_tooltip': ["Changer le type de carte", 'Change map type', 'Cambiar tipo de mapa'],
  'simulate_track': ["Rejouer une trace", 'Replay a track', 'Reproducir una pista'],
  'manage_destinations': [
    "Gestion des destinations",
    'Destinations management',
    'Gestión de destinos'
  ],
  'delete_destination_confirm_message':["Supprimer",'Delete','Eliminar'],
  'export_destinations': ["Exporter les destinations", 'Export destinations', 'Exportar destinos'],
  'import_destinations': ["Importer les destinations", 'Import destinations', 'Importar destinos'],
  'name_current_position': [
    "Nommer la position actuelle",
    'Name current position',
    'Nombrar la posición actual',
  ],
  'enter_destination_name_hint': ["Entrer le nom de la destination", "Enter destination name", "Introducir nombre del destino"],
  'export_destinations_share_text':["Voici mes destinations",'Here are my destinations','Aquí están mis destinos'],
  'no_destinations_to_export':["Pas de destination à exporter",
    'No destinations to export','No hay destinos para exportar'],
  'no_destination_available':["Pas de destination",'No destination available','No hay destino disponible'],
  'destinations_imported_success':["Importation réussie",'Importation successful','Importación exitosa'],
  'choose_destination':["Choisir la destination",'Choose the destination','Elegir le destino'],
  'destination_set':["Destination vers ",'Destination to ','Destino a '],
  'create_destination': ["Créer une destination", 'Create a destination', 'Crear un destino'],
  'create_destination_on_map': ["Destination depuis la carte", 'destination from map', 'Destino desde le mapa'],
  'pick_destination_title': ["Choisir sur la carte", 'Pick on map', 'Elegir en le mapa'],
  'change_destination': ["Changer de destination", 'Change the destination', 'Cambiar le destino'],
  'view_statistics': ["Joindre la destination", 'Join the destination', 'Unirse al destino'],
  'name': ["Nom", "Name", "Nombre"],
  'namereq': ["Nom requis", "Name required", "Nombre requerido"],
  'is_aerodrome': ["Estce un aérodrome ?", "Is it an aerodrome?", "¿Es un aérodrome?"],
  'address_not_found': ["Adresse non trouvée", "Address not found", "Dirección no encontrada"],
  'search_address_hint': ["Rechercher une adresse...", "Search address...", "Buscar dirección..."],
  'home_saved': ["enregistrée", "saved", "guardada"],
  'destination_already_exists': ["Cette destination existe déjà", "This destination already exists", "Este destino ya existe"],
  'lat': ["Latitude", "Latitude", "Latitud"],
  'lon': ["Longitude", "Longitude", "Longitud"],
  'latreq': ["Latitude requise", "Latitude required", "Latitud requerida"],
  'lonreq': ["Longitude requise", "Longitude required", "Longitud requerida"],
  'inval': ["Valeur invalide", "Invalid value", "Valor no válido"],
  'invlon': ["Longitude invalide", "Invalid longitude", "Longitud no válida"],
  'cut_prompt_body': ["Touchez la trace à l'endroit où vous voulez la couper", "Tap the track where you want to cut it", "Toca la pista donde quieras cortarla"],
  'oaci_cache': ["Cache OACI", "OACI Cache", "Caché OACI"],
  'tiles_count': ["Tuiles en cache :", "Cached tiles:", "Mosaicos en caché:"],
  'cache_size': ["Taille du cache :", "Cache size:", "Tamaño de caché:"],
  'clear_cache': ["Vider le cache", "Clear cache", "Vaciar caché"],
  'cache_cleared': ["Cache vidé", "Cache cleared", "Caché vaciado"],
  'oaci_quota_exceeded': [
    "Quota OACI dépassé. Passage en mode hors-ligne pour cette zone.",
    "OACI quota exceeded. Switching to offline mode for this area.",
    "Cuota OACI superada. Cambiando a modo fuera de línea para esta área."
  ],
  'flight_preparation': ["Préparation du vol", "Flight Preparation", "Preparación del vuelo"],
  'flight_preparation_short': ["Préparation :", "Preparation:", "Preparación:"],
  'drag_points_instruction': [
    "Faites glisser les points ou tapez sur la carte", 
    "Drag points or tap on the map", 
    "Arrastra los puntos o toca el mapa"
  ],
  'choose_aerodrome_for_prep': [
    "Veuillez choisir un aérodrome pour la préparation de vol.",
    "Please choose an aerodrome for flight preparation.",
    "Por favor, elija un aeródromo para la preparación del vuelo."
  ],
  'route_saved_msg': [
    "Route '%s' sauvegardée dans les destinations !",
    "Route '%s' saved in destinations!",
    "¡Ruta '%s' guardada en los destinos!"
  ],
  'nav_point': ["Point de navigation", "Navigation point", "Punto de navegación"],
  'name_this_point': ["Nommez ce point", "Name this point", "Nombra este punto"],
  'departure_point': ["Départ", "Departure", "Salida"],
  'delete_point_q': ["Supprimer ce point ?", "Delete this point?", "¿Eliminar este punto?"],
  'remove_point_from_route': ["Voulez-vous retirer '%s' de votre itinéraire ?", "Do you want to remove '%s' from your route?", "¿Quieres eliminar '%s' de tu ruta?"],
  'route_note': ["Note de route", "Route note", "Nota de ruta"],
  'enter_segment_note': ["Entrez une note pour ce segment (ex: monter à 4000ft)", "Enter a note for this segment (e.g. climb to 4000ft)", "Introduzca una nota para este segmento (ej. subir a 4000 pies)"],
  'edit_point': ["Éditer le point", "Edit point", "Editar punto"],
  'segment_note': ["Note de segment", "Segment note", "Nota de segmento"],
  'press_to_close': ["Appuyez pour fermer", "Tap to close", "Toca para cerrar"],
  'undo_last_change': ["Annuler la dernière modification", "Undo last change", "Deshacer último cambio"],
  'show_compass_tooltip': ["Afficher le cap", "Show compass", "Mostrar rumbo"],
  'wp_reached': ["Point atteint :", "Waypoint reached:", "Punto alcanzado:"],
  'heading_to': ["Cap vers", "Heading to", "Rumbo a"],
  'unit_mb': ["Mo", "MB", "MB"],
  'tap_segment_to_add_note': ["Tapez sur un segment de la route pour ajouter une note", "Tap on a route segment to add a note", "Toca un segmento de la ruta para añadir una nota"],
  'add_route_note': ["Ajouter une note de route", "Add route note", "Añadir nota de ruta"],
};
