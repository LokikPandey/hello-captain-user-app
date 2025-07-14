import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Essentials/kWidgets.dart';
import 'package:hello_captain_user/Helper/hive_config.dart';
import 'package:hello_captain_user/Helper/image_pick_helper.dart';
import 'package:hello_captain_user/Models/user_model.dart';
import 'package:hello_captain_user/Pages/Auth/CountryDialog.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

import '../../Models/app_settings_model.dart';

class Register_UI extends ConsumerStatefulWidget {
  const Register_UI({super.key});

  @override
  ConsumerState<Register_UI> createState() => _Register_UIState();
}

class _Register_UIState extends ConsumerState<Register_UI> {
  bool showPassword = false;
  final fullname = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final dob = TextEditingController();
  final password = TextEditingController();
  final isLoading = ValueNotifier(false);
  String selectedCountry = "+977";
  String? base64Image;
  final formKey = GlobalKey<FormState>();

  Future<void> login() async {
    try {
      if (!formKey.currentState!.validate()) return;
      // if (base64Image == null) {
      //   KSnackbar(
      //     context,
      //     message: 'Please choose a profile image!',
      //     error: true,
      //   );
      //   return;
      // }

      String? fcm = "";
      try {
        fcm = await FirebaseMessaging.instance.getToken();
      } catch (err) {
        fcm = "";
      }
      isLoading.value = true;
      Map<String, dynamic> data = {
        "customer_fullname": fullname.text.trim(),
        "email": email.text.trim(),
        "phone_number": selectedCountry + phone.text.trim(),
        "phone": selectedCountry + phone.text.trim(),
        "password": password.text.trim(),
        "dob": dob.text,
        "countrycode": selectedCountry,
        "token": "$fcm",
        "customer_image": base64Image,
        "checked": "false",
      };
      final res = await AuthRepo.register(data);

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
    fullname.dispose();
    phone.dispose();
    email.dispose();
    dob.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KScaffold(
      isLoading: isLoading,
      appBar: AppBar(title: Label("Create Account").title, centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    base64Image = await ImagePickHelper.pickImage();
                    setState(() {});
                  },
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        base64Image != null
                            ? MemoryImage(base64Decode(base64Image!))
                            : null,
                    child:
                        base64Image == null
                            ? Center(child: Icon(Icons.person))
                            : SizedBox(),
                  ),
                ),
                kHeight(30),
                KField(
                  controller: fullname,
                  showRequired: false,
                  label: "Fullname",
                  hintText: "Enter full name",
                  autofillHints: [AutofillHints.name],
                  validator: (val) => KValidation.required(val),
                ),
                height15,
                KField(
                  controller: phone,
                  showRequired: false,
                  label: "Phone Number",
                  prefixText: selectedCountry,
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
                        Label(
                          selectedCountry,
                          fontSize: 15,
                          height: 1.5,
                        ).regular,
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
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (val) => KValidation.phone(val),
                ),
                height15,
                KField(
                  controller: email,
                  showRequired: false,
                  label: "Email",
                  textCapitalization: TextCapitalization.none,
                  hintText: "Enter email address",
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => KValidation.email(val),
                ),
                height15,
                KField(
                  controller: dob,
                  onTap: () async {
                    DateTime? res = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1800),
                      lastDate: DateTime.now(),
                    );

                    if (res != null) {
                      dob.text = kDateFormat(res.toString());
                    }
                  },
                  readOnly: true,
                  showRequired: false,
                  label: "D.O.B (Optional)",
                  hintText: "Choose DOB",
                ),
                height15,
                KField(
                  controller: password,
                  label: "Password",
                  hintText: "Password Here",
                  showRequired: false,
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
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          MediaQuery.of(context).viewInsets.bottom == 0
              ? SafeArea(
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
                        label: "Singup",
                        backgroundColor: Kolor.primary,
                        style: KButtonStyle.expanded,
                      ),
                    ],
                  ),
                ),
              )
              : SizedBox(),
    );
  }
}
