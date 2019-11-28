import 'package:test/test.dart';

class TestElement {
  final String title;
  final Future<void> Function() testFunction;

  TestElement(this.title, this.testFunction) : assert(title != null);

  String get formattedTitle => title.toLowerCase().replaceAll(" ", "_");

  void run({Function screenShot, Function(Function, String) traceAction}) =>
      test(title, () async {
        await screenShot("${title}_start");
        await traceAction(testFunction, formattedTitle);
        await screenShot("${title}_end");
      });
}
