part of http_browser_client;

class HttpBrowserClient implements HttpClient {
   
  static bool IS_ASYNC = true;
  
  final log = new Logger("HttpBrowserClient");
  
  bool withCredentials;
    
  HttpBrowserClient({bool withCredentials:false}){
    this.withCredentials = withCredentials; 
  }

  
  Uri resolveUri(Uri uri, String path) => HttpClient.ResolveUri(uri, path);
  
  HttpRequest newRequest(){
    var request = new HttpRequest();
    return request;
  }
  
  void setHeaders(HttpRequest request, Map<String, String> headers){
    if (withCredentials){
      request.withCredentials = withCredentials;         
    }
    if (headers == null) return;
    headers.forEach((k,v)=>request.setRequestHeader(k, v));

  }

  Future<Response> reponseFromRequest(HttpRequest request){
    if (request.readyState == 4) return new Future.value(new BrowserResponse(request));
    var completer = new Completer();

    request.onLoad.listen((event){
      completer.complete(new BrowserResponse(request));
    });

    request.onError.listen((ProgressEvent evt){
      var error = new HttpClientError(500, "connection.unvailable","Host unreachable.");
      completer.completeError(error);
    });

    return completer.future;
  }

  Future<Response> head(url, {Map<String, String> headers}){
    log.finest("head $url $headers");
    var request = newRequest();
    request.open("HEAD", url.toString());
    setHeaders(request,headers);
    request.send();
    return reponseFromRequest(request);
  }
  
  void _openRequest(request, verb, url){
    request.open(verb, url.toString(), async: IS_ASYNC);
  }
  
  Future<Response> get(url, {Map<String, String> headers, body, String responseType, Encoding encoding: UTF8}){
    log.finest("get $url $headers");
    var request = newRequest();
    if (responseType != null) request.responseType = responseType;
    _openRequest(request, "GET", url.toString());
    setHeaders(request,headers);


    if (body != null) {
      var data;
      if (body is String) {
        data = body;
      } else if (body is List) {
        data = body;
      } else if (body is Map) {
        request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        data = mapToQuery(body, encoding: encoding);
      } else {
        throw new ArgumentError('Invalid request body "$body".');
      }
      request.send(data);
    } else {
      request.send();
    }

    return reponseFromRequest(request);
  }
  
  Future<Response> post(url, {Map<String, String> headers, body, String responseType, Encoding encoding: UTF8}){
    log.finest("post $url $headers");
    return this.putOrPost("POST", url, headers: headers, body: body, responseType: responseType , encoding: encoding);
  }
  
  Future<Response> putOrPost(String verb, url, {Map<String, String> headers, body, String responseType, Encoding encoding}){
    log.finest("$verb $url $headers");
    var request = newRequest();
    if (responseType != null) request.responseType = responseType;
    _openRequest(request, verb, url.toString());
    setHeaders(request,headers);
    var data;
    if (body != null) {
      if (body is String) {
        data = body;
      } else if (body is List) {
        data = body;
      } else if (body is Map) {
        request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
        data = mapToQuery(body, encoding: encoding);
      } else {
        throw new ArgumentError('Invalid request body "$body".');
      }
    } 
    request.send(data);
    return reponseFromRequest(request); 
  }
  
  Future<Response> put(url, {Map<String, String> headers, body, String responseType, Encoding encoding: UTF8}){
    return this.putOrPost("PUT", url, headers: headers, body: body , responseType: responseType , encoding: encoding);
  }
  
  Future<Response> delete(url, {Map<String, String> headers}){
    log.finest("delete $url $headers");
    var request = newRequest();
    _openRequest(request, "DELETE", url.toString());
    setHeaders(request,headers);
    request.send();
    return reponseFromRequest(request); 
  }
  
  void close({bool force}){
     
  }
  
  String mapToQuery(Map<String, String> map, {Encoding encoding}) {
    var pairs = <List<String>>[];
    map.forEach((key, value) =>
        pairs.add([Uri.encodeQueryComponent(key, encoding: encoding),
                   Uri.encodeQueryComponent(value, encoding: encoding)]));
    return pairs.map((pair) => "${pair[0]}=${pair[1]}").join("&");
  }
}

class BrowserResponse implements Response {
  HttpRequest request;
  BrowserResponse(this.request);
  int get statusCode=>request.status;
  Map get headers=>request.responseHeaders;
  Object get body=>request.response;
}