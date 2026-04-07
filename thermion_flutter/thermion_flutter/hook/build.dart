import 'dart:convert';
import 'dart:io';
import 'package:hooks/hooks.dart';

void main(List<String> args) async {
  await build(args, (BuildInput input, BuildOutputBuilder output) async {
    final includeDirs = _findThermionDartIncludeDirs(input.packageRoot);

    final cmakeSafePath = includeDirs
        .map((dir) => dir.replaceAll('\\', '/'))
        .map((dir) => '"$dir"')
        .join(' ');
    final cmakeContent = 'set(DART_PKG_HEADERS $cmakeSafePath)';

    final outfile = File.fromUri(
        input.packageRoot.resolve('.dart_tool/generated_headers.cmake'));
    if (!outfile.parent.existsSync()) {
      outfile.parent.createSync(recursive: true);
    }
    await outfile.writeAsString(cmakeContent);

    output.metadata
        .addAll({'generated_headers_path': outfile.uri.toFilePath()});
  });
}

List<String> _findThermionDartIncludeDirs(Uri packageRoot) {
  // Try to find thermion_dart via the package_config.json in this package's
  // .dart_tool directory (written by `flutter pub get`).
  final pkgConfigUri =
      packageRoot.resolve('.dart_tool/package_config.json');
  final pkgConfigFile = File.fromUri(pkgConfigUri);

  if (!pkgConfigFile.existsSync()) {
    throw Exception(
        'package_config.json not found at ${pkgConfigFile.path}. '
        'Run "flutter pub get" in the thermion_flutter package first.');
  }

  final pkgConfig =
      jsonDecode(pkgConfigFile.readAsStringSync()) as Map<String, dynamic>;
  final packages = (pkgConfig['packages'] as List).cast<Map<String, dynamic>>();

  final thermionDartEntry = packages.firstWhere(
    (p) => p['name'] == 'thermion_dart',
    orElse: () => throw Exception(
        'thermion_dart not found in package_config.json at ${pkgConfigFile.path}'),
  );

  // rootUri is relative to the directory containing package_config.json
  final rootUriStr = thermionDartEntry['rootUri'] as String;
  final pkgConfigDir = pkgConfigUri.resolve('./');
  final thermionDartRoot = pkgConfigDir.resolve(rootUriStr);
  final rootPath = thermionDartRoot.toFilePath(windows: Platform.isWindows);

  return [
    '$rootPath/native/include',
    '$rootPath/native/include/filament',
    '$rootPath/native/include/filament/release',
  ];
}
