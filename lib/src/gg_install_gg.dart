// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_log/gg_log.dart';
import 'package:gg_process/gg_process.dart';

/// The command line interface for GgInstallGg
class GgInstallGg extends Command<dynamic> {
  /// Constructor
  GgInstallGg({
    required this.ggLog,
    GgProcessWrapper processWrapper = const GgProcessWrapper(),
  }) : _processWrapper = processWrapper {
    _addFlags();
  }

  @override
  String name = 'install-gg';

  @override
  String description = 'Install the gg command line interface globally.';

  /// The log function
  final GgLog ggLog;

  @override
  Future<void> run() async {
    await _installGg();
  }

  // ######################
  // Private
  // ######################

  final GgProcessWrapper _processWrapper;

  // ...........................................................................
  Future<void> _installGg() async {
    // Read verbose flag
    final verbose = argResults!['verbose'] as bool;
    final force = argResults!['force'] as bool;
    final isInstalled = await _isGgInstalled();

    if (isInstalled) {
      if (!force) {
        if (verbose) {
          ggLog(green('gg is already installed.'));
        }
        return;
      } else {
        ggLog(
          blue(
            'gg is already installed. '
            'Because of --force it will be reinstalled anyway...',
          ),
        );
      }
    }

    if (!isInstalled) {
      ggLog(blue('gg is not installed. Installing it now...'));
    }

    final p = await _processWrapper.start(
      'dart',
      ['pub', 'global', 'activate', 'gg'],
    );

    if (verbose) {
      // Listen to stdout and stderr and print it live
      p.stdout.transform(utf8.decoder).listen((String event) {
        ggLog(darkGray(event.trim()));
      });

      p.stderr.transform(utf8.decoder).listen((String event) {
        ggLog(darkGray(event.trim()));
      });
    }

    // Wait for the process to finish
    final exitCode = await p.exitCode;

    if (exitCode != 0) {
      throw Exception(
        red('Error while executing »dart pub global activate gg«}'),
      );
    } else {
      ggLog(green('gg was successfully installed.'));
    }
  }

  // ...........................................................................
  Future<bool> _isGgInstalled() async {
    try {
      final p = await _processWrapper.start(
        'gg',
        ['--version'],
      );
      // Wait for the process to finish
      final exitCode = await p.exitCode;
      return exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  // ...........................................................................
  void _addFlags() {
    // Add flags
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Print verbose output.',
      defaultsTo: false,
    );

    // Add flags
    argParser.addFlag(
      'force',
      abbr: 'f',
      negatable: false,
      help: 'Runs installation no matter if gg is already installed.',
      defaultsTo: false,
    );
  }
}
