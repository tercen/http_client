library http_client;

import 'dart:async';
import 'dart:convert';

class HttpClientError {
  int statusCode;
  String error;
  String reason;
  HttpClientError(this.statusCode, this.error, this.reason);
}

abstract class HttpClient {
  static HttpClient CURRENT;

  static void setCurrent(HttpClient client) {
    CURRENT = client;
  }
  
  static Uri ResolveUri(Uri uri, String path) {
      var ps = new List.from(uri.pathSegments)..addAll(path.split("/"));
      return uri.replace(pathSegments: ps);
    }

  factory HttpClient() {
    if (CURRENT == null) throw "HttpClient CURRENT == null";

    return CURRENT;
  }


  Uri resolveUri(Uri uri, String path);

/// Sends an HTTP HEAD request with the given headers to the given URL, which
/// can be a [Uri] or a [String].
///
/// For more fine-grained control over the request, use [send] instead.
  Future<Response> head(url, {Map<String, String> headers});

/// Sends an HTTP GET request with the given headers to the given URL, which
/// can be a [Uri] or a [String].
///
/// For more fine-grained control over the request, use [send] instead.
///
  /**
   * [String] telling the server the desired response format.
   *
   * Default is `String`.
   * Other options are one of 'arraybuffer', 'blob', 'document', 'json',
   * 'text'. Some newer browsers will throw NS_ERROR_DOM_INVALID_ACCESS_ERR if
   * `responseType` is set while performing a synchronous request.
   *
   * See also: [MDN responseType](https://developer.mozilla.org/en-US/docs/DOM/XMLHttpRequest#responseType)
   */
  Future<Response> get(url, {Map<String, String> headers, String responseType});

/// Sends an HTTP POST request with the given headers and body to the given
/// URL, which can be a [Uri] or a [String].
///
/// [body] sets the body of the request. It can be a [String], a [List<int>]
/// or a [Map<String, String>]. If it's a String, it's encoded using
/// [encoding] and used as the body of the request. The content-type of the
/// request will default to "text/plain".
///
/// If [body] is a List, it's used as a list of bytes for the body of the
/// request.
///
/// If [body] is a Map, it's encoded as form fields using [encoding]. The
/// content-type of the request will be set to
/// `"application/x-www-form-urlencoded"`; this cannot be overridden.
///
/// [encoding] defaults to [UTF8].
///
/// For more fine-grained control over the request, use [send] instead.
  Future<Response> post(url, {Map<String, String> headers, body, String responseType, Encoding encoding});

/// Sends an HTTP PUT request with the given headers and body to the given
/// URL, which can be a [Uri] or a [String].
///
/// [body] sets the body of the request. It can be a [String], a [List<int>]
/// or a [Map<String, String>]. If it's a String, it's encoded using
/// [encoding] and used as the body of the request. The content-type of the
/// request will default to "text/plain".
///
/// If [body] is a List, it's used as a list of bytes for the body of the
/// request.
///
/// If [body] is a Map, it's encoded as form fields using [encoding]. The
/// content-type of the request will be set to
/// `"application/x-www-form-urlencoded"`; this cannot be overridden.
///
/// [encoding] defaults to [UTF8].
///
/// For more fine-grained control over the request, use [send] instead.
  Future<Response> put(url, {Map<String, String> headers, body, String responseType, Encoding encoding});

/// Sends an HTTP DELETE request with the given headers to the given URL,
/// which can be a [Uri] or a [String].
///
/// For more fine-grained control over the request, use [send] instead.
  Future<Response> delete(url, {Map<String, String> headers});

/// Closes the client and cleans up any resources associated with it. It's
/// important to close each client when it's done being used; failing to do so
/// can cause the Dart process to hang.
  void close({bool force});
}

abstract class Response {
  int get statusCode;
  Map get headers;
  Object get body;
}

class ContentTypeHeaderValue {
  static const HEADER_CONTENT_TYPE = "content-type";
  static const UTF8CHARSET = "utf-8";
  static const JSON_CONTENT_TYPE = "application/json";

  static const Map JSON_HEADER = const {HEADER_CONTENT_TYPE: "$JSON_CONTENT_TYPE ; charset=$UTF8CHARSET"};

  static Map<String, String> getJsonHeader() => new Map.from(JSON_HEADER);

  static Map addJsonHeader(Map headers){
    headers[HEADER_CONTENT_TYPE] = "$JSON_CONTENT_TYPE ; charset=$UTF8CHARSET";
    return headers;
  }

  String contentType;
  Map params;

  ContentTypeHeaderValue.json(){
    params = {};
    contentType = JSON_CONTENT_TYPE;
    charset = UTF8CHARSET;
  }

  ContentTypeHeaderValue.fromString(String value){
    params = {};
    var list = value.split(";").toList();
    if (list.isEmpty) throw "ContentTypeHeader : wrong value $value";
    contentType = list.first;
    for (int i = 1 ; i < list.length ; i++){
      var param = list[i].trim();
      var ll = param.split("=").toList();
      if (ll.length != 2) throw "ContentTypeHeader : wrong param ${param}";
      params[ll.first] = ll[1];
    }
  }
//charset=utf-8
  String get charset => params["charset"];
  set charset(String c) {
    params["charset"] = c;
  }

  String toString(){
    var sb = new StringBuffer();
    sb..write(contentType);
    params.forEach((k,v)=>sb.write(";$k:$v"));
    return sb.toString();
  }
}