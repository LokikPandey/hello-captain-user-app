// ignore_for_file: no_logic_in_create_state

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_captain_user/Essentials/KScaffold.dart';
import 'package:hello_captain_user/Essentials/Label.dart';
import 'package:hello_captain_user/Essentials/kField.dart';
import 'package:hello_captain_user/Pages/Image%20Preview/imagePreviewUI.dart';
import 'package:hello_captain_user/Repository/auth_repo.dart';
import 'package:hello_captain_user/Resources/colors.dart';
import 'package:hello_captain_user/Resources/commons.dart';
import 'package:hello_captain_user/Resources/constants.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Chat_Detail_UI extends ConsumerStatefulWidget {
  final String receiverId;
  final String pic;
  final String name;
  const Chat_Detail_UI({
    super.key,
    required this.receiverId,
    required this.pic,
    required this.name,
  });

  @override
  ConsumerState<Chat_Detail_UI> createState() =>
      _Chat_Detail_UIState(receiverId);
}

class _Chat_Detail_UIState extends ConsumerState<Chat_Detail_UI> {
  final String receiverId;
  _Chat_Detail_UIState(this.receiverId);
  final isUploading = ValueNotifier(false);

  final TextEditingController _messageController = TextEditingController();
  late final StreamSubscription<DatabaseEvent> _messagesSubscription;

  final ValueNotifier<List> messagesNotifier = ValueNotifier([]);

