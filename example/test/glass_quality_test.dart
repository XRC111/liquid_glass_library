import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_flutter/liquid_glass.dart';

void main() {
  test('quality tiers follow API level', () {
    expect(GlassQuality.fromDevice(sdkInt: 35, lowRamDevice: false), GlassQuality.full);
    expect(GlassQuality.fromDevice(sdkInt: 27, lowRamDevice: false), GlassQuality.medium);
    expect(GlassQuality.fromDevice(sdkInt: 24, lowRamDevice: false), GlassQuality.minimal);
    expect(GlassQuality.fromDevice(sdkInt: 35, lowRamDevice: true), GlassQuality.minimal);
  });
}
