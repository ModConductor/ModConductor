import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:mc_client/mc_client.dart';

import 'support/native_child.dart';

const darkApplication = SettingsSnapshot(
  presentation: PresentationPreferences(
    appearance: AppearancePreference.dark,
    textScale: 1.25,
    contrast: ContrastPreference.standard,
  ),
  inheritsApplication: false,
);

const lightWorkspace = SettingsSnapshot(
  presentation: PresentationPreferences(
    appearance: AppearancePreference.light,
    textScale: 1.5,
    interfaceScale: 0.9,
    contrast: ContrastPreference.high,
  ),
  inheritsApplication: false,
);

void main() {
  final executable = Platform.environment['MC_ENGINE_PATH'];
  late Directory fixture, state, root;
  final children = <NativeChild>[];

  Future<NativeChild> start() async {
    final child = await NativeChild.start(executable!, state);
    children.add(child);
    return child;
  }

  setUp(() async {
    fixture = await Directory.systemTemp.createTemp('mc-settings-wire-');
    state = await Directory('${fixture.path}/state').create();
    root = await Directory('${fixture.path}/workspace').create();
  });

  tearDown(() async {
    for (final child in children) {
      await child.close();
    }
    children.clear();
    await fixture.delete(recursive: true);
  });

  group(
    'native settings wire',
    skip: executable == null
        ? 'Set MC_ENGINE_PATH to a published NativeAOT engine.'
        : false,
    () {
      test(
        'authenticated application and workspace scopes persist independently',
        () async {
          final child = await start();
          final settings = child.settings();
          final id = newOperationId();
          await child.workspaces().create(id, 'Settings', root.path);

          expect(
            (await settings.readApplication()).inheritsApplication,
            isFalse,
          );
          expect(
            (await settings.readWorkspace(id)).inheritsApplication,
            isTrue,
          );
          expect(
            await settings.saveApplication(darkApplication),
            darkApplication,
          );
          expect(
            await settings.saveWorkspace(id, lightWorkspace),
            lightWorkspace,
          );
          expect(await settings.readApplication(), darkApplication);
          expect(await settings.readWorkspace(id), lightWorkspace);
          expect((await child.operations().check()).runtime.nativeAot, isTrue);

          await child.close();
          final restarted = await start();
          expect(await restarted.settings().readApplication(), darkApplication);
          expect(await restarted.settings().readWorkspace(id), lightWorkspace);
        },
      );

      test(
        'workspace inheritance does not copy application presentation',
        () async {
          final child = await start();
          final id = newOperationId();
          await child.workspaces().create(id, 'Settings', root.path);
          final settings = child.settings();
          await settings.saveApplication(darkApplication);
          await settings.saveWorkspace(
            id,
            SettingsSnapshot(
              presentation: lightWorkspace.presentation,
              inheritsApplication: true,
            ),
          );

          final loaded = await settings.readWorkspace(id);
          expect(loaded.inheritsApplication, isTrue);
          expect(
            await File('${root.path}/mod-conductor.toml').readAsString(),
            'version = 1\n',
          );
          expect(await settings.readApplication(), darkApplication);
        },
      );

      test(
        'malformed duplicate and unsupported files return typed failures',
        () async {
          final child = await start();
          final settings = child.settings();
          final file = File('${state.path}/settings.toml');
          await file.writeAsString('version = 1\nversion = 1\n');
          await expectLater(
            settings.readApplication(),
            throwsA(
              isA<SettingsException>().having(
                (error) => error.fault,
                'fault',
                SettingsFault.invalidDocument,
              ),
            ),
          );
          await file.writeAsString(
            'version = 7\n[presentation]\nappearance = "system"\ntext_scale = 1.0\ncontrast = "system"\n',
          );
          await expectLater(
            settings.readApplication(),
            throwsA(
              isA<SettingsException>().having(
                (error) => error.fault,
                'fault',
                SettingsFault.unsupportedVersion,
              ),
            ),
          );
        },
      );

      test(
        'a corrected application file reads without restarting the engine',
        () async {
          final child = await start();
          final settings = child.settings();
          final file = File('${state.path}/settings.toml');
          await file.writeAsString('version = 1\nversion = 1\n');
          await expectLater(
            settings.readApplication(),
            throwsA(
              isA<SettingsException>().having(
                (error) => error.fault,
                'fault',
                SettingsFault.invalidDocument,
              ),
            ),
          );
          await file.writeAsString(
            'version = 1\n[presentation]\nappearance = "dark"\ntext_scale = 1.0\ncontrast = "system"\n',
          );
          expect(
            await settings.readApplication(),
            SettingsSnapshot(
              presentation: PresentationPreferences(
                appearance: AppearancePreference.dark,
                textScale: 1,
                contrast: ContrastPreference.system,
              ),
              inheritsApplication: false,
            ),
          );
        },
      );

      test(
        'missing authentication rejects settings before a file effect',
        () async {
          final child = await start();
          await expectLater(
            child
                .settings(authenticate: false)
                .saveApplication(darkApplication),
            throwsA(
              isA<GrpcError>().having(
                (error) => error.code,
                'status',
                StatusCode.unauthenticated,
              ),
            ),
          );
          expect(File('${state.path}/settings.toml').existsSync(), isFalse);
        },
      );
    },
  );
}
