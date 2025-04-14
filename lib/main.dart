import 'package:flutter/material.dart';
import 'package:intercom_flutter/intercom_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'components/bottom_nav_bar.dart';
import 'pages/report_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Intercom with environment variables
  await Intercom.instance.initialize(
    dotenv.env['INTERCOM_APP_ID']!,
    iosApiKey: dotenv.env['INTERCOM_IOS_API_KEY']!,
    androidApiKey: dotenv.env['INTERCOM_ANDROID_API_KEY']!,
  );
  
  // Register an unidentified user
  await Intercom.instance.loginUnidentifiedUser();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Route',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F8DED), // Intercom blue color
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F8DED),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1F8DED),
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Urban Route'),
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            HomePage(),
            ReportPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Intercom.instance.displayMessenger();
          },
          shape: const CircleBorder(),
          child: SvgPicture.asset(
            'assets/messenger.svg',
            width: 33,
            height: 33,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.map,
            size: 80,
            color: Color(0xFF1F8DED),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Urban Route',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your urban exploration companion',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1F8DED),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'User Profile',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Your profile information will appear here',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
