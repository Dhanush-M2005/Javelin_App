import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/dataset_provider.dart';
import 'providers/wifi_service_provider.dart';
import 'providers/throw_selection_provider.dart';
import 'screens/throws_screen.dart';
import 'screens/compare_screen.dart';
import 'widgets/enhanced_appbar.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatasetProvider()..loadDatasets()),
        ChangeNotifierProvider(create: (_) => ThrowSelectionProvider()),
        ChangeNotifierProxyProvider<DatasetProvider, WifiServiceProvider>(
          create: (context) {
            final provider = WifiServiceProvider(context.read<DatasetProvider>());
            // Check connection on app startup
            Future.microtask(() => provider.checkCurrentConnection());
            return provider;
          },
          update: (context, datasetProvider, previous) {
            if (previous != null) {
              return previous;
            }
            final provider = WifiServiceProvider(datasetProvider);
            Future.microtask(() => provider.checkCurrentConnection());
            return provider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Javelin Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF0096FF),
        colorScheme: ColorScheme.fromSwatch(
          brightness: Brightness.dark,
          primarySwatch: MaterialColor(0xFF0096FF, {
            50: Color(0xFFE0F2FF),
            100: Color(0xFFB3E0FF),
            200: Color(0xFF80CCFF),
            300: Color(0xFF4DB8FF),
            400: Color(0xFF26A8FF),
            500: Color(0xFF0096FF),
            600: Color(0xFF008EFF),
            700: Color(0xFF0083FF),
            800: Color(0xFF0079FF),
            900: Color(0xFF0066FF),
          }),
          accentColor: const Color(0xFF0096FF),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
          selectedItemColor: Color(0xFF0096FF),
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _goToCompare() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  List<Widget> get _widgetOptions => <Widget>[
    ThrowsScreen(onAnalyze: _goToCompare),
    const CompareScreen(),
  ];

  void onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const EnhancedAppBar(),
      body: _selectedIndex < _widgetOptions.length 
          ? _widgetOptions[_selectedIndex] 
          : const Center(child: Text("Not Implemented")),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.list),
        label: 'Throws',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.compare),
        label: 'Compare',
      ),
    ],
        currentIndex: _selectedIndex,
        onTap: onItemTapped,
      ),
    );
  }
}