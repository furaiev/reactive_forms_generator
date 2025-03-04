import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'reactive_forms_generator.dart';

Builder reactiveFormsGenerator(BuilderOptions options) {
  return LibraryBuilder(
    ReactiveFormsGenerator(),
    generatedExtension: '.gform.dart',
  );
}
