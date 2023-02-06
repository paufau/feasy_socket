class FeasyEventListeners<T extends Function> {
  List<T> listeners = [];

  addListener(T listener) {
    listeners.add(listener);

    return () {
      listeners.remove(listener);
    };
  }

  callListeners({dynamic data}) {
    for (var listener in listeners) {
      listener(data);
    }
  }
}
