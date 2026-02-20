import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'components/routs.dart';
import 'models/home_service.dart';
import 'models/location_service.dart';
import 'models/track_data.dart';
import 'models/premium_state.dart';
import 'models/settings_state.dart';
import 'screens/map_screen.dart';
import 'screens/map_track_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/tracks_screen.dart';
import 'screens/homes_screen.dart';
import 'screens/pick_on_map_screen.dart';
import 'screens/documentation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Active le mode bord à bord
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  
  // Configuration pour forcer la transparence totale sans voile de contraste
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false, // Désactive le voile gris Android sur la barre du bas
    statusBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
  ));

  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => TrackData()),
        ChangeNotifierProvider(create: (context) => LocaData()),
        ChangeNotifierProvider(create: (context) => HomeService()),
        ChangeNotifierProvider(create: (context) => PremiumState()),
        ChangeNotifierProvider(create: (context) => SettingsState()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Trackeo',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.blue,
        ),
         localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', ''),
          Locale('en', ''),
          Locale('es', ''),
        ],
        home: Builder(
          builder: (context) {
            updateLanguage(context);
            return const MapScreen();
          }
        ),
        routes: {
          MapTrack.id: (context) => const MapTrack(),
          StatsScreen.id: (context) => const StatsScreen(),
          HomesScreen.id: (context) => const HomesScreen(),
          PickOnMapScreen.id: (context) => const PickOnMapScreen(),
          DocumentationScreen.id: (context) => const DocumentationScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == TracksScreen.id) {
            final isSelectionMode = settings.arguments as bool? ?? false;
            return MaterialPageRoute(
              builder: (context) =>
                  TracksScreen(isSelectionMode: isSelectionMode),
            );
          }
          return null;
        },
      ),
    );
  }
}
