// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:args/command_runner.dart';
import 'package:fake_async/fake_async.dart';
import 'package:gg_console_colors/gg_console_colors.dart';
import 'package:gg_install_gg/src/gg_install_gg.dart';
import 'package:gg_process/gg_process.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  final messages = <String>[];
  final ggLog = messages.add;
  late CommandRunner<void> runner;
  late GgInstallGg ggInstallGg;
  late GgProcessWrapper processWrapper;
  late GgFakeProcess ggVersionProcess;
  late GgFakeProcess dartPubGlobalProcess;

  // ...........................................................................
  void initGgVersion() {
    ggVersionProcess = GgFakeProcess();
    when(() => processWrapper.start('gg', ['--version'])).thenAnswer(
      (_) async => ggVersionProcess,
    );
  }

  // ...........................................................................
  void initDartPubGlobal() {
    dartPubGlobalProcess = GgFakeProcess();
    when(
      () => processWrapper.start('dart', ['pub', 'global', 'activate', 'gg']),
    ).thenAnswer(
      (_) async => dartPubGlobalProcess,
    );
  }

  // ...........................................................................
  void init(FakeAsync fake) {
    messages.clear();
    processWrapper = MockGgProcessWrapper();
    ggInstallGg = GgInstallGg(ggLog: ggLog, processWrapper: processWrapper);
    runner = CommandRunner('gg', 'gg command line interface');
    runner.addCommand(ggInstallGg);
    initGgVersion();
    initDartPubGlobal();
  }

  // ...........................................................................
  group('GgInstallGg()', () {
    group('run()', () {
      group('should not install gg', () {
        group('when gg is already installed', () {
          test('and --force is not set', () {
            fakeAsync((fake) {
              init(fake);

              // Start the process
              runner.run(['install-gg', '--verbose']);
              fake.flushMicrotasks();

              // Let gg version exit with success
              ggVersionProcess.exit(0);
              fake.flushMicrotasks();

              // No install should be done
              expect(messages.last, contains('gg is already installed.'));
            });
          });
        });
      });

      group('should install gg', () {
        group('when gg is not installed', () {
          group('with »gg --help« exiting with exitCode != 0', () {
            for (final verboseStr in ['true', 'false']) {
              final isVerbose = verboseStr == 'true';

              test('with --verbose == $verboseStr', () {
                fakeAsync((fake) {
                  init(fake);

                  // Start the process
                  runner.run(['install-gg', if (isVerbose) '--verbose']);
                  fake.flushMicrotasks();

                  // Let gg version exit with error = not installed
                  ggVersionProcess.exit(1);
                  fake.flushMicrotasks();

                  // Let dart pub global print on stdout and stderr
                  dartPubGlobalProcess.pushToStdout.add('Message to stdout');
                  dartPubGlobalProcess.pushToStderr.add('Message to stderr');

                  // Let dart pub global exit with success
                  dartPubGlobalProcess.exit(0);
                  fake.flushMicrotasks();

                  // gg should be installed
                  expect(
                    messages,
                    [
                      blue('gg is not installed. Installing it now...'),
                      if (isVerbose) darkGray('Message to stdout'),
                      if (isVerbose) darkGray('Message to stderr'),
                      green('gg was successfully installed.'),
                    ],
                  );
                });
              });
            }
          });

          test('exiting with exception', () {
            fakeAsync((fake) {
              init(fake);

              // Start the process
              runner.run(['install-gg', '--verbose']);
              fake.flushMicrotasks();

              // Let gg version exit with error = not installed
              ggVersionProcess.exitWithException(
                Exception('Command not found'),
              );
              fake.flushMicrotasks();

              // Let dart pub global exit with success
              dartPubGlobalProcess.exit(0);
              fake.flushMicrotasks();

              // gg should be installed
              expect(
                messages[0],
                contains(blue('gg is not installed. Installing it now...')),
              );

              expect(
                messages[1],
                green('gg was successfully installed.'),
              );
            });
          });
        });

        group('when gg is installed', () {
          test('and --force is set', () {
            fakeAsync((fake) {
              init(fake);

              // Start the process
              runner.run(['install-gg', '--force', '--verbose']);
              fake.flushMicrotasks();

              // Let gg version exit with error = installed
              ggVersionProcess.exit(0);
              fake.flushMicrotasks();

              // Let dart pub global exit with success
              dartPubGlobalProcess.exit(0);
              fake.flushMicrotasks();

              // gg should be installed
              expect(
                messages[0],
                blue(
                  'gg is already installed. '
                  'Because of --force it will be reinstalled anyway...',
                ),
              );

              expect(
                messages[1],
                green('gg was successfully installed.'),
              );
            });
          });
        });
      });

      group('shouuld throw', () {
        test('when »dart pub global activate gg« exits with error', () {
          fakeAsync((fake) {
            init(fake);

            // Start the process
            late String exception;
            runner.run(['install-gg', '--verbose']).catchError((Object e) {
              exception = e.toString();
            });
            fake.flushMicrotasks();

            // Let gg version exit with error = not installed
            ggVersionProcess.exit(1);
            fake.flushMicrotasks();

            // Let dart pub global exit with error
            dartPubGlobalProcess.exit(1);
            fake.flushMicrotasks();

            // An exception should be thrown
            expect(
              exception,
              contains('Error while executing »dart pub global activate gg«'),
            );

            // gg should be installed
            expect(
              messages[0],
              blue('gg is not installed. Installing it now...'),
            );
          });
        });
      });
    });
  });
}
