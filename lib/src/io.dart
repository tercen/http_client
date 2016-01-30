part of http_client_io;

class BaseClientImpl extends http.BaseClient {
  http.Client _client;

  http.Client get client {
    if (_client == null) _client = new http.Client();
    return _client;
  }

  bool _followRedirects = false;
  BaseClientImpl({bool followRedirects: false}) {
    _followRedirects = followRedirects;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.followRedirects = _followRedirects;
    request.maxRedirects = 5;
    return client.send(request);
  }

//X509Certificate
  set badCertificateCallback(bool callback(cert, String host, int port)) {
    InstanceMirror myClassInstanceMirror = reflect(client);
    var _inner =
        MirrorSystem.getSymbol('_inner', myClassInstanceMirror.type.owner);
    var ioclientmirror = myClassInstanceMirror.getField(_inner);
    ioclientmirror.setField(#badCertificateCallback, callback);
  }

  void close() {
    if (_client != null) {
      _client.close();
      _client = null;
    }
  }
}

class LoadBalancerBaseClientImpl extends BaseClientImpl {
  List<Uri> _uris;
  List<Uri> _failedUri = [];
  int _uriIndex;
  Timer _timer;

  LoadBalancerBaseClientImpl(List<Uri> list, {bool followRedirects: false})
      : super(followRedirects: followRedirects) {
    uris = list;
    _timer = new Timer.periodic(new Duration(seconds: 5), _onTimer);
  }

  set uris(List<Uri> list) {
    _uris = list;
    _uriIndex = 0;
    _failedUri = [];
  }

  int get _maxRetry => _uris.length + _failedUri.length;

  void close() {
    super.close();
    if (_timer != null) _timer.cancel();
    _timer = null;
  }

  _onTimer(Timer t) {
    _uris.addAll(_failedUri);
    _failedUri = [];
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _send(request, 0);
  }

  Future<http.StreamedResponse> _send(http.BaseRequest request, int retry) {
    var currentUri;
    return new Future.sync(() {
      var uri = getLoadBalancedRequest(request);
      var i = _uriIndex - 1;
      currentUri = _uris[i];
      return super.send(uri);
    }).catchError((e) {
      if (e is iolib.SocketException) {
        var failedUri = currentUri;
        _failedUri.add(failedUri);
        _uris.remove(failedUri);
        if (retry < _maxRetry) {
          return _send(request, retry++);
        } else
          throw e;
      }
    });
  }

  http.BaseRequest getLoadBalancedRequest(http.BaseRequest request) {
    if (_uris == null || _uris.isEmpty) return request;
    http.Request req =
        new http.Request(request.method, getLoadBalancedUri(request.url));

    req.persistentConnection = request.persistentConnection;
    req.followRedirects = request.followRedirects;

    req.maxRedirects = request.maxRedirects;
    request.headers.forEach((k, v) {
      req.headers[k] = v;
    });

    if (request is http.Request) {
      req.encoding = request.encoding;
      req.bodyBytes = request.bodyBytes;
    }

    return req;
  }

  Uri getLoadBalancedUri(Uri requestUri) {
    if (_uris == null || _uris.isEmpty) return requestUri;
    if (_uriIndex >= _uris.length) _uriIndex = 0;
    var answer = _uris[_uriIndex];
    answer = requestUri.replace(host: answer.host, port: answer.port);
    _uriIndex++;
    return answer;
  }
}

class HttpIOClient implements HttpClient {
  final log = new Logger("HttpIOClient");

  static void setAsCurrent() {
    HttpClient.setCurrent(new HttpIOClient());
  }

  BaseClientImpl client;

  factory HttpIOClient({bool followRedirects: true}) {
    return new HttpIOClient._(
        new BaseClientImpl(followRedirects: followRedirects));
  }

  HttpIOClient._(this.client);

  Uri resolveUri(Uri uri, String path) => HttpClient.ResolveUri(uri, path);

  set badCertificateCallback(bool callback(cert, String host, int port)) {
    client.badCertificateCallback = callback;
  }

  Future<Response> head(url, {Map<String, String> headers}) {
    return client
        .head(url, headers: headers)
        .then((rep) => new IOResponse(rep));
  }

  Future<Response> get(url,
      {Map<String, String> headers,
      body,
      String responseType,
      Encoding encoding: UTF8}) {
    if (body != null) {
      var uri = url is Uri ? url : Uri.parse(url);
      var request = new http.Request("GET", uri);
      if (body != null) request.body = body;
      if (headers != null) {
        request.headers.addAll(headers);
      }
      if (encoding != null) {
        request.encoding = encoding;
      }
      return client
          .send(request)
          .then(http.Response.fromStream)
          .then((response) {
        return new IOResponse(response, responseType: responseType);
      });
    } else {
      return client
          .get(url, headers: headers)
          .then((rep) => new IOResponse(rep, responseType: responseType));
    }
  }

  Future<Response> post(url,
      {Map<String, String> headers,
      body,
      String responseType,
      Encoding encoding: UTF8}) {
    return client
        .post(url, headers: headers, body: body, encoding: encoding)
        .then((rep) => new IOResponse(rep));
  }

  Future<Response> put(url,
      {Map<String, String> headers,
      body,
      String responseType,
      Encoding encoding: UTF8}) {
    return client
        .put(url, headers: headers, body: body, encoding: encoding)
        .then((rep) => new IOResponse(rep));
  }

  Future<Response> delete(url, {Map<String, String> headers}) {
    return client
        .delete(url, headers: headers)
        .then((rep) => new IOResponse(rep));
  }

  void close({bool force}) {
    if (force != null && force) client.close();
  }

  Future<Response> search(url,
      {Map<String, String> headers,
      body,
      String responseType,
      Encoding encoding}) {
    var uri = url is Uri ? url : Uri.parse(url);
    var request = new http.Request("SEARCH", uri);
    if (body != null) request.body = body;
    if (headers != null) {
      request.headers.addAll(headers);
    }
    if (encoding != null) {
      request.encoding = encoding;
    }
    return client.send(request).then(http.Response.fromStream).then((response) {
      return new IOResponse(response, responseType: responseType);
    });
  }
}

class IOResponse extends Response {
  http.Response response;
  String responseType;

  IOResponse(this.response, {String responseType}) {
    this.responseType = responseType;
  }

  int get statusCode => response.statusCode;
  Map get headers => response.headers;
  Object get body {
    if (responseType == "arraybuffer") return response.bodyBytes;
    return response.body;
  }
}
