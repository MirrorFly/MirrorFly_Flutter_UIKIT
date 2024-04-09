import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:mirrorfly_plugin/flychat.dart';
import 'package:mirrorfly_plugin/logmessage.dart';
import 'package:mirrorfly_plugin/model/callback.dart';
import 'package:mirrorfly_plugin/model/message_delivered_model.dart';
import 'package:mirrorfly_uikit_plugin/app/common/extensions.dart';
import '../../../data/permissions.dart';
import '../../../models.dart';
import 'package:mirrorfly_uikit_plugin/app/modules/chat/controllers/chat_controller.dart';

import '../../../common/constants.dart';

class MessageInfoController extends GetxController {
  var chatController = Get.find<ChatController>();

  // var messageID = Get.arguments["messageID"];
  var jid = "";//Get.arguments["jid"];
  var isGroupProfile = false.obs;//Get.arguments["isGroupProfile"];
  var chatMessage = <ChatMessageModel>[].obs;//[Get.arguments["chatMessage"] as ChatMessageModel].obs;
  var readTime = ''.obs;
  var deliveredTime = ''.obs;

  var calendar = DateTime.now();

  /*@override
  void onInit() {
    super.onInit();
    getStatusOfMessage(chatMessage.first.messageId);
  }*/

  init(ChatMessageModel chatMessage, bool isGroupProfile, String jid) {
    this.isGroupProfile(isGroupProfile);
    this.jid = jid;
    this.chatMessage([chatMessage]);
    getStatusOfMessage(this.chatMessage.first.messageId);
  }

  String getChatTime(BuildContext context, int? epochTime) {
    if (epochTime == null) return "";
    if (epochTime == 0) return "";
    var convertedTime = epochTime; // / 1000;
    //messageDate.time = convertedTime
    var hourTime = manipulateMessageTime(
        context, DateTime.fromMicrosecondsSinceEpoch(convertedTime));
    var currentYear = DateTime.now().year;
    calendar = DateTime.fromMicrosecondsSinceEpoch(convertedTime);
    var time = (currentYear == calendar.year)
        ? DateFormat("dd-MMM-yyyy").format(calendar)
        : DateFormat("yyyy/MM/dd").format(calendar);
    return "$time at $hourTime";
  }

  String manipulateMessageTime(BuildContext context, DateTime messageDate) {
    var format = MediaQuery.of(context).alwaysUse24HourFormat ? 24 : 12;
    var hours = calendar.hour; //calendar[Calendar.HOUR]
    calendar = messageDate;
    var dateHourFormat = setDateHourFormat(format, hours);
    return DateFormat(dateHourFormat).format(messageDate);
  }

  String setDateHourFormat(int format, int hours) {
    var dateHourFormat = (format == 12)
        ? (hours < 10)
            ? "hh:mm aa"
            : "h:mm aa"
        : (hours < 10)
            ? "HH:mm"
            : "H:mm";
    return dateHourFormat;
  }

  checkFile(String mediaLocalStoragePath) {
    return mediaLocalStoragePath.isNotEmpty &&
        File(mediaLocalStoragePath).existsSync();
  }

  downloadMedia(BuildContext context, String messageId) async {
    var permission = await AppPermission.getStoragePermission(permissionContent: Constants.writeStoragePermission, deniedContent: Constants.writeStoragePermissionDenied, context: context);
    if (permission) {
      Mirrorfly.downloadMedia(messageId: messageId);
    }
  }
  /*@override
  void onClose(){
    super.onClose();
    // player.stop();
    // player.dispose();
  }*/

  String currentPostLabel = "00:00";
  var maxDuration = 100.obs;
  var currentPos = 0.obs;
  var isPlaying = false.obs;
  var audioPlayed = false.obs;

  // AudioPlayer player = AudioPlayer();
  ChatMessageModel? playingChat;

