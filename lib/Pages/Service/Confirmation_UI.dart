import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:lottie/lottie.dart';

class Confirmation_UI extends StatelessWidget {
  final String subtitle;
  final String description;
  final String transactionId;
  final String driverId;

  const Confirmation_UI({
    super.key,
    this.subtitle = "Order Placed",
    this.description = "You can track order status in Orders page.",
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
                  "assets/animations/success.json",
                  height: 300,
                ),
                Label(
                  "🎉 Success 🎉",
                  weight: 900,
                  fontSize: 25,
                  color: StatusText.success,
                ).title,
                Label(subtitle, weight: 900, fontSize: 25).title,
                Label(description).regular,
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
                  onPressed:
                      () => context.push(
                        "/order-detail/$transactionId/$driverId",
                      ),
                  label: "View Order Details",
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
