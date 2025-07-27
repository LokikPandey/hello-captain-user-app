import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Essentials/kWidgets.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

import 'package:hello_captain_user/Helper/hive_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Models/user_model.dart';
import 'package:hello_captain_user/Models/app_settings_model.dart';

import 'CountryDialog.dart';

class LoginOtp_UI extends ConsumerStatefulWidget {
  const LoginOtp_UI({super.key});

  @override
  ConsumerState<LoginOtp_UI> createState() => _LoginOtp_UIState();
}

class _LoginOtp_UIState extends ConsumerState<LoginOtp_UI> {
  final phone = TextEditingController();
  final otp = TextEditingController();
  final isLoading = ValueNotifier(false);
  String selectedCountry = "+977"; // UI display only

  Future<void> sendOtp() async {
    try {
      FocusScope.of(context).unfocus();
      isLoading.value = true;

      final number = phone.text.trim();
      final res = await AuthRepo.sendOtp(number);
      if (res["code"] != "200") throw res["message"];

      KSnackbar(context, message: "OTP sent successfully");
    } catch (e) {
      KSnackbar(context, message: "$e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    try {
      FocusScope.of(context).unfocus();
      isLoading.value = true;

      final number = phone.text.trim();
      final fcm = await FirebaseMessaging.instance.getToken();

      final res = await AuthRepo.verifyOtp(
        phone: number,
        otp: otp.text.trim(),
        token: fcm ?? "",
      );

      if (res["code"] != "200") throw res["message"];

      final user = res["data"][0];

      await HiveConfig.setData("userData", {
        "phone": number,
        "password": user["password"] ?? "",
      });

      ref.read(userProvider.notifier).state = UserModel.fromMap(user);
      ref.read(appSettingsProvider.notifier).state = AppSettingsModel.fromMap(
        res as Map<String, dynamic>,
      );

      KSnackbar(context, message: "Login Successful");
      context.go("/");
    } catch (e) {
      KSnackbar(context, message: "$e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    phone.dispose();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      isLoading: isLoading,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Centered Titles
              Center(child: Label("Login").title),
              height20,
              Center(child: Label("Welcome Back to", fontSize: 17).regular),
              Center(
                child: Label("Hello Captain", fontSize: 25, weight: 700).title,
              ),
              kHeight(30),

              /// Phone + Send OTP
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: KField(
                      controller: phone,
                      hintText: "Phone",
                      fontSize: 16,
                      maxLength: 10,
                      keyboardType: TextInputType.phone,
                      prefix: IconButton(
                        onPressed: () async {
                          final res = await showDialog(
                            context: context,
                            builder: (_) => CountryDialog(),
                          );
                          if (res != null && res["code"] != null) {
                            selectedCountry = res["code"];
                            setState(() {});
                          }
                        },
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Label(selectedCountry, fontSize: 16).regular,
                            const Icon(Icons.arrow_drop_down, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Kolor.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      "Send OTP",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              height15,

              /// OTP Input
              KField(
                controller: otp,
                hintText: "Enter OTP",
                fontSize: 16,
                keyboardType: TextInputType.number,
              ),

              /// Login with Password / Create Account below OTP field
              height10,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => context.push("/login"),
                    child: Label("Login with Password", weight: 900).regular,
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => context.push("/register"),
                    child: Label("Create Account", weight: 900).regular,
                  ),
                ],
              ),

              height15,
            ],
          ),
        ),
      ),

      /// Bottom Buttons
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(kPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KButton(
                onPressed: verifyOtp,
                label: "Verify OTP",
                backgroundColor: Kolor.primary,
                style: KButtonStyle.expanded,
              ),
              height10,
              disclaimer(),
            ],
          ),
        ),
      ),
    );
  }
}
