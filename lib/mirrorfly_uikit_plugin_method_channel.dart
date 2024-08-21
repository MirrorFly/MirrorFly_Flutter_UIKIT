import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mirrorfly_uikit_plugin_platform_interface.dart';

/// An implementation of [MirrorflyUikitPluginPlatform] that uses method channels.
class MethodChannelMirrorflyUikitPlugin extends MirrorflyUikitPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mirrorfly_uikit_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
