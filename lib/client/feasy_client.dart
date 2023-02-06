import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:feasy_socket/client/client_option.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../shared/feasy_connection.dart';
import '../shared/feasy_event.dart';

class FeasyClient {
  FeasyClient({this.options = const ClientOptions(address: 'localhost')});

  late WebSocketChannel server;

  ClientOptions options;

  makeConnection() {
    try {
      print('reconnect');
      server = WebSocketChannel.connect(Uri.parse(
          '${options.protocol}://${options.address}:${options.port}'));

      print(server.closeReason);

      if (onConnectionListener != null) {
        passListener(onConnectionListener!);
      }
    } catch (e) {
      Timer(Duration(milliseconds: options.reconnectIntervalMs), () {
        makeConnection();
      });
    }
  }

  void Function(FeasyConnection connection)? onConnectionListener;

  passListener(void Function(FeasyConnection connection) onConnection) async {
    await GetStorage.init();

    var connectionId = GetStorage().read<String>('_connection_id');

    if (connectionId == null) {
      connectionId = Uuid().v4();
      GetStorage().write('_connection_id', connectionId);
    }

    print(connectionId);

    final connection = FeasyConnection(id: connectionId, channel: server);

    onConnection(connection);

    connection.sendSystemEvent(FeasyEventType.HELLO, data: connectionId);

    int lastResponseTime = 0;

    Timer.periodic(Duration(milliseconds: options.hearbeatIntervalMs), (timer) {
      int now = DateTime.now().millisecondsSinceEpoch;
      if (lastResponseTime > 0 &&
          now - lastResponseTime >
              options.hearbeatIntervalMs + options.heartbeatResponseTimeMs) {
        connection.emitDisconnect();
        timer.cancel();
        makeConnection();
      }
    });

    server.stream.listen((event) {
      print('LISTEN');
      print(event);

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

  Future init(void Function(FeasyConnection connection) onConnection) async {
    onConnectionListener = onConnection;
    makeConnection();
  }
}
