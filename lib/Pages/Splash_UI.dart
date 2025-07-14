import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Splash_UI extends ConsumerStatefulWidget {
  const Splash_UI({super.key});

  @override
  ConsumerState<Splash_UI> createState() => _Splash_UIState();
}

class _Splash_UIState extends ConsumerState<Splash_UI> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, '/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(
        255,
        236,
        111,
        35,
      ), // 👈 Sets background color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            children: [
              Image.asset("$kImagePath/hello_captain_logo.png"),
              const SizedBox(height: 10), // Spacing between image and text
              const Text(
                "Powered By Nepali Dreams",
                style: TextStyle(
                  fontFamily: "Manrope",
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
