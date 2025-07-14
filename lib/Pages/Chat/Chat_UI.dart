import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kCard.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';

class Chat_UI extends ConsumerStatefulWidget {
  const Chat_UI({super.key});

  @override
  ConsumerState<Chat_UI> createState() => _Chat_UIState();
}

class _Chat_UIState extends ConsumerState<Chat_UI> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    return KScaffold(
      appBar: KAppBar(context, title: "Chats", showBack: false),
      body: SafeArea(
        child: StreamBuilder<DatabaseEvent>(
          stream: FirebaseDatabase.instance.ref('Inbox/${user!.id}').onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
              return Center(child: Label("No chats found").regular);
            }

            // Convert the snapshot to a Map
            final data = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );

            final entries = data.entries.toList();

            return ListView.separated(
              separatorBuilder: (context, index) => height10,
              itemCount: entries.length,
              padding: EdgeInsets.all(kPadding),
              itemBuilder: (context, index) {
                final chat = entries[index].value as Map;
                return KCard(
                  onTap:
                      () => context.push(
                        "/chat/detail/${chat['rid']}",
                        extra: {"pic": chat['pic'], "name": chat['name']},
                      ),
                  child: Row(
                    spacing: 15,
                    children: [
                      CircleAvatar(backgroundImage: NetworkImage(chat['pic'])),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Label(chat['name'] ?? "User", weight: 700).regular,
                            if (chat['msg'].isNotEmpty)
                              Label(chat['msg'], fontSize: 12).subtitle,
                          ],
                        ),
                      ),
                      Label(kDateFormat(chat['date'])).subtitle,
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
