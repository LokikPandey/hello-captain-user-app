import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';

class ContactHelper {
  static Future<Contact?> pickContact() async {
    try {
      final FlutterNativeContactPicker contactPicker =
          FlutterNativeContactPicker();

      return await contactPicker.selectContact();
    } catch (e) {
      rethrow;
    }
  }
}
