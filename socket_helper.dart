import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobifone_meet/mbf_meet.dart';
import '../config/config.dart';
import '../config/globals.dart';
import '../screen/calling.dart';
import '../screen/contacts.dart';
import '../screen/waiting.dart';
import 'package:socket_io_client/socket_io_client.dart';

class Singleton {
  static final Singleton _singleton = Singleton._internal();

  factory Singleton() {
    return _singleton;
  }

  Singleton._internal();

  Socket socket = io(
      Config().socketUrl,
      OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'jwt': Config().jwt_token})
          .build());

  void connectServer(context) {
    socket.connect();

    socket.onConnect((data) {
      print("onConnect");
    });

    socket.onDisconnect((data) {
      print("onDisconnect");
    });

    socket.on(Config().SOCKET_EVENT_MISS_CALL, (data) {
      print("MISS");
      pushToContactScreenFunction(context);
      // Navigator.pop(context);
    });

    socket.on("NewRoomA", (data) {
      data.forEach((key, value) {
        if (key == "call_id") {
          call_id = value;
        }
        if (key == "fromUserName") {
          fromUserName = value;
        }
      });
    });

    socket.on("NewRoomB", (data) {
      data.forEach((key, value) {
        if (key == "call_id") {
          call_id = value;
        }
        if (key == "fromUserName") {
          fromUserName = value;
        }
      });
      pushToCallingScreen(context);
      // print("NewRoomA $call_id");
    });

    socket.on("CancelCall", (data) {
      pushToContactScreenFunction(context);
      print("CancelCall");
    });

    socket.on("RejectCall", (data) {
      print("RejectCall");
      pushToContactScreenFunction(context);
      // Navigator.pop(context);
      // socketDelegate?.onRejectCallAction(context);
    });

    socket.on("AcceptCall", (data) {
      print("AcceptCall");
      pushToContactScreenFunction(context);
      if (!isCall) {
        joinMeeting();
      }
    });

    socket.on("CALL_ENDED", (data) {
      MBFMeet.closeMeeting();
      socket.emit("leave room");
      isCall = false;
      pushToContactScreenFunction(context);
    });
  }

  joinMeeting() async {
    // Enable or disable any feature flag here
    // If feature flag are not provided, default values will be used
    // Full list of feature flags (and defaults) available in the README
    Map<FeatureFlagEnum, bool> featureFlags = {
      FeatureFlagEnum.WELCOME_PAGE_ENABLED: false,
    };
    if (true) {
      // Here is an example, disabling features for each platform
      if (Platform.isAndroid) {
        // Disable ConnectionService usage on Android to avoid issues (see README)
        featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      } else if (Platform.isIOS) {
        // Disable PIP on iOS as it looks weird
        featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      }
      //config off redundant function
      featureFlags[FeatureFlagEnum.ADD_PEOPLE_ENABLED] = false;
      featureFlags[FeatureFlagEnum.CALENDAR_ENABLED] = false;
      featureFlags[FeatureFlagEnum.CALL_INTEGRATION_ENABLED] = false;
      featureFlags[FeatureFlagEnum.CLOSE_CAPTIONS_ENABLED] = false;
      featureFlags[FeatureFlagEnum.INVITE_ENABLED] = false;
      featureFlags[FeatureFlagEnum.IOS_RECORDING_ENABLED] = false;
      featureFlags[FeatureFlagEnum.MEETING_NAME_ENABLED] = false;
      featureFlags[FeatureFlagEnum.MEETING_PASSWORD_ENABLED] = false;
      featureFlags[FeatureFlagEnum.PIP_ENABLED] = false;
      featureFlags[FeatureFlagEnum.RAISE_HAND_ENABLED] = false;
      featureFlags[FeatureFlagEnum.RECORDING_ENABLED] = false;
      featureFlags[FeatureFlagEnum.TILE_VIEW_ENABLED] = false;
      featureFlags[FeatureFlagEnum.TOOLBOX_ALWAYS_VISIBLE] = false;
      featureFlags[FeatureFlagEnum.WELCOME_PAGE_ENABLED] = false;
    }
    // Define meetings options here
    // thanh
    isCall = true;
    call_id = "322612779";
    var options = MBFMeetingOptions(room: call_id)
      ..serverURL = serverString
      ..token = tokenString
      ..subject = ""
      ..userDisplayName = call_id
      ..userEmail = ""
      ..iosAppBarRGBAColor = ""
      ..featureFlags.addAll(featureFlags)
      ..webOptions = {
        "roomName": call_id,
        "width": "100%",
        "height": "100%",
        "enableWelcomePage": false,
        "chromeExtensionBanner": null,
        "userInfo": {"displayName": call_id}
      };

    debugPrint("JitsiMeetingOptions: $options");
    await MBFMeet.joinMeeting(
      options,
      listener: MBFMeetingListener(
          onConferenceWillJoin: (message) {
            debugPrint("${options.room} will join with message: $message");
          },
          onConferenceJoined: (message) {
            debugPrint("${options.room} joined with message: $message");
          },
          onConferenceTerminated: (message) {
            debugPrint("${options.room} terminated with message: $message");
            socket.emit('leave room');
          },
          genericListeners: [
            MBFGenericListener(
                eventName: 'readyToClose',
                callback: (dynamic message) {
                  debugPrint("readyToClose callback");
                }),
          ]),
    );
  }
}

pushToCallingScreen(context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => CallingScreen()));
}

pushToWaitingScreen(context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => WaitingScreen()));
}

pushToContactScreenFunction(context) {
  Navigator.push(
      context, MaterialPageRoute(builder: (context) => ContactScreen()));
}
