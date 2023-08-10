import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mirrorfly_uikit_plugin/app/common/constants.dart';
import 'package:mirrorfly_uikit_plugin/mirrorfly_uikit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'helper.dart';

class AppPermission {
  AppPermission._();
  /*static Future<bool> getLocationPermission() async{
    var permission = await Geolocator.requestPermission();
    mirrorFlyLog(permission.name, permission.index.toString());
    return permission.index==2 || permission.index==3;
  }*/



  static Future<PermissionStatus> getContactPermission(BuildContext context) async {
    final permission = await Permission.contacts.status;
    var info = await PackageInfo.fromPlatform();
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      const newPermission = Permission.contacts;
      if(context.mounted) {
        var deniedPopupValue = await mirrorFlyPermissionDialog(context,
            notNowBtn: () {
              return false;
            },
            continueBtn: () async {
              // newPermission.request();
            },
            icon: contactPermission,
            content: Constants.contactPermission,appName: info.appName);
        if(deniedPopupValue) {
          return await newPermission.request();
        }else {
          return newPermission.status;
        }
      }
      return newPermission.status;
    } else {
      return permission;
    }
  }

  static Future<bool> getStoragePermission(BuildContext context) async {
    var info = await PackageInfo.fromPlatform();
    var sdkVersion=0;
    if (Platform.isAndroid) {
      var sdk =  await DeviceInfoPlugin().androidInfo;
      sdkVersion=sdk.version.sdkInt;
    } else {
      sdkVersion = 0;
    }
    final permission = await Permission.storage.status;
    if (sdkVersion < 33) {
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.permanentlyDenied) {
        const newPermission = Permission.storage;
        if(context.mounted) {
          var deniedPopupValue = await mirrorFlyPermissionDialog(context,
              notNowBtn: () {
                return false;
              },
              continueBtn: () async {
                // newPermission.request();
              },
              icon: filePermission,
              content: Constants.filePermission,appName: info.appName);
          if(deniedPopupValue) {
            return await newPermission.request().isGranted;
          }else{
            return newPermission.status.isGranted;
          }
        }
        return false;
      } else {
        return permission.isGranted;
      }
    } else {
      if(context.mounted) {
        return getAndroid13Permission(context);
      } else {
        return false;
      }
    }
  }
  static Future<bool> requestNotificationPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      debugPrint('Notification permission granted');
      return true;
    } else {
      debugPrint('Notification permission denied');
      return false;
    }
  }

  static Future<bool> getAndroid13Permission(BuildContext context) async {
    var info = await PackageInfo.fromPlatform();
    final photos = await Permission.photos.status;
    final videos = await Permission.videos.status;
    final mediaLibrary = await Permission.mediaLibrary.status;
    // final audio = await Permission.audio.status;
    const newPermission = [
      Permission.photos,
      Permission.videos,
      // Permission.audio
    ];
    if ((photos != PermissionStatus.granted && photos != PermissionStatus.permanentlyDenied) ||
        (videos != PermissionStatus.granted && videos != PermissionStatus.permanentlyDenied) ||
        (mediaLibrary != PermissionStatus.granted && mediaLibrary != PermissionStatus.permanentlyDenied)
    ) {
      if(context.mounted) {
        mirrorFlyLog("showing mirrorfly popup", "");
        var deniedPopupValue = await mirrorFlyPermissionDialog(context,
            notNowBtn: () {
              return false;
            },
            continueBtn: () {
              // newPermission.request();
            },
            icon: filePermission,
            content: Constants.filePermission,appName: info.appName);
        if(deniedPopupValue) {
          var newp = await newPermission.request();
          PermissionStatus? photo = newp[Permission.photos];
          PermissionStatus? video = newp[Permission.videos];
          PermissionStatus? mediaLibrary = newp[Permission.mediaLibrary];
          // var audio = await newPermission[2].isGranted;
          return (photo!.isGranted && video!.isGranted && mediaLibrary!.isGranted);
          // ? PermissionStatus.granted
          // : PermissionStatus.denied;
        }else{
          return false;//PermissionStatus.denied;
        }
      }
      return false;
    } else {
      mirrorFlyLog("showing mirrorfly popup", "${photos.isGranted} ${videos.isGranted}");
      return (photos.isGranted && videos.isGranted && mediaLibrary.isGranted);
    }
  }

  static Future<PermissionStatus> getManageStoragePermission() async {
    final permission = await Permission.manageExternalStorage.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      final newPermission = await Permission.manageExternalStorage.request();
      return newPermission;
    } else {
      return permission;
    }
  }

  //not used so var deniedPopupValue = await not imple
  static Future<PermissionStatus> getCameraPermission(BuildContext context) async {
    var info = await PackageInfo.fromPlatform();
    final permission = await Permission.camera.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      const newPermission = Permission.camera;
      if(context.mounted) {
        mirrorFlyPermissionDialog(context,
            notNowBtn: () {
              return false;
            },
            continueBtn: () async {
              newPermission.request();
            },
            icon: cameraPermission,
            content: Constants.cameraPermission,appName: info.appName);
      }
      return newPermission.status;
    } else {
      return permission;
    }
  }

  //not used so var deniedPopupValue = await not imple
  static Future<PermissionStatus> getAudioPermission(BuildContext context) async {
    var info = await PackageInfo.fromPlatform();
    final permission = await Permission.microphone.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      const newPermission = Permission.microphone;
      if(context.mounted) {
        mirrorFlyPermissionDialog(context,
            notNowBtn: () {
              return false;
            },
            continueBtn: () async {
              newPermission.request();
            },
            icon: audioPermission,
            content: Constants.audioPermission,appName: info.appName);
      }
      return newPermission.status;
    } else {
      return permission;
    }
  }

  //not used so var deniedPopupValue = await not imple
  static Future<bool> askFileCameraAudioPermission(BuildContext context) async {
    var info = await PackageInfo.fromPlatform();
    var filePermission = Permission.storage;
    var camerapermission = Permission.camera;
    var audioPermission = Permission.microphone;
    if (await filePermission.isGranted == false ||
        await camerapermission.isGranted == false ||
        await audioPermission.isGranted == false) {
      if(context.mounted) {
        mirrorFlyPermissionDialog(context,
            notNowBtn: () {
              return false;
            },
            continueBtn: () async {
              if (await requestPermission(filePermission) &&
                  await requestPermission(camerapermission) &&
                  await requestPermission(audioPermission)) {
                return true;
              } else {
                return false;
              }
            },
            icon: cameraPermission,
            content: Constants.cameraPermission,appName: info.appName);
      }
    } else {
      return true;
    }
    return false;
  }

  static Future<bool> requestPermission(Permission permission) async {
    var status1 = await permission.status;
    mirrorFlyLog('status', status1.toString());
    if (status1 == PermissionStatus.denied &&
        status1 != PermissionStatus.permanentlyDenied) {
      mirrorFlyLog('permission.request', status1.toString());
      final status = await permission.request();
      return status.isGranted;
    }
    return status1.isGranted;
  }

  static Future<bool> checkPermission(BuildContext context,Permission permission, String permissionIcon, String permissionContent) async {
    var info = await PackageInfo.fromPlatform();
    var status = await permission.status;
    if (status == PermissionStatus.granted) {
      debugPrint("permission granted opening");
      return true;
    }else if(status == PermissionStatus.permanentlyDenied){
      mirrorFlyLog('permanentlyDenied', 'permission');
      var permissionAlertMessage = "";
      var permissionName = "$permission";
      permissionName = permissionName.replaceAll("Permission.", "");

      switch (permissionName.toLowerCase()){
        case "camera":
          permissionAlertMessage = Constants.cameraPermissionDenied;
          break;
        case "microphone":
          permissionAlertMessage = Constants.microPhonePermissionDenied;
          break;
        case "storage":
          permissionAlertMessage = Constants.storagePermissionDenied;
          break;
        case "contacts":
          permissionAlertMessage = Constants.contactPermissionDenied;
          break;
        case "location":
          permissionAlertMessage = Constants.locationPermissionDenied;
          break;
        default:
          permissionAlertMessage = "${info.appName} need the ${permissionName.toUpperCase()} Permission. But they have been permanently denied. Please continue to app settings, select \"Permissions\", and enable \"${permissionName.toUpperCase()}\"";
      }
      if(context.mounted) {
        var deniedPopupValue = await customPermissionDialog(context, icon: permissionIcon, content: permissionAlertMessage, appName: info.appName);
        if(deniedPopupValue){
          openAppSettings();
          return false;
        }else{
          return false;
        }
      }else {
        return false;
      }
      /*var deniedPopupValue = await customPermissionDialog(context,icon: permissionIcon,
          content: permissionAlertMessage,appName: info.appName);
      if(deniedPopupValue){
        openAppSettings();
        return false;
      }else{
        return false;
      }*/
    }else{
      // mirrorFlyLog('denied', 'permission');
      if(context.mounted) {
        var popupValue = await customPermissionDialog(context,icon: permissionIcon,
            content: permissionContent,appName: info.appName);
        if(popupValue){
          return AppPermission.requestPermission(permission);
        }else{
          return false;
        }
      }else{
        return false;
      }
      /*var popupValue = await customPermissionDialog(context,icon: permissionIcon,
          content: permissionContent,appName: info.appName);
      if(popupValue){
        return AppPermission.requestPermission(permission);
      }else{
        return false;
      }*/
    }
  }

  static permissionDeniedDialog({required String content, required BuildContext context}){
    Helper.showAlert(
        message:
        content,
        title: "Permission Denied",
        actions: [
          TextButton(
              onPressed: () {
                // Get.back();
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text("OK")),
        ], context: context);
  }
  static Future<bool> mirrorFlyPermissionDialog(BuildContext context,
      {required Function() notNowBtn,
      required Function() continueBtn,
      required String icon,
      required String content,required String appName}) async {
    return await showDialog(context: context, builder: (BuildContext context) { return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: MirrorflyUikit.theme == "dark" ? darkPopupColor : Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 35.0),
            color: MirrorflyUikit.getTheme?.primaryColor,// buttonBgColor,
            child: Center(child: SvgPicture.asset(icon,package: package, colorFilter: ColorFilter.mode(MirrorflyUikit.getTheme!.colorOnPrimary, BlendMode.srcIn),)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content.replaceAll('Mirrorfly', appName),
              style: TextStyle(fontSize: 14, color: MirrorflyUikit.getTheme?.textPrimaryColor),
            ),
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context,false);
              // Get.back(result: "no");
              notNowBtn();
            },
            child: Text(
              "NOT NOW",
              style: TextStyle(color: MirrorflyUikit.getTheme?.primaryColor),
            )),
        TextButton(
            onPressed: () {
              Navigator.pop(context,true);
              // Get.back(result: "yes");
              continueBtn();
            },
            child: Text(
              "CONTINUE",
              style: TextStyle(color: MirrorflyUikit.getTheme?.primaryColor),
            ))
      ],
    ); },);
  }

  static Future<bool> customPermissionDialog(BuildContext context,
      {required String icon,
      required String content,required String appName}) async {
    return await showDialog(context: context, builder: (BuildContext context) { return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: MirrorflyUikit.theme == "dark" ? darkPopupColor : Colors.white,
      // shadowColor: MirrorflyUikit.getTheme?.textSecondaryColor,
      // elevation: 4,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 35.0),
            color: MirrorflyUikit.getTheme?.primaryColor,
            child: Center(child: SvgPicture.asset(icon,package: package, colorFilter: ColorFilter.mode(MirrorflyUikit.getTheme!.colorOnPrimary, BlendMode.srcIn),)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              content.replaceAll('Mirrorfly', appName),
              style: TextStyle(fontSize: 14, color: MirrorflyUikit.getTheme?.textPrimaryColor),
            ),
          )
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pop(context,false);
              // Get.back(result: false);
              // notNowBtn();
            },
            child: Text(
              "NOT NOW",
              style: TextStyle(color: MirrorflyUikit.getTheme?.primaryColor),
            )),
        TextButton(
            onPressed: () {
              Navigator.pop(context,true);
              // Get.back(result: true);
              // continueBtn();
            },
            child:  Text(
              "CONTINUE",
              style: TextStyle(color: MirrorflyUikit.getTheme?.primaryColor),
            ))
      ],
    ); },);
  }
}
