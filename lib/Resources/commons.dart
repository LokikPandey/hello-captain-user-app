import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Essentials/Label.dart';
import 'colors.dart';
import 'constants.dart';

const SizedBox width5 = SizedBox(width: 5);
const SizedBox width10 = SizedBox(width: 10);
const SizedBox width15 = SizedBox(width: 15);
const SizedBox width20 = SizedBox(width: 20);
const SizedBox height5 = SizedBox(height: 5);
const SizedBox height10 = SizedBox(height: 10);
const SizedBox height15 = SizedBox(height: 15);
const SizedBox height20 = SizedBox(height: 20);
SizedBox kHeight(double height) => SizedBox(height: height);
SizedBox kWidth(double width) => SizedBox(width: width);

Widget get div => const Divider(color: Kolor.border, thickness: .5);

void systemColors() {
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
}

BorderRadius kRadius(double radius) => BorderRadius.circular(radius);

Future<T?> navPush<T extends Object?>(BuildContext context, Widget screen) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

Future<T?> navPushReplacement<T extends Object?, TO extends Object?>(
  BuildContext context,
  Widget screen,
) {
  return Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => screen),
  );
}

Future<T?> navPopUntilPush<T extends Object?>(
  BuildContext context,
  Widget screen,
) {
  Navigator.popUntil(context, (route) => false);
  return navPush(context, screen);
}

void KSnackbar(
  BuildContext context, {
  dynamic message,
  bool error = false,
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      elevation: 0,
      backgroundColor: Colors.grey.shade900,
      padding: EdgeInsets.zero,
      content: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: error ? StatusText.danger : Colors.lightGreen,
              width: 5,
            ),
          ),
        ),
        child: Row(
          spacing: 10,
          children: [
            Icon(
              error ? Icons.dangerous : Icons.check_circle,
              color: error ? StatusText.danger : Colors.lightGreen,
            ),
            Expanded(
              child: Column(
                spacing: 1,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Label(
                    error ? "Oops!" : "Yay! Success",
                    weight: 900,
                    color: error ? StatusText.danger : Colors.lightGreen,
                  ).regular,
                  Label("$message", fontSize: 12, color: Colors.white).regular,
                ],
              ),
            ),
          ],
        ),
      ),
      action: action,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}

void KErrorAlert(BuildContext context, {required dynamic message}) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          backgroundColor: Kolor.card,
          title: Label("An Error Occurred!", color: StatusText.danger).title,
          icon: const Icon(Icons.dangerous, color: StatusText.danger, size: 50),
          content: Label("$message", textAlign: TextAlign.center).regular,
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Label("Back to cart").regular,
            ),
          ],
        ),
  );
}

Widget googleLoginButton({required void Function()? onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: Kolor.scaffold,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: kRadius(15),
        side: BorderSide(color: Kolor.border),
      ),
      padding: EdgeInsets.all(15),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        SvgPicture.asset("$kIconPath/glogo.svg", height: 25),
        Label("Google", fontSize: 17, weight: 600).regular,
      ],
    ),
  );
}

Widget get kSmallLoading => Center(
  child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator()),
);

Widget kNoData({
  String title = "Oops!",
  String subtitle = "Something Went Wrong.",
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset("$kImagePath/no-data.svg", height: 150),
        Label(
          title,
          textAlign: TextAlign.center,
          weight: 700,
          fontSize: 17,
        ).regular,
        Label(subtitle, textAlign: TextAlign.center).subtitle,
      ],
    ),
  );
}
