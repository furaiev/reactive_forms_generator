import 'package:code_builder/code_builder.dart';
import 'package:reactive_forms_generator/src/form_generator.dart';
import 'package:reactive_forms_generator/src/reactive_forms/reactive_inherited_streamer.dart';

class ReactiveForm {
  final ReactiveInheritedStreamer reactiveInheritedStreamer;

  const ReactiveForm(this.reactiveInheritedStreamer);

  String get className => 'Reactive${formGenerator.className}';

  FormGenerator get formGenerator => reactiveInheritedStreamer.formGenerator;

  Constructor get _constructor => Constructor(
        (b) => b
          ..optionalParameters.addAll(
            [
              Parameter(
                (b) => b
                  ..name = 'key'
                  ..named = true
                  ..type = Reference('Key?'),
              ),
              Parameter(
                (b) => b
                  ..name = 'form'
                  ..named = true
                  ..required = true
                  ..toThis = true,
              ),
              Parameter(
                (b) => b
                  ..name = 'child'
                  ..named = true
                  ..required = true
                  ..toThis = true,
              ),
              Parameter(
                (b) => b
                  ..name = 'onWillPop'
                  ..toThis = true
                  ..named = true,
              ),
            ],
          )
          ..initializers.add(
            refer('super').call(
              [],
              {'key': CodeExpression(Code('key'))},
            ).code,
          ),
      );

  // List<Spec> get imports => [
  //       Directive.import('package:flutter/foundation.dart'),
  //       Directive.import('package:flutter/material.dart'),
  //       Directive.import('package:reactive_forms/reactive_forms.dart'),
  //       Directive.import(
  //           'package:reactive_forms/src/widgets/inherited_streamer.dart'),
  //     ];

  Class get reactiveForm => Class(
        (b) => b
          ..name = className
          ..extend = Reference('StatelessWidget')
          ..constructors.add(_constructor)
          ..fields.addAll([
            Field(
              (b) => b
                ..name = 'child'
                ..modifier = FieldModifier.final$
                ..type = Reference('Widget'),
            ),
            Field(
              (b) => b
                ..name = 'form'
                ..modifier = FieldModifier.final$
                ..type = Reference(formGenerator.className),
            ),
            Field(
              (b) => b
                ..name = 'onWillPop'
                ..modifier = FieldModifier.final$
                ..type = Reference('WillPopCallback?'),
            )
          ])
          ..methods.addAll(
            [
              Method(
                (b) => b
                  ..name = 'of'
                  ..static = true
                  ..returns = Reference('${formGenerator.className}?')
                  ..requiredParameters.add(
                    Parameter(
                      (b) => b
                        ..name = 'context'
                        ..type = Reference('BuildContext'),
                    ),
                  )
                  ..optionalParameters.add(
                    Parameter(
                      (b) => b
                        ..name = 'listen'
                        ..named = true
                        ..defaultTo = Code('true')
                        ..type = Reference('bool'),
                    ),
                  )
                  ..body = Code('''
                  if (listen) {
                    return context
                        .dependOnInheritedWidgetOfExactType<${reactiveInheritedStreamer.className}>()
                        ?.form;
                  }
              
                  final element = context.getElementForInheritedWidgetOfExactType<
                      ${reactiveInheritedStreamer.className}>();
                  return element == null
                      ? null
                      : (element.widget as ${reactiveInheritedStreamer.className}).form;
                '''),
              ),
              Method(
                (b) => b
                  ..name = 'build'
                  ..returns = Reference('Widget')
                  ..requiredParameters.add(
                    Parameter(
                      (b) => b
                        ..name = 'context'
                        ..type = Reference('BuildContext'),
                    ),
                  )
                  ..annotations.add(
                    CodeExpression(Code('override')),
                  )
                  ..body = Code('''
                    return ${reactiveInheritedStreamer.className}(
                      form: form,
                      stream: form.form.statusChanged,
                      child: WillPopScope(
                        onWillPop: onWillPop,
                        child: child,
                      ),
                    );
                  '''),
              )
            ],
          ),
      );

  Class get generate => reactiveForm;
}
