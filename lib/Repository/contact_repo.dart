import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Helper/api_config.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';

final contactsFuture = FutureProvider.autoDispose((ref) async {
  final user = ref.read(userProvider);
  if (user == null) throw "User not logged in!";

  final res = await ContactRepo.fetchContacts(user.id);
  return res;
});

class ContactRepo {
  static Future<Map<String, dynamic>> addContact(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await apiCallBack(
        path: "/add_emergency_contact",
        body: body,
        method: "POST",
      );
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchContacts(String userId) async {
    try {
      final res = await apiCallBack(
        path: "/getemergencycontact",
        body: {"user_id": userId},
      );
      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> deleteContact(String contactId) async {
    try {
      final res = await apiCallBack(
        path: "/delete_emergency_contact",
        body: {"contact_id": contactId},
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> sos({
    required String userId,
    required String lat,
    required String lng,
  }) async {
    try {
      final res = await apiCallBack(
        path: "/send_emergency_message",
        body: {"user_id": userId, "latitude": lat, "longitude": lng},
      );

      return res;
    } catch (e) {
      rethrow;
    }
  }
}
