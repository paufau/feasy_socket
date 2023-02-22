import 'package:feasy_socket/server/feasy_server.dart';

void main() async {
  await FeasyServer().init((connection) {
    connection.onConnect(() {
      print('Server: connected ${connection.id}');
    });

    connection.onDisconnect(() {
      print('Server: disconnected ${connection.id}');
    });

    connection.onDataTransfer((data) {
      print('Server: data ${connection.id} - $data');
    });
  });
}
