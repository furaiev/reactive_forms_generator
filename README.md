<p align="center">
  <img src="https://github.com/artflutter/reactive_forms_generator/blob/master/assets/img.png?raw=true" height="200" />
  <h1><b>ReactiveFormsGenerator</b></h1>
</p>

Welcome to [ReactiveFormsGenerator](https://pub.dev/packages/reactive_forms_generator), code generator for [reactive_forms](https://pub.dev/packages/reactive_forms) 
which will save you tons of time and make your forms type safe.

**There is no reason write code manually! Let the code generation work for you.**

# Table of Contents
- [Motivation](#motivation)
- [How to use](#how-to-use)
  - [Minimum Requirements](#minimum-requirements)
  - [Installation](#installation)
  - [Ignore lint warnings on generated files](#ignore-lint-warnings-on-generated-files)
  - [Run the generator](#run-the-generator)
- [Features](#features)
  - [Syntax](#syntax)
    - [Basics](#basics)
      - [Model](#basics-model)
      - [Annotation](#basics-annotation)
      - [Validation](#basics-validation)
      - [Form](#basics-form)
    - [Dynamic forms with FormArray](#dynamic-forms-with-formarray)
      - [Model](#array-model)
      - [Annotation](#array-annotation)
      - [Validation](#array-validation)
      - [Form](#array-form)
    - [Nested forms with FormGroups](#nested-forms-with-formgroups)
      - [Model](#group-model)
      - [Annotation](#group-annotation)
      - [Validation](#group-validation)
      - [Form](#group-form)
    - [Nested forms with array of FormGroups](#nested-forms-with-array-of-formgroups)
      - [Model](#array-group-model)
      - [Annotation](#array-group-annotation)
      - [Form](#array-group-form)

# Motivation

One of the goals of this package is to make [reactive_forms](https://pub.dev/packages/reactive_forms) package even more cool and fun to use.

Let's see what issues this package tries to mitigate.

Here is how typical `reactive_forms` form looks like

```dart
/// form instantiation
FormGroup buildForm() => fb.group(<String, Object>{
  'email': FormControl<String>(
    validators: [Validators.required, Validators.email],
  ),
  'password': ['', Validators.required, Validators.minLength(8)],
  'rememberMe': false,
});

/// form itself
final form = ReactiveFormBuilder(
    form: buildForm,
    builder: (context, form, child) {
      return Column(
        children: [
          ReactiveTextField<String>(
            formControlName: 'email',
          ),
          const SizedBox(height: 16.0),
          ReactiveTextField<String>(
            formControlName: 'password',
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              if (form.valid) {
                print(form.value);
              } else {
                form.markAllAsTouched();
              }
            },
            child: const Text('Sign Up'),
          ),
          ElevatedButton(
            onPressed: () => form.resetState({
              'email': ControlState<String>(value: null),
              'password': ControlState<String>(value: null),
              'rememberMe': ControlState<bool>(value: false),
            }, removeFocus: true),
            child: const Text('Reset all'),
          ),
        ],
      );
    },
);
```

1. First issue is `String` identifiers which is used to define fields. Technically you can extract them into separate 
class, enum or whatever you like. But this is manual work which you have to do each time you create the form. The other 
disadvantage is when you refer to any field by his `String` identifier you loos static type check. There is no way for
static analyser to check if some random field name `login` is suitable to put in particular widget. So you can easily 
get the form which looks `ok` but fails to build due to the typo in field names and putting `login` field into 
`ReactiveCheckbox` field. **Isn't it better the code generation to do it for you?**


2. Second issue is output which is always `Map<String, Object>`. It is ok for languages like JS. But for the typed language 
you would prefer to get the output fom the form like model. And avoid manual type casting like this one.
```dart
final document = DocumentInput(
      subTypeId: form.value["subType"] as DocumentSubTypeMixin,
      documentNumber: form.value["documentNumber"] as String,
      countryIsoCode: form.value["country"] as CountryMixin,
      countryOfIssueIsoCode: form.value["country"] as CountryMixin,
      issueDate: form.value["issueDate"] as DateTime,
      vesselId: form.value["vessel"] as VesselMixin,
    );
```

This is two main issues that forced me to write this generator.
In the next chapters of documentation you'll see how we define and annotate the model which describes the form state and
how easy and elegant it works with a bit of magic from code generation.

# How to use

## Minimum Requirements

- Dart SDK: >=2.12.0 <3.0.0
- Flutter: >= 2.2.0

## Installation

To use [reactive_forms_generator], you will need your typical [build_runner]/code-generator setup.\
First, install [build_runner] and [reactive_forms_generator] by adding them to your `pubspec.yaml` file:

```yaml
# pubspec.yaml
dependencies:
  reactive_forms:
  reactive_forms_annotation:

dev_dependencies:
  build_runner:
  reactive_forms_generator:
```

This installs three packages:

- [build_runner](https://pub.dev/packages/build_runner), the tool to run code-generators
- [reactive_forms](https://pub.dev/packages/reactive_forms), form engine itself
- [reactive_forms_generator](https://pub.dev/packages/reactive_forms_generator), the code generator
- [reactive_forms_annotation](https://pub.dev/packages/reactive_forms_annotation), a package containing annotations for [reactive_forms_generator].

## Ignore lint warnings on generated files

It is likely that the code generated by [reactive_forms_generator] will cause your linter to
report warnings.

The solution to this problem is to tell the linter to ignore generated files,
by modifying your `analysis_options.yaml`:

```yaml
analyzer:
  exclude:
    - "**/*.gform.dart"
```

## Run the generator

To run the code generator you have two possibilities:

- If your package depends on Flutter:
    - `flutter pub run build_runner build`
- If your package _does not_ depend on Flutter:
    - `dart pub run build_runner build`

# Features

## Syntax

### Basics

Let's start from simple login form.

First we need to define our form model

#### Model <a name="basics-model" />
```dart
class Tiny {
  final String email;

  final String password;

  Tiny({this.email = '', this.password = ''});
}
```

We defined here a simple model with non-nullable `email` and `password` fields.

#### Annotation <a name="basics-annotation" />

The next step is to add annotations to help generator do his job.

```dart
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

@ReactiveFormAnnotation()
class Tiny {
  @FormControlAnnotation()
  final String email;

  @FormControlAnnotation()
  final String password;

  Tiny({this.email = '', this.password = ''});
}
```

`ReactiveFormAnnotation` - tells the generator that we want to Form based on this model.
`FormControlAnnotation` - maps fields to control elements.

#### Validation <a name="basics-validation" />

The login form should not proceed if there is any empty values. We need to modify our code to add some `required` validators.

```dart
import 'package:example/helpers.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

Map<String, dynamic>? requiredValidator(AbstractControl<dynamic> control) {
  return Validators.required(control);
}

@ReactiveFormAnnotation()
class Tiny {
  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String email;

  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String password;

  Tiny({this.email = '', this.password = ''});
}
```

As far as we are using annotations - validators should be top level functions or static class fields.

Now we are ready to run our form generator. You can check output [here](https://github.com/artflutter/reactive_forms_generator/blob/master/packages/reactive_forms_generator/example/lib/docs/basics/tiny.gform.dart).

#### Form <a name="basics-form" />

Let's build our form based on generated code

```dart
final form = TinyFormBuilder(
  // setup form model with initial data
  model: Tiny(),
  // form builder
  builder: (context, formModel, child) {
    return Column(
      children: [
        ReactiveTextField<String>(
          formControl: formModel.emailControl,
          validationMessages: (control) => {
            ValidationMessage.required: 'The email must not be empty',
          },
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 8.0),
        ReactiveTextField<String>(
          formControl: formModel.passwordControl,
          obscureText: true,
          validationMessages: (control) => {
            ValidationMessage.required: 'The password must not be empty',
          },
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
        const SizedBox(height: 8.0),
        ReactiveTinyFormConsumer(
          builder: (context, form, child) {
            return ElevatedButton(
              child: Text('Submit'),
              onPressed: form.form.valid
                      ? () {
                print(form.model.email);
                print(form.model.password);
              }
                      : null,
            );
          },
        ),
      ],
    );
  },
);
```

`TinyFormBuilder` - generated widget that injects form into context
`ReactiveTextField` - bundled text fields 
`ReactiveTinyFormConsumer` - generated widget that rebuilds upon form change

You can get access to prefilled form model by calling `form.model.[field-name]`.

### Dynamic forms with FormArray

The next example will show how to build dynamic forms. We will create a mailing list which will allow adding new email
and basic validation.

#### Model <a name="array-model" />
The model is pretty simple.

```dart
class MailingList {
  final List<String?> emailList;

  MailingList({
    this.emailList = const [],
  });
}
```

#### Annotation <a name="array-annotation" />

The next step is to add annotations to help generator do his job.

```dart
import 'package:example/helpers.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

@ReactiveFormAnnotation()
class MailingList {
  @FormArrayAnnotation(
    validators: const [
      emailDuplicates,
    ],
  )
  final List<String?> emailList;

  MailingList({
    this.emailList = const [],
  });
}
```

`ReactiveFormAnnotation` - tells the generator that we want to Form based on this model.
`FormArrayAnnotation` - maps fields to control elements.

#### Validation <a name="array-validation" />

The mailing list form should not be valid in two cases - if there are duplicates and if any field is invalid email.

```dart
/// simple regexp to validate email
final emailRegex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

/// validator that validates field against email regex
Map<String, dynamic> emailValidator(AbstractControl<dynamic> control) {
  final email = control.value as String?;

  return email != null && emailRegex.hasMatch(email)
          ? <String, dynamic>{}
          : <String, dynamic>{ValidationMessage.email: true};
}

/// validates there is no duplicates in email list and each item is valid email
Map<String, dynamic>? mailingListValidator(AbstractControl control) {
  final formArray = control as FormArray<String>;
  final emails = formArray.value ?? [];
  final test = Set<String>();

  // sets errors for each input in case if value is invalid email
  formArray.controls.forEach((e) => e.setErrors(emailValidator(e)));

  // checks that there is no duplicates
  final result = emails.fold<bool>(true,
    (previousValue, element) => previousValue && test.add(element ?? ''),
  );

  return result ? null : <String, dynamic>{'emailDuplicates': true};
}
```

As far as we are using annotations - validators should be top level functions or static class fields.

Now we are ready to run our form generator. You can check output [here](https://github.com/artflutter/reactive_forms_generator/blob/master/packages/reactive_forms_generator/example/lib/docs/arrays/mailing_list.gform.dart).

#### Form <a name="array-form" />

Let's build our form based on generated code

```dart
// create form based on generated widget
final form = MailingListFormBuilder(
  // instantiate with empty model
  model: MailingList(),
  builder: (context, formModel, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              // renders list of fields corresponding to added elements
              child: ReactiveFormArray<String>(
                formArray: formModel.emailListControl,
                builder: (context, formArray, child) => Column(
                  children: formModel.emailListValue
                          .asMap()
                          .map((i, email) {
                    return MapEntry(
                            i,
                            ReactiveTextField<String>(
                              formControlName: i.toString(),
                              validationMessages: (_) => {
                                'email': 'Invalid email',
                              },
                              decoration: InputDecoration(
                                      labelText: 'Email ${i}'),
                            ));
                  })
                          .values
                          .toList(),
                ),
              ),
            ),
            SizedBox(width: 16),
            // adds new item to the list of fields
            ElevatedButton(
              onPressed: () {
                formModel.addEmailListItem('');
              },
              child: const Text('add'),
            )
          ],
        ),
        SizedBox(height: 16),
        // renders error related to the whole list of elements
        ReactiveMailingListFormConsumer(
          builder: (context, form, child) {
            // map error keys to text
            final errorText = {
              'emailDuplicates': 'Two identical emails are in the list',
            };
            final errors = <String, dynamic>{};

            // filter values related to individual text fields
            form.emailListControl.errors.forEach((key, value) {
              final intKey = int.tryParse(key);
              if (intKey == null) {
                errors[key] = value;
              }
            });
            
            // if there is still erros left - render an error message 
            if (form.emailListControl.hasErrors && errors.isNotEmpty) {
              return Text(errorText[errors.entries.first.key] ?? '');
            } else {
              return Container();
            }
          },
        ),
        SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                if (formModel.form.valid) {
                  print(formModel.model);
                } else {
                  formModel.form.markAllAsTouched();
                }
              },
              child: const Text('Sign Up'),
            ),
            ReactiveMailingListFormConsumer(
              builder: (context, form, child) {
                return ElevatedButton(
                  child: Text('Submit'),
                  onPressed: form.form.valid ? () {} : null,
                );
              },
            ),
          ],
        )
      ],
    );
  },
);
```

### Nested forms with FormGroups

The next example will show how to build nested forms. We will create a user profile form with first/last names 
and home/office addresses. Address will contain city/street/zip fields.

#### Model <a name="group-model" />
The model will be separated on two parts `UserProfile` and `Address`

```dart
class UserProfile {
  final String firstName;

  final String lastName;

  final Address? home;

  final Address? office;

  UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.home,
    this.office,
  });
}

class Address {
  final String? street;

  final String? city;

  final String? zip;

  Address({
    this.street,
    this.city,
    this.zip,
  });
}

```

#### Annotation <a name="group-annotation" />

The next step is to add annotations to help generator do his job.

```dart
import 'package:example/helpers.dart';
import 'package:reactive_forms_annotations/reactive_forms_annotations.dart';

@ReactiveFormAnnotation()
class UserProfile {
  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String firstName;

  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String lastName;

  final Address? home;

  final Address? office;

  UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.home,
    this.office,
  });
}

@FormGroupAnnotation()
class Address {
  @FormControlAnnotation()
  final String? street;

  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String? city;

  @FormControlAnnotation()
  final String? zip;

  Address({
    this.street,
    this.city,
    this.zip,
  });
}
```

`ReactiveFormAnnotation` - tells the generator that we want to Form based on this model.
`FormGroupAnnotation` - describes the nested form.

#### Validation <a name="group-validation" />

We will use only simple `requiredValidator` for first/last names and city.

```dart
Map<String, dynamic>? requiredValidator(AbstractControl<dynamic> control) {
  return Validators.required(control);
}
```

As far as we are using annotations - validators should be top level functions or static class fields.

Now we are ready to run our form generator. You can check output [here](https://github.com/artflutter/reactive_forms_generator/blob/master/packages/reactive_forms_generator/example/lib/docs/group/user_profile.gform.dart).

#### Form <a name="group-form" />

Let's build our form based on generated code

```dart
// create form based on generated widget
final form = UserProfileFormBuilder(
  model: UserProfile(),
  builder: (context, formModel, child) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReactiveTextField<String>(
            formControl: formModel.firstNameControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'First name',
            ),
          ),
          const SizedBox(height: 8.0),
          ReactiveTextField<String>(
            formControl: formModel.lastNameControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'Last name',
            ),
          ),
          const SizedBox(height: 24.0),
          Text('Home address', style: TextStyle(fontSize: 18)),
          ReactiveTextField<String>(
            formControl: formModel.homeForm.cityControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'Home city',
            ),
          ),
          const SizedBox(height: 8.0),
          ReactiveTextField<String>(
            formControl: formModel.homeForm.streetControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'Home street',
            ),
          ),
          const SizedBox(height: 8.0),
          ReactiveTextField<String>(
            formControl: formModel.homeForm.zipControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Home zip',
            ),
          ),
          const SizedBox(height: 8.0),
          Text('Office address', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8.0),
          ReactiveTextField<String>(
            formControl: formModel.officeForm.cityControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'Office city',
            ),
          ),
          const SizedBox(height: 8.0),
          ReactiveTextField<String>(
            formControl: formModel.officeForm.streetControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'Office street',
            ),
          ),
          const SizedBox(height: 8.0),
          ReactiveTextField<String>(
            formControl: formModel.officeForm.zipControl,
            validationMessages: (control) => {
              ValidationMessage.required: 'Must not be empty',
            },
            decoration: const InputDecoration(
              labelText: 'Office zip',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (formModel.form.valid) {
                print(formModel.model);
              } else {
                formModel.form.markAllAsTouched();
              }
            },
            child: const Text('Sign Up'),
          ),
          ReactiveUserProfileFormConsumer(
            builder: (context, form, child) {
              return ElevatedButton(
                child: Text('Submit'),
                onPressed: form.form.valid
                        ? () {
                  print(form.model.firstName);
                  print(form.model.lastName);
                }
                        : null,
              );
            },
          ),
        ],
      ),
    );
  },
);
```

### Nested forms with array of FormGroups

The next example will show how to build nested forms. We will create a delivery list with simple control for `name` and 
form group for `address`; Address will contain city/street fields.

#### Model <a name="array-group-model" />
The model will be separated on three parts `DeliveryList`, `DeliveryPoint` and `Address`

```dart
class DeliveryList {
  final List<DeliveryPoint> deliveryList;

  DeliveryList({
    this.deliveryList = const [],
  });
}

class DeliveryPoint {
  final String name;

  final Address? address;

  DeliveryPoint({
    this.name = '',
    this.address,
  });
}

class Address {
  final String? street;

  final String? city;

  Address({
    this.street,
    this.city,
  });
}
```

#### Annotation <a name="array-group-annotation" />

The next step is to add annotations to help generator do his job.

```dart
@FormGroupAnnotation()
class DeliveryPoint {
  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String name;

  final Address? address;

  DeliveryPoint({
    this.name = '',
    this.address,
  });
}

@FormGroupAnnotation()
class Address {
  @FormControlAnnotation(
    validators: const [requiredValidator],
  )
  final String? street;

  @FormControlAnnotation()
  final String? city;

  Address({
    this.street,
    this.city,
  });
}
```

`ReactiveFormAnnotation` - tells the generator that we want to Form based on this model.
`FormGroupAnnotation` - describes the nested form.

Now we are ready to run our form generator. You can check output [here](https://github.com/artflutter/reactive_forms_generator/blob/master/packages/reactive_forms_generator/example/lib/docs/array_group/delivery_list.gform.dart).

#### Form <a name="array-group-form" />

Let's build our form based on generated code

```dart
// create form based on generated widget
final form = DeliveryListFormBuilder(
  model: DeliveryList(),
  builder: (context, formModel, child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ReactiveFormArray<Map<String, Object?>>(
                formArray: formModel.deliveryListControl,
                builder: (context, formArray, child) {
                  return Column(
                    children: formModel.deliveryListValue
                            .asMap()
                            .map((i, deliveryPoint) {
                      return MapEntry(
                              i,
                              Column(
                                children: [
                                  ReactiveTextField<String>(
                                    formControlName: '${i}.name',
                                    validationMessages: (_) => {
                                      ValidationMessage.required:
                                      'Must not be empty',
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Name ${i}',
                                    ),
                                  ),
                                  ReactiveTextField<String>(
                                    formControlName:
                                    '${i}.address.street',
                                    validationMessages: (_) => {
                                      ValidationMessage.required:
                                      'Must not be empty',
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Street ${i}',
                                    ),
                                  ),
                                  ReactiveTextField<String>(
                                    formControlName: '${i}.address.city',
                                    validationMessages: (_) => {
                                      ValidationMessage.required:
                                      'Must not be empty',
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'City ${i}',
                                    ),
                                  ),
                                ],
                              ));
                    })
                            .values
                            .toList(),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                formModel.deliveryListControl.add(
                  FormGroup({
                    'name': FormControl<String>(value: ''),
                    'address': FormGroup({
                      'street': FormControl<String>(),
                      'city': FormControl<String>()
                    })
                  }),
                );
              },
              child: const Text('add'),
            )
          ],
        ),
        SizedBox(height: 16),
        SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                if (formModel.form.valid) {
                  print(formModel.model);
                } else {
                  formModel.form.markAllAsTouched();
                }
              },
              child: const Text('Sign Up'),
            ),
            ReactiveDeliveryListFormConsumer(
              builder: (context, form, child) {
                return ElevatedButton(
                  child: Text('Submit'),
                  onPressed: form.form.valid ? () {} : null,
                );
              },
            ),
          ],
        )
      ],
    );
  },
);
```