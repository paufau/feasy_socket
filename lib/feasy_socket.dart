import 'dart:async';
import 'dart:io';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class FeasyEventType {
  static String CONNECTED = "CONNECTED";
  static String DISCONNECTED = "DISCONNECTED";
  static String PING = "PING";
  static String PONG = "PONG";
}

class FeasySocketServer {
  init(void Function(String type, dynamic data) onEvent) {
    var handler = webSocketHandler((WebSocketChannel socket) {
      bool isConnected = false;

      int pingIntervalMs = 5000;
      int pingTTA = 15000;
      int lastPing = 0;

      Timer.periodic(Duration(milliseconds: pingIntervalMs), (timer) {
        int now = DateTime.now().millisecondsSinceEpoch;
        if (lastPing > 0 && now - lastPing > pingIntervalMs + pingTTA) {
          onEvent(FeasyEventType.DISCONNECTED, null);
          timer.cancel();
        } else {
          socket.sink.add(FeasyEventType.PING);
        }
      });

      socket.stream.listen((event) {
        print(event);

        if (!isConnected) {
          isConnected = true;
          onEvent(FeasyEventType.CONNECTED, null);
        }

        if (event == FeasyEventType.PONG) {
          lastPing = DateTime.now().millisecondsSinceEpoch;
        }
      });
    });

    shelf_io.serve(handler, InternetAddress.anyIPv4, 8082).then((server) {
      print('Serving at ws://${server.address.host}:${server.port}');
    });
  }
}
