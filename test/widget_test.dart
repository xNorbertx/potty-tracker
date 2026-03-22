// Basic smoke test - full widget tests would require Firebase mocking
import 'package:flutter_test/flutter_test.dart';
import 'package:potty_tracker/models/consistency.dart';

void main() {
  test('Consistency enum has 4 values', () {
    expect(Consistency.values.length, 4);
  });
}
