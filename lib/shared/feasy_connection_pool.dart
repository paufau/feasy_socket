import 'feasy_connection.dart';

class FeasyConnectionPool {
  FeasyConnectionPool();

  final List<FeasyConnection> _pool = [];

  FeasyConnectionPool broadcast(String? event) {
    _pool.map((c) => c.send(event));
    return this;
  }

  FeasyConnectionPool remove(FeasyConnection connection) {
    _pool.remove(connection);
    return this;
  }

  FeasyConnectionPool add(FeasyConnection connection) {
    _pool.add(connection);
    return this;
  }
}
