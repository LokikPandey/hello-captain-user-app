import 'package:flutter/material.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import '../../Essentials/Label.dart';
import '../../Essentials/kWidgets.dart';

class Forgot_Password_UI extends StatefulWidget {
  const Forgot_Password_UI({super.key});

  @override
  State<Forgot_Password_UI> createState() => _Forgot_Password_UIState();
}

class _Forgot_Password_UIState extends State<Forgot_Password_UI> {
  final email = TextEditingController();
  final isLoading = ValueNotifier(false);

  Future<void> forgotPassword() async {
    try {
      FocusScope.of(context).unfocus();
      isLoading.value = true;
      final res = await AuthRepo.forgotPassword(email.text);
      if (res["code"] != "200") throw res["message"];

      KSnackbar(context, message: "Email Sent on ${email.text}!");
    } catch (e) {
      KSnackbar(context, message: '$e', error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      isLoading: isLoading,
      appBar: AppBar(title: Label("Forgot Password").title, centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.email_outlined, size: 40, color: Kolor.primary),
              height10,
              Label(
                "A Reset Password email will be sent to your registered email address.",
                fontSize: 17,
              ).title,
              height10,
              KField(
                controller: email,
                label: "Enter your email address",
                hintText: "Your Email Address Here",
                showRequired: false,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                validator: (val) => KValidation.email(val),
                onChanged: (val) => setState(() {}),
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
                onPressed: email.text.isNotEmpty ? forgotPassword : null,
                label: "Proceed",
                style: KButtonStyle.expanded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
