import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_model_generator/builders/gql_to_model_builder.dart';

import 'package:graphql_model_generator/common/utils.dart';
import "package:gql/language.dart" as lang;
import 'package:graphql_model_generator/writers/basic_class_writer.dart';
void main() {
  test('utils.capitalise() capitalises.', () {
    String source = "lowerCased";
    String goal = "LowerCased";
    expect(Utils.capitalise(source), goal);
  });
  test('utils.toSnakeCase() snakeCases.', () {
    String source = "MyCustomClassName";
    String goal = "my_custom_class_name";
    expect(Utils.toSnakeCase(source), goal);

    String sourceStartsWithMultipleCaps = "MYCAPCustomClassName";
    String goalStartsWithMultipleCaps = "mycapcustom_class_name";
    expect(Utils.toSnakeCase(sourceStartsWithMultipleCaps),
        goalStartsWithMultipleCaps);

    String sourceMultipleCaps = "MyMCCustomClassName";
    String goalMultipleCaps = "my_mccustom_class_name";
    expect(Utils.toSnakeCase(sourceMultipleCaps), goalMultipleCaps);
  });
  test('utils.getTypeImportPathDirective()', () {
    String source = "lib/data/models";
    String goal = "package:your_app_package/data/models/image_model.dart";
    expect(
        Utils.getTypeImportPathDirective(
                "imageModel", "your_app_package", source)
            .url,
        goal);
  });
  test('utils.getTypeExportPathDirective()', () {
    String source = "lib/data/models";
    String goal = "package:your_app_package/data/models/image_model.dart";
    expect(
        Utils.getTypeExportPathDirective(
                "imageModel", "your_app_package", source)
            .url,
        goal);
  });

  test('utils.gqlTypeToDartType()', () {
    expect(Utils.gqlTypeToDartType('Int'), 'int');
    expect(Utils.gqlTypeToDartType('Float'), 'double');
    expect(Utils.gqlTypeToDartType('Boolean'), 'bool');
    expect(Utils.gqlTypeToDartType('string'), 'String');
    expect(Utils.gqlTypeToDartType('Int'), 'int');
    expect(Utils.gqlTypeToDartType('color'), 'Color');
  });

  test('utils.isDartType()', () {
    expect(Utils.isDartType('String'), true);
    expect(Utils.isDartType('int'), true);
    expect(Utils.isDartType('double'), true);
    expect(Utils.isDartType('bool'), true);
    expect(Utils.isDartType('Color'), true);
    expect(Utils.isDartType('MyClass'), false);
    expect(Utils.isDartType('SomeOtherClass'), false);
    expect(Utils.isDartType('ool'), false);
  });

  var graphqlString = '''
"""
something before
@const
"""
type Author {
    name: String!,
    """
    @DefaultValue("12/4/2000")
    """
    date: Date!,
    
    """
    @DefaultValue(false)
    """
    isTrue: bool!,
    
    """
    @DefaultValue ("a string")
    """
    defaultString : String!,
}
  ''';

  test('parse file. ', () {

    var packageName = "test.package";
    var importPath = "";

    final DocumentNode doc = lang.parseString(graphqlString);
    final TypeVisitor v = TypeVisitor();
    doc.accept(v);
    // ListBuilder<Directive> classImportDirectives = ListBuilder<Directive>();

    for (var gqlType in v.types) {
      try {
        // String typeName = gqlType.name.value;
        // Generate and write class to disk
        BasicClassWriter interpreter =
        BasicClassWriter(gqlType, packageName, importPath);
        String classBody = interpreter.writeClassFromGQLType();
        // writeToFile(buildStep, typeName, classBody);
        if (kDebugMode) {
          print (classBody);
        }

        // generate import directive for builder output class.
        // classImportDirectives.add(Utils.getTypeExportPathDirective(
        //     typeName, packageName, importPath));
      } catch (err) {
        // developer.log(err.toString());
      }
    }

  });
}
