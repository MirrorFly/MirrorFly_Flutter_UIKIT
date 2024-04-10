import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;

import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mirrorfly_plugin/flychat.dart';
import 'package:mirrorfly_plugin/logmessage.dart';
import 'package:mirrorfly_uikit_plugin/app/data/helper.dart';

import 'package:mirrorfly_uikit_plugin/app/modules/dashboard/widgets.dart';
import '../../mirrorfly_uikit_plugin.dart';
import '../data/session_management.dart';
import 'constants.dart';
import 'extensions.dart';
import 'main_controller.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: padding,
      height: 0.29,
      color: MirrorflyUikit.getTheme?.textPrimaryColor.withOpacity(0.5) ??
          dividerColor,
    );
  }
}

class ProfileTextImage extends StatelessWidget {
  final String text;
  final Color? bgColor;
  final double fontSize;
  final double radius;
  final Color fontColor;

  const ProfileTextImage(
      {super.key,
      required this.text,
      this.fontSize = 15,
      this.bgColor,
      this.radius = 25,
      this.fontColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return radius == 0
        ? Container(
            decoration: BoxDecoration(
                color: bgColor ??
                    (text.isNotEmpty
                        ? Color(Helper.getColourCode(text))
                        : MirrorflyUikit.getTheme?.primaryColor)),
            child: Center(
              child: Text(
                getString(text),
                style: TextStyle(
                    fontSize: fontSize,
                    color: fontColor,
                    fontWeight: FontWeight.w800),
              ),
            ),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: bgColor ?? Color(Helper.getColourCode(text)),
            child: Center(
                child: Text(
              getString(text),
              style: TextStyle(
                  fontSize: radius != 0 ? radius / 1.5 : fontSize,
                  color: fontColor),
            )),
          );
  }

  String getString(String str) {
    String string = Constants.emptyString;
    // debugPrint("str.characters.length ${str}");
    if (str.characters.length >= 2) {
      if (str.trim().contains(" ")) {
        var st = str.trim().split(" ");
        string = st[0].characters.take(1).toUpperCase().toString() +
            st[1].characters.take(1).toUpperCase().toString();
      } else {
        string = str.characters.take(2).toUpperCase().toString();
      }
    } else {
      string = str;
    }
    return string;
  }
}

class ImageNetwork extends GetView<MainController> {
  final double? width;
  final double? height;
  final String url;
  final Widget? errorWidget;
  final bool clipOval;
  final Function()? onTap;
  final bool isGroup;
  final bool blocked;
  final bool unknown;

