import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:mirrorfly_plugin/mirrorfly_view.dart';
import 'package:mirrorfly_plugin/mirrorflychat.dart';

import '../../common/constants.dart';
import '../../model/call_user_list.dart';
import '../outgoing_call/call_controller.dart';

class OnGoingCallView extends StatefulWidget {
  const OnGoingCallView({Key? key,  required this.userJid}) : super(key: key);

  final String userJid;

  @override
  State<OnGoingCallView> createState() => _OnGoingCallViewState();
}


class _OnGoingCallViewState extends State<OnGoingCallView> {
  final controller = Get.put(CallController());

  @override
  void initState() {
    super.initState();
    controller.initCallController(buildContext: context,widget.userJid);
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: AppColors.callerBackground,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // controller.layoutSwitch.value ?

              SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: [
                      Obx(() {
                        return controller.callList.length > 1 &&
                                controller.layoutSwitch.value
                            ? MirrorFlyView(
                                    userJid:
                                        controller.callList[1].userJid ?? Constants.emptyString,
                                    alignProfilePictureCenter: false,
                                    profileSize: 100)
                                .setBorderRadius(
                                    const BorderRadius.all(Radius.circular(10)))
                            : const SizedBox.shrink();
                      }),
                      Obx(() {
                        return Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                controller.callStatus
                                        .contains(CallStatus.reconnecting)
                                    ? const Text(
                                        "${CallStatus.reconnecting}...",
                                        style: TextStyle(color: Colors.white),
                                      )
                                    : const SizedBox.shrink(),
                                controller.callStatus
                                        .contains(CallStatus.reconnecting)
                                    ? const SizedBox(
                                        height: 10,
                                      )
                                    : const SizedBox.shrink(),
                                controller.callList.length > 1 &&
                                        controller
                                            .callList[1].isAudioMuted.value
                                    ? const CircleAvatar(
                                        backgroundColor: Colors.black45,
                                        child: Icon(Icons.mic_off),
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ));
                      }),
                    ],
                  )),

              /*Positioned(
                bottom: 5,
                left: 0,
                right: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() {
                      return controller.callList.length > 1
                          ? Align(
                              alignment: Alignment.topRight,
                              child: SizedBox(
                                width: 130,
                                height: 180,
                                child: MirrorFlyView(
                                  userJid: controller.callList[0].userJid ?? "",
                                  viewBgColor: Colors.blueGrey,
                                ).setBorderRadius(const BorderRadius.all(
                                    Radius.circular(10))),
                              ),
                            )
                          : const SizedBox.shrink();
                    }),
                    const SizedBox(
                      height: 10,
                    ),
                    buildCallOptions(),
                  ],
                ),
              ),*/

              /*Obx(() {
              return Expanded(
                child: GridView.builder(
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: //1,
                         controller.callList.length <= 2
                          ? 1
                          : 2,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                        childAspectRatio: //1.3
                      controller.callList.length <= 2
                          ? 1.3
                          : 2 / 3,
                    ),
                    itemCount: controller.callList.length,
                    itemBuilder: (con, index) {
                      // return buildProfileView();
                      var user = controller.callList[index];
                      debugPrint("#Mirrorfly call --> $user");
                      return MirrorFlyView(userJid: user.userJid ?? "").setBorderRadius(
                          const BorderRadius.all(Radius.circular(10)));
                    }),
              );  }),*/

              Obx(() {
                return controller.callList.isNotEmpty
                    ? AnimatedPositioned(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        left: 0,
                        right: 0,
                        bottom: controller.isVisible.value ? 200 : 0,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            height: 180,
                            width: 130,
                            child: MirrorFlyView(
                              userJid: controller.callList[0].userJid ?? Constants.emptyString,
                              viewBgColor: Colors.blueGrey,
                            ).setBorderRadius(
                                const BorderRadius.all(Radius.circular(10))),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  debugPrint("InkWell");
                  controller.isVisible(!controller.isVisible.value);
                },
              ),
              Obx(() {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  bottom: controller.isVisible.value ? 0.0 : -200,
                  left: 0.0,
                  right: 0.0,
                  child: buildCallOptions(),
                );
                // return
                // Positioned(top: 5, left: 0, right: 0, child: buildToolbar()),
              }),
              Obx(() {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  top: controller.isVisible.value ? 0.0 : -72,
                  left: 0.0,
                  right: 0.0,
                  height: 72,
                  child: buildToolbar(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildToolbar() {
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(addUserCall,package: package,),
            ),
            IconButton(
              onPressed: () {},
              icon: SvgPicture.asset(moreMenu,package: package,),
            )
          ],
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(() {
                return SizedBox(
                  width: 200,
                  child: Text(
                    controller.callTitle.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 12.0,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
              const SizedBox(
                height: 8,
              ),
              Obx(() {
                return Text(
                  controller.callTimer.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontSize: 12.0,
                  ),
                );
              }),
            ],
          ),
        )
      ],
    );
  }

  Widget buildCallOptions() {
    double rightSideWidth = 15;
    controller.callType.value == 'video'
        ? rightSideWidth = 20
        : rightSideWidth = 30;
    return Obx(() {
      return Column(
        children: [
          InkWell(
            onTap: () {
              controller.showCallOptions();
            },
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SvgPicture.asset(
                callOptionsUpArrow,package: package,
                width: 30,
              ),
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                heroTag: "mute",
                elevation: 0,
                backgroundColor: controller.muted.value
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                onPressed: () => controller.muteAudio(),
                child: controller.muted.value
                    ? SvgPicture.asset(
                        muteActive,package: package,
                      )
                    : SvgPicture.asset(
                        muteInactive,package: package,
                      ),
              ),
              SizedBox(width: rightSideWidth),
              controller.callType.value == 'video' &&
                      !controller.videoMuted.value
                  ? FloatingActionButton(
                      heroTag: "switchCamera",
                      elevation: 0,
                      backgroundColor: controller.cameraSwitch.value
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      onPressed: () => controller.switchCamera(),
                      child: controller.cameraSwitch.value
                          ? SvgPicture.asset(cameraSwitchActive,package: package,)
                          : SvgPicture.asset(cameraSwitchInactive,package: package,),
                    )
                  : const SizedBox.shrink(),
              controller.callType.value == 'video' &&
                      !controller.videoMuted.value
                  ? SizedBox(width: rightSideWidth)
                  : const SizedBox.shrink(),
              FloatingActionButton(
                heroTag: "videoMute",
                elevation: 0,
                backgroundColor: controller.videoMuted.value
                    ? Colors.white
                    : Colors.white.withOpacity(0.3),
                onPressed: () => controller.videoMute(),
                child: controller.videoMuted.value
                    ? SvgPicture.asset(videoInactive,package: package,)
                    : SvgPicture.asset(videoActive,package: package,),
              ),
              SizedBox(
                width: rightSideWidth,
              ),
              FloatingActionButton(
                heroTag: "speaker",
                elevation: 0,
                backgroundColor:
                    controller.audioOutputType.value == AudioDeviceType.receiver
                        ? Colors.white.withOpacity(0.3)
                        : Colors.white,
                onPressed: () => controller.changeSpeaker(),
                child:
                    controller.audioOutputType.value == AudioDeviceType.receiver
                        ? SvgPicture.asset(speakerInactive,package: package,)
                        : controller.audioOutputType.value ==
                                AudioDeviceType.speaker
                            ? SvgPicture.asset(speakerActive,package: package,)
                            : controller.audioOutputType.value ==
                                    AudioDeviceType.bluetooth
                                ? SvgPicture.asset(speakerBluetooth,package: package,)
                                : controller.audioOutputType.value ==
                                        AudioDeviceType.headset
                                    ? SvgPicture.asset(speakerHeadset,package: package,)
                                    : SvgPicture.asset(speakerActive,package: package,),
              ),
            ],
          ),
          // Visibility(
          //   visible: controller.isVisible.value,
          //   child:
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0, top: 20.0),
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    maximumSize: const Size(200, 50),
                    shape: const StadiumBorder(),
                    backgroundColor: AppColors.endButton),
                onPressed: () {
                  controller.disconnectCall();
                },
                child: SvgPicture.asset(
                  callEndButton,package: package,
                )),
          ),
          // )
        ],
      );
    });
  }

  Widget buildListViewHorizontal(List<CallUserList> users) {
    return ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: users.length,
        itemBuilder: (cxt, index) {
          return MirrorFlyView(
            userJid: users[index].userJid ?? Constants.emptyString,
            viewBgColor: Colors.blueGrey,
          ).setBorderRadius(const BorderRadius.all(Radius.circular(
              10))); /*controller.callUsers.first !=
              controller.remoteUsers[index].value
              ? Container(
            height: 200,
            width: 150,
            padding: const EdgeInsets.all(8),
            child: controller.mutedUsers.contains(controller.remoteUsers[index])
                ?
              Container(
                  margin: const EdgeInsets.only(right: 4),
                  color: AppColors.audioCallBackground,
                  padding: const EdgeInsets.all(4),
                  child: buildProfileView());
          : MirrorFlyView(
              isLocalUser: controller.remoteUsers[index].value == "local",
              remoteUserJid: controller.remoteUsers[index].value,
            ).setBorderRadius(const BorderRadius.all(Radius.circular(10))),
          )
              : Container();*/
        });
  }
}
