import 'package:test/test.dart';

class TestElement {
  final String title;
  final Future<void> Function() testFunction;

  TestElement(this.title, this.testFunction) : assert(title != null);


  void run({Function screenShot}) => test(title, () async {
        await screenShot("${title}_start");
        await testFunction();
        await screenShot("${title}_end");
      });
}
