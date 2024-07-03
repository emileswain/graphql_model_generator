import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gql/ast.dart';
import 'package:graphql_model_generator/common/utils.dart';
import 'package:graphql_model_generator/common/validated_field_type.dart';

/// Generates custom dart class given the graphQL type data.
///
/// Implements a super basic typical flutter type model class.
/// Doesn't implement Freezed or any other conventions.
///
/// Very basic starter classes.
///
/// Graphql example
/// ```graphql
/// type ImageModel{
///     name: String!,
///     author: Author!,
///     title: String!,
///     url: String!,
///     tags: [String]!,
///     altText: String!,
/// }
/// ```
///
/// Output Class.
/// ```dart
/// import 'package:your_app_package/data/models/author.dart';
///
/// class ImageModel {
///   ImageModel({
///     required this.name,
///     required this.author,
///     required this.title,
///     required this.url,
///     required this.tags,
///     required this.altText,
///   });
///
///   factory ImageModel.fromJson(Map<String, dynamic> json) {
///     List<String> newTags = [];
///     final jsonTags = List<dynamic>.from(json['tags']).toList();
///     for (var itemData in jsonTags) {
///       final item = itemData;
///       if (item != null) {
///         newTags.add(item);
///       }
///     }
///     return ImageModel(
///       name: json['name'],
///       author: json['author'],
///       title: json['title'],
///       url: json['url'],
///       tags: newTags,
///       altText: json['altText'],
///     );
///   }
///
///   final String name;
///
///   final Author author;
///
///   final String title;
///
///   final String url;
///
///   final List<String> tags;
///
///   final String altText;
///
///   Map<String, dynamic> toJson() => {
///         "name": name,
///         "author": author.toJson(),
///         "title": title,
///         "url": url,
///         "tags": tags.map((item) => item).toList(),
///         "altText": altText,
///       };
///
///   ImageModel copyWith({
///     String? name,
///     Author? author,
///     String? title,
///     String? url,
///     List<String>? tags,
///     String? altText,
///   }) {
///     return ImageModel(
///       name: name ?? this.name,
///       author: author ?? this.author,
///       title: title ?? this.title,
///       url: url ?? this.url,
///       tags: tags ?? this.tags,
///       altText: altText ?? this.altText,
///     );
///   }
/// }
/// ```
class BasicClassWriter {
  /// import for supporting Color type.
  static String colourTypeImportDirective = 'package:flutter/material.dart';

  /// graphql data received from ast
  ObjectTypeDefinitionNode gqlType;

  /// the package name for importing dependencies & this file.
  String packageName;

  /// the package path for importing dependencies & this file.
  String packagePath;

  /// Outputs a basic flutter model class given the gqlType data.
  ///
  /// @param gqlType Graphql ast Type information
  /// @param packageName Project package name
  /// @param packagePath Package path
  BasicClassWriter(this.gqlType, this.packageName, this.packagePath);

