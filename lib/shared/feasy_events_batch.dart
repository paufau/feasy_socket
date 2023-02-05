import 'package:feasy_socket/shared/feasy_connection_pool.dart';

class FeasyEventsBatch {
  FeasyEventsBatch({required this.pool});

  FeasyConnectionPool pool;

  List<void Function()> queue = [];

  rebind(FeasyConnectionPool pool) {
    this.pool = pool;
  }

  add(Function(FeasyConnectionPool pool) executor) {
    queue.add(() => executor(pool));
  }

  clean() {
    queue = [];
  }

  release() {
    for (var callback in queue) {
      callback();
    }

    clean();
  }

  FeasyEventsBatch merge(FeasyEventsBatch batch) {
    queue.addAll(batch.queue);
    pool = batch.pool;
    return this;
  }
}
