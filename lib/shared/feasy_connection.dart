import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'feasy_event.dart';

class FeasyConnection {
  FeasyConnection({required this.id, required this.channel});

  String id;
  WebSocketChannel channel;

  void Function()? _handleConnect;
  void Function()? _handleDisonnect;
  void Function(String? data)? _handleDataTransfer;

  bool isConnected = false;

  onConnect(void Function() handleConnect) {
    _handleConnect = handleConnect;
  }

  onDisconnect(void Function() handleDisonnect) {
    _handleDisonnect = handleDisonnect;
  }

  onDataTransfer(void Function(String? data) handleDataTransfer) {
    _handleDataTransfer = handleDataTransfer;
  }

  emitConnect() {
    if (!isConnected) {
      isConnected = true;
      if (_handleConnect != null) {
        _handleConnect!();
      }
    }
  }

  emitDisconnect() {
    if (isConnected) {
      isConnected = false;
      if (_handleDisonnect != null) {
        _handleDisonnect!();
      }
    }
  }

  emitDataTransfer(String? data) {
    if (_handleDataTransfer != null && isConnected) {
      _handleDataTransfer!(data);
    }
  }

  send(String? data) {
    if (isConnected) {
      channel.sink.add(jsonEncode(
          FeasyEvent(type: FeasyEventType.TRANSFER, data: data).toJson()));
    }
  }

  sendSystemEvent(String? type, {String? data}) {
    channel.sink.add(jsonEncode(FeasyEvent(type: type, data: data).toJson()));
  }
}
