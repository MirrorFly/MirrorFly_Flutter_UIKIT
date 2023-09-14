import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mirrorfly_plugin/flychat.dart';
import 'package:mirrorfly_plugin/model/register_model.dart';
import 'package:mirrorfly_uikit_plugin/app/common/app_constants.dart';
import 'package:mirrorfly_uikit_plugin/app/data/helper.dart';
import 'package:mirrorfly_uikit_plugin/app/model/app_config.dart';
import 'package:mirrorfly_uikit_plugin/app/model/reply_hash_map.dart';

import 'app/common/app_theme.dart';
import 'app/common/main_controller.dart';
import 'app/common/navigation_manager.dart';
import 'app/data/apputils.dart';
import 'app/data/session_management.dart';
import 'app/modules/chat/controllers/chat_controller.dart';
import 'app/modules/chat/views/chat_view.dart';
import 'mirrorfly_uikit_plugin_platform_interface.dart';

class MirrorflyUikit {
  static MirrorFlyAppTheme? getTheme = MirrorFlyTheme.mirrorFlyLightTheme;
  bool isTrialLicenceKey = true;
  bool showMobileNumberOnList = true;
  bool showStatusOption = true;
  bool enableLocalNotification = true;
  String googleMapKey = '';
  static bool isSDKInitialized = false;
  static String theme = "light";

  static var instance = MirrorflyUikit();

  // Initialize the NavigationManager in the constructor
  final NavigationManager navigationManager = NavigationManager();

  GlobalKey<NavigatorState>? globalNavigatorKey;

  static Future<String?> getPlatformVersion() {
    return MirrorflyUikitPluginPlatform.instance.getPlatformVersion();
  }


  ///Used as a initUIKIT class for [MirrorflyUikit]
  /// * [baseUrl] provide the base url for making api calls
  /// * [licenseKey] provide the License Key
  /// * [googleMapKey] provide the googleMap Key for location messages
  /// * [iOSContainerID] provide the App Group of the iOS Project
  /// * [isTrialLicenceKey] to provide trial/live register and contact sync
  /// * [showMobileNumberOnList] to show mobile on contact list
  /// * [storageFolderName] provide the Local Storage Folder Name
  initUIKIT(
      {required String baseUrl,required GlobalKey<NavigatorState> navigatorKey,
      required String licenseKey,
      String? googleMapKey,
      required String iOSContainerID,
      String? storageFolderName,
      bool isTrialLicenceKey = true,
        bool showMobileNumberOnList = true,
        bool showStatusOption = true,
        bool enableLocalNotification = true}) async {
    Mirrorfly.init(
        baseUrl: baseUrl,
        licenseKey: licenseKey,
        iOSContainerID: iOSContainerID,
        storageFolderName: storageFolderName,
        enableMobileNumberLogin: true,
        isTrialLicenceKey: isTrialLicenceKey,
        chatHistoryEnable: false,
        enableDebugLog: true);
    isSDKInitialized = true;
    this.isTrialLicenceKey = isTrialLicenceKey;
    this.showMobileNumberOnList = showMobileNumberOnList;
    this.showStatusOption = showStatusOption;
    this.enableLocalNotification = enableLocalNotification;
    this.googleMapKey = googleMapKey ?? '';
    globalNavigatorKey = navigatorKey;
    ReplyHashMap.init();
    rootBundle.loadString('assets/mirrorfly_config.json').then((configFile) {
      var config = AppConfig.fromJson(json.decode(configFile));
      theme = config.appTheme.theme!;
      getTheme = MirrorFlyTheme.customTheme(
          primaryColor: config.appTheme.customTheme!.primaryColor,
          secondaryColor:
          config.appTheme.customTheme!.secondaryColor,
          scaffoldColor:
          config.appTheme.customTheme!.scaffoldColor,
          colorOnPrimary:
          config.appTheme.customTheme!.colorOnPrimary,
          textPrimaryColor:
          config.appTheme.customTheme!.textPrimaryColor,
          textSecondaryColor:
          config.appTheme.customTheme!.textSecondaryColor,
          chatBubblePrimaryColor:
          config.appTheme.customTheme!.chatBubblePrimaryColor,
          chatBubbleSecondaryColor: config
              .appTheme.customTheme!.chatBubbleSecondaryColor,
          appBarColor: config.appTheme.customTheme!.appBarColor,
          colorOnAppbar:
          config.appTheme.customTheme!.colorOnAppbar);
      /*getTheme = config.appTheme.theme == "light"
          ? MirrorFlyTheme.mirrorFlyLightTheme
          : config.appTheme.theme == "dark"
              ? MirrorFlyTheme.mirrorFlyDarkTheme
              : config.appTheme.customTheme != null
                  ? MirrorFlyTheme.customTheme(
                      primaryColor: config.appTheme.customTheme!.primaryColor,
                      secondaryColor:
                          config.appTheme.customTheme!.secondaryColor,
                      scaffoldColor:
                          config.appTheme.customTheme!.scaffoldColor,
                      colorOnPrimary:
                          config.appTheme.customTheme!.colorOnPrimary,
                      textPrimaryColor:
                          config.appTheme.customTheme!.textPrimaryColor,
                      textSecondaryColor:
                          config.appTheme.customTheme!.textSecondaryColor,
                      chatBubblePrimaryColor:
                          config.appTheme.customTheme!.chatBubblePrimaryColor,
                      chatBubbleSecondaryColor: config
                          .appTheme.customTheme!.chatBubbleSecondaryColor,
                      appBarColor: config.appTheme.customTheme!.appBarColor,
                      colorOnAppbar:
                          config.appTheme.customTheme!.colorOnAppbar)
                  : MirrorFlyTheme.mirrorFlyLightTheme;*/
    }).catchError((e) {
      debugPrint("Mirrorfly config file not found in assets $e");
    });
    SessionManagement.onInit().then((value) {
      Get.put<MainController>(MainController());
      SessionManagement.setBool(AppConstants.enableLocalNotification, enableLocalNotification);
    });
  }

