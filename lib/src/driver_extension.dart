import 'package:meta/meta.dart';
import 'package:flutter_driver/flutter_driver.dart';

enum FinderType {
  type,
  text,
  key,
  semanticsLabel,
  tooltip,
}

enum TapType {
  tap,
  doubleTap,
  longPress,
}

class DriverExtension {
  FlutterDriver _driver;
  SerializableFinder currentScreenFinder;
  double dyOffset = 0;
  double dxOffset = 0;

  DriverExtension._(this._driver) : assert(_driver != null);

  FlutterDriver get driver => _driver;

  static Future<DriverExtension> connect({
    String dartVmServiceUrl,
    bool printCommunication = false,
    bool logCommunicationToFile = true,
    int isolateNumber,
    Pattern fuchsiaModuleTarget,
  }) async {
    final FlutterDriver driver = await FlutterDriver.connect(
        dartVmServiceUrl: dartVmServiceUrl,
        printCommunication: printCommunication,
        isolateNumber: isolateNumber,
        fuchsiaModuleTarget: fuchsiaModuleTarget);
    return DriverExtension._(driver);
  }

  Future<void> close() async {
    await _driver.close();
  }

  Future<void> findWidgetOnScreen(
    SerializableFinder scrollable,
    SerializableFinder item, {
    double alignment = 0.0,
    double dxScroll = 0.0,
    double dyScroll = -400.0,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    assert(scrollable != null);
    assert(item != null);
    assert(alignment != null);
    assert(dxScroll != null);
    assert(dyScroll != null);
    assert((dxScroll != 0.0 && dyScroll == 0.0) ||
        (dxScroll == 0.0 && dyScroll != 0.0));
    assert(dxScroll != 0.0 || dyScroll != 0.0);

    bool isVisible = false;
    await resetScreenScrollPosition(scrollable,
        dy: dyOffset <= 0 ? 10000 : dyOffset);

    _driver.waitFor(item, timeout: timeout).then<void>((_) {
      isVisible = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));

    if(!isVisible) {
      // try to wait for another 2 seconds and find widget if
      // scrolling on top is taking to long
      await Future<void>.delayed(const Duration(milliseconds: 2000));
    }

    while (!isVisible) {
      await _driver.scroll(
          scrollable, dxScroll, dyScroll, const Duration(milliseconds: 50),
          timeout: timeout);
      dyOffset += dyScroll + (dyScroll < 0 ? -300 : 300);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    await _driver.scrollIntoView(item, alignment: alignment);
  }

  Future<void> resetScreenScrollPosition(SerializableFinder scrollable,
      {double dx = 0, double dy = 10000}) async {
    await _driver.scroll(scrollable, dx, dy, const Duration(milliseconds: 500),
        timeout: Duration(seconds: 30));
    dyOffset = 0;
    dxOffset = 0;
  }

  SerializableFinder _getAppropriateFinder(FinderType type, String target) {
    switch (type) {
      case FinderType.type:
        return find.byType(target);
        break;
      case FinderType.text:
        return find.text(target);
        break;
      case FinderType.key:
        return find.byValueKey(target);
        break;
      case FinderType.semanticsLabel:
        return find.bySemanticsLabel(target);
        break;
      case FinderType.tooltip:
        return find.byTooltip(target);
        break;
      default:
        return find.byType(target);
    }
  }

  Function _getAppropriateTap(TapType type) {
    switch (type) {
      case TapType.tap:
        return findAndTap;
        break;
      case TapType.doubleTap:
        return findAndDoubleTap;
        break;
      case TapType.longPress:
        return findAndLongPress;
        break;
      default:
        return findAndTap;
    }
  }

  Future<void> _findBeforeAction(SerializableFinder finder,
      {SerializableFinder scrollable, double dyScroll: -400}) async {
    await findWidgetOnScreen(scrollable ?? currentScreenFinder, finder,
        dyScroll: dyScroll, timeout: Duration(seconds: 30));
  }

  Future<void> findAndTap(SerializableFinder finder,
      {Duration timeout,
      SerializableFinder scrollable,
      double dyScroll = -400,
      bool withReset = true}) async {
    await _findBeforeAction(finder, scrollable: scrollable, dyScroll: dyScroll);
    await _driver.tap(finder, timeout: timeout);
  }

  Future<void> findAndDoubleTap(SerializableFinder finder,
      {Duration timeout, SerializableFinder scrollable}) async {
    await _findBeforeAction(finder, scrollable: scrollable);
    _driver.tap(finder);
    await _driver.tap(finder, timeout: timeout);
  }

  Future<void> findAndLongPress(SerializableFinder finder,
      {Duration timeout, SerializableFinder scrollable}) async {
    await _findBeforeAction(finder, scrollable: scrollable);
    await _driver.scroll(finder, 0, 0, Duration(milliseconds: 500),
        timeout: timeout);
  }

  Future<void> tapByType(String target,
      {Duration timeout,
      TapType type = TapType.tap,
      SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.type, target);
    await _getAppropriateTap(type)(finder,
        timeout: timeout, scrollable: scrollable);
  }

  Future<void> tapByText(String target,
      {Duration timeout,
      TapType type = TapType.tap,
      SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.text, target);
    await _getAppropriateTap(type)(finder,
        timeout: timeout, scrollable: scrollable);
  }

  Future<void> tapByValueKey(String target,
      {Duration timeout,
      TapType type = TapType.tap,
      SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.key, target);
    await _getAppropriateTap(type)(finder,
        timeout: timeout, scrollable: scrollable);
  }

  Future<void> tapBySemanticsLabel(String target,
      {Duration timeout,
      TapType type = TapType.tap,
      SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.semanticsLabel, target);
    await _getAppropriateTap(type)(finder,
        timeout: timeout, scrollable: scrollable);
  }

  Future<void> tapByTooltip(String target,
      {Duration timeout,
      TapType type = TapType.tap,
      SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.tooltip, target);
    await _getAppropriateTap(type)(finder,
        timeout: timeout, scrollable: scrollable);
  }

  Future<void> findAndEnterText(SerializableFinder finder, String text,
      {SerializableFinder scrollable}) async {
    await findAndTap(finder, scrollable: scrollable, withReset: false);
    await _driver.enterText(text);
  }

  Future<void> enterTextByType(String target, String text,
      {SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.type, target);
    await findAndEnterText(finder, text, scrollable: scrollable);
  }

  Future<void> enterTextByText(String target, String text,
      {SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.text, target);
    await findAndEnterText(finder, text, scrollable: scrollable);
  }

  Future<void> enterTextByValueKey(String target, String text,
      {SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.key, target);
    await findAndEnterText(finder, text, scrollable: scrollable);
  }

  Future<void> enterTextBySemanticsLabel(
      String target, String text, SerializableFinder scrollable) async {
    final finder = _getAppropriateFinder(FinderType.semanticsLabel, target);
    await findAndEnterText(finder, text, scrollable: scrollable);
  }

  Future<void> enterTextByTooltip(String target, String text,
      {SerializableFinder scrollable}) async {
    final finder = _getAppropriateFinder(FinderType.tooltip, target);
    await findAndEnterText(finder, text, scrollable: scrollable);
  }

  Future<void> dismissOverlay([SerializableFinder modalBarrier]) async {
    if (modalBarrier != null) {
      await findAndTap(modalBarrier);
    } else {
      await findAndTap(_getAppropriateFinder(FinderType.type, 'ModalBarrier'));
    }
  }

  Future<void> selectItem(
      SerializableFinder dropDownButton, SerializableFinder item,
      {SerializableFinder scrollable, SerializableFinder dismiss}) async {
    await findAndTap(dropDownButton, withReset: false);
    final menu = scrollable ?? find.byType("_DropdownMenu");
    await findAndTap(find.descendant(of: menu, matching: item),
        scrollable: menu, dyScroll: -100);
    if (dismiss != null) {
      dismissOverlay();
    }
  }

  Future<void> closeDrawer({bool isLeft = true}) async {
    await _driver.scroll(currentScreenFinder, isLeft ? -300 : 300, 0,
        const Duration(milliseconds: 300));
  }
}
