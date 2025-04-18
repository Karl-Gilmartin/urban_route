import 'package:flutter/material.dart';
import 'package:intercom_flutter/intercom_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'components/bottom_nav_bar.dart';
import 'pages/report_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'pages/map_page.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const darkNavy = Color(0xFF00171F);
  static const deepBlue = Color(0xFF003459);
  static const cyanBlue = Color(0xFF007EA7);
  static const brightCyan = Color(0xFF00A8E8);
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
  final _supabase = Supabase.instance.client;

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
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF1F8DED),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/home': (context) => HomePage(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const HomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: const [
          Center(
            child: Text('Home Page'),
          ),
          ReportPage(),
          Center(
            child: Text('Profile Page'),
          ),
          MapPage(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: onItemTapped,
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