  ///Used as a register class for [MirrorflyUikit]
  ///
  ///* [userIdentifier] provide the Unique Id to Register the User
  ///* [fcmToken] provide the FCM token this is an optional
  ///sample response {'status': true, 'message': 'Register Success};
  static Future<Map> registerUser({required String userIdentifier,
      String fcmToken = ""}) async {
    if (!isSDKInitialized) {
      return setResponse(false, 'SDK Not Initialized');
    }
    if (await AppUtils.isNetConnected()) {
      var value = await Mirrorfly.registerUser(userIdentifier, fcmToken: fcmToken);
      try {
        var userData = registerModelFromJson(value); //message
        if (userData.data != null) {
          SessionManagement.setLogin(userData.data!.username!.isNotEmpty);
          SessionManagement.setUser(userData.data!);
          Mirrorfly.enableDisableArchivedSettings(true);
          SessionManagement.setUserIdentifier(userIdentifier);
          // Mirrorfly.setRegionCode(regionCode ?? 'IN');///if its not set then error comes in contact sync delete from phonebook.
          // SessionManagement.setCountryCode((countryCode ?? "").replaceAll('+', ''));
          await _setUserJID(userData.data!.username!);
          return setResponse(true, 'Register Success');
        } else {
          return setResponse(false, userData.message.toString());
        }
      } catch (e) {
        return setResponse(false, '$e');
      }
    } else {
      return Future.value(
          setResponse(false, 'Check your internet connection and try again'));
    }
  }

  ///Used as a register class for [MirrorflyUikit]
  ///Use this Method to logout from our UIkit
  ///this will clear all the chat data.
  ///sample response {'status': true, 'message': 'Logout successfully};
  static Future<Map<String, dynamic>> logoutFromUIKIT() async {
    try {
      var value = await Mirrorfly.logoutOfChatSDK(); //.then((value) {
      if (value) {
        var token = SessionManagement.getToken().checkNull();
        SessionManagement.clear().then((value) {
          SessionManagement.setToken(token);
        });
        return setResponse(true, 'Logout successfully');
      } else {
        return setResponse(false, 'Logout Failed');
      }
      //});
    } catch (e) {
      return setResponse(false, 'Logout Failed');
    }
  }

  ///Used as a [isOnGoingCall] class for [MirrorflyUikit]
  ///used to check if there is an ongoing call
  ///this method works in [Android], in [iOS] returns always false
  ///returns the bool value
  static Future<bool?> isOnGoingCall() async {
    return await Mirrorfly.isOnGoingCall();
  }

  static Map<String, dynamic> setResponse(bool status, String message) {
    return {'status': status, 'message': message};
  }

  static _setUserJID(String username) async {
    Mirrorfly.getAllGroups(true);
    await Mirrorfly.getJid(username).then((value) {
      if (value != null) {
        SessionManagement.setUserJID(value);
      }
    }).catchError((error) {});
  }

  static ChatView chatPage() {
    Get.put<ChatController>(ChatController());
    return const ChatView(
      jid: "",
      showChatDeliveryIndicator: false,
    );
  }
}