  const ImageNetwork({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.errorWidget,
    required this.clipOval,
    this.onTap,
    required this.isGroup,
    required this.blocked,
    required this.unknown,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => CachedNetworkImage(
        key: UniqueKey(),
        imageUrl: getImageUrl(),
        fit: BoxFit.fill,
        width: width,
        height: height,
        cacheKey: getImageUrl(),
        httpHeaders: {"Authorization": controller.currentAuthToken.value},
        placeholder: (context, string) {
          if (!(blocked || (unknown && Constants.enableContactSync))) {
            if (errorWidget != null) {
              return errorWidget!;
            }
          }
          return clipOval
              ? ClipOval(
                  child: Image.asset(
                    getSingleOrGroup(isGroup),
                    package: package,
                    height: height,
                    width: width,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  getSingleOrGroup(isGroup),
                  package: package,
                  height: height,
                  width: width,
                  fit: BoxFit.cover,
                );
        },
        errorWidget: (context, link, error) {
          if (getImageUrl().isNotEmpty) {
            // mirrorFlyLog("image error", "$error link : $link token : ${controller.authToken.value}");
            if (error.toString().contains("401") && url.isNotEmpty) {
              // controller.getAuthToken();
              // _deleteImageFromCache(url);
              CachedNetworkImage.evictFromCache(url, cacheKey: url)
                  .then((value) {
                refreshHeaders();
              });
            }
          }

          if (!(blocked || (unknown && Constants.enableContactSync))) {
            if (errorWidget != null) {
              return errorWidget!;
            }
          }
          return clipOval
              ? ClipOval(
                  child: Image.asset(
                    getSingleOrGroup(isGroup),
                    package: package,
                    height: height,
                    width: width,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  getSingleOrGroup(isGroup),
                  package: package,
                  height: height,
                  width: width,
                  fit: isGroup ? BoxFit.cover : BoxFit.contain,
                );
        },
        imageBuilder: (context, provider) {
          return clipOval
              ? ClipOval(
                  child: !(blocked || (unknown && Constants.enableContactSync))
                      ? Image(
                          image: provider,
                          fit: BoxFit.fill,
                        )
                      : Image.asset(
                          getSingleOrGroup(isGroup),
                          package: package,
                          height: height,
                          width: width,
                          fit: BoxFit.cover,
                        ),
                )
              : InkWell(
                  onTap: onTap,
                  child: !(blocked || (unknown && Constants.enableContactSync))
                      ? Image(
                          image: provider,
                          fit: BoxFit.fill,
                        )
                      : Image.asset(
                          getSingleOrGroup(isGroup),
                          package: package,
                          height: height,
                          width: width,
                          fit: BoxFit.cover,
                        ),
                );
        },
      ),
    );
    // }
  }

  String getImageUrl() {
    if (url.isEmpty) {
      return "";
    }
    if (url.startsWith("http")) {
      return url;
    } else {
      if (url.contains("/")) return "";
      // return controller.mediaEndpoint + url;
      return SessionManagement.getMediaEndPoint().checkNull() + url;
    }
  }

  Future<bool> isTokenExpired(String token) async {
    // logic to check if the token is expired
    // Return true if the token is expired, otherwise return false
    final http.Response response = await http
        .get(Uri.parse(getImageUrl()), headers: {"Authorization": token});
    var code = response.statusCode;
    LogMessage.d("ImageNetwork",
        "isTokenExpired url ${getImageUrl()} token: $token statusCode : ${response.statusCode}");
    return code == 401;
  }

  Future<Map<String, String>> refreshHeaders() async {
    if (getImageUrl().isEmpty) {
      return {};
    }
    var count = 0;
    // logic to get refreshed headers
    // get the available current Token
    var token = await Mirrorfly.getCurrentAuthToken();
    // This might involve checking the token expiration, refreshing the token if needed, and returning the headers
    while ((await isTokenExpired(token))) {
      if (count <= 1) {
        count++;
        if (SessionManagement.getUsername().checkNull().isNotEmpty &&
            SessionManagement.getPassword().checkNull().isNotEmpty) {
          await Mirrorfly.refreshAndGetAuthToken(flyCallBack: (response) {
            token = response.data;
          });
        }
        LogMessage.d(
            "ImageNetwork", "refreshAndGetAuthToken retryCount $count");
      } else {
        LogMessage.d("ImageNetwork",
            "refreshHeaders $count retryCount exceed retrying stopped...");
        break;
      }
    }
    LogMessage.d("ImageNetwork",
        "refreshHeaders url ${getImageUrl()} token: $token statusCode : ${200} retryCount : $count");
    // Adding the token in headers
    controller.currentAuthToken(token);
    return {
      'Authorization': token,
    };
  }

  String getSingleOrGroup(bool isGroup) {
    return isGroup ? groupImg : profileImg;
  }

  /*void _deleteImageFromCache(String url) {
    */ /*cache.DefaultCacheManager manager = cache.DefaultCacheManager();
    manager.emptyCache();*/ /*
    CachedNetworkImage.evictFromCache(url, cacheKey: url).then((value) => controller.getAuthToken());
    */ /*cache.DefaultCacheManager().removeFile(url).then((value) {
      mirrorFlyLog('File removed', "");
      controller.getAuthToken();
    }).onError((error, stackTrace) {
      mirrorFlyLog("", error.toString());
    });*/ /*
    //await CachedNetworkImage.evictFromCache(url);
  }*/
}

class ListItem extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final Function()? onTap;
  final EdgeInsetsGeometry? dividerPadding;

  const ListItem(
      {super.key,
      this.leading,
      required this.title,
      this.trailing,
      this.onTap,
      this.dividerPadding});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                leading != null
                    ? Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: leading)
                    : const SizedBox(),
                Expanded(
                  child: title,
                ),
                const SizedBox(
                  width: 2,
                ),
                trailing ?? const SizedBox()
              ],
            ),
          ),
          dividerPadding != null
              ? AppDivider(padding: dividerPadding)
              : const SizedBox()
        ],
      ),
    );
  }
}

