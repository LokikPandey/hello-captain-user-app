import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/wallet_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Transaction_History_UI extends ConsumerStatefulWidget {
  const Transaction_History_UI({super.key});

  @override
  ConsumerState<Transaction_History_UI> createState() =>
      _Transaction_History_UIState();
}

class _Transaction_History_UIState
    extends ConsumerState<Transaction_History_UI> {
  final status = {"0": "Pending", "1": "Success", "2": "Failed"};

  @override
  Widget build(BuildContext context) {
    final historyData = ref.watch(walletFuture);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(walletFuture.future),
      child: KScaffold(
        appBar: KAppBar(context, title: "Transaction History"),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(kPadding),
            child: historyData.when(
              data:
                  (data) =>
                      data['data'].isNotEmpty
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Label('Recent Transactions', weight: 700).regular,
                              height15,
                              ListView.separated(
                                physics: NeverScrollableScrollPhysics(),
                                separatorBuilder: (context, index) => height15,
                                shrinkWrap: true,
                                itemCount: data["data"].length,
                                itemBuilder: (context, index) {
                                  final txn = data['data'][index];
                                  return KCard(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      spacing: 10,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Label(
                                                "${txn['type']}",
                                                weight: 700,
                                                fontSize: 17,
                                              ).regular,
                                              Label("${txn['bank']}").regular,
                                              height5,
                                              Label(
                                                kDateFormat(txn['date']),
                                              ).subtitle,
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Label(
                                              kCurrencyFormat(
                                                txn['wallet_amount'],
                                              ),
                                              weight: 900,
                                            ).regular,
                                            Label(
                                              status[txn['status']] ??
                                                  "Unknown",
                                            ).regular,
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                          : kNoData(
                            title: "No Transactions!",
                            subtitle:
                                "All the transactions made on this platform will appear here.",
                          ),
              error: (error, stackTrace) => kNoData(subtitle: "$error"),
              loading: () => kSmallLoading,
            ),
          ),
        ),
      ),
    );
  }
}
