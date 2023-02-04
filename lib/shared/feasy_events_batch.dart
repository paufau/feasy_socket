import 'package:feasy_socket/shared/feasy_connection_pool.dart';

class FeasyEventsBatch {
  FeasyEventsBatch({required this.pool});

  FeasyConnectionPool pool;

  List<void Function(FeasyConnectionPool pool)> queue = [];

  rebind(FeasyConnectionPool pool) {
    this.pool = pool;
  }

  add(Function(FeasyConnectionPool pool) executor) {
    queue.add(executor);
  }

  release() {
    queue.map((e) => e(pool));
    queue = [];
  }
}
