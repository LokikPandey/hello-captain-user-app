import 'package:flutter/material.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'colors.dart';

const String kFont = "Manrope";

ThemeData kTheme(BuildContext context) => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Kolor.scaffold,
  splashFactory: InkSplash.splashFactory,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Kolor.primary,
    brightness: Brightness.light,
  ),

  fontFamily: kFont,
  dialogTheme: DialogThemeData(
    insetPadding: EdgeInsets.all(kPadding),
    backgroundColor: Kolor.scaffold,
    shape: RoundedRectangleBorder(borderRadius: kRadius(20)),
  ),
  datePickerTheme: DatePickerThemeData(
    backgroundColor: Kolor.scaffold,
    dayStyle: defStyle,
    yearStyle: defStyle,
    weekdayStyle: defStyle,
    headerHelpStyle: TextStyle(fontVariations: [FontVariation.weight(800)]),
    headerHeadlineStyle: defStyle.copyWith(fontSize: 25),
    rangePickerHeaderHelpStyle: TextStyle(
      fontVariations: [FontVariation.weight(800)],
    ),
    rangePickerHeaderHeadlineStyle: TextStyle(
      fontVariations: [FontVariation.weight(800)],
    ),
  ),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(backgroundColor: Kolor.scaffold),
  ),
  textTheme: TextTheme(
    bodyLarge: defStyle,
    bodyMedium: defStyle,
    bodySmall: defStyle,
    headlineLarge: defStyle,
    headlineMedium: defStyle,
    headlineSmall: defStyle,
    titleLarge: defStyle,
    titleMedium: defStyle,
    titleSmall: defStyle,
    labelLarge: defStyle,
    labelMedium: defStyle,
    labelSmall: defStyle,
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Kolor.primary,
      textStyle: defStyle,
    ),
  ),
  appBarTheme: const AppBarTheme(
    actionsIconTheme: IconThemeData(color: Kolor.fadeText),
    surfaceTintColor: Kolor.primary,
    backgroundColor: Kolor.scaffold,
    elevation: 0,
  ),
  chipTheme: ChipThemeData(
    selectedColor: kColor(context).secondary,
    labelStyle: const TextStyle(color: Colors.black, fontFamily: kFont),
  ),
  badgeTheme: BadgeThemeData(
    backgroundColor: kColor(context).primary,
    largeSize: 20,
    textStyle: const TextStyle(
      fontSize: 15,
      fontVariations: [FontVariation.weight(600)],
      fontFamily: kFont,
    ),
  ),
  textSelectionTheme: TextSelectionThemeData(
    selectionHandleColor: Kolor.primary,
    cursorColor: kColor(context).primary,
    selectionColor: kColor(context).secondaryContainer,
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: Kolor.secondary,
    linearTrackColor: Kolor.card,
    circularTrackColor: Kolor.card,
    refreshBackgroundColor: Kolor.card,
  ),
);

TextStyle get defStyle =>
    TextStyle(fontFamily: kFont, fontVariations: [FontVariation.weight(600)]);