  /// Generate the Model class with
  /// * +fromJson()
  /// * +toJson()
  /// * +copyWith()
  /// @returns Class body as a string.
  String writeClassFromGQLType() {
    // print(" Generating model for (gqlType.name) :  ${gqlType.name.value}");

    String className = gqlType.name.value;
    List<Directive> classImportDirectives = List<Directive>.empty(growable: true);
    ListBuilder<Field> classFields = ListBuilder<Field>();
    ListBuilder<Parameter> classConstructorOptionalParameters = ListBuilder<Parameter>();

    List<ValidatedFieldType> validatedFields = List<ValidatedFieldType>.empty(growable: true);

    /// Pre-process gqlType field data.
    ///
    /// Read the type fields using the ValidatedFieldType.parseGqlField() to pre-determine certain
    /// properties of the field, for example valid field name, if its a List or not.
    /// These values are then used to customise the properties of the code_builders class definition
    /// methods and final output.
    /// We also use this loop to define the imports, classConstructorOptionalParameters and classFields
    for (var gqlField in gqlType.fields) {
      /// Pre-process type information
      ValidatedFieldType validatedFieldType = ValidatedFieldType.parseGqlField(gqlField);

      /// Add import directives
      // Set the import directives for the class field types that require imports.
      // i.e. import 'package:your_app_package/data/models/author.dart';
      if (!validatedFieldType.isDartType) {
        // classImportDirectives
        //     .add(Utils.getTypeImportPathDirective(validatedFieldType.fieldType, packageName, packagePath));
        var import = Utils.getTypeImportPathDirective(validatedFieldType.fieldType, packageName, packagePath);
        var found = classImportDirectives.firstWhere((element) => element.url == import.url,
            orElse: () => Directive.import("NotFound"));
        if (found.url == "NotFound") {
          classImportDirectives.add(import);
        }
      }
      if (validatedFieldType.isColorType) {
        var import = Directive.import(colourTypeImportDirective);
        var found = classImportDirectives.firstWhere((element) => element.url == import.url,
            orElse: () => Directive.import("NotFound"));
        if (found.url == "NotFound") {
          classImportDirectives.add(import);
        }
      }

      /// set the class constructor parameters.
      /// i.e. {required this.name,}
      classConstructorOptionalParameters.add(Parameter((p) =>
      p
        ..name = validatedFieldType.name
        ..required = true
        ..toThis = true
        ..named = true));

      /// set the class fields
      /// ie. final String name;
      classFields.add(Field((f) =>
      f
        ..name = validatedFieldType.name
        ..modifier = FieldModifier.final$
        ..type = validatedFieldType.isList
            ? Reference("List<${validatedFieldType.fieldType}>")
            : Reference(validatedFieldType.fieldType)));

      /// Store validatedFields for use in generating child methods.
      validatedFields.add(validatedFieldType);
    }

    /// Build Class constructor and Factory methods.
    /// * i.e. +ImageModel()
    /// * +fromJson()
    ///
    ListBuilder<Constructor> classConstructors = ListBuilder<Constructor>();
    Constructor classConstructor = Constructor(
          (c) => c..optionalParameters = classConstructorOptionalParameters,
    );
    Constructor fromJsonConstructor = generateFromJsonConstructor(className, validatedFields);
    classConstructors.add(classConstructor);
    classConstructors.add(fromJsonConstructor);

    /// create the various class methods.
    /// * +toJson()
    /// * +copyWith()
    ///
    Method toJsonMethod = generateToJsonMethod(validatedFields);
    Method copyWithMethod = generateCopyWithMethod(className, validatedFields);

    /// Finally create the Model Class for the graphql type.
    ///
    Class typeClass = Class((b) =>
    b
      ..name = className
      ..constructors = classConstructors
      ..fields = classFields
      ..methods.add(toJsonMethod)
      ..methods.add(copyWithMethod));

    /// Format and write the class to string using DartFormatter
    ///
    /// Ensuring to wrap in a code_builder Library() to support imports
    final emitter = DartEmitter(
      allocator: Allocator(),
      orderDirectives: true,
    );

    var directives = ListBuilder<Directive>();
    directives.addAll(classImportDirectives);

    final library = Library((l) =>
    l
      ..body.add(typeClass)
      ..directives = directives);

    return DartFormatter().format('${library.accept(emitter)}');
  }

  /// Create fromJson Constructor factory method.
  ///
  /// Graphql example
  /// ```graphql
  /// type ImageModel{
  ///     name: String!,
  ///     author: Author!,
  ///     title: String!,
  ///     url: String!,
  ///     tags: [String]!,
  ///     altText: String!,
  /// }
  /// ```
  ///
  /// Method
  /// ```dart
  ///   factory ImageModel.fromJson(Map<String, dynamic> json) {
  ///     List<String> newTags = [];
  ///     final jsonTags = List<dynamic>.from(json['tags']).toList();
  ///     for (var itemData in jsonTags) {
  ///       final item = itemData;
  ///       if (item != null) {
  ///         newTags.add(item);
  ///       }
  ///     }
  ///     return ImageModel(
  ///       name: json['name'],
  ///       author: json['author'],
  ///       title: json['title'],
  ///       url: json['url'],
  ///       tags: newTags,
  ///       altText: json['altText'],
  ///     );
  ///   }
  /// ```
  ///
  /// @param className Name of class
  /// @param validatedFields List of class fields
  /// @returns Constructor instance describing factory fromJson() method.
  Constructor generateFromJsonConstructor(String className, List<ValidatedFieldType> validatedFields) {
    // fromJson Factory method code
    StringBuffer sb = StringBuffer();

    // Write the parsing json array blocks
    for (var validatedFieldType in validatedFields) {
      if (validatedFieldType.isList) {
        var capped = Utils.capitalise(validatedFieldType.name);
        sb.writeln("List<${validatedFieldType.fieldType}> new$capped = [];");
        sb.writeln("final json$capped = List<dynamic>.from(json['${validatedFieldType.name}']).toList();");

        sb.writeln("for (var itemData in json$capped) {");

        sb.writeln("try {"); // Open Try

        if (!validatedFieldType.isDartType) {
          sb.writeln("final item = ${validatedFieldType.fieldType}.fromJson(itemData);");
        } else {
          sb.writeln("final item = itemData;");
        }

        //sb.writeln("if (item != null) {");
        sb.writeln(" new$capped.add(item);");
        //sb.writeln("}");// end if
        sb.writeln("}catch(e){");
        sb.writeln("// fix"); // end catch
        sb.writeln("}"); // end catch

        sb.writeln("}");
      }
    }

    // Write Return statement.
    sb.write("return $className(");
    for (var validatedFieldType in validatedFields) {
      if (validatedFieldType.isList) {
        var capped = Utils.capitalise(validatedFieldType.name);
        sb.write(" ${validatedFieldType.name}: new$capped ,");
      } else {
        sb.write(" ${validatedFieldType.name}: json['${validatedFieldType.name}'] ,");
      }
    }
    sb.write(");");

    Constructor fromJsonConstructor = Constructor((c) =>
    c
      ..name = "fromJson"
      ..factory = true
      ..requiredParameters = ListBuilder({
        Parameter((p) =>
        p
          ..name = 'json'
          ..type = const Reference("Map<String, dynamic>"))
      })
    // ..body = const Code("return ImageModel(name: json['name'],title: json['title'],url: json['url'],);"));
      ..body = Code(sb.toString()));

    return fromJsonConstructor;
  }

