import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Helper/image_pick_helper.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Essentials/Label.dart';
import '../Auth/CountryDialog.dart';

class Edit_Profile_UI extends ConsumerStatefulWidget {
  const Edit_Profile_UI({super.key});

  @override
  ConsumerState<Edit_Profile_UI> createState() => _Edit_Profile_UIState();
}

class _Edit_Profile_UIState extends ConsumerState<Edit_Profile_UI> {
  final formKey = GlobalKey<FormState>();
  final isLoading = ValueNotifier(false);
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final dob = TextEditingController();
  String selectedCountry = "+977";
  String? base64Image;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) => setUserdata());
  }

  void setUserdata() {
    final user = ref.read(userProvider);
    if (user == null) return;

    setState(() {
      name.text = user.customer_fullname;
      phone.text = user.phone_number.substring(user.phone_number.length - 10);
      selectedCountry = user.phone_number.substring(
        0,
        user.phone_number.length - 10,
      );

      email.text = user.email;
      dob.text = user.dob;
    });
  }

  Future<void> editProfile() async {
    try {
      FocusScope.of(context).unfocus();
      isLoading.value = true;
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      if (!formKey.currentState!.validate()) return;
      Map<String, dynamic> data = {
        "id": user.id,
        "phone_number": selectedCountry + phone.text,
        "phone": selectedCountry + phone.text,
        "email": email.text,
        "no_telepon_lama": user.phone_number,
        "customer_fullname": name.text,
        "countrycode": selectedCountry,
        "dob": dob.text,
        "customer_image": base64Image,
        "fotopelanggan_lama": base64Image == null ? null : user.customer_image,
      };

      final res = await AuthRepo.editProfile(data);

      if (res["code"] != "200") throw res["message"];
      KSnackbar(context, message: "Profile updated.");
      await AuthRepo.logout(context, ref);
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    dob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider)!;
    return KScaffold(
      isLoading: isLoading,
      appBar: KAppBar(context, title: "Edit Profile"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              base64Image == null
                                  ? CachedNetworkImageProvider(
                                    user.customer_image,
                                  )
                                  : MemoryImage(base64Decode(base64Image!))
                                      as ImageProvider,
                          onBackgroundImageError: (_, __) {
                            // Optional: handle image loading error
                          },
                        ),
                      ),

                      IconButton.filledTonal(
                        onPressed: () async {
                          base64Image = await ImagePickHelper.pickImage();
                          setState(() {});
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Kolor.secondary,
                          foregroundColor: Kolor.scaffold,
                        ),
                        icon: Icon(Icons.camera_alt),
                      ),
                    ],
                  ),
                ),
                height20,
                KField(
                  controller: name,
                  label: "Name",
                  hintText: "Enter Name",
                  validator: (val) => KValidation.required(val),
                ),
                height15,
                KField(
                  controller: phone,
                  label: "Phone",
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

                  maxLength: 10,
                  autofillHints: [AutofillHints.telephoneNumber],
                  keyboardType: TextInputType.phone,
                  hintText: "Enter Phone",
                  validator: (val) => KValidation.required(val),
                ),
                height15,
                KField(
                  controller: email,
                  label: "Email",
                  hintText: "Enter Email",
                  autofillHints: [AutofillHints.email],
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
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
                  label: "D.O.B.",
                  hintText: "Choose DOB",
                ),
                kHeight(50),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade900),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            Label(
                              "Note: Account deletion request can be submitted by filling the form. Hello Captain support team will connect shortly to confirm and initiate deletion.",
                              weight: 300,
                              color: Colors.red,
                            ).regular,
                      ),
                      width10,
                      KButton(
                        onPressed: () async {
                          await launchUrl(
                            Uri.parse(
                              "https://docs.google.com/forms/d/e/1FAIpQLScc3mZYKAFxGBZha_STj0Kq9yrIyE5OMptpU8zilrWgS2ixMA/viewform?usp=header",
                            ),
                          );
                        },
                        label: "Delete account",
                        backgroundColor: Colors.red.shade400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(kPadding),
          child: KButton(onPressed: editProfile, label: "Update"),
        ),
      ),
    );
  }
}
