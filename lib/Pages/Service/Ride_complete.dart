import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:lottie/lottie.dart';

class RideCompletedUI extends StatelessWidget {
  final String transactionId;
  final String driverId;

  const RideCompletedUI({
    super.key,
    required this.transactionId,
    required this.driverId,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: KScaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LottieBuilder.asset(
                  "assets/animations/success.json", // <- Add your ride completed animation file
                  height: 300,
                ),
                Label(
                  "✅ Ride Completed ✅",
                  weight: 900,
                  fontSize: 25,
                  color: StatusText.success,
                ).title,
                Label(
                  "Thank you for riding with us!",
                  weight: 900,
                  fontSize: 22,
                ).title,
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(kPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                KButton(
                  onPressed: () => context.push(
                    "/order-detail/$transactionId/$driverId",
                  ),
                  label: "View Ride Details",
                  style: KButtonStyle.expanded,
                ),
                const SizedBox(height: 10),
                KButton(
                  onPressed: () => context.go("/"),
                  label: "Go Home",
                  style: KButtonStyle.expanded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
