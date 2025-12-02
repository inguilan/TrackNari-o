import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'utils/flutter_map_fixes.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/camionero/camionero_home_screen.dart';
import 'screens/contratista/contratista_home_screen.dart';
import 'screens/common/loading_widget.dart';

// INICIO: PARCHES PARA COMPATIBILIDAD
// Agrega el método 'hashValues' al ámbito global para que lo use positioned_tap_detector_2
int hashValues(dynamic a, dynamic b) {
  return Object.hash(a, b);
}

// Extiende TextTheme para agregar headline5 para retrocompatibilidad
extension TextThemeCompat on TextTheme {
  TextStyle get headline5 => titleLarge ?? const TextStyle(fontSize: 20);
}
// FIN: PARCHES PARA COMPATIBILIDAD

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Para desarrollo, usamos una configuración de Firebase temporal
    // En producción, deberías usar la configuración generada automáticamente
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDEMOKEY",  // Reemplazar con API key real en producción
          authDomain: "trackarino.firebaseapp.com",
          projectId: "trackarino",
          storageBucket: "trackarino.appspot.com",
          messagingSenderId: "123456789",
          appId: "1:123456789:web:abcdef1234567890",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error al inicializar Firebase: $e');
    }
    // La app puede funcionar sin Firebase en desarrollo
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        Provider(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'Tracknariño',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Inicializa los servicios y verifica el estado de autenticación
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      // Inicializar el servicio de autenticación
      await authService.init();
      
      if (authService.isAuthenticated) {
        // Inicializar otros servicios si el usuario está autenticado
        final notificationService = Provider.of<NotificationService>(context, listen: false);
        await notificationService.initialize();
        
        if (authService.currentUser?.tipoUsuario == 'camionero') {
          // Inicializar servicio de ubicación para camioneros
          final locationService = Provider.of<LocationService>(context, listen: false);
          await locationService.init(authService.currentUser!.id!);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al inicializar servicios: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: LoadingWidget(message: 'Iniciando aplicación...'),
          ),
        ),
      );
    }

    // Obtener el estado de autenticación
    final authService = Provider.of<AuthService>(context);
    
    // Si no está autenticado, mostrar pantalla de login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }
    
    // Redirigir según el tipo de usuario
    switch (authService.currentUser?.tipoUsuario) {
      case 'camionero':
        return CamioneroHomeScreen(usuario: authService.currentUser!);
      case 'contratista':
        return ContratistaHomeScreen(usuario: authService.currentUser!);
      default:
        return const LoginScreen(); // Por defecto, si hay algún error
    }
  }
}
