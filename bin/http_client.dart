import 'package:http_client/http_io_client.dart';

void main() {
  var client = new HttpIOClient();

  client.get("https://tercen.com").then((res) {
    print(res.statusCode);
    print(res.headers);
    print(res.body);
  });
}