  playAudio(ChatMessageModel chatMessage) async {
    /*setPlayingChat(chatMessage);
    if (!playingChat!.mediaChatMessage!.isPlaying) {
      int result = await player.play(playingChat!.mediaChatMessage!.mediaLocalStoragePath,position: Duration(milliseconds:playingChat!.mediaChatMessage!.currentPos), isLocal: true);
      if (result == 1) {
        playingChat!.mediaChatMessage!.isPlaying=true;
      } else {
        mirrorFlyLog("", "Error while playing audio.");
      }
    } else if (!playingChat!.mediaChatMessage!.isPlaying) {
      int result = await player.resume();
      if (result == 1) {
        playingChat!.mediaChatMessage!.isPlaying=true;
        this.chatMessage.refresh();
      } else {
        mirrorFlyLog("", "Error on resume audio.");
      }
    } else {
      int result = await player.pause();
      if (result == 1) {
        playingChat!.mediaChatMessage!.isPlaying=false;
        this.chatMessage.refresh();
      } else {
        mirrorFlyLog("", "Error on pause audio.");
      }
    }*/
  }

  void setPlayingChat(ChatMessageModel chatMessage) {
    /*if(playingChat!=null){
      if(playingChat?.mediaChatMessage!.messageId!=chatMessage.messageId){
        player.stop();
        playingChat?.mediaChatMessage!.isPlaying=false;
        playingChat = chatMessage;
      }
    }
    else{
      playingChat = chatMessage;
    }*/
  }

  void onSeekbarChange(double value, ChatMessageModel chatMessage) {
    /*debugPrint('onSeekbarChange $value');
    if (playingChat != null) {
      player.seek(Duration(milliseconds: value.toInt()));
    }else{
      chatMessage.mediaChatMessage?.currentPos=value.toInt();
      // this.chatMessage.refresh();
    }*/
  }

  var messageDeliveredList = <ParticipantList>[].obs;
  var messageReadList = <ParticipantList>[].obs;
  var statusCount = 0.obs;

  String chatDate(BuildContext cxt, ParticipantList item) =>
      getChatTime(cxt, int.parse(item.time.checkNull()));

  getMessageStatus(String messageId) async {
    // statusCount(await Mirrorfly.getGroupMessageStatusCount(messageId));
    Mirrorfly.getGroupMessageDeliveredRecipients(messageId: messageId, groupJid: jid, flyCallBack: (FlyResponse response) {
    mirrorFlyLog("deliveredResp", response.data);
    if(response.hasData) {
      var item = messageStatusDetailFromJson(response.data);
      statusCount(item.totalParticipantCount!);
      messageDeliveredList(item.participantList);
    }
        });

    Mirrorfly.getGroupMessageSeenRecipients(messageId: messageId, groupJid: jid, flyCallBack: (FlyResponse response) {
      LogMessage.d("readResp", response.data);
      if(response.hasData) {
        var readItem = messageStatusDetailFromJson(response.data);
        messageReadList(readItem.participantList);
      }
    });
  }

  var visibleDeliveredList = false.obs;

  onDeliveredClick() {
    if (visibleDeliveredList.value) {
      visibleDeliveredList(false);
    } else {
      visibleDeliveredList(true);
    }
  }

  var visibleReadList = false.obs;

  onReadClick() {
    if (visibleReadList.value) {
      visibleReadList(false);
    } else {
      visibleReadList(true);
    }
  }

  void onMessageStatusUpdated(ChatMessageModel chatMessageModel) {
    // mirrorFlyLog("MESSAGE STATUS UPDATED on Info", chatMessageModel.messageId);
    if (chatMessageModel.messageId == chatMessage[0].messageId) {
      chatMessage[0] = chatMessageModel;
      chatMessage.refresh();
      getStatusOfMessage(chatMessageModel.messageId);
    }
  }

  getStatusOfMessage(String messageId) {
    if (!isGroupProfile.value) {
      Mirrorfly.getMessageStatusOf(messageId: messageId).then((value) {
        var response = json.decode(value);
        readTime(response["seenTime"]);
        deliveredTime(response["deliveredTime"]);
      });
    } else {
      getMessageStatus(messageId);
    }
  }
}
