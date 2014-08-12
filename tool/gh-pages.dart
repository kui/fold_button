#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:ghpages_generator/ghpages_generator.dart' as gh;

String PROJECT_DIR =
    path.absolute(
        path.dirname(path.dirname(Platform.script.toFilePath())));

main() {
  new gh.Generator(rootDir: PROJECT_DIR)
    ..withExamples = true
    ..withIndexGeneration = true
    ..generate(doCustomTask: (workDir) {
      gh.moveExampleAtRoot(workDir);
    });
}
