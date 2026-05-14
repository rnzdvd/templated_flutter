import 'dart:io';

const _copyItems = [
  '_templates',
  'CLAUDE.md',
  '.claude',
  '.env.prod',
  '.env.dev',
  'lib',
  'install_packages.ps1',
  'analysis_options.yaml',
  'build.yaml',
  'mason.yaml',
  'melos.yaml',
];

const _skipNames = {
  'pubspec.yaml', 'pubspec.lock', 'package.json', 'package-lock.json',
  'bin', '.git', 'node_modules', '.dart_tool', 'build', 'env.g.dart',
};

const _textExtensions = {
  '.dart', '.yaml', '.yml', '.md', '.json', '.ps1', '.sh', '.txt',
};

void main() {
  final scaffoldRoot = _findScaffoldRoot();
  final targetDir = Directory.current.path;
  final projectName = _projectName(targetDir);

  print('\nFlutter Clean Architecture Scaffold');
  print('=====================================\n');
  print('Project : $projectName');
  print('Target  : $targetDir\n');

  final copied = <String>[];
  final missing = <String>[];

  for (final item in _copyItems) {
    final srcDir = Directory('$scaffoldRoot/$item');
    final srcFile = File('$scaffoldRoot/$item');

    if (srcDir.existsSync()) {
      _copyDir(srcDir, Directory('$targetDir/$item'), targetDir, projectName, copied);
    } else if (srcFile.existsSync()) {
      _copyFile(srcFile, File('$targetDir/$item'), targetDir, projectName, copied);
    } else {
      missing.add(item);
    }
  }

  print('Copied ${copied.length} file(s):\n');
  for (final f in copied) {
    print('  + $f');
  }

  if (missing.isNotEmpty) {
    print('\nNot found in scaffold (skipped):');
    for (final f in missing) {
      print('  - $f');
    }
  }

  print('\n-------------------------------------');
  print('Next steps:');
  print('  1. dart pub global activate mason_cli');
  print('  2. mason get');
  print('  3. PowerShell: .\\install_packages.ps1');
  print('     or manually update pubspec.yaml + flutter pub get');
  print('  4. melos run build');
  print('-------------------------------------\n');
}

// ─── Root resolution ─────────────────────────────────────────────────────────

String _findScaffoldRoot() {
  // Local run: dart run bin/scaffold.dart
  // Platform.script → file:///.../bin/scaffold.dart → parent.parent = scaffold root
  final uri = Platform.script;
  if (uri.scheme == 'file') {
    final root = File(uri.toFilePath()).parent.parent;
    if (File('${root.path}/mason.yaml').existsSync()) {
      return root.path;
    }
  }

  // pub global activate fallback — look for package dir in pub-cache
  final pubCache = Platform.environment['PUB_CACHE'] ??
      (Platform.isWindows
          ? '${Platform.environment['LOCALAPPDATA']}\\Pub\\Cache'
          : '${Platform.environment['HOME']}/.pub-cache');

  final gitCacheDir = Directory('$pubCache/git');
  if (gitCacheDir.existsSync()) {
    for (final entry in gitCacheDir.listSync().whereType<Directory>()) {
      final name = entry.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
      if (name.startsWith('flutter-scaffold') && File('${entry.path}/mason.yaml').existsSync()) {
        return entry.path;
      }
    }
  }

  throw StateError(
    'Could not locate scaffold files.\n'
    'Run directly from the cloned repo: dart run bin/scaffold.dart',
  );
}

// ─── Project name ─────────────────────────────────────────────────────────────

String _projectName(String targetDir) {
  final pubspec = File('$targetDir/pubspec.yaml');
  if (pubspec.existsSync()) {
    final match = RegExp(r'^name:\s*(\S+)', multiLine: true)
        .firstMatch(pubspec.readAsStringSync());
    if (match != null) return match.group(1)!;
  }
  return Directory(targetDir).uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => 'app');
}

// ─── Copy helpers ─────────────────────────────────────────────────────────────

void _copyDir(Directory src, Directory dest, String targetDir, String projectName, List<String> copied) {
  dest.createSync(recursive: true);
  for (final entity in src.listSync()) {
    final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty, orElse: () => '');
    if (_skipNames.contains(name)) continue;

    if (entity is Directory) {
      _copyDir(entity, Directory('${dest.path}/$name'), targetDir, projectName, copied);
    } else if (entity is File) {
      _copyFile(entity, File('${dest.path}/$name'), targetDir, projectName, copied);
    }
  }
}

void _copyFile(File src, File dest, String targetDir, String projectName, List<String> copied) {
  final ext = src.path.contains('.') ? '.${src.path.split('.').last.toLowerCase()}' : '';

  if (_textExtensions.contains(ext)) {
    final content = src.readAsStringSync().replaceAll('package:templated_flutter/', 'package:$projectName/');
    dest.writeAsStringSync(content);
  } else {
    src.copySync(dest.path);
  }

  final relative = dest.path.replaceFirst(targetDir, '').replaceFirst(RegExp(r'^[/\\]'), '');
  copied.add(relative);
}
