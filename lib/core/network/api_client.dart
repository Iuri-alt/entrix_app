import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Cliente HTTP da API Entrix (FastAPI no Render).
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required TokenStorage tokens,
    http.Client? httpClient,
  })  : _tokens = tokens,
        _http = httpClient ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'ENTRIX_API_URL',
    defaultValue: 'https://entrix-api.onrender.com',
  );

  /// O plano gratuito do Render "dorme"; o primeiro acesso pode levar ~1 minuto.
  static const _timeout = Duration(seconds: 75);

  final String baseUrl;
  final TokenStorage _tokens;
  final http.Client _http;

  /// Chamado quando o servidor recusa o token (sessão expirada).
  void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body}) => _send('PUT', path, body: body);

  Future<void> delete(String path) => _send('DELETE', path);

  Future<Uint8List> download(String path) async {
    final response = await _run(() async =>
        _http.get(_uri(path), headers: await _headers(json: false)));
    _ensureSuccess(response);
    return response.bodyBytes;
  }

  Future<dynamic> upload(
    String path, {
    required Uint8List bytes,
    required String filename,
    Map<String, String>? query,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path, query))
      ..headers.addAll(await _headers(json: false))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final response = await _run(() async => http.Response.fromStream(await _http.send(request)));
    return _decode(response);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool auth = true,
  }) async {
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(await _headers(auth: auth));
    if (body != null) request.body = jsonEncode(body);
    final response = await _run(() async => http.Response.fromStream(await _http.send(request)));
    return _decode(response);
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, String>> _headers({bool auth = true, bool json = true}) async {
    final token = auth ? await _tokens.read() : null;
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _run(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on TimeoutException {
      throw const ApiException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const ApiException('Sem conexão com o servidor. Verifique sua internet.');
    } on Exception catch (e) {
      // Ex.: falha de certificado (data do aparelho errada) ou erro de E/S.
      throw ApiException('Falha de comunicação com o servidor ($e).');
    }
  }

  dynamic _decode(http.Response response) {
    _ensureSuccess(response);
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ApiException('Resposta inválida do servidor. Tente novamente em instantes.');
    }
  }

  void _ensureSuccess(http.Response response) {
    final code = response.statusCode;
    if (code >= 200 && code < 300) return;
    if (code == 401) onUnauthorized?.call();
    throw ApiException(_errorMessage(response), statusCode: code);
  }

  static String _errorMessage(http.Response response) {
    try {
      final detail = (jsonDecode(utf8.decode(response.bodyBytes)) as Map)['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final msg = (detail.first as Map)['msg'] as String? ?? '';
        return msg.replaceFirst('Value error, ', '');
      }
    } catch (_) {
      // Corpo não é JSON: cai na mensagem genérica abaixo.
    }
    return switch (response.statusCode) {
      401 => 'Sessão expirada. Entre novamente.',
      404 => 'Registro não encontrado.',
      >= 500 => 'Erro no servidor. Tente novamente em instantes.',
      _ => 'Não foi possível concluir a operação (${response.statusCode}).',
    };
  }
}
