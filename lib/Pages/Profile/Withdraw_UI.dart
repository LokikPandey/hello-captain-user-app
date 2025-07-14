import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Essentials/kWidgets.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/wallet_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Withdraw_UI extends ConsumerStatefulWidget {
  const Withdraw_UI({super.key});

  @override
  ConsumerState<Withdraw_UI> createState() => _Withdraw_UIState();
}

class _Withdraw_UIState extends ConsumerState<Withdraw_UI> {
  final isLoading = ValueNotifier(false);
  final _formKey = GlobalKey<FormState>();
  final amount = TextEditingController();
  final bankName = TextEditingController();
  final accountNumber = TextEditingController();
  final holderName = TextEditingController();

  Future<void> withdraw() async {
    try {
      final user = ref.read(userProvider);

      if (user == null) throw "User not logged in!";

      if (!_formKey.currentState!.validate()) return;

      isLoading.value = true;
      final res = await WalletRepo.withdraw({
        "id": user.id,
        "bank": bankName.text,
        "nama": holderName.text,
        "amount": parseToDouble(amount.text) * 100,
        "card": accountNumber.text,
        "email": user.email,
        "phone_number": user.phone_number,
        "type": "withdraw",
      });

      KSnackbar(context, message: res["message"]);
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void dispose() {
    amount.dispose();
    bankName.dispose();
    accountNumber.dispose();
    holderName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider)!;
    final bankListData = ref.watch(bankListFuture);
    return KScaffold(
      isLoading: isLoading,
      appBar: KAppBar(context, title: "Withdraw"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(kPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        Label(
                          kCurrencyFormat(user.balance),
                          fontSize: 25,
                        ).title,
                        Label(
                          "Balance (NPR)",
                          color: Kolor.primary,
                          weight: 700,
                          fontSize: 16,
                        ).regular,
                      ],
                    ),
                  ),
                ),

                height20,
                Label("Enter bank details", weight: 700).title,
                height20,
                KField(
                  controller: amount,
                  prefixText: "NPR",
                  hintText: "Amount",
                  label: "Amount",
                  keyboardType: TextInputType.number,
                  validator: (val) => KValidation.required(val),
                ),
                height15,
                bankListData.when(
                  data:
                      (data) => Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          return data
                              .map((option) => option['bank_name'] as String)
                              .where((bankName) {
                                return bankName.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase(),
                                );
                              });
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 1,
                              borderRadius: BorderRadius.circular(8),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                shrinkWrap: true,
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Label(option, fontSize: 15).regular,
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        fieldViewBuilder:
                            (
                              context,
                              textEditingController,
                              focusNode,
                              onFieldSubmitted,
                            ) => KField(
                              label: "Bank Name",
                              hintText: "Select Bank Name",
                              suffix: Icon(Icons.keyboard_arrow_down_outlined),
                              controller: textEditingController,
                              focusNode: focusNode,
                              validator: (val) => KValidation.required(val),
                              onFieldSubmitted: (val) => onFieldSubmitted,
                            ),
                        onSelected: (String selection) {
                          setState(() {
                            bankName.text = selection;
                          });
                        },
                      ),
                  error: (error, stackTrace) => Label("$error").regular,
                  loading: () => LinearProgressIndicator(),
                ),

                height15,
                KField(
                  controller: accountNumber,
                  hintText: "Account Number",
                  label: "A/C Number",
                  keyboardType: TextInputType.number,
                  validator: (val) => KValidation.required(val),
                ),
                height15,
                KField(
                  controller: holderName,
                  hintText: "Account Holder Name",
                  label: "Account Holder Name",
                  validator: (val) => KValidation.required(val),
                ),
                height20,
                disclaimer(),
                height20,
                KButton(
                  onPressed: withdraw,
                  label: "Submit",
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
