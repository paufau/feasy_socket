// import 'dart:convert';

// import 'client/client_option.dart';
// import 'client/feasy_client.dart';
// import 'server/feasy_server.dart';

// void main(List<String> args) async {
//   await FeasyServer().init((connection) {
//     connection.onDataTransfer((data) {
//       print('Server data transfer $data');
//     });
//   });

//   await FeasyClient(options: ClientOptions(address: '192.168.1.34'))
//       .init(((connection) {
//     connection.send(jsonEncode({'my': 'field'}));

//     connection.onDisconnect(() {
//       print("List connection with server");
//     });
//   }));
// }
