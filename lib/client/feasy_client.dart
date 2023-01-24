import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:feasy_socket/client/client_option.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../shared/feasy_connection.dart';
import '../shared/feasy_event.dart';

class FeasyClient {
  FeasyClient({this.options = const ClientOptions(address: 'localhost')});

  late WebSocketChannel server;

  ClientOptions options;

  Future init(void Function(FeasyConnection connection) onConnection) async {
    server = WebSocketChannel.connect(
        Uri.parse('${options.protocol}://${options.address}:${options.port}'));
    final connection = FeasyConnection(id: Uuid().v4(), channel: server);

    onConnection(connection);

    connection.sendSystemEvent(FeasyEventType.HELLO);

    int lastResponseTime = 0;

    Timer.periodic(Duration(milliseconds: options.hearbeatIntervalMs), (timer) {
      int now = DateTime.now().millisecondsSinceEpoch;
      if (lastResponseTime > 0 &&
          now - lastResponseTime >
              options.hearbeatIntervalMs + options.heartbeatResponseTimeMs) {
        connection.emitDisconnect();
        timer.cancel();
      }
    });

    server.stream.listen((event) {
      lastResponseTime = DateTime.now().millisecondsSinceEpoch;
      final feasyEvent = FeasyEvent.fromJson(jsonDecode(event));

      if (feasyEvent.type == FeasyEventType.HEARTBEAT) {
        connection.sendSystemEvent(FeasyEventType.HEARTBEAT);
      }

      if (feasyEvent.type == FeasyEventType.HELLO) {
        connection.emitConnect();
      }

      if (feasyEvent.type == FeasyEventType.TRANSFER) {
        connection.emitDataTransfer(feasyEvent.data);
      }
    });
  }
}
