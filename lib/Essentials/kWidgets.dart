import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hello_captain_user/Resources/theme.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../Resources/app_config.dart';
import '../Resources/colors.dart';

Widget disclaimer({
  TextAlign textAlign = TextAlign.left,
  double fontSize = 15,
}) {
  return Text.rich(
    textAlign: textAlign,
    TextSpan(
      style: TextStyle(
        fontSize: fontSize,
        height: 1.5,
        fontFamily: kFont,
        color: Colors.grey.shade700,
        fontVariations: [FontVariation.weight(500)],
      ),
      children: [
        const TextSpan(text: "By proceeding you agree to our "),
        TextSpan(
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              await launchUrlString(termsConditionLink);
            },
          text: "Terms & Conditions",
          style: TextStyle(
            fontVariations: [FontVariation.weight(700)],
            color: StatusText.neutral,
          ),
        ),
        const TextSpan(text: " and "),
        TextSpan(
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              await launchUrlString(privacyPolicyLink);
            },
          text: "Privacy Policy",
          style: TextStyle(
            fontVariations: [FontVariation.weight(700)],
            color: StatusText.neutral,
          ),
        ),
      ],
    ),
  );
}
