import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/foundation.dart';
import '../models/cryptocurrency.dart';

class WebSocketService {
  static const String wsUrl = 'ws://localhost:8081/ws/crypto';
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  StreamController<Cryptocurrency?>? _priceUpdateController;
  StreamController<String>? _connectionStatusController;
  
  String? _currentSymbol;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 5);

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageController?.stream ?? const Stream.empty();
  Stream<Cryptocurrency?> get priceUpdateStream => _priceUpdateController?.stream ?? const Stream.empty();
  Stream<String> get connectionStatusStream => _connectionStatusController?.stream ?? const Stream.empty();
  
  bool get isConnected => _isConnected;
  String? get currentSymbol => _currentSymbol;

  /// Initialize WebSocket connection
  Future<void> connect() async {
    if (_isConnected) return;
    
    try {
      debugPrint('🔗 Connecting to WebSocket: $wsUrl');
      
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      _priceUpdateController = StreamController<Cryptocurrency?>.broadcast();
      _connectionStatusController = StreamController<String>.broadcast();
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleConnectionClosed,
      );
      
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStatusController?.add('connected');
      
      // Start ping timer to keep connection alive
      _startPingTimer();
      
      debugPrint('✅ WebSocket connected successfully');
      
    } catch (e) {
      debugPrint('❌ WebSocket connection failed: $e');
      _handleError(e);
    }
  }

  /// Subscribe to real-time updates for a cryptocurrency
  Future<void> subscribe(String symbol) async {
    if (!_isConnected) {
      await connect();
    }
    
    _currentSymbol = symbol.toLowerCase();
    
    final message = {
      'action': 'subscribe',
      'symbol': _currentSymbol,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _sendMessage(message);
    debugPrint('📡 Subscribed to real-time updates for $_currentSymbol');
  }

  /// Unsubscribe from current symbol
  void unsubscribe() {
    if (_isConnected && _currentSymbol != null) {
      final message = {
        'action': 'unsubscribe',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      _sendMessage(message);
      _currentSymbol = null;
      debugPrint('🔇 Unsubscribed from real-time updates');
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final Map<String, dynamic> data = json.decode(message);
      final String messageType = data['type'] ?? 'unknown';
      
      debugPrint('📨 Received WebSocket message: $messageType');
      
      // Emit to message stream
      _messageController?.add(data);
      
      switch (messageType) {
        case 'connected':
          debugPrint('✅ WebSocket connection confirmed');
          break;
          
        case 'subscribed':
          debugPrint('📡 Subscription confirmed for ${data['symbol']}');
          break;
          
        case 'initial_data':
        case 'price_update':
          _handlePriceUpdate(data);
          break;
          
        case 'error':
          debugPrint('❌ WebSocket error: ${data['message']}');
          break;
          
        case 'pong':
          // Ping/pong for connection health
          break;
          
        default:
          debugPrint('🤷 Unknown message type: $messageType');
      }
      
    } catch (e) {
      debugPrint('❌ Error parsing WebSocket message: $e');
    }
  }

  /// Handle price update messages
  void _handlePriceUpdate(Map<String, dynamic> data) {
    try {
      final cryptoData = data['data'];
      if (cryptoData != null) {
        final crypto = Cryptocurrency.fromJson(cryptoData);
        _priceUpdateController?.add(crypto);
        debugPrint('💰 Price update received for ${crypto.symbol}: \$${crypto.price?.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('❌ Error processing price update: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    _connectionStatusController?.add('error');
    
    // Attempt to reconnect
    _attemptReconnect();
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    debugPrint('🔌 WebSocket connection closed');
    _isConnected = false;
    _connectionStatusController?.add('disconnected');
    _stopPingTimer();
    
    // Attempt to reconnect
    _attemptReconnect();
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('❌ Max reconnection attempts reached');
      _connectionStatusController?.add('failed');
      return;
    }
    
    _reconnectAttempts++;
    final delay = Duration(seconds: reconnectDelay.inSeconds * _reconnectAttempts);
    
    debugPrint('🔄 Attempting to reconnect (${_reconnectAttempts}/$maxReconnectAttempts) in ${delay.inSeconds}s');
    _connectionStatusController?.add('reconnecting');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      await connect();
      
      // Re-subscribe if we had a symbol
      if (_currentSymbol != null) {
        await subscribe(_currentSymbol!);
      }
    });
  }

  /// Send message to WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = json.encode(message);
        _channel!.sink.add(jsonMessage);
      } catch (e) {
        debugPrint('❌ Error sending WebSocket message: $e');
      }
    }
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        _sendMessage({
          'action': 'ping',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  /// Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Disconnect WebSocket
  void disconnect() {
    debugPrint('🔌 Disconnecting WebSocket');
    
    _stopPingTimer();
    _reconnectTimer?.cancel();
    
    _channel?.sink.close();
    _channel = null;
    
    _messageController?.close();
    _priceUpdateController?.close();
    _connectionStatusController?.close();
    
    _messageController = null;
    _priceUpdateController = null;
    _connectionStatusController = null;
    
    _isConnected = false;
    _currentSymbol = null;
    _reconnectAttempts = 0;
  }

  /// Force refresh data for current symbol
  void forceRefresh() {
    if (_currentSymbol != null) {
      _sendMessage({
        'action': 'refresh',
        'symbol': _currentSymbol,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }
}
