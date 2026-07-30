import 'package:flutter/material.dart';
import 'package:om_ai/resources/st_colors.dart';
import 'package:om_ai/screens/home_screen.dart';
import 'package:flutter/services.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OM AI',
      theme: ThemeData(primaryColor: StColors.pageBackground),
      navigatorKey: navigatorKey,
      home: HomeScreen(),
    );
  }
}
