
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/product_model.dart';
import 'providers/product_provider.dart';
import 'screens/add_product_screen.dart';
import 'screens/detail_product_screen.dart';
import 'screens/edit_product_screen.dart';
import 'screens/list_product_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const ListProductScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) => DetailProductScreen(
        id: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) => EditProductScreen(
        product: state.extra as Product,
      ),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddProductScreen(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProductProvider()..init(),
      child: MaterialApp.router(
        title: 'Pastel.Shop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF3B6CE),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFFF8FB),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF8DCE8),
            foregroundColor: Color(0xFF69465A),
            centerTitle: true,
          ),
          cardTheme: const CardThemeData(
            color: Color(0xFFFFF0F5),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
