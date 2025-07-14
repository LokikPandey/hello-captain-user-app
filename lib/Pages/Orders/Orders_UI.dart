import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/orders_repo.dart';
import 'package:hello_captain_user/Resources/app-data.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Orders_UI extends ConsumerStatefulWidget {
  const Orders_UI({super.key});

  @override
  ConsumerState<Orders_UI> createState() => _Orders_UIState();
}

class _Orders_UIState extends ConsumerState<Orders_UI> {
  @override
  Widget build(BuildContext context) {
    final ordersData = ref.watch(ordersHistoryFuture);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(ordersHistoryFuture.future),
      child: KScaffold(
        appBar: KAppBar(context, title: "Rides", showBack: false),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(kPadding).copyWith(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ordersData.when(
                  data:
                      (data) =>
                          data['data'].isNotEmpty
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Label(
                                    "Recent Rides",
                                    color: Kolor.primary,
                                    weight: 800,
                                  ).regular,
                                  height15,
                                  ListView.separated(
                                    physics: NeverScrollableScrollPhysics(),

                                    itemBuilder: (context, index) {
                                      final order = data['data'][index];
                                      // log("$order");
                                      return KCard(
                                        onTap:
                                            () => context.push(
                                              "/order-detail/${order['transaction_id']}/${order['driver_id']}",
                                            ),
                                        width: double.infinity,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Label(
                                                  "#${order['transaction_id']}",
                                                  textAlign: TextAlign.end,
                                                ).subtitle,

                                                Label(
                                                  "${kStatus[order['status']]}",
                                                  color:
                                                      statusColorMap[kStatus[order['status']]],
                                                  weight: 800,
                                                ).regular,
                                              ],
                                            ),
                                            height15,
                                            Row(
                                              spacing: 10,
                                              children: [
                                                Expanded(
                                                  child:
                                                      Label(
                                                        "${order['pickup_address']}",
                                                        maxLines: 2,
                                                        fontSize: 12,
                                                      ).regular,
                                                ),
                                                Icon(
                                                  order['destination_address'] ==
                                                          ''
                                                      ? Icons.timelapse_sharp
                                                      : Icons.arrow_forward,
                                                  size: 15,
                                                ),
                                                Expanded(
                                                  child:
                                                      Label(
                                                        "${order['destination_address'] == '' ? secondsToHoursMinutes(order['estimate_time']) : order['destination_address']}",
                                                        textAlign:
                                                            TextAlign.end,
                                                        maxLines: 2,
                                                        fontSize: 12,
                                                      ).regular,
                                                ),
                                              ],
                                            ),
                                            height15,
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Label(
                                                  kDateFormat(order['date']),
                                                ).subtitle,
                                                Label(
                                                  order['service'],
                                                  color: Kolor.primary,
                                                ).subtitle,
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    separatorBuilder:
                                        (context, index) => height15,
                                    itemCount: (data['data'] as List).length,
                                    shrinkWrap: true,
                                  ),
                                ],
                              )
                              : kNoData(
                                title: "No Rides.",
                                subtitle:
                                    "Created, Pending or Finished Rides will appear here.",
                              ),
                  error: (error, stackTrace) => kNoData(),
                  loading: dummy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dummy() => Skeletonizer(
    child: Column(
      spacing: 15,
      children: List.generate(
        5,
        (index) =>
            Skeleton.leaf(child: KCard(height: 150, width: double.infinity)),
      ),
    ),
  );
}
