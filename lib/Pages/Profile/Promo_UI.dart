import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/wallet_repo.dart';
import 'package:hello_captain_user/Resources/app_config.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Promo_UI extends ConsumerWidget {
  const Promo_UI({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoData = ref.watch(promoFuture);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(promoFuture.future),
      child: KScaffold(
        appBar: KAppBar(context, title: "Promo"),
        body: SafeArea(
          child: promoData.when(
            data:
                (data) => ListView.separated(
                  separatorBuilder: (context, index) => height15,
                  itemCount: data['data'].length,
                  padding: EdgeInsets.all(kPadding).copyWith(top: 0),
                  physics: AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final promo = data['data'][index];
                    // log("$promo");
                    return KCard(
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
                                      '$promoImageBaseUrl/${promo["promo_image"]}',
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
                                color: Kolor.scaffold,
                                child:
                                    Label(
                                      kDateFormat(promo["expired"]),
                                      weight: 900,
                                      fontSize: 12,
                                    ).regular,
                              ),
                            ],
                          ),
                          height10,
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Label(promo['promo_title']).regular,
                                    Label(promo['promo_code']).title,
                                  ],
                                ),
                              ),
                              KButton(
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: promo["promo_code"]),
                                  );

                                  KSnackbar(
                                    context,
                                    message:
                                        "${promo["promo_code"]} copied to clipboard!",
                                  );
                                },
                                label: "Copy",
                                radius: 100,
                                fontSize: 12,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                backgroundColor: Kolor.secondary,
                              ),
                            ],
                          ),
                          height10,
                          Label("Applicable for", fontSize: 10).subtitle,
                          height5,
                          KCard(
                            color: Kolor.scaffold,
                            radius: 6,
                            borderWidth: 1,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child:
                                Label(
                                  "${promo['service']}",
                                  weight: 600,
                                  fontSize: 10,
                                ).regular,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            error: (error, stackTrace) => kNoData(),
            loading: () => kSmallLoading,
          ),
        ),
      ),
    );
  }
}
