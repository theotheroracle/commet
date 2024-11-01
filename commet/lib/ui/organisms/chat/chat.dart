import 'dart:async';
import 'dart:math';

import 'package:commet/client/attachment.dart';
import 'package:commet/client/components/command/command_component.dart';
import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/client/components/emoticon/emoticon_component.dart';
import 'package:commet/client/components/gif/gif_component.dart';
import 'package:commet/client/components/gif/gif_search_result.dart';
import 'package:commet/client/components/read_receipts/read_receipt_component.dart';
import 'package:commet/client/components/threads/thread_component.dart';
import 'package:commet/client/components/typing_indicators/typing_indicator_component.dart';
import 'package:commet/client/room.dart';
import 'package:commet/client/timeline.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/ui/organisms/attachment_processor/attachment_processor.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/organisms/chat/chat_view.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/event_bus.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;

class Chat extends StatefulWidget {
  const Chat(this.room, {this.threadId, this.isBubble = false, super.key});
  final Room room;
  final String? threadId;
  final bool isBubble;
  @override
  State<Chat> createState() => ChatState();
}

enum EventInteractionType {
  reply,
  edit,
}

class ChatState extends State<Chat> {
  Room get room => widget.room;
  Timeline? _timeline;

  Timeline? get timeline => _timeline;

  ThreadsComponent? threadsComponent;

  String get labelChatPageFileTooLarge => Intl.message(
      "This file is too large to upload!",
      desc:
          "Text that is shown when the user attempts to upload a file that is greater than the allowed size",
      name: "labelChatPageFileTooLarge");

  String get labelChatPageFileTooLargeTitle => Intl.message(
      "Max file size exceeded",
      desc:
          "Title for the dialog that is shown when the user attempts to upload a file that is greater than the allowed size",
      name: "labelChatPageFileTooLargeTitle");

  bool processing = false;
  List<PendingFileAttachment> attachments = List.empty(growable: true);

  EventInteractionType? interactionType;
  TimelineEvent? interactingEvent;

  StreamController<void> onFocusMessageInput = StreamController();
  StreamController<String> setMessageInputText = StreamController();

  StreamSubscription? onFileDroppedSubscription;

  GifComponent? gifs;
  RoomEmoticonComponent? emoticons;
  ReadReceiptComponent? receipts;
  TypingIndicatorComponent? typingIndicators;

  Debouncer typingStatusDebouncer =
      Debouncer(delay: const Duration(seconds: 5));
  DateTime lastSetTyping = DateTime.fromMicrosecondsSinceEpoch(0);

  bool get isThread => widget.threadId != null;

  bool get isBubble => widget.isBubble;

  @override
  void initState() {
    Log.i(
        "Initializing room timeline for: ${widget.room.displayName} ${widget.threadId ?? ""}");

    onFileDroppedSubscription =
        EventBus.onFileDropped.stream.listen(onFileDropped);

    gifs = room.getComponent<GifComponent>();
    emoticons = room.getComponent<RoomEmoticonComponent>();
    threadsComponent = room.client.getComponent<ThreadsComponent>();
    receipts = room.getComponent<ReadReceiptComponent>();
    typingIndicators = room.getComponent<TypingIndicatorComponent>();

    if (widget.threadId != null && threadsComponent != null) {
      loadThreadTimeline();
    } else {
      if (room.timeline != null) {
        _timeline = room.timeline;
      } else {
        loadTimeline();
      }
    }

    super.initState();
  }

  Future<void> loadTimeline() async {
    var t = await room.loadTimeline();
    setState(() {
      _timeline = t;
    });
  }

  Future<void> loadThreadTimeline() async {
    Timeline? timeline = room.timeline;
    timeline ??= await room.loadTimeline();

    var threadTimeline = await threadsComponent!.getThreadTimeline(
        roomTimeline: timeline, threadRootEventId: widget.threadId!);
    setState(() {
      _timeline = threadTimeline;
    });
  }

  @override
  void dispose() {
    Log.i(
        "Disposing room timeline for: ${widget.room.displayName} ${widget.threadId ?? ""}");

    onFileDroppedSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatView(this);
  }

  void addAttachment(PendingFileAttachment attachment) {
    if (room.client.maxFileSize != null) {
      if (attachment.size != null &&
          attachment.size! > room.client.maxFileSize!) {
        AdaptiveDialog.show(context, builder: (_) {
          return SizedBox(
              height: 100,
              child:
                  Center(child: tiamat.Text.label(labelChatPageFileTooLarge)));
        }, title: labelChatPageFileTooLargeTitle);

        return;
      }
    }

    setState(() {
      attachments.add(attachment);
    });
  }

