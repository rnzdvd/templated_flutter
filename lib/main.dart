import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:templated_flutter/core/utils/screen_registry.dart';
import 'package:templated_flutter/store.dart';
import 'package:toastification/toastification.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  getIt.registerSingleton<Store>(Store());

  runApp(const App());
}

// GoRouter configuration
final _router = GoRouter(initialLocation: '', routes: [
   
  ],
);

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp.router(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          fontFamily: 'ProductSans',
        ),
        routerConfig: _router,
      ),
    );
  }
}
