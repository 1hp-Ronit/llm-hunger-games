import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class WebSocketService{
  WebSocketChannel? _channel;


  // Stream that exposes the incoming messages as parsed maps
  Stream<Map<String, dynamic>> connect(int gameId){
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws/game/$gameId'));

    return _channel!.stream.map((message) => jsonDecode(message) as Map<String, dynamic>);
  }
  void disconnect(){
    _channel?.sink.close();
  }

}