Widget memberItem(
    {required String name,
    required String image,
    required String status,
    bool? isAdmin,
    required Function() onTap,
    String spantext = Constants.emptyString,
    bool isCheckBoxVisible = false,
    bool isChecked = false,
    Function(bool? value)? onchange,
    bool isGroup = false,
    required bool blocked,
    required bool unknown}) {
  var titlestyle = TextStyle(
      color: MirrorflyUikit.getTheme?.textPrimaryColor ?? Colors.black,
      fontSize: 14.0,
      fontWeight: FontWeight.w700);
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                right: 16.0, left: 16.0, top: 4, bottom: 4),
            child: Row(
              children: [
                ImageNetwork(
                  url: image.checkNull(),
                  width: 48,
                  height: 48,
                  clipOval: true,
                  errorWidget: name.checkNull().isNotEmpty
                      ? ProfileTextImage(
                          fontSize: 20,
                          text: name.checkNull(),
                        )
                      : null,
                  blocked: blocked,
                  unknown: unknown,
                  isGroup: isGroup,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        spantext.isEmpty
                            ? Text(
                                name.checkNull(),
                                style: titlestyle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis, //TextStyle
                              )
                            : spannableText(
                                name.checkNull(),
                                spantext,
                                titlestyle,
                              ),
                        Text(
                          status.checkNull(),
                          style: TextStyle(
                            color:
                                MirrorflyUikit.getTheme?.textSecondaryColor ??
                                    Colors.black,
                            fontSize: 12.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                (isAdmin != null && isAdmin)
                    ? Text("Admin",
                        style: TextStyle(
                          color: MirrorflyUikit.getTheme?.primaryColor ??
                              buttonBgColor,
                          fontSize: 12.0,
                        ))
                    : const SizedBox(),
                Visibility(
                  visible: isCheckBoxVisible,
                  child: Theme(
                    data: ThemeData(
                      unselectedWidgetColor: Colors.grey,
                    ),
                    child: Checkbox(
                      activeColor:
                          MirrorflyUikit.getTheme!.primaryColor, //Colors.white,
                      checkColor: MirrorflyUikit.getTheme?.colorOnPrimary,
                      value: isChecked,
                      onChanged: onchange,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const AppDivider(
              padding: EdgeInsets.only(right: 16, left: 75, top: 4))
        ],
      ),
    ),
  );
}

class EmojiLayout extends StatelessWidget {
  const EmojiLayout(
      {super.key,
      required this.textController,
      this.onEmojiSelected,
      this.onBackspacePressed});
  final TextEditingController textController;
  final Function(emoji.Category?, emoji.Emoji)? onEmojiSelected;
  final Function()? onBackspacePressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: emoji.EmojiPicker(
        onBackspacePressed: onBackspacePressed,
        onEmojiSelected: onEmojiSelected,
        textEditingController: textController,
        config: emoji.Config(
          height: 256,
          // bgColor: const Color(0xFFF2F2F2),
          checkPlatformCompatibility: true,
          emojiViewConfig: emoji.EmojiViewConfig(
            // Issue: https://github.com/flutter/flutter/issues/28894
            emojiSizeMax: 28 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.20
                    : 1.0),
          ),
          swapCategoryAndBottomBar: false,
          skinToneConfig: const emoji.SkinToneConfig(),
          categoryViewConfig: const emoji.CategoryViewConfig(),
          bottomActionBarConfig: const emoji.BottomActionBarConfig(),
          searchViewConfig: const emoji.SearchViewConfig(),
        ),
      ),
    );
  }
}