  /// Generate the toJson method.
  ///
  /// Graphql example
  /// ```graphql
  /// type ImageModel{
  ///     name: String!,
  ///     author: Author!,
  ///     title: String!,
  ///     url: String!,
  ///     tags: [String]!,
  ///     altText: String!,
  /// }
  /// ```
  ///
  /// Class toJson() method
  /// ```dart
  ///   Map<String, dynamic> toJson() => {
  ///         "name": name,
  ///         "author": author.toJson(),
  ///         "altText": altText,
  ///         "tags": tags.map((item) => item).toList(),
  ///         "heroImage": heroImage.toJson(),
  ///         "images": images.map((item) => item.toJson()).toList(),
  ///       };
  /// ```
  ///
  /// @param validatedFields List of class fields
  /// @returns Method instance describing toJson() method.
  Method generateToJsonMethod(List<ValidatedFieldType> validatedFields) {
    StringBuffer sb = StringBuffer();
    sb.writeln("{");
    for (var validatedFieldType in validatedFields) {
      // working with none lists.
      if (!validatedFieldType.isList) {
        if (validatedFieldType.isDartType) {
          sb.writeln('"${validatedFieldType.name}" : ${validatedFieldType.name},');
        } else {
          sb.writeln('"${validatedFieldType.name}" : ${validatedFieldType.name}.toJson(),');
        }
      } else {
        // working with Lists
        if (validatedFieldType.isDartType) {
          sb.writeln('"${validatedFieldType.name}" : ${validatedFieldType.name}.map((item) => item).toList(),');
        } else {
          sb.writeln(
              '"${validatedFieldType.name}" : ${validatedFieldType.name}.map((item) => item.toJson()).toList(),');
        }
      }
    }
    sb.writeln("}");

    // toJson Method
    Method toJsonMethod = Method((m) =>
    m
      ..name = "toJson"
      ..lambda = true
      ..returns = const Reference("Map<String, dynamic>")
      ..body = Code(sb.toString()));

    return toJsonMethod;
  }

  /// Generates copyWithMethod()
  ///
  /// Graphql example
  /// ```graphql
  /// type ImageModel{
  ///     name: String!,
  ///     author: Author!,
  ///     title: String!,
  ///     url: String!,
  ///     tags: [String]!,
  ///     altText: String!,
  /// }
  /// ```
  ///
  /// class method
  /// ```dart
  /// ImageCollection copyWith({
  ///   String? name,
  ///   Author? author,
  ///   String? altText,
  ///   List<String>? tags,
  ///   ImageModel? heroImage,
  ///   List<ImageModel>? images,
  /// }) {
  ///   return ImageCollection(
  ///     name: name ?? this.name,
  ///     author: author ?? this.author,
  ///     altText: altText ?? this.altText,
  ///     tags: tags ?? this.tags,
  ///     heroImage: heroImage ?? this.heroImage,
  ///     images: images ?? this.images,
  ///   );
  /// }
  /// ```
  /// @param className Name of class
  /// @param validatedFields List of class fields
  /// @returns Method instance describing copyWith() method.
  Method generateCopyWithMethod(String className, List<ValidatedFieldType> validatedFields) {
    ListBuilder<Parameter> methodParameters = ListBuilder<Parameter>();

    StringBuffer sb = StringBuffer();

    sb.writeln("return $className(");
    for (var validatedFieldType in validatedFields) {
      sb.writeln("${validatedFieldType.name} : ${validatedFieldType.name} ?? this.${validatedFieldType.name}, ");
      var fieldType = validatedFieldType.fieldType;
      if (validatedFieldType.isList) {
        fieldType = "List<$fieldType>";
      }
      // Save an additional loop, also do parameters
      methodParameters.add(Parameter((p) =>
      p
        ..name = validatedFieldType.name
        ..type = Reference("$fieldType?")
        ..required = false
        ..toThis = false
        ..named = true));
    }
    sb.writeln(");");

    // toJson Method
    Method copyWithMethod = Method((m) =>
    m
      ..name = "copyWith"
      ..lambda = false
      ..optionalParameters = methodParameters
      ..returns = Reference(className)
      ..body = Code(sb.toString()));

    return copyWithMethod;
  }
}
