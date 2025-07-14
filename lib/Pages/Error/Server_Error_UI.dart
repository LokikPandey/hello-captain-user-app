import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import '../../Essentials/Label.dart';
import '../../Repository/auth_repo.dart';
import '../../Resources/constants.dart';

class Server_Error_UI extends ConsumerStatefulWidget {
  const Server_Error_UI({super.key});

  @override
  ConsumerState<Server_Error_UI> createState() => _Error_UIState();
}

class _Error_UIState extends ConsumerState<Server_Error_UI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Label("Server Error!", fontSize: 30, weight: 700).title,
                Label(
                  "Server is busy please try again!",
                  fontSize: 17,
                  weight: 500,
                  textAlign: TextAlign.center,
                ).subtitle,
                height20,
                TextButton(
                  onPressed: () => ref.refresh(authFuture.future),
                  child: Label("Retry").regular,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
