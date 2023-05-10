import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get/get.dart';
import 'package:mirrorfly_uikit_plugin/app/common/constants.dart';
import 'package:mirrorfly_uikit_plugin/app/data/helper.dart';
import 'package:mirrorfly_plugin/flychat.dart';
import '../../../../mirrorfly_uikit_plugin.dart';
import '../../../models.dart';
import 'package:mirrorfly_uikit_plugin/app/data/session_management.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../common/de_bouncer.dart';
import '../../../data/apputils.dart';
import '../../../data/permissions.dart';
import '../../chatInfo/views/chat_info_view.dart';
import '../../group/views/group_info_view.dart';
import '../views/chat_view.dart';

class ContactController extends FullLifeCycleController
    with FullLifeCycleMixin {
  ScrollController scrollController = ScrollController();
  var pageNum = 1;
  var isPageLoading = false.obs;
  var scrollable = MirrorflyUikit.isTrialLicence.obs;
  var usersList = <Profile>[].obs;
  var mainUsersList = List<Profile>.empty(growable: true).obs;
  var selectedUsersList = List<Profile>.empty(growable: true).obs;
  var selectedUsersJIDList = List<String>.empty(growable: true).obs;
  var forwardMessageIds = List<String>.empty(growable: true).obs;
  final TextEditingController searchQuery = TextEditingController();
  var _searchText = "";
  var _first = true;

  var isForward = false.obs;
  var isCreateGroup = false.obs;
  var groupJid = "".obs;
  BuildContext? context;
  @override
  void onInit(){
    super.onInit();
    debugPrint('controller init');
  }

  Future<void> init(BuildContext context,{bool forward = false,List<String>? messageIds ,bool group = false,String groupjid = ''}) async {
    this.context=context;
    isForward(forward);
    if (isForward.value) {
      isCreateGroup(false);
      if(messageIds!=null) {
        forwardMessageIds.addAll(messageIds);
      }
    } else {
      isCreateGroup(group);
      groupJid(groupjid);
    }
    scrollController.addListener(_scrollListener);
    //searchQuery.addListener(_searchListener);
    if (await AppUtils.isNetConnected() || !MirrorflyUikit.isTrialLicence) {
      isPageLoading(true);
      fetchUsers(false);
    } else {
      toToast(Constants.noInternetConnection);
    }
    //Mirrorfly.syncContacts(true);
    //Mirrorfly.getRegisteredUsers(true).then((value) => mirrorFlyLog("registeredUsers", value.toString()));
    // progressSpinner(!MirrorflyUikit.isTrialLicence && await Mirrorfly.contactSyncStateValue());
  }

  void userUpdatedHisProfile(String jid) {
    updateProfile(jid);
  }

  Future<void> updateProfile(String jid) async {
    if (jid.isNotEmpty) {
      getProfileDetails(jid).then((value) {
        var userListIndex = usersList.indexWhere((element) => element.jid == jid);
        var mainListIndex =
        mainUsersList.indexWhere((element) => element.jid == jid);
        mirrorFlyLog('value.isBlockedMe', value.isBlockedMe.toString());
        if (!userListIndex.isNegative) {
          usersList[userListIndex] = value;
          usersList.refresh();
        }
        if (!mainListIndex.isNegative) {
          mainUsersList[mainListIndex] = value;
          mainUsersList.refresh();
        }
      });
    }
  }

  //Add participants
  final _search = false.obs;

  set search(bool value) => _search.value = value;

  bool get search => _search.value;

  void onSearchPressed() {
    if (_search.value) {
      _search(false);
    } else {
      _search(true);
    }
  }

  bool get isCreateVisible => isCreateGroup.value;

  bool get isSearchVisible => !_search.value;

  bool get isClearVisible =>
      _search.value && lastInputValue.value.isNotEmpty /*&& !isForward.value && isCreateGroup.value*/;

  bool get isMenuVisible => !_search.value && !isForward.value;

  bool get isCheckBoxVisible => isCreateGroup.value || isForward.value;

  _scrollListener() {
    if (scrollController.hasClients) {
      if (scrollController.position.extentAfter <= 0 &&
          isPageLoading.value == false) {
        if (scrollable.value) {
          //isPageLoading.value = true;
          fetchUsers(false);
        }
      }
    }
  }

  @override
  void onClose() {
    super.onClose();
    searchQuery.dispose();
  }

  final deBouncer = DeBouncer(milliseconds: 700);
  RxString lastInputValue = "".obs;

  searchListener(String text) async {
    debugPrint("searching .. ");
    if (lastInputValue.value != searchQuery.text.trim()) {
      lastInputValue(searchQuery.text.trim());
      if (searchQuery.text.trim().isEmpty) {
        _searchText = "";
        pageNum = 1;
      } else {
        isPageLoading(true);
        _searchText = searchQuery.text.trim();
        pageNum = 1;
      }
      if (MirrorflyUikit.isTrialLicence) {
        deBouncer.run(() {
          fetchUsers(true);
        });
      } else {
        fetchUsers(true);
      }
    }
  }

  backFromSearch() {
    _search.value = false;
    searchQuery.clear();
    _searchText = "";
    lastInputValue('');
    //if(!_IsSearching){
    //isPageLoading.value=true;
    pageNum = 1;
    //fetchUsers(true);
    //}
    usersList(mainUsersList);
    scrollable(MirrorflyUikit.isTrialLicence);
  }

  fetchUsers(bool fromSearch,{bool server=false}) async {
    if(!MirrorflyUikit.isTrialLicence){
      var granted = await Permission.contacts.isGranted;
      if(!granted){
        isPageLoading(false);
        return;
      }
    }
    if (await AppUtils.isNetConnected() || !MirrorflyUikit.isTrialLicence) {
      var future = (MirrorflyUikit.isTrialLicence)
          ? Mirrorfly.getUserList(pageNum, _searchText)
          : Mirrorfly.getRegisteredUsers(false);
      future.then((data) async {
        //Mirrorfly.getUserList(pageNum, _searchText).then((data) async {
        mirrorFlyLog("userlist", data);
        var item = userListFromJson(data);
        var list = <Profile>[];

        if (groupJid.value.checkNull().isNotEmpty) {
          await Future.forEach(item.data!, (it) async {
            await Mirrorfly.isMemberOfGroup(
                    groupJid.value.checkNull(), it.jid.checkNull())
                .then((value) {
              mirrorFlyLog("item", value.toString());
              if (value == null || !value) {
                list.add(it);
              }
            });
          });
          if (_first) {
            _first = false;
            mainUsersList(list);
          }
          if (fromSearch) {
            if (MirrorflyUikit.isTrialLicence) {
              usersList(list);
              pageNum = pageNum + 1;
              scrollable.value = list.length == 20;
            } else {
              var userlist = mainUsersList.where((p0) => getName(p0)
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.trim().toLowerCase()));
              usersList(userlist.toList());
              scrollable(false);
              /*for (var userDetail in mainUsersList) {
                  if (userDetail.name.toString().toLowerCase().contains(_searchText.trim().toLowerCase())) {
                    usersList.add(userDetail);
                  }
                }*/
            }
          } else {
            if (MirrorflyUikit.isTrialLicence) {
              usersList.addAll(list);
              pageNum = pageNum + 1;
              scrollable.value = list.length == 20;
            } else {
              usersList(list);
              scrollable(false);
            }
          }
          isPageLoading.value = false;
          usersList.refresh();
        } else {
          list.addAll(item.data!);
          if (!MirrorflyUikit.isTrialLicence && fromSearch) {
            var userlist = mainUsersList.where((p0) => getName(p0)
                .toString()
                .toLowerCase()
                .contains(_searchText.trim().toLowerCase()));
            usersList(userlist.toList());
            /*for (var userDetail in mainUsersList) {
              if (userDetail.name.toString().toLowerCase().contains(_searchText.trim().toLowerCase())) {
                usersList.add(userDetail);
              }
            }*/
          }
          if (_first) {
            _first = false;
            mainUsersList(list);
          }
          if (fromSearch) {
            if (MirrorflyUikit.isTrialLicence) {
              usersList(list);
              pageNum = pageNum + 1;
              scrollable.value = list.length == 20;
            } else {
              var userlist = mainUsersList.where((p0) => getName(p0)
                  .toString()
                  .toLowerCase()
                  .contains(_searchText.trim().toLowerCase()));
              usersList(userlist.toList());
              scrollable(false);
              /*for (var userDetail in mainUsersList) {
                  if (userDetail.name.toString().toLowerCase().contains(_searchText.trim().toLowerCase())) {
                    usersList.add(userDetail);
                  }
                }*/
            }
          } else {
            if (MirrorflyUikit.isTrialLicence) {
              usersList.addAll(list);
              pageNum = pageNum + 1;
              scrollable.value = list.length == 20;
            } else {
              usersList(list);
              scrollable(false);
            }
          }
          isPageLoading.value = false;
          usersList.refresh();
        }
      }).catchError((error) {
        debugPrint("Get User list error--> $error");
        toToast(error.toString());
      });
    } else {
      toToast(Constants.noInternetConnection);
    }
  }

  Future<List<Profile>> removeGroupMembers(List<Profile> items) async {
    var list = <Profile>[];
    for (var it in items) {
      var value = await Mirrorfly.isMemberOfGroup(
          groupJid.value.checkNull(), it.jid.checkNull());
      mirrorFlyLog("item", value.toString());
      if (value == null || !value) {
        list.add(it);
      }
    }
    return list;
  }

  get users => usersList;

  String imagePath(String? imgUrl) {
    if (imgUrl == null || imgUrl == "") {
      return "";
    }
    Mirrorfly.imagePath(imgUrl).then((value) {
      return value ?? "";
    });
    return "";
  }

  contactSelected(Profile item) {
    if (selectedUsersList.contains(item)) {
      selectedUsersList.remove(item);
      selectedUsersJIDList.remove(item.jid);
      //item.isSelected = false;
    } else {
      selectedUsersList.add(item);
      selectedUsersJIDList.add(item.jid!);
      //item.isSelected = true;
    }
    usersList.refresh();
  }

  forwardMessages(BuildContext context) async {
    if (await AppUtils.isNetConnected()) {
      Mirrorfly.forwardMessagesToMultipleUsers(
              forwardMessageIds, selectedUsersJIDList)
          .then((value) {
        debugPrint(
            "to chat profile ==> ${selectedUsersList[0].toJson().toString()}");
        // Get.back(result: selectedUsersList[0]);
        Navigator.pop(context, selectedUsersList[0]);
      });
    } else {
      toToast(Constants.noInternetConnection);
    }
  }

  onListItemPressed(Profile item, BuildContext context) {
    if (isForward.value || isCreateGroup.value) {
      if (item.isBlocked.checkNull()) {
        unBlock(item, context);
      } else {
        contactSelected(item);
      }
    } else {
      // mirrorFlyLog("Contact Profile", item.toJson().toString());
      // Get.toNamed(Routes.chat, arguments: item);
      Navigator.push(context, MaterialPageRoute(builder: (con) => ChatView(jid: item.jid!,isUser: true,)));

    }
  }

  unBlock(Profile item, BuildContext context) {
    Helper.showAlert(message: "Unblock ${getName(item)}?", actions: [
      TextButton(
          onPressed: () {
            // Get.back();
            Navigator.pop(context);
          },
          child: Text("NO", style: TextStyle(color: MirrorflyUikit.getTheme?.primaryColor),)),
      TextButton(
          onPressed: () async {
            if (await AppUtils.isNetConnected()) {
              // Get.back();
              Navigator.pop(context);
              Helper.progressLoading(context: context);
              Mirrorfly.unblockUser(item.jid.checkNull()).then((value) {
                Helper.hideLoading(context: context);
                if (value != null && value) {
                  toToast("${getName(item)} has been Unblocked");
                  userUpdatedHisProfile(item.jid.checkNull());
                }
              }).catchError((error) {
                Helper.hideLoading(context: context);
                debugPrint(error);
              });
            } else {
              toToast(Constants.noInternetConnection);
            }
          },
          child: Text("YES", style: TextStyle(color: MirrorflyUikit.getTheme?.primaryColor))),
    ], context: context);
  }

  backToCreateGroup(BuildContext context) async {
    if (await AppUtils.isNetConnected()) {
      /*if (selectedUsersJIDList.length >= Constants.minGroupMembers) {
        Get.back(result: selectedUsersJIDList);
      } else {
        toToast("Add at least two contacts");
      }*/
      if (groupJid.value.isEmpty) {
        if (selectedUsersJIDList.length >= Constants.minGroupMembers) {
          // Get.back(result: selectedUsersJIDList);
          if(context.mounted) Navigator.pop(context, selectedUsersJIDList);
        } else {
          toToast("Add at least two contacts");
        }
      } else {
        if (selectedUsersJIDList.isNotEmpty) {
          // Get.back(result: selectedUsersJIDList);
          if(context.mounted) Navigator.pop(context, selectedUsersJIDList);
        } else {
          toToast("Add at least two contacts");
        }
      }
    } else {
      toToast(Constants.noInternetConnection);
    }
    /*if(groupJid.value.isEmpty) {
      if (selectedUsersJIDList.length >= Constants.minGroupMembers) {
        Get.back(result: selectedUsersJIDList);
      } else {
        toToast("Add at least two contacts");
      }
    }else{
      if (selectedUsersJIDList.length >= Constants.minGroupMembers) {
        Get.back(result: selectedUsersJIDList);
      } else {
        toToast("Add at least two contacts");
      }
    }*/
  }

  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  var progressSpinner = false.obs;

  refreshContacts(bool isNetworkToastNeeded) async {
    if(!MirrorflyUikit.isTrialLicence) {
      mirrorFlyLog('Contact Sync', "[Contact Sync] refreshContacts()");
      if (await AppUtils.isNetConnected()) {
        if (!await Mirrorfly.contactSyncStateValue()) {
          var contactPermissionHandle = await AppPermission.checkPermission(context!,
              Permission.contacts, contactPermission,
              Constants.contactSyncPermission);
          if (contactPermissionHandle) {
            progressSpinner(true);
            Mirrorfly.syncContacts(!SessionManagement.isInitialContactSyncDone())
                .then((value) {
              progressSpinner(false);
              // viewModel.onContactSyncFinished(success)
              // viewModel.isContactSyncSuccess.value = true
              _first = true;
              fetchUsers(_searchText.isNotEmpty);
            });
          } /* else {
      MediaPermissions.requestContactsReadPermission(
      this,
      permissionAlertDialog,
      contactPermissionLauncher,
      null)
      val email = Utils.returnEmptyStringIfNull(SharedPreferenceManager.getString(Constants.EMAIL))
      if (ChatUtils.isContusUser(email))
      EmailContactSyncService.start()
      }*/
        } else {
          progressSpinner(true);
          mirrorFlyLog('Contact Sync',
              "[Contact Sync] Contact syncing is already in progress");
        }
      } else {
        if(isNetworkToastNeeded) {
          toToast(Constants.noInternetConnection);
        }
        // viewModel.onContactSyncFinished(false);
      }
    }
  }

  void onContactSyncComplete(bool result) {
    progressSpinner(false);
    _first = true;
    fetchUsers(_searchText.isNotEmpty,server: result);
  }

  @override
  void onDetached() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  FocusNode searchFocus = FocusNode();
  @override
  Future<void> onResumed() async {
    if (!MirrorflyUikit.isTrialLicence) {
      var status = await Permission.contacts.isGranted;
      if(status) {
        refreshContacts(false);
      }else{
        usersList.clear();
        usersList.refresh();
      }
    }
    if(search) {
      if (!KeyboardVisibilityController().isVisible) {
        if (searchFocus.hasFocus) {
          searchFocus.unfocus();
          Future.delayed(const Duration(milliseconds: 100), () {
            searchFocus.requestFocus();
          });
        }
      }
    }
  }

  void userDeletedHisProfile(String jid) {
    userUpdatedHisProfile(jid);
  }

  showProfilePopup(Rx<Profile> profile, BuildContext context){
    showQuickProfilePopup(context: context,
        // chatItem: chatItem,
        chatTap: () {
          // Get.back();
          Navigator.pop(context);
          onListItemPressed(profile.value, context);
        },
        callTap: () {},
        videoTap: () {},
        infoTap: () {
          // Get.back();
          Navigator.pop(context);
          if (profile.value.isGroupProfile ?? false) {
            // Get.toNamed(Routes.groupInfo, arguments: profile.value);
            Navigator.push(context, MaterialPageRoute(builder: (con) => GroupInfoView(jid: profile.value.jid.checkNull())));
          } else {
            // Get.toNamed(Routes.chatInfo, arguments: profile.value);
            Navigator.push(context, MaterialPageRoute(builder: (con)=> ChatInfoView(jid: profile.value.jid.checkNull())));
          }
        },profile: profile);
  }

  void userBlockedMe(String jid) {
    userUpdatedHisProfile(jid);
  }

  void unblockedThisUser(String jid) {
    userUpdatedHisProfile(jid);
  }
}
