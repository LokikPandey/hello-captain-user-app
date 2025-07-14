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
        }

        context.push(
          path,
          extra: {...data, "serviceName": label, "serviceImage": image},
        );
      },
      child: SizedBox(
        width: 110,
        height: 150, // Enough height to prevent overflow
        child: Column(
          children: [
            Container(
              height: 100,
              width: 100,
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 253, 253, 253), // Very light pastel orange
                    Color.fromARGB(255, 251, 250, 248), // Soft light orange
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CachedNetworkImage(imageUrl: image, fit: BoxFit.contain),
            ),

            const SizedBox(height: 5),
            Label(label, weight: 700, color: Kolor.primary).regular,
          ],
        ),
      ),
    );
  }
}
