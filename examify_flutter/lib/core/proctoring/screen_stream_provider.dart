import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScreenStreamNotifier extends Notifier<dynamic> {
  @override
  dynamic build() => null;

  void setStream(dynamic stream) {
    state = stream;
  }

  void clear() {
    state = null;
  }
}

final screenStreamProvider = NotifierProvider<ScreenStreamNotifier, dynamic>(
  () => ScreenStreamNotifier(),
);