  void removeAttachment(PendingFileAttachment attachment) {
    setState(() {
      attachments.remove(attachment);
    });
  }

  void sendMessage(String message) async {
    setState(() {
      processing = true;
    });

    for (var file in attachments) {
      await file.resolve();
      var exif = await readExifFromBytes(file.data!);

      if (exif.keys.any((e) => e.toLowerCase().contains("gps"))) {
        // ignore: use_build_context_synchronously
        var confirmation = await AdaptiveDialog.confirmation(context,
            title: file.name ?? "File",
            confirmationText: "Send File",
            cancelText: "Don't send file",
            dangerous: true,
            prompt:
                "Location data was detected in file '${file.name}', are you sure you want to send?");

        if (confirmation != true) {
          setState(() {
            processing = false;
          });
          return;
        }
      }
    }

    var processedAttachments = await room.processAttachments(attachments);

    setState(() {
      processing = false;
    });

    var component = room.client.getComponent<CommandComponent>();

    if (component?.isExecutable(message) == true) {
      component?.executeCommand(message, room,
          interactingEvent: interactingEvent, type: interactionType);
    } else if (isThread) {
      threadsComponent!.sendMessage(
          threadRootEventId: widget.threadId!,
          room: room,
          message: message,
          inReplyTo: interactionType == EventInteractionType.reply
              ? interactingEvent
              : null,
          replaceEvent: interactionType == EventInteractionType.edit
              ? interactingEvent
              : null,
          processedAttachments: processedAttachments);
    } else {
      room.sendMessage(
          message: message,
          inReplyTo: interactionType == EventInteractionType.reply
              ? interactingEvent
              : null,
          replaceEvent: interactionType == EventInteractionType.edit
              ? interactingEvent
              : null,
          processedAttachments: processedAttachments);
    }

    typingIndicators?.setTypingStatus(false);

    setInteractingEvent(null);
    clearAttachments();
    setMessageInputText.add("");
  }

  void setInteractingEvent(TimelineEvent? event, {EventInteractionType? type}) {
    setState(() {
      if (event == null) {
        interactingEvent = null;
        interactionType = null;
        return;
      }
      interactingEvent = event;
      interactionType = type;

      switch (type) {
        case EventInteractionType.reply:
          onFocusMessageInput.add(null);
          break;
        case EventInteractionType.edit:
          setMessageInputText.add(event.body!);
          onFocusMessageInput.add(null);
          break;
        default:
      }
    });
  }

  void clearAttachments() {
    setState(() {
      attachments.clear();
    });
  }

  void addReaction(TimelineEvent event, Emoticon emote) {
    room.addReaction(event, emote);
  }

  void sendSticker(Emoticon sticker) {
    emoticons?.sendSticker(
        sticker,
        interactionType == EventInteractionType.reply
            ? interactingEvent
            : null);
  }

  Future<void> sendGif(GifSearchResult gif) async {
    await gifs?.sendGif(
        gif,
        interactionType == EventInteractionType.reply
            ? interactingEvent
            : null);
  }

  void editLastMessage() {
    if (!room.permissions.canUserEditMessages) return;
    if (interactionType != null) return;

    for (int i = 0; i < min(20, room.timeline!.events.length); i++) {
      var event = room.timeline!.events[i];

      if (event.senderId != room.client.self!.identifier) continue;

      if (event.type != EventType.message) continue;

      setInteractingEvent(event, type: EventInteractionType.edit);
      break;
    }
  }

  void onInputTextUpdated(String currentText) {
    if (isThread) {
      return;
    }

    if (currentText.isEmpty) {
      stopTyping();
      typingStatusDebouncer.cancel();
      lastSetTyping = DateTime.fromMicrosecondsSinceEpoch(0);
    } else {
      if ((DateTime.now().difference(lastSetTyping)).inSeconds > 3) {
        typingIndicators?.setTypingStatus(true);
        lastSetTyping = DateTime.now();
      }
      typingStatusDebouncer.run(stopTyping);
    }
  }

  void stopTyping() {
    typingIndicators?.setTypingStatus(false);
  }

  void onFileDropped(DropDoneDetails event) async {
    for (var file in event.files) {
      var size = await file.length();
      Uint8List? data;
      if (size < 50000000) {
        data = await file.readAsBytes();
      }

      if (mounted) {
        var attachment = PendingFileAttachment(
            name: file.name, path: file.path, size: size, data: data);

        var processedAttachment =
            await AdaptiveDialog.show<PendingFileAttachment>(context,
                scrollable: false,
                builder: (context) => AttachmentProcessor(
                      attachment: attachment,
                    ));

        if (processedAttachment != null) {
          setState(() {
            attachments.add(processedAttachment);
          });
        }
      }
    }
  }
}
