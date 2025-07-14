import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Essentials/kWidgets.dart';
import 'package:hello_captain_user/Helper/hive_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

import '../../Models/app_settings_model.dart';
import '../../Models/user_model.dart';
import 'CountryDialog.dart';

class Login_UI extends ConsumerStatefulWidget {
  const Login_UI({super.key});

  @override
  ConsumerState<Login_UI> createState() => _Login_UIState();
}

class _Login_UIState extends ConsumerState<Login_UI> {
  bool showPassword = false;
  final phone = TextEditingController();
  final password = TextEditingController();
  final isLoading = ValueNotifier(false);
  String selectedCountry = "+977";

  Future<void> login() async {
    try {
      FocusScope.of(context).unfocus();
      isLoading.value = true;
      final res = await AuthRepo.login(
        selectedCountry + phone.text,
        password.text,
      );

      if (res["code"] != "200") throw res["message"];
      await HiveConfig.setData("userData", {
        "phone": selectedCountry + phone.text,
        "password": password.text,
      });

      ref.read(userProvider.notifier).state = UserModel.fromMap(res["data"][0]);
      ref.read(appSettingsProvider.notifier).state = AppSettingsModel.fromMap(
        res as Map<String, dynamic>,
      );

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
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      isLoading: isLoading,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Column(
            children: [
              Label("Login").title,
              height20,
              Label("Welcome Back to", fontSize: 17).regular,
              Label("Hello Captain", weight: 700, fontSize: 25).title,
              kHeight(30),
              KField(
                controller: phone,
                showRequired: false,
                label: "Enter your phone number",
                prefix: IconButton(
                  onPressed: () async {
                    final res = await showDialog(
                      context: context,
                      builder: (context) => CountryDialog(),
                    );

                    selectedCountry = res["code"];
                    setState(() {});
                  },
                  icon: Row(
                    spacing: 5,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Label(selectedCountry, fontSize: 18, height: 1.5).regular,
                      Flexible(
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 15,
                        ),
                      ),
                    ],
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                hintText: "Enter Phone Number",
                fontSize: 18,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (val) => KValidation.phone(val),
              ),
              height15,
              KField(
                controller: password,
                label: "Enter Password",
                hintText: "Password Here",
                showRequired: false,
                fontSize: 18,
                obscureText: !showPassword,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  icon: Icon(
                    showPassword ? Icons.remove_red_eye : Icons.password,
                    size: 25,
                  ),
                ),
                textCapitalization: TextCapitalization.none,
                validator: (val) => KValidation.required(val),
              ),
              height10,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => context.push("/forgot-password"),
                    child: Label("Forgot Password?", weight: 900).regular,
                  ),
                  TextButton(
                    onPressed: () => context.push("/register"),
                    child: Label("Create Account", weight: 900).regular,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(kPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              height10,
              disclaimer(),
              height10,
              KButton(
                onPressed: login,
                label: "Login",
                backgroundColor: Kolor.primary,
                style: KButtonStyle.expanded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
