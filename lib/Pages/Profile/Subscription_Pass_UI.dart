// ignore_for_file: unused_result

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/subscription_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Subscription_Pass_UI extends ConsumerStatefulWidget {
  const Subscription_Pass_UI({super.key});

  @override
  ConsumerState<Subscription_Pass_UI> createState() =>
      _Subscription_Pass_UIState();
}

class _Subscription_Pass_UIState extends ConsumerState<Subscription_Pass_UI> {
  String selectedSub = "";
  double selectedAmount = 0;
  final isLoading = ValueNotifier(false);

  void purchaseSub() async {
    try {
      isLoading.value = true;
      final uid = ref.read(userProvider)?.id;
      if (uid == null) throw "User not logged in!";
      final res = await SubscriptionRepo.purchase(uid, selectedSub);
      await ref.refresh(activeSubscriptionFuture.future);
      KSnackbar(
        context,
        message: res['message'],
        error: res["status"] == "error",
      );
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSubscription = ref.watch(activeSubscriptionFuture);
    final subscriptionData = ref.watch(subscriptionListFuture);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(activeSubscriptionFuture.future),
      child: KScaffold(
        isLoading: isLoading,
        appBar: KAppBar(context, title: "Subscription Pass"),
        body: SafeArea(
          child: activeSubscription.when(
            data: (activeData) {
              // If there is an active subscription, show its card
              if (activeData.isNotEmpty) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(kPadding),
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Stack(
                    children: [
                      KCard(
                        padding: EdgeInsets.all(10),
                        borderWidth: 2,
                        color: StatusText.success.lighten(.1),
                        borderColor: StatusText.success,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: kRadius(15),
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        '${activeData["image"]}',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                KCard(
                                  margin: EdgeInsets.all(10),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  radius: 5,
                                  color: Colors.pink.shade700,
                                  child:
                                      Label(
                                        "Exp: ${kDateFormat(activeData["expiry_date"])}",
                                        weight: 900,
                                        fontSize: 11,
                                        color: Kolor.scaffold,
                                      ).regular,
                                ),
                              ],
                            ),
                            height10,

                            Row(
                              spacing: 15,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Label(
                                        activeData['name'],
                                        color: StatusText.success,
                                      ).title,
                                      Label(
                                        activeData['description'],
                                        weight: 600,
                                        fontSize: 12,
                                      ).subtitle,
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Label(
                                      kCurrencyFormat(activeData['price']),
                                      weight: 900,
                                      fontSize: 17,
                                    ).regular,
                                    height5,
                                    Label(
                                      "Purchased On",
                                      weight: 500,
                                      fontSize: 10,
                                    ).subtitle,
                                    Label(
                                      kDateFormat(activeData['purchase_date']),
                                      weight: 900,
                                      fontSize: 12,
                                    ).subtitle,
                                  ],
                                ),
                              ],
                            ),
                            height15,
                            Label(
                              "Benefits",
                              weight: 800,
                              fontSize: 12,
                              color: Kolor.primary,
                            ).regular,
                            Label(
                              "Get discount of ${activeData['discount_percent']}%, max upto ${kCurrencyFormat(activeData['max_discount'])}",
                              fontSize: 12,
                              weight: 500,
                            ).regular,
                            height15,
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children:
                                  "${activeData['included_services']}"
                                      .split(",")
                                      .map(
                                        (e) => KCard(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 5,
                                            horizontal: 10,
                                          ),
                                          color: StatusText.success.lighten(.8),
                                          radius: 5,
                                          child:
                                              Label(
                                                e,
                                                fontSize: 12,
                                                weight: 700,
                                                color: Colors.white,
                                              ).regular,
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                          color: StatusText.success,
                        ),

                        child: Label("Actve", color: Colors.white).regular,
                      ),
                    ],
                  ),
                );
              }
              // Else, show the subscription list
              return subscriptionData.when(
                data:
                    (data) => ListView.separated(
                      separatorBuilder: (context, index) => height15,
                      itemCount: data['data'].length,
                      padding: EdgeInsets.all(kPadding).copyWith(top: 0),
                      physics: AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final subscription = data['data'][index];
                        bool selected = selectedSub == subscription['id'];
                        return KCard(
                          onTap: () {
                            setState(() {
                              selectedSub = subscription['id'];
                              selectedAmount = parseToDouble(
                                subscription['price'],
                              );
                            });
                          },
                          padding: EdgeInsets.all(10),
                          borderWidth: 2,
                          color:
                              selected ? Kolor.primary.lighten(.1) : Kolor.card,
                          borderColor: selected ? Kolor.primary : Kolor.card,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      borderRadius: kRadius(15),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          '${subscription["image"]}',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  KCard(
                                    margin: EdgeInsets.all(10),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    color: Kolor.secondary,
                                    child:
                                        Label(
                                          "${subscription["duration"]} days",
                                          weight: 900,
                                          fontSize: 12,
                                          color: Kolor.scaffold,
                                        ).regular,
                                  ),
                                ],
                              ),
                              height10,
                              Row(
                                spacing: 15,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Label(
                                          subscription['name'],
                                          color:
                                              selected
                                                  ? Kolor.primary
                                                  : Colors.black,
                                        ).title,
                                        Label(
                                          subscription['description'],
                                          fontSize: 12,
                                          weight: 600,
                                        ).subtitle,
                                      ],
                                    ),
                                  ),
                                  Label(
                                    kCurrencyFormat(subscription['price']),
                                    weight: 900,
                                    fontSize: 20,
                                  ).regular,
                                ],
                              ),
                              height15,
                              Label(
                                "Benefits",
                                weight: 800,
                                fontSize: 12,
                                color: Kolor.primary,
                              ).regular,
                              Label(
                                "Get discount of ${subscription['discount_percent']}%, max upto ${kCurrencyFormat(subscription['max_discount'])}",
                                fontSize: 12,
                              ).regular,
                              height15,
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children:
                                    "${subscription['included_services']}"
                                        .split(",")
                                        .map(
                                          (e) => KCard(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 5,
                                              horizontal: 10,
                                            ),
                                            color:
                                                selected
                                                    ? Kolor.primary
                                                    : Kolor.scaffold,
                                            radius: 5,
                                            child:
                                                Label(
                                                  e,
                                                  fontSize: 12,
                                                  color:
                                                      selected
                                                          ? Colors.white
                                                          : Colors.black,
                                                ).regular,
                                          ),
                                        )
                                        .toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                error: (error, stackTrace) => kNoData(),
                loading: () => kSmallLoading,
              );
            },
            error: (error, stackTrace) => kNoData(),
            loading: () => kSmallLoading,
          ),
        ),
        bottomNavigationBar: Visibility(
          visible:
              (activeSubscription.value == null ||
                  activeSubscription.value!.isEmpty) &&
              selectedSub.isNotEmpty &&
              selectedAmount > 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(kPadding),
              child: KButton(
                onPressed: purchaseSub,
                style: KButtonStyle.expanded,
                label: "Pay ${kCurrencyFormat(selectedAmount)}",
              ),
            ),
          ),
        ),
      ),
    );
  }
}
