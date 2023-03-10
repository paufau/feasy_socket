import 'dart:async';
import 'dart:convert';

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

  makeConnection() async {
    try {
      print('reconnect');
      server = WebSocketChannel.connect(Uri.parse(
          '${options.protocol}://${options.address}:${options.port}'));

      await server.ready;

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

    server.stream.listen((event) {
      print('LISTEN');
      print(event);

      final feasyEvent = FeasyEvent.fromJson(jsonDecode(event));

      if (feasyEvent.type == FeasyEventType.HELLO) {
        connection.emitConnect();
      }

      if (feasyEvent.type == FeasyEventType.TRANSFER) {
        connection.emitDataTransfer(feasyEvent.data);
      }
    }, onDone: () {
      connection.emitDisconnect();
      makeConnection();
    }, onError: (e) {
      connection.emitDisconnect();
      makeConnection();
    });
  }

  Future init(void Function(FeasyConnection connection) onConnection) async {
    onConnectionListener = onConnection;
    makeConnection();
  }
}
