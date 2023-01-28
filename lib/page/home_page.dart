import 'package:flutter/material.dart';
import 'package:my_api/my_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  static const String _tag = "HomePage";

  final client = FinanceClient();

  void openPage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  /// Triggers on menu button pressed
  void onMenuPressed() {
    init();
  }

  void init() async {
    try {
      final client = ApiClient();
      await client.init(
        onLoginRequired: () => openPage(const LoginPage()),
      );
    } on Exception catch(e) {
      Log.e(_tag, "Error: $e");
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => onMenuPressed(),
        ),
      ),
    );
  }
}