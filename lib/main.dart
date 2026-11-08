import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/theme.dart';
import 'models/retailer.dart';
import 'services/repository_manager.dart';
import 'state/auth_provider.dart';
import 'state/cart_provider.dart';
import 'state/desk_provider.dart';
import 'views/auth/pin_auth_screen.dart';
import 'views/distributor/distributor_desk_screen.dart';
import 'views/retailer/retailer_catalog_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load human-editable config.json from project root
  await AppConfig.load();

  // 2. Initialize Firebase using options from config.json (with demo fallback)
  try {
    await Firebase.initializeApp(
      options: AppConfig.firebaseOptions,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e (Using resilient offline/demo fallback mode)');
  }

  // 3. Initialize repository manager (supports both Firestore and WooCommerce REST API)
  await RepositoryManager.instance.initialize();

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

    if (auth.isSalesman) {
      final retailer = auth.currentRetailer ??
          const Retailer(
            id: 'temp_retailer',
            storeName: 'Select Retailer',
            mobile: '',
            pin: '',
            route: '',
            status: 'active',
          );
      return RetailerCatalogScreen(retailer: retailer);
    }

    if (auth.isAdmin || auth.isStaff) {
      return const DistributorDeskScreen();
    }

    return const PinAuthScreen();
  }
}