  void _setupMessageListener() {
    DatabaseReference chatRef = FirebaseDatabase.instance.ref().child("chat");
    final senderId = ref.read(userProvider)!.id;

    if (senderId.compareTo(receiverId) > 0) {
      chatRef = chatRef.child("$senderId-$receiverId");
    } else {
      chatRef = chatRef.child("$receiverId-$senderId");
    }

    _messagesSubscription = chatRef.onValue.listen((DatabaseEvent event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        final messages =
            data.entries.map((e) {
              final messageMap = Map<String, dynamic>.from(e.value);
              return messageMap;
            }).toList();

        // Sort messages by timestamp, from oldest to newest.
        messages.sort((a, b) => a["timestamp"].compareTo(b["timestamp"]));
        messagesNotifier.value = messages;
      } else {
        log("No messages found or invalid data format.");
      }
    }, onError: (e) => log("Error reading messages: $e"));
  }

  Future<void> sendMessage(
    String message,
    String senderId,
    String tokenDriver,
    String tokenUser,
    String receiverName,
    String receiverPic,
  ) async {
    final user = ref.read(userProvider);
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final currentRef = "chat/$senderId-$receiverId";
    final chatRef = "chat/$receiverId-$senderId";

    final DatabaseReference reference = FirebaseDatabase.instance.ref();
    final DatabaseReference messageRef = reference.child(currentRef).push();
    final String pushId = messageRef.key!;

    final Map<String, dynamic> messageUserMap = {
      "receiver_id": receiverId,
      "sender_id": senderId,
      "tokendriver": tokenDriver,
      "tokenuser": tokenUser,
      "chat_id": pushId,
      "text": message,
      "type": "text",
      "pic_url": "",
      "status": "0",
      "time": "",
      "sender_name": user!.customer_fullname,
      "timestamp": formattedDate,
    };

    final Map<String, dynamic> userMap = {
      "$currentRef/$pushId": messageUserMap,
      "$chatRef/$pushId": messageUserMap,
    };

    try {
      await reference.update(userMap);

      final inboxSenderRef = "Inbox/$senderId/$receiverId";
      final inboxReceiverRef = "Inbox/$receiverId/$senderId";

      final Map<String, dynamic> senderMap = {
        "rid": senderId,
        "name": user.customer_fullname,
        "pic": user.customer_image,
        "tokendriver": tokenUser,
        "tokenuser": tokenDriver,
        "msg": message,
        "status": "0",
        "timestamp": -now.millisecondsSinceEpoch,
        "date": formattedDate,
      };

      final Map<String, dynamic> receiverMap = {
        "rid": receiverId,
        "name": receiverName,
        "pic": receiverPic,
        "tokendriver": tokenDriver,
        "tokenuser": tokenUser,
        "msg": message,
        "status": "1",
        "timestamp": -now.millisecondsSinceEpoch,
        "date": formattedDate,
      };

      final Map<String, dynamic> bothUserMap = {
        inboxSenderRef: receiverMap,
        inboxReceiverRef: senderMap,
      };

      await reference.update(bothUserMap);
    } catch (e) {
      KSnackbar(context, message: "$e", error: true);
    }
  }

  Future<void> pickAndSendImage(
    String senderId,
    String tokenDriver,
    String tokenUser,
    String receiverName,
    String receiverPic,
  ) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 40,
      );

      if (pickedFile != null) {
        final file = pickedFile;
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storageRef = FirebaseStorage.instance
            .ref("/images")
            .child('$fileName.jpg');

        isUploading.value = true;
        final uploadTask = storageRef.putData(await file.readAsBytes());
        final snapshot = await uploadTask.whenComplete(() {
          isUploading.value = false;
        });
        final downloadUrl = await snapshot.ref.getDownloadURL();

        // Send image message
        await sendImageMessage(
          downloadUrl,
          senderId,
          tokenDriver,
          tokenUser,
          receiverName,
          receiverPic,
        );
      }
    } catch (e) {
      KSnackbar(context, message: "Error while uploading image!", error: true);
    }
  }

  Future<void> sendImageMessage(
    String imageUrl,
    String senderId,
    String tokenDriver,
    String tokenUser,
    String receiverName,
    String receiverPic,
  ) async {
    try {
      final user = ref.read(userProvider);
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      final currentRef = "chat/$senderId-$receiverId";
      final chatRef = "chat/$receiverId-$senderId";

      final DatabaseReference reference = FirebaseDatabase.instance.ref();
      final DatabaseReference messageRef = reference.child(currentRef).push();
      final String pushId = messageRef.key!;

      final Map<String, dynamic> messageUserMap = {
        "receiver_id": receiverId,
        "sender_id": senderId,
        "tokendriver": tokenDriver,
        "tokenuser": tokenUser,
        "chat_id": pushId,
        "text": "",
        "type": "image",
        "pic_url": imageUrl,
        "status": "0",
        "time": "",
        "sender_name": user!.customer_fullname,
        "timestamp": formattedDate,
      };

      final Map<String, dynamic> userMap = {
        "$currentRef/$pushId": messageUserMap,
        "$chatRef/$pushId": messageUserMap,
      };

      await reference.update(userMap);
      // Optionally update inbox as in sendMessage
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _setupMessageListener();
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final uid = user!.id;
    return KScaffold(
      appBar: AppBar(
        surfaceTintColor: Kolor.scaffold,
        leadingWidth: 30,
        title: Row(
          spacing: 15,
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.pic)),
            Label(widget.name, fontSize: 15).regular,
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ValueListenableBuilder<List>(
                valueListenable: messagesNotifier,
                builder: (context, messages, _) {
                  // Group messages by date
                  final grouped = groupMessagesByDate(messages);

                  // Flatten the grouped map into a list of items with headers
                  final List items = [];
                  grouped.entries.toList().reversed.forEach((entry) {
                    items.addAll(entry.value.reversed);
                    items.add({'header': entry.key});
                  });

                  return ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.all(kPadding),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      if (item is Map && item.containsKey('header')) {
                        // Date header
                        final date = DateTime.parse(item['header']);
                        String label;
                        final now = DateTime.now();
                        if (DateFormat('yyyy-MM-dd').format(now) ==
                            item['header']) {
                          label = "Today";
                        } else if (DateFormat(
                              'yyyy-MM-dd',
                            ).format(now.subtract(Duration(days: 1))) ==
                            item['header']) {
                          label = "Yesterday";
                        } else {
                          label = DateFormat('dd MMM yyyy').format(date);
                        }
                        return Center(
                          child: Row(
                            spacing: 10,
                            children: [
                              Expanded(child: div),
                              Label(label).regular,
                              Expanded(child: div),
                            ],
                          ),
                        );
                      } else {
                        // Message bubble (reuse your existing code)
                        final message = item;
                        final isSentByMe = message["sender_id"] == uid;
                        return Align(
                          alignment:
                              isSentByMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child:
                              message['type'] != "image"
                                  ? Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          .7,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          isSentByMe
                                              ? Kolor.primary
                                              : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          !isSentByMe
                                              ? CrossAxisAlignment.start
                                              : CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          message["text"],
                                          style: TextStyle(
                                            color:
                                                isSentByMe
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                        ),
                                        Label(
                                          DateFormat("hh:mm a").format(
                                            DateTime.parse(
                                              message['timestamp'],
                                            ),
                                          ),
                                          fontSize: 10,
                                          color:
                                              isSentByMe
                                                  ? Colors.white
                                                  : Colors.black,
                                          textAlign:
                                              isSentByMe
                                                  ? TextAlign.end
                                                  : TextAlign.start,
                                        ).regular,
                                      ],
                                    ),
                                  )
                                  : GestureDetector(
                                    onTap: () {
                                      navPush(
                                        context,
                                        ImagePreviewUI(
                                          imgUrl: message['pic_url'],
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 5,
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            MediaQuery.of(context).size.width *
                                            .7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: kRadius(10),
                                      ),
                                      child: Column(
                                        spacing: 5,
                                        crossAxisAlignment:
                                            !isSentByMe
                                                ? CrossAxisAlignment.start
                                                : CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 150,
                                            height: 150,

                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade900,
                                              borderRadius: kRadius(10),
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  message['pic_url'] ?? "",
                                                ),
                                              ),
                                            ),
                                          ),
                                          Label(
                                            DateFormat("hh:mm a").format(
                                              DateTime.parse(
                                                message['timestamp'],
                                              ),
                                            ),
                                            fontSize: 10,
                                            color: Colors.black,
                                            textAlign:
                                                isSentByMe
                                                    ? TextAlign.end
                                                    : TextAlign.start,
                                          ).regular,
                                        ],
                                      ),
                                    ),
                                  ),
                        );
                      }
                    },
                  );
                },
              ),
            ),

            // Input field and send button
            Padding(
              padding: const EdgeInsets.all(kPadding),
              child: Column(
                children: [
                  ValueListenableBuilder(
                    valueListenable: isUploading,
                    builder:
                        (context, uploading, child) =>
                            uploading
                                ? LinearProgressIndicator(minHeight: 2)
                                : SizedBox(),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: KField(
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          suffix: IconButton(
                            onPressed: () {
                              pickAndSendImage(
                                user.id,
                                "tokenDriver",
                                "tokenUser",
                                widget.name,
                                widget.pic,
                              );
                            },
                            icon: Icon(Icons.image_outlined, size: 22),
                          ),
                          hintText: "Enter a message...",
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          sendMessage(
                            _messageController.text,
                            user.id,
                            "tokenDriver",
                            "tokenUser",
                            widget.name,
                            widget.pic,
                          );
                          _messageController.clear();
                        },
                        icon: const Icon(Icons.send),
                        color: Kolor.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, List<Map<String, dynamic>>> groupMessagesByDate(List messages) {
  Map<String, List<Map<String, dynamic>>> grouped = {};
  for (var msg in messages) {
    final date = DateTime.parse(msg['timestamp']);
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    grouped.putIfAbsent(dateKey, () => []).add(msg);
  }
  return grouped;
}
