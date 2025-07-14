import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/wallet_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';

class Recharge_UI extends ConsumerStatefulWidget {
  const Recharge_UI({super.key});

  @override
  ConsumerState<Recharge_UI> createState() => _Recharge_UIState();
}

class _Recharge_UIState extends ConsumerState<Recharge_UI> {
  final amount = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = ValueNotifier(false);

  late final Future<Khalti?> khalti;

  PaymentResult? paymentResult;

  @override
  void dispose() {
    amount.dispose();
    isLoading.dispose();
    super.dispose();
  }

  void fetchPidx() async {
    try {
      FocusScope.of(context).unfocus();
      isLoading.value = true;
      final userId = ref.read(userProvider)?.id;
      if (userId == null) throw "User is not logged in!";
      final res = await WalletRepo.generatePidx(int.parse(amount.text), userId);
      final String pidx = res['pidx'];

      context.push(
        "/profile/recharge/pay-khalti",
        extra: {"pidx": pidx} as Map<String, dynamic>,
      );
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider)!;
    final user = ref.watch(userProvider)!;
    return KScaffold(
      isLoading: isLoading,
      appBar: KAppBar(context, title: "Recharge Wallet"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child:
                      Label(kCurrencyFormat(user.balance), fontSize: 30).title,
                ),

                Center(child: Label("Wallet (NPR)").regular),
                height20,
                KField(
                  controller: amount,
                  prefixText: "NPR",
                  fontSize: 22,
                  hintText: "0",
                  label: "Enter Recharge Amount",
                  showRequired: false,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: (val) => KValidation.required(val),
                ),
                height20,
                Label("Payment Methods", weight: 700).regular,
                height10,
                KCard(
                  color: Kolor.scaffold,
                  borderWidth: 1,
                  child: Column(
                    spacing: 10,
                    children: [
                      _paymentTile(
                        onTap: fetchPidx,
                        image: "$kImagePath/payment/khalti-logo.png",
                        title: "Khalti",
                        subtitle: "Recharge with Khalti",
                        isActive: appSettings.khaliti_active == "1",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentTile({
    void Function()? onTap,
    required String title,
    required String subtitle,
    required String image,
    bool isActive = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        spacing: 15,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Kolor.scaffold,
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(image),
                fit: BoxFit.contain,
                colorFilter:
                    isActive
                        ? null
                        : ColorFilter.mode(
                          Kolor.fadeText,
                          BlendMode.saturation,
                        ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Label(
                  title,
                  fontSize: 17,
                  color: !isActive ? Kolor.fadeText : null,
                ).title,
                Label(
                  subtitle,
                  fontSize: 12,
                  maxLines: 2,
                  color: !isActive ? Kolor.fadeText : null,
                ).regular,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
