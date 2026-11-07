import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/firebase_options.dart';
import 'config/theme.dart';
import 'services/database_service.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/desk_provider.dart';
import 'views/auth/pin_auth_screen.dart';
import 'views/distributor/distributor_desk_screen.dart';
import 'views/retailer/retailer_catalog_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely catch if credentials are placeholders)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e (Using resilient offline/demo fallback mode)');
  }

  // Initialize database service
  await DatabaseService.instance.initialize();

  runApp(const WholesaleDeskApp());
}

class WholesaleDeskApp extends StatelessWidget {
  const WholesaleDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DeskProvider()),
      ],
      child: MaterialApp(
        title: 'Wholesale Desk - B2B Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppRootRouter(),
      ),
    );
  }
}

class AppRootRouter extends StatelessWidget {
  const AppRootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return const PinAuthScreen();
    }

    if (auth.isRetailer && auth.currentRetailer != null) {
      return RetailerCatalogScreen(retailer: auth.currentRetailer!);
    }

    if (auth.isAdmin || auth.isStaff) {
      return const DistributorDeskScreen();
    }

    return const PinAuthScreen();
  }
}
