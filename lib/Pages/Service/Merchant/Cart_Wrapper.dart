import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/cart_repo.dart';
import 'package:hello_captain_user/Repository/purchasing_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:simple_shadow/simple_shadow.dart';

class CartWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String serviceId;
  final String serviceName;
  const CartWrapper({
    super.key,
    required this.child,
    required this.serviceId,
    this.serviceName = "",
  });

  @override
  ConsumerState<CartWrapper> createState() => _CartWrapperState();
}

class _CartWrapperState extends ConsumerState<CartWrapper> {
  ValueNotifier isLoading = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final cartData = ref.watch(cartProvider);
    final currentMerchant = ref.watch(currentMerchantProvider);

    double finalAmount = 0;

    for (var item in cartData) {
      double item_cost =
          item.promo_price <= 0 ? item.item_price : item.promo_price;
      finalAmount += item.quantity * item_cost;
    }

    return KScaffold(
      isLoading: isLoading,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          widget.child,
          if (cartData.isNotEmpty)
            SafeArea(
              child: SimpleShadow(
                sigma: 15,
                child: KCard(
                  onTap: () {
                    if (currentMerchant != null) {
                      context.push(
                        "/merchant/detail/checkout",
                        extra: Map.from({
                          "serviceId": widget.serviceId,
                          "serviceName": widget.serviceName,
                        }),
                      );
                    }
                  },

                  width: double.infinity,
                  color: Kolor.secondary,
                  radius: 100,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ).copyWith(right: 10),
                  margin: EdgeInsets.all(kPadding),
                  child: Row(
                    spacing: 15,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label(
                              "Cart total",
                              weight: 600,
                              color: Colors.white,
                              fontSize: 10,
                            ).regular,
                            Label(
                              kCurrencyFormat(finalAmount / 100),
                              weight: 800,
                              color: Colors.white,
                            ).regular,
                          ],
                        ),
                      ),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Label("${cartData.length}", weight: 900).regular,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
