import 'package:hive_flutter/hive_flutter.dart';

class HiveConfig {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox('hiveBox');
  }

  static Future<void> setData(dynamic key, dynamic value) async {
    final boxExists = await Hive.boxExists("hiveBox");
    if (boxExists) {
      if (!Hive.isBoxOpen("hiveBox")) {
        await Hive.openBox("hiveBox");
      }
      final hiveBox = Hive.box("hiveBox");
      await hiveBox.put(key, value);
      // log("$value added to hive");
    } else {
      // log("hiveBox does not exist. Creating and adding data.");
      final hiveBox = await Hive.openBox("hiveBox");
      await hiveBox.put(key, value);
      // log("$value added to hive");
    }
  }

  static Future<void> clearBox() async {
    if (await Hive.boxExists("hiveBox")) {
      if (!Hive.isBoxOpen("hiveBox")) {
        await Hive.openBox("hiveBox");
      }
      final hiveBox = Hive.box("hiveBox");
      await hiveBox.clear();
      // log("hiveBox cleared successfully.");
    } else {
      // log("hiveBox does not exist. Nothing to clear.");
    }
  }
}
