import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Secret/Map_Key.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';

class Khalti_UI extends ConsumerStatefulWidget {
  final String pidx;
  const Khalti_UI({super.key, required this.pidx});

  @override
  ConsumerState<Khalti_UI> createState() => _Khalti_UIState();
}

class _Khalti_UIState extends ConsumerState<Khalti_UI> {
  late final Future<Khalti?> khalti;
  bool error = false;
  String title = "Connecting to Khalti.";
  String subtitle = "Please do not go back or exit the app.";

  PaymentResult? paymentResult;

  @override
  void initState() {
    super.initState();
    final payConfig = KhaltiPayConfig(
      publicKey: KHALTI_PUBLIC_KEY,
      pidx: widget.pidx,
      environment: Environment.test,
    );

    khalti = Khalti.init(
      enableDebugging: true,
      payConfig: payConfig,
      onPaymentResult: (paymentResult, khalti) {
        log("Khalti on payment result-> $paymentResult");

        // log("${paymentResult.payload?.status}");
        // log("${paymentResult.payload?.pidx}");
        // log("${paymentResult.payload?.totalAmount}");
        // log("${paymentResult.payload?.transactionId}");

        setState(() {
          this.paymentResult = paymentResult;
          title = "Congratulations!";
          subtitle = "Payment successful. Refresh the wallet";
        });

        khalti.close(context);

        if (paymentResult.payload?.status == "Completed") {
          KSnackbar(
            context,
            message:
                "Payment successful. Please refresh the page to see updated wallet",
            error: false,
          );
          context.go(
            "/confirmation",
            extra:
                Map.from({
                  'subtitle': "Wallet Top-Up Successful",
                  'description': "Refresh home page to view updated wallet.",
                }).cast<String, dynamic>(),
          );
        } else {
          KSnackbar(
            context,
            message: "Relax! If funds deducted, will be credited back",
            error: false,
          );
          setState(() {
            title = "Oops!";
            subtitle =
                "No update on payment. If funds deducted, will be credited back. Go back and try again.";
          });
        }
      },
      onMessage: (
        khalti, {
        description,
        statusCode,
        event,
        needsPaymentConfirmation,
      }) async {
        final descriptionMap = description as Map;
        log(
          'Description: $description, Status Code: $statusCode, Event: $event, NeedsPaymentConfirmation: $needsPaymentConfirmation',
        );
        if (statusCode != 200) {
          setState(() {
            title = "Oops!";
            subtitle = "${descriptionMap["status"]}. Go back and try again.";
          });
        }

        khalti.close(context);
      },
      onReturn: () => log("Returned back"),
    );

    openKhaltiPayment();
  }

  void openKhaltiPayment() {
    khalti.then((khaltiInstance) async {
      if (khaltiInstance != null) {
        final instance = khaltiInstance;
        instance.open(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            spacing: 20,
            mainAxisSize: MainAxisSize.min,
            children: [
              !error ? Icon(Icons.dangerous) : kSmallLoading,
              Label(title).regular,
              Label(subtitle).subtitle,
            ],
          ),
        ),
      ),
    );
  }
}
