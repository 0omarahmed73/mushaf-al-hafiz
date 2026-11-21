// Feature 010 T002: the lines of the frame trace and the trace's being off in normal builds.
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/motion/frame_trace.dart';

FrameTiming _timing({int buildUs = 4000, int rasterUs = 2500}) {
  const start = 1000000;
  return FrameTiming(
    vsyncStart: start,
    buildStart: start,
    buildFinish: start + buildUs,
    rasterStart: start + buildUs,
    rasterFinish: start + buildUs + rasterUs,
    rasterFinishWallTime: start + buildUs + rasterUs,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a frame is printed as build, raster and total with two decimals', () {
    expect(
      FrameTrace.formatFrame(_timing()),
      'build=4.00 raster=2.50 total=6.50',
    );
    expect(
      FrameTrace.formatFrame(_timing(buildUs: 12345, rasterUs: 678)),
      'build=12.35 raster=0.68 total=13.02',
    );
  });

  test('the swipe-start line says whether each neighbour was ready', () {
    expect(
      FrameTrace.warmLine(next: true, prev: false),
      'PAGEWARM next=true prev=false',
    );
    expect(
      FrameTrace.warmLine(next: false, prev: true),
      'PAGEWARM next=false prev=true',
    );
  });

  test('the trace is off in a normal build and installing it logs nothing', () {
    expect(FrameTrace.enabled, isFalse);
    final lines = <String>[];
    FrameTrace.install(log: lines.add);
    expect(lines, isEmpty);
  });
}
