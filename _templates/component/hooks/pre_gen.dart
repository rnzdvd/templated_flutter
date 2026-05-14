import 'dart:io';
import 'package:mason/mason.dart';

void run(HookContext context) {
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final content = pubspecFile.readAsStringSync();
    final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
    if (match != null) {
      context.vars['package_name'] = match.group(1)!;
    }
  }
}
