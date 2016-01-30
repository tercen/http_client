import 'dart:html';
import 'package:http_client/http_browser_client.dart';

void main() {
  var client = new HttpBrowserClient();

  client.get("test.txt").then((res) {
    document.body.text =
        "statusCode : ${res.statusCode} , headers : ${res.headers} , body : ${res.body}";
  });
}
