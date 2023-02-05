import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../shared/feasy_connection.dart';
import '../shared/feasy_event.dart';

import 'package:shelf/shelf_io.dart' as shelf_io;

class FeasyServer {
  Map<String, FeasyConnection> _savedConnections = {};

  Future<HttpServer> init(
      void Function(FeasyConnection connection) onConnection) async {
    var handler = webSocketHandler((WebSocketChannel socket) {
      int pingIntervalMs = 5000;
      int pingResponseTime = 15000;
      int lastResponseTime = 0;

      runHeartbeat(FeasyConnection connection) {
        Timer.periodic(Duration(milliseconds: pingIntervalMs), (timer) {
          int now = DateTime.now().millisecondsSinceEpoch;
          if (lastResponseTime > 0 &&
              now - lastResponseTime > pingIntervalMs + pingResponseTime) {
            connection.emitDisconnect();
            timer.cancel();
          } else {
            connection.sendSystemEvent(FeasyEventType.HEARTBEAT);
          }
        });
      }

      var connection;

      socket.stream.listen((event) {
        lastResponseTime = DateTime.now().millisecondsSinceEpoch;

        final feasyEvent = FeasyEvent.fromJson(jsonDecode(event));

        if (feasyEvent.type == FeasyEventType.HELLO) {
          final connectionId = feasyEvent.data;

          if (connectionId == null) {
            throw Exception('No connection id found');
          }

          final savedConnection = _savedConnections[connectionId];

          if (savedConnection == null) {
            connection = FeasyConnection(id: connectionId, channel: socket);
            _savedConnections[connectionId] = connection;
            onConnection(connection);

            runHeartbeat(connection);

            connection.sendSystemEvent(FeasyEventType.HELLO);
            connection.emitConnect();
          } else {
            savedConnection.emitDisconnect();
            savedConnection.channel = socket;
            savedConnection.channel.changeStream((e) => socket.stream);
            savedConnection.channel.changeSink((p0) => socket.sink);
            savedConnection.emitConnect();
          }
        }

        if (connection != null) {
          if (feasyEvent.type == FeasyEventType.TRANSFER) {
            connection.emitDataTransfer(feasyEvent.data);
          }
        }
      });
    });

    final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8082);
    print('Serving at ws://${server.address.host}:${server.port}');

    return server;
  }
}
