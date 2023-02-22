import 'package:feasy_socket/client/feasy_client.dart';

void main() async {
  await FeasyClient().init((connection) {
    connection.onConnect(() {
      print('Client: connected ${connection.id}');
    });

    connection.onDisconnect(() {
      print('Client: disconnected ${connection.id}');
    });

    connection.onDataTransfer((data) {
      print('Client: data ${connection.id} - $data');
    });
  });
}
