import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:reactive_forms_generator/src/form_generator.dart';
import 'package:reactive_forms_generator/src/types.dart';
import 'package:source_gen/source_gen.dart';
import 'package:recase/recase.dart';

abstract class FormElementGenerator {
  final FieldElement field;

  FormElementGenerator(this.field);

  String get value =>
      '${(field.enclosingElement as ClassElement).name.camelCase}.${field.name}';

  String? validatorName(ExecutableElement? e) {
    var name = e?.name;

    if (e is MethodElement) {
      name = '${e.enclosingElement.name}.$name';
    }

    return name;
  }

  List<String> syncValidatorList(TypeChecker typeChecker) {
    if (typeChecker.hasAnnotationOfExact(field)) {
      final annotation = typeChecker.firstAnnotationOfExact(field);
      return annotation
              ?.getField('validators')
              ?.toListValue()
              ?.map((e) {
                return validatorName(e.toFunctionValue());
              })
              .whereType<String>()
              .toList() ??
          [];
    }
    return [];
  }

  List<String> asyncValidatorList(TypeChecker typeChecker) {
    if (typeChecker.hasAnnotationOfExact(field)) {
      final annotation = typeChecker.firstAnnotationOfExact(field);
      return annotation
              ?.getField('asyncValidators')
              ?.toListValue()
              ?.map((e) {
                return validatorName(e.toFunctionValue());
              })
              .whereType<String>()
              .toList() ??
          [];
    }
    return [];
  }

  int asyncValidatorsDebounceTime(TypeChecker typeChecker) {
    int? debounceTime;
    if (typeChecker.hasAnnotationOfExact(field)) {
      final annotation = typeChecker.firstAnnotationOfExact(field);
      debounceTime = annotation
          ?.getField(
            'asyncValidatorsDebounceTime',
          )
          ?.toIntValue();
    }
    return debounceTime ?? 250;
  }

  bool disabled(TypeChecker typeChecker) {
    bool? disabled;
    if (typeChecker.hasAnnotationOfExact(field)) {
      final annotation = typeChecker.firstAnnotationOfExact(field);
      disabled = annotation
          ?.getField(
            'disabled',
          )
          ?.toBoolValue();
    }
    return disabled ?? false;
  }

  bool touched(TypeChecker typeChecker) {
    bool? touched;
    if (typeChecker.hasAnnotationOfExact(field)) {
      final annotation = typeChecker.firstAnnotationOfExact(field);
      touched = annotation
          ?.getField(
            'touched',
          )
          ?.toBoolValue();
    }
    return touched ?? false;
  }

  String element();
}

class FormGroupGenerator extends FormElementGenerator {
  FormGroupGenerator(FieldElement field) : super(field);

  @override
  String element() {
    final enclosingClass = field.type.element as ClassElement;
    final formGenerator = FormGenerator(enclosingClass);

    final props = [
      '${formGenerator.className.camelCase}.formElements()',
      'validators: [${syncValidatorList(formControlChecker).join(',')}]',
      'asyncValidators: [${asyncValidatorList(formControlChecker).join(',')}]',
      'asyncValidatorsDebounceTime: ${asyncValidatorsDebounceTime(formControlChecker)}',
      'disabled: ${disabled(formControlChecker)}',
    ].join(',');

    return 'FormGroup($props)';
  }
}

class FormControlGenerator extends FormElementGenerator {
  FormControlGenerator(FieldElement field) : super(field);

  @override
  String element() {
    final props = [
      'value: $value',
      'validators: [${syncValidatorList(formControlChecker).join(',')}]',
      'asyncValidators: [${asyncValidatorList(formControlChecker).join(',')}]',
      'asyncValidatorsDebounceTime: ${asyncValidatorsDebounceTime(formControlChecker)}',
      'disabled: ${disabled(formControlChecker)}',
      'touched: ${touched(formControlChecker)}',
    ].join(',');

    return 'FormControl<${field.type.getDisplayString(withNullability: false)}>($props)';
  }
}

class FormArrayGenerator extends FormElementGenerator {
  FormArrayGenerator(FieldElement field) : super(field);

  @override
  String element() {
    final type = field.type;
    final typeArguments =
        type is ParameterizedType ? type.typeArguments : const [];

    final props = [
      '$value.map((e) => FormControl<${typeArguments.first}>(value: e)).toList()',
      'validators: [${syncValidatorList(formArrayChecker).join(',')}]',
      'asyncValidators: [${asyncValidatorList(formArrayChecker).join(',')}]',
      'asyncValidatorsDebounceTime: ${asyncValidatorsDebounceTime(formControlChecker)}',
      'disabled: ${disabled(formControlChecker)}',
    ].join(',');

    return 'FormArray<${typeArguments.first}>($props)';
  }
}
