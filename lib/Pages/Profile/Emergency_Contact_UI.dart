// ignore_for_file: unused_result
import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kButton.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Helper/contact_pick_helper.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Repository/contact_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Emergency_Contact_UI extends ConsumerStatefulWidget {
  const Emergency_Contact_UI({super.key});

  @override
  ConsumerState<Emergency_Contact_UI> createState() =>
      _Emergency_Contact_UIState();
}

class _Emergency_Contact_UIState extends ConsumerState<Emergency_Contact_UI> {
  final isLoading = ValueNotifier(false);
  String selectedRelationship = "Father";

  Future<void> deleteContact(String contactId) async {
    try {
      Navigator.pop(context);
      isLoading.value = true;
      await ContactRepo.deleteContact(contactId);

      KSnackbar(context, message: "Contact Deleted Successfully!");
      ref.refresh(contactsFuture.future);
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addContact({required String name, required String phone}) async {
    try {
      Navigator.pop(context);
      final user = ref.read(userProvider);
      if (user == null) throw "User not logged in!";

      isLoading.value = true;

      await ContactRepo.addContact({
        "user_id": user.id,
        "name": name,
        "phone_number": phone,
        "relationship": selectedRelationship,
      });
      KSnackbar(context, message: "Emergency Contact Added Successfully!");
      ref.refresh(contactsFuture.future);
    } catch (e) {
      // log("$e");
      KSnackbar(context, message: e, error: true);
    } finally {
      isLoading.value = false;
      setState(() {
        selectedRelationship = "Father";
      });
    }
  }

  Future<void> pickContact() async {
    try {
      Contact? contact = await ContactHelper.pickContact();

      if (contact == null) {
        KSnackbar(context, message: "No Contacts Selected", error: true);
        return;
      } else if (contact.fullName == null ||
          contact.phoneNumbers == null ||
          contact.phoneNumbers!.isEmpty) {
        throw "Contact invalid! Please select a contact with both name and phone number.";
      }

      showDialog(
        context: context,
        builder:
            (context) => StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Label("Add Contact?").title,
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Label(
                        "Do you want to add ${contact.fullName} | ${contact.phoneNumbers![0]} as emergency contact?",
                      ).regular,
                      height20,
                      Label("Relationship", color: Kolor.primary).regular,
                      height5,
                      KCard(
                        borderWidth: 1,
                        padding: EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 15,
                        ),
                        color: Kolor.scaffold,
                        child: DropdownButton<String>(
                          value: selectedRelationship,
                          items:
                              [
                                    "Father",
                                    "Mother",
                                    "Brother",
                                    "Sister",
                                    "Friend",
                                  ]
                                  .map(
                                    (e) => DropdownMenuItem<String>(
                                      value: e,
                                      child: Label(e).regular,
                                    ),
                                  )
                                  .toList(),
                          isExpanded: true,
                          underline: SizedBox(),

                          onChanged: (value) {
                            setState(() {
                              selectedRelationship = value ?? "Father";
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    KButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      label: "No",
                      backgroundColor: Kolor.scaffold,
                      foregroundColor: Colors.black,
                    ),
                    KButton(
                      onPressed:
                          () => addContact(
                            name: contact.fullName ?? "No Name",
                            phone: contact.phoneNumbers![0],
                          ),
                      label: "Yes",
                      radius: 100,
                      backgroundColor: Kolor.primary,
                    ),
                  ],
                );
              },
            ),
      );
    } catch (e) {
      KSnackbar(context, message: e, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsData = ref.watch(contactsFuture);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(contactsFuture.future),
      child: KScaffold(
        isLoading: isLoading,
        appBar: KAppBar(context, title: "Emergency Contacts"),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(kPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                contactsData.when(
                  skipLoadingOnRefresh: false,
                  data: (data) {
                    if (data['data'] != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SvgPicture.asset(
                              "$kImagePath/emergency.svg",
                              height: 200,
                            ),
                          ),
                          height20,
                          Label(
                            "Added Contacts (${data['data'].length})",
                          ).regular,
                          height15,
                          ListView.separated(
                            physics: NeverScrollableScrollPhysics(),
                            separatorBuilder: (context, index) => div,
                            itemCount: data['data'].length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final contact = data['data'][index];
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 5,
                                ),
                                child: Row(
                                  spacing: 15,
                                  children: [
                                    CircleAvatar(
                                      child:
                                          Label(
                                            "${contact['name'][0]}"
                                                .toUpperCase(),
                                          ).regular,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 5,
                                            children: [
                                              Label(contact['name']).regular,
                                              KCard(
                                                color: Kolor.secondary,
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 5,
                                                  vertical: 1,
                                                ),
                                                child:
                                                    Label(
                                                      contact['relationship'],
                                                      fontSize: 10,
                                                      color: Colors.white,
                                                    ).regular,
                                              ),
                                            ],
                                          ),
                                          Label(
                                            contact['phone_number'],
                                          ).subtitle,
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title:
                                                    Label(
                                                      "Delete Contact?",
                                                    ).title,
                                                content:
                                                    Label(
                                                      "Do you want to remove ${contact['name']} from emergency contacts?",
                                                    ).regular,
                                                actions: [
                                                  KButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                    },
                                                    label: "No",
                                                    backgroundColor:
                                                        Kolor.scaffold,
                                                    foregroundColor:
                                                        Colors.black,
                                                  ),
                                                  KButton(
                                                    onPressed:
                                                        () => deleteContact(
                                                          contact['id'],
                                                        ),
                                                    label: "Yes",
                                                    radius: 100,
                                                    backgroundColor:
                                                        Kolor.primary,
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                      visualDensity: VisualDensity.compact,
                                      icon: Icon(
                                        Icons.delete_outline_outlined,
                                        color: StatusText.danger,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return kNoData(
                      title: "No Contacts Added.",
                      subtitle: "Add people to emergency contact.",
                    );
                  },

                  error: (error, stackTrace) => kNoData(),
                  loading:
                      () => Skeletonizer(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder:
                              (context, index) => Padding(
                                padding: const EdgeInsets.all(5),
                                child: Row(
                                  spacing: 15,
                                  children: [
                                    CircleAvatar(),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Label("John Doe").regular,
                                          Label("+911234567890").regular,
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          separatorBuilder: (context, index) => div,
                          itemCount: 3,
                        ),
                      ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: pickContact,
          elevation: 0,
          label: Label("Add Contact").regular,
          icon: Icon(Icons.add),
        ),
      ),
    );
  }
}
