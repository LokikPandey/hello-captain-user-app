import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

import '../../Essentials/kButton.dart';
import '../../Essentials/kWidgets.dart';

class Change_Password_UI extends ConsumerStatefulWidget {
  const Change_Password_UI({super.key});

  @override
  ConsumerState<Change_Password_UI> createState() => _Change_Password_UIState();
}

class _Change_Password_UIState extends ConsumerState<Change_Password_UI> {
  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();
  final isLoading = ValueNotifier(false);
  final _fromKey = GlobalKey<FormState>();
  bool showPassword = false;

  Future<void> changePassword() async {
    try {
      isLoading.value = true;
      if (_fromKey.currentState!.validate()) {
        final user = ref.read(userProvider);
        if (user == null) throw "User not logged in!";

        final res = await AuthRepo.changePassword(
          oldPassword.text,
          newPassword.text,
          user.phone_number,
        );

        if (res["code"] != "200") throw res["message"];
        oldPassword.clear();
        newPassword.clear();

        await AuthRepo.logout(context, ref);
        KSnackbar(context, message: "Password changed! Please Login Again.");
      }
    } catch (e) {
      KSnackbar(context, message: "$e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    oldPassword.dispose();
    newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      isLoading: isLoading,
      appBar: KAppBar(context, title: "Change Password"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Form(
            key: _fromKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                KField(
                  controller: oldPassword,
                  label: "Current Password",
                  hintText: "Enter current password",
                  obscureText: true,
                  textCapitalization: TextCapitalization.none,
                  validator: (val) => KValidation.required(val),
                ),
                height15,
                KField(
                  controller: newPassword,
                  label: "New Password",
                  hintText: "Enter new password",
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                    icon: Icon(
                      showPassword ? Icons.password : Icons.remove_red_eye,
                    ),
                  ),
                  obscureText: showPassword,
                  textCapitalization: TextCapitalization.none,
                  validator: (val) => KValidation.required(val),
                ),
              ],
            ),
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
                onPressed: changePassword,
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
