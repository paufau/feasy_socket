class ClientOptions {
  const ClientOptions(
      {required this.address,
      this.port = 8082,
      this.protocol = 'ws',
      this.reconnectIntervalMs = 5000,
      this.hearbeatIntervalMs = 5000,
      this.heartbeatResponseTimeMs = 15000});

  final int reconnectIntervalMs;
  final int hearbeatIntervalMs;
  final int heartbeatResponseTimeMs;
  final String address;
  final String protocol;
  final int port;
}
