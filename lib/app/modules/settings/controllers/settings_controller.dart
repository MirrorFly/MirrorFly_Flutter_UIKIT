import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mirrorfly_uikit_plugin/app/data/helper.dart';
import 'package:mirrorfly_plugin/flychat.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import '../../../common/constants.dart';
import '../../../data/apputils.dart';
import '../../../data/session_management.dart';

class SettingsController extends GetxController {
  PackageInfo? packageInfo;

  @override
  void onInit() {
    super.onInit();
    getPackageInfo();
  }

  getPackageInfo() async {
    packageInfo.obs.value = await PackageInfo.fromPlatform();
  }

  logout(BuildContext context) {
    Get.back();
    if (SessionManagement.getEnablePin()) {
      // Get.toNamed(Routes.pin)?.then((value){
      //   if(value!=null && value){
      //     logoutFromSDK(context);
      //   }
      // });
    } else {
      logoutFromSDK(context);
    }
  }

  logoutFromSDK(BuildContext context) async {
    if (await AppUtils.isNetConnected()) {
      if(context.mounted)Helper.progressLoading(context: context);
      Mirrorfly.logoutOfChatSDK().then((value) {
        Helper.hideLoading(context: context);
        if (value) {
          var token = SessionManagement.getToken().checkNull();
          SessionManagement.clear().then((value) {
            SessionManagement.setToken(token);
            // Get.offAllNamed(Routes.login);
          });
        } else {
          Get.snackbar("Logout", "Logout Failed");
        }
      }).catchError((er) {
        Helper.hideLoading(context: context);
        SessionManagement.clear().then((value) {
          // SessionManagement.setToken(token);
          // Get.offAllNamed(Routes.login);
        });
      });
    } else {
      toToast(Constants.noInternetConnection);
    }
  }

  getReleaseDate() async {
    var releaseDate = "Nov";
    String pathToYaml =
        join(dirname(Platform.script.toFilePath()), '../pubspec.yaml');
    File file = File(pathToYaml);
    file.readAsString().then((String content) {
      Map yaml = loadYaml(content);
      debugPrint(yaml['build_release_date']);
      releaseDate = yaml['build_release_date'];
    });
    return releaseDate;
  }
}