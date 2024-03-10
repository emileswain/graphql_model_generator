import 'package:flutter_test/flutter_test.dart';

import 'package:graphql_model_generator/common/utils.dart';

void main() {
  test('utils.capitalise() capitalises.', () {
    String source = "lowerCased";
    String goal = "LowerCased";
    expect( Utils.capitalise(source), goal);
  });
  test('utils.toSnakeCase() snakeCases.', () {
    String source = "MyCustomClassName";
    String goal = "my_custom_class_name";
    expect( Utils.toSnakeCase(source), goal);

    String sourceStartsWithMultipleCaps = "MYCAPCustomClassName";
    String goalStartsWithMultipleCaps = "mycapcustom_class_name";
    expect( Utils.toSnakeCase(sourceStartsWithMultipleCaps), goalStartsWithMultipleCaps);

    String sourceMultipleCaps = "MyMCCustomClassName";
    String goalMultipleCaps = "my_mccustom_class_name";
    expect( Utils.toSnakeCase(sourceMultipleCaps), goalMultipleCaps);
  });
  test('utils.getTypeImportPathDirective()', () {
    String source = "lib/data/models";
    String goal = "package:your_app_package/data/models/image_model.dart";
    expect( Utils.getTypeImportPathDirective("imageModel","your_app_package",source).url, goal);
  });
  test('utils.getTypeExportPathDirective()', () {
    String source = "lib/data/models";
    String goal = "package:your_app_package/data/models/image_model.dart";
    expect( Utils.getTypeExportPathDirective("imageModel","your_app_package",source).url, goal);
  });

  test('utils.gqlTypeToDartType()', () {
    expect( Utils.gqlTypeToDartType('Int'), 'int');
    expect( Utils.gqlTypeToDartType('Float'), 'double');
    expect( Utils.gqlTypeToDartType('Boolean'), 'bool');
    expect( Utils.gqlTypeToDartType('string'), 'String');
    expect( Utils.gqlTypeToDartType('Int'), 'int');
    expect( Utils.gqlTypeToDartType('color'), 'Color');
  });

  test('utils.isDartType()', () {
    expect( Utils.isDartType('String'), true);
    expect( Utils.isDartType('int'), true);
    expect( Utils.isDartType('double'), true);
    expect( Utils.isDartType('bool'), true);
    expect( Utils.isDartType('Color'), true);
    expect( Utils.isDartType('MyClass'), false);
    expect( Utils.isDartType('SomeOtherClass'), false);
    expect( Utils.isDartType('ool'), false);

  });
}
