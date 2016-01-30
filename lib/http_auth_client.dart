library http_auth_client;

import 'dart:convert';
import 'dart:async';
import 'http_client.dart' as http;

abstract class HttpAuthBaseClient implements http.HttpClient {
  http.HttpClient _client;

  HttpAuthBaseClient([this._client]) {
    if (this._client == null) this._client = new http.HttpClient();
  }


  @override
  Uri resolveUri(Uri uri, String path) => http.HttpClient.ResolveUri(uri, path);

  Future addAuthHeader(Map headers);

  @override
  void close({bool force}) => _client.close(force:force);

  @override
  Future<http.Response> put(url, {Map<String, String> headers, body, Encoding encoding, String responseType}) {
    return addAuthHeader(headers).then((h) {
      return _client.put(url, headers: h, body: body, encoding: encoding);
    });
  }

  @override
  Future<http.Response> get(url, {Map<String, String> headers, String responseType}) {
    return addAuthHeader(headers).then((h) {
      return _client.get(url, headers: h, responseType: responseType);
    });
  }

  @override
  Future<http.Response> delete(url, {Map<String, String> headers}) {
    return addAuthHeader(headers).then((h) {
      return _client.delete(url, headers: h);
    });
  }

  @override
  Future<http.Response> head(url, {Map<String, String> headers}) {
    return addAuthHeader(headers).then((h) {
      return _client.head(url, headers: h);
    });
  }

  @override
  Future<http.Response> post(url, {Map<String, String> headers, body, Encoding encoding, String responseType}) {
    return addAuthHeader(headers).then((h) {
      return _client.post(url, headers: h, body: body, encoding: encoding, responseType: responseType);
    });
  }
}
