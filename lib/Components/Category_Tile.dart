import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import '../Resources/colors.dart';
import '../Resources/commons.dart';

class CategoryTile extends StatelessWidget {
  final int index;
  final String id;
  final String label;
  final String image;
  final String type;
  final Map<String, dynamic> data;
  const CategoryTile({
    super.key,
    required this.id,
    required this.label,
    required this.image,
    required this.index,
    required this.type,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        String path = "";
        switch (type) {
          case "Passenger Transportation":
            path = "/passenger-transportation";
            break;

          case "Rental":
            path = "/rental";
            break;

          case "Shipment":
            path = "/shipment";
            break;

          case "Purchasing Service":
            path = "/purchasing-service";
            break;
          default:
        }
        context.push(
          path,
          extra: {...data, "serviceName": label, "serviceImage": image},
        );
      },
      child: Stack(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            margin: EdgeInsets.all(8),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: kRadius(15),
              gradient: LinearGradient(
                colors: [
                  Colors.primaries[index % Colors.primaries.length].lighten(),
                  Colors.primaries[(index + 1) % Colors.primaries.length]
                      .lighten(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Label(label).regular,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CachedNetworkImage(imageUrl: image, height: 80),
          ),
        ],
      ),
    );
  }
}
