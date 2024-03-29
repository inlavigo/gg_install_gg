// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('bin/gg_install_gg.dart', () {
    // #########################################################################

    test('should be executable', () async {
      // Execute bin/gg_install_gg.dart and check if it prints help
      final result = await Process.run(
        './bin/gg_install_gg.dart',
        ['--help'],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      final stdout = result.stdout as String;

      expect(
        stdout,
        contains('Install the gg command line interface globally.'),
      );
    });
  });
}
