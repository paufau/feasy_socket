import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../shared/feasy_connection.dart';
import '../shared/feasy_event.dart';

class FeasyServer {
  Future<HttpServer> init(
      void Function(FeasyConnection connection) onConnection) async {
    var handler = webSocketHandler((WebSocketChannel socket) {
      FeasyConnection? connection;

      socket.stream.listen((event) {
        final feasyEvent = FeasyEvent.fromJson(jsonDecode(event));

        if (feasyEvent.type == FeasyEventType.HELLO) {
          final connectionId = feasyEvent.data;

          if (connectionId == null) {
            throw Exception('No connection id found');
          }

          connection = FeasyConnection(id: connectionId, channel: socket);

          onConnection(connection!);

          connection!.sendSystemEvent(FeasyEventType.HELLO);
          connection!.emitConnect();
        }

        if (connection != null) {
          if (feasyEvent.type == FeasyEventType.TRANSFER) {
            connection!.emitDataTransfer(feasyEvent.data);
          }
        }
      }, onDone: () {
        if (connection != null) {
          connection!.emitDisconnect();
        }
      }, onError: (e) {
        if (connection != null) {
          connection!.emitDisconnect();
        }
      });
    }, pingInterval: const Duration(seconds: 5));

    final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8082);
    print('Serving at ws://${server.address.host}:${server.port}');

    return server;
  }
}
