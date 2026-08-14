import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CursorState {
  normal,
  explore,
  open,
  download,
  custom,
}

final cursorStateProvider = StateProvider<CursorState>((ref) => CursorState.normal);
final cursorCustomTextProvider = StateProvider<String>((ref) => '');
