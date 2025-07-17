import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile_UI extends ConsumerStatefulWidget {
  const Profile_UI({super.key});

  @override
  ConsumerState<Profile_UI> createState() => _Profile_UIState();
}

class _Profile_UIState extends ConsumerState<Profile_UI> {
  final isLoading = ValueNotifier(false);

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await AuthRepo.logout(context, ref);
    } catch (e) {
      KSnackbar(context, message: "$e", error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider)!;

    return KScaffold(
      isLoading: isLoading,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFAF0), // Light pastel orange / Floral White
                Color(0xFFFFF2DC), // Light peach
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(kPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  spacing: 15,
                  children: [
                    CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        user.customer_image,
                      ),
                      onBackgroundImageError: (_, __) {
                        // Optional: handle image loading error
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Label(user.customer_fullname).title,
                          Label(user.email).regular,
                        ],
                      ),
                    ),
                  ],
                ),
                height20,
                KCard(
                  color:
                      Kolor
                          .scaffold, // You might want to adjust this color if it clashes with the gradient
                  borderWidth: 1,
                  padding: EdgeInsets.all(10),
                  child: Column(
                    children: [
                      KCard(
                        radius: 10,
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined),
                            Label("Wallet").regular,
                            Spacer(),
                            Label(
                              kCurrencyFormat(
                                user.balance,
                                symbol: "NPR ",
                                decimalDigits: 2,
                              ),
                              weight: 900,
                            ).regular,
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                          horizontal: 5,
                        ).copyWith(bottom: 5),
                        child: Row(
                          children: [
                            Expanded(
                              child: IconButton(
                                onPressed:
                                    () => context.push("/profile/recharge"),
                                icon: Column(
                                  spacing: 10,
                                  children: [
                                    SvgPicture.asset(
                                      "$kIconPath/wallet.svg",
                                      height: 25,
                                    ),
                                    Label("Recharge", fontSize: 12).regular,
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: IconButton(
                                onPressed:
                                    () => context.push("/profile/withdraw"),
                                icon: Column(
                                  spacing: 10,
                                  children: [
                                    SvgPicture.asset(
                                      "$kIconPath/withdraw.svg",
                                      height: 25,
                                    ),
                                    Label("Withdraw", fontSize: 12).regular,
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: IconButton(
                                onPressed: () => context.push("/profile/promo"),
                                icon: Column(
                                  spacing: 10,
                                  children: [
                                    SvgPicture.asset(
                                      "$kIconPath/promo.svg",
                                      height: 25,
                                    ),
                                    Label("Promo", fontSize: 12).regular,
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: IconButton(
                                onPressed:
                                    () => context.push(
                                      "/profile/transaction-history",
                                    ),
                                icon: Column(
                                  spacing: 10,
                                  children: [
                                    SvgPicture.asset(
                                      "$kIconPath/history.svg",
                                      height: 25,
                                    ),
                                    Label("History", fontSize: 12).regular,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                height20,
                _tile(
                  onTap: () => context.push("/profile/subscription-pass"),
                  icon: Icons.airplane_ticket_outlined,
                  label: "Subscription Pass",
                ),
                div,
                _tile(
                  onTap: () => context.push("/profile/edit"),
                  icon: Icons.edit_note,
                  label: "Edit Profile",
                ),
                div,
                _tile(
                  onTap: () => context.push("/profile/change-password"),
                  icon: Icons.change_circle_outlined,
                  label: "Change Password",
                ),
                div,
                _tile(
                  onTap: () => context.push("/profile/emergency-contact"),
                  icon: Icons.emergency,
                  label: "Emergency Contact",
                ),
                height20,
                Label("System").regular,
                height20,
                _tile(
                  onTap: () => context.push("/profile/about-us"),
                  icon: Icons.document_scanner_outlined,
                  label: "About Us",
                ),
                div,
                _tile(
                  onTap: () => context.push("/profile/privacy"),
                  icon: Icons.privacy_tip_outlined,
                  label: "Privacy",
                ),
                div,
                _tile(
                  onTap: () async {
                    await SharePlus.instance.share(
                      ShareParams(
                        title: "Hello Captain",
                        subject: "Hello Captain App for Customers",
                        text: 'Check out the app on Play Store: $playStoreLink',
                      ),
                    );
                  },
                  icon: Icons.share,
                  label: "Share",
                ),
                div,
                _tile(
                  onTap: () async {
                    if (await canLaunchUrl(Uri.parse(playStoreLink))) {
                      await launchUrl(
                        Uri.parse(playStoreLink),
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: Icons.rate_review_outlined,
                  label: "Rate Us",
                ),
                div,
                InkWell(
                  onTap: logout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      spacing: 15,
                      children: [
                        Icon(Icons.logout, color: StatusText.danger, size: 25),
                        Label(
                          "Logout",
                          fontSize: 17,
                          color: StatusText.danger,
                        ).regular,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile({
    void Function()? onTap,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          spacing: 15,
          children: [Icon(icon, size: 25), Label(label, fontSize: 17).regular],
        ),
      ),
    );
  }
}
