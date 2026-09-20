import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../application/device_controller.dart';
import '../../domain/device/device_connection_status.dart';

enum ConnectionRecoveryStatus { connected, disconnected, reconnecting, failed }

final class ConnectionRecoveryState {
  const ConnectionRecoveryState({
    required this.status,
    this.returnToDiscovery = false,
  });

  const ConnectionRecoveryState.connected()
    : this(status: ConnectionRecoveryStatus.connected);

  const ConnectionRecoveryState.disconnected({bool returnToDiscovery = false})
    : this(
        status: ConnectionRecoveryStatus.disconnected,
        returnToDiscovery: returnToDiscovery,
      );

  const ConnectionRecoveryState.reconnecting()
    : this(status: ConnectionRecoveryStatus.reconnecting);

  const ConnectionRecoveryState.failed()
    : this(status: ConnectionRecoveryStatus.failed);

  final ConnectionRecoveryStatus status;
  final bool returnToDiscovery;

  bool get blocksDeviceActions => status != ConnectionRecoveryStatus.connected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionRecoveryState &&
          status == other.status &&
          returnToDiscovery == other.returnToDiscovery;

  @override
  int get hashCode => Object.hash(status, returnToDiscovery);
}

final connectionRecoveryControllerProvider = NotifierProvider.autoDispose
    .family<ConnectionRecoveryController, ConnectionRecoveryState, String>(
      ConnectionRecoveryController.new,
    );

final class ConnectionRecoveryController
    extends Notifier<ConnectionRecoveryState> {
  ConnectionRecoveryController(this.deviceId);

  final String deviceId;

  DeviceConnectionStatus? _connectionStatus;
  bool _intentionalDisconnect = false;
  bool _lossHandled = false;
  bool _reconnectCommandActive = false;
  bool _reconnectWaitingForCommand = false;

  @override
  ConnectionRecoveryState build() {
    ref
      ..listen(connectionStateProvider, _onConnectionChanged)
      ..listen(deviceControllerProvider, _onDeviceCommandChanged);

    _connectionStatus = ref.read(connectionStateProvider).value;
    final initialState = switch (_connectionStatus) {
      DeviceConnectionStatus.ready => const ConnectionRecoveryState.connected(),
      DeviceConnectionStatus.disconnected =>
        const ConnectionRecoveryState.disconnected(),
      _ => const ConnectionRecoveryState.connected(),
    };
    if (_connectionStatus == DeviceConnectionStatus.disconnected) {
      scheduleMicrotask(_handleUnexpectedDisconnect);
    }
    return initialState;
  }

  void retry() {
    if (_intentionalDisconnect || _reconnectCommandActive) return;
    if (state.status != ConnectionRecoveryStatus.failed &&
        state.status != ConnectionRecoveryStatus.disconnected) {
      return;
    }
    _startReconnect();
  }

  void disconnectIntentionally() {
    if (_intentionalDisconnect) return;
    _intentionalDisconnect = true;
    _lossHandled = true;
    _reconnectCommandActive = false;
    _reconnectWaitingForCommand = false;
    state = const ConnectionRecoveryState.disconnected(returnToDiscovery: true);
    ref.read(deviceControllerProvider.notifier).disconnect();
  }

  void returnToDiscovery() => disconnectIntentionally();

  void _onConnectionChanged(
    AsyncValue<DeviceConnectionStatus>? previous,
    AsyncValue<DeviceConnectionStatus> next,
  ) {
    if (!ref.mounted) return;
    if (next.hasError) {
      if (_reconnectCommandActive || _reconnectWaitingForCommand) {
        _failRecovery();
      }
      return;
    }

    final nextStatus = next.value;
    if (nextStatus == null || nextStatus == _connectionStatus) return;
    _connectionStatus = nextStatus;

    switch (nextStatus) {
      case DeviceConnectionStatus.ready:
        if (_intentionalDisconnect) return;
        _lossHandled = false;
        _reconnectCommandActive = false;
        _reconnectWaitingForCommand = false;
        state = const ConnectionRecoveryState.connected();
      case DeviceConnectionStatus.disconnected:
        if (_intentionalDisconnect) {
          state = const ConnectionRecoveryState.disconnected(
            returnToDiscovery: true,
          );
          return;
        }
        _handleUnexpectedDisconnect();
      case DeviceConnectionStatus.error:
        if (_reconnectCommandActive || _reconnectWaitingForCommand) {
          _failRecovery();
        }
      case DeviceConnectionStatus.connecting ||
          DeviceConnectionStatus.discovering ||
          DeviceConnectionStatus.reconnecting:
        if (_reconnectCommandActive || _reconnectWaitingForCommand) {
          state = const ConnectionRecoveryState.reconnecting();
        }
      case DeviceConnectionStatus.idle ||
          DeviceConnectionStatus.scanning ||
          DeviceConnectionStatus.disconnecting:
        break;
    }
  }

  void _handleUnexpectedDisconnect() {
    if (!ref.mounted || _intentionalDisconnect || _lossHandled) return;
    _lossHandled = true;
    state = const ConnectionRecoveryState.disconnected();
    _startReconnect();
  }

  void _startReconnect() {
    if (!ref.mounted || _intentionalDisconnect || _reconnectCommandActive) {
      return;
    }
    state = const ConnectionRecoveryState.reconnecting();
    if (ref.read(deviceControllerProvider).isLoading) {
      _reconnectWaitingForCommand = true;
      return;
    }
    _reconnectWaitingForCommand = false;
    _reconnectCommandActive = true;
    ref.read(deviceControllerProvider.notifier).connect(deviceId);
  }

  void _onDeviceCommandChanged(
    AsyncValue<void>? previous,
    AsyncValue<void> next,
  ) {
    if (!ref.mounted || _intentionalDisconnect) return;
    if (_reconnectWaitingForCommand && !next.isLoading) {
      _startReconnect();
      return;
    }
    if (!_reconnectCommandActive || previous?.isLoading != true) return;
    if (next.hasError) _failRecovery();
  }

  void _failRecovery() {
    _reconnectCommandActive = false;
    _reconnectWaitingForCommand = false;
    state = const ConnectionRecoveryState.failed();
  }
}
