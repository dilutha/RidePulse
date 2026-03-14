import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'core/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(

      create: (_) => AuthProvider()..initialize(),

      builder: (context, child) {

        final authProvider = context.watch<AuthProvider>();

        final router = AppRouter.createRouter(authProvider);

        return MaterialApp.router(

          title: 'Ride Pulse',

          debugShowCheckedModeBanner: false,

          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),

          routerConfig: router,
        );
      },
    );
  }
}