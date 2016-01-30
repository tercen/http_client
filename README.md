http_client
==============

Unique interface.

## using io

``` dart
import 'package:http_client/http_io_client.dart';

void main() {
  var client = new HttpIOClient();

  client.get("https://tercen.com").then((res) {
    print(res.statusCode);
    print(res.headers);
    print(res.body);
  });
}
```


## using browser

``` dart
import 'dart:html';
import 'package:http_client/http_browser_client.dart';

void main() {
  var client = new HttpBrowserClient();

  client.get("test.txt").then((res) {
    document.body.text =
        "statusCode : ${res.statusCode} , headers : ${res.headers} , body : ${res.body}";
  });
}

```