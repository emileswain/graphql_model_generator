import 'package:code_builder/code_builder.dart';

/// /////////////////////////////////////////////////////////
/// Validation and formating tools
/// /////////////////////////////////////////////////////////
/// Converting GQL types to Dart types and matching Flutter
/// naming conventions requires some formatting to be applied
/// to the various fields and internal vars defined in the
/// outputted code.
class Utils {
  /// /////////////////////////////////////////////////////////
  /// Convert between graphql schema types and dart types.
  ///   /// /////////////////////////////////////////////////////////
  static bool isDartType(String type) {
    try {
      return ["String", "int", "double", "bool", "Color"].contains(type);
    } catch (_) {
      return false;
    }
  }

  /// /////////////////////////////////////////////////////////
  /// Convert capital case words (i.e. class names) into snake case.
  /// MyClassName -> my_class_name
  /// /////////////////////////////////////////////////////////
  static String toSnakeCase(String input) {
    RegExp exp = RegExp(r'(?<=[a-z])[A-Z]+');
    String result = input.replaceAllMapped(exp, (Match m) => ('_${m.group(0) ?? ""}')).toLowerCase();
    return result;
  }

  /// /////////////////////////////////////////////////////////
  /// Capitalise a word.
  /// /////////////////////////////////////////////////////////
  static String capitalise(String s) => (s.length > 1) ? s[0].toUpperCase() + s.substring(1) : s.toUpperCase();

  /// /////////////////////////////////////////////////////////
  /// Convert the build runners packagePath into an import path.
  /// /////////////////////////////////////////////////////////
  /// packagePath = lib/data/models
  /// packagePath != packagePath = lib/data/models/
  /// packagePath != packagePath = lib/data/models/models.graphql
  ///
  /// Goal
  /// import 'package:your_app_package/data/models/image_model.dart';
  ///
  /// TODO make more robust by using path to join directories. it's Fragile.
  static Directive getTypeImportPathDirective(
      String typeClassName, String packageName, String packagePath) {
    String importPath = packagePath;
    importPath = importPath.replaceFirst("lib/", "");
    String typeClassPath = Utils.toSnakeCase(typeClassName);
    return Directive.import('package:$packageName/$importPath/$typeClassPath.dart');
  }
  static Directive getTypeExportPathDirective(
      String typeClassName, String packageName, String packagePath) {
    String importPath = packagePath;
    importPath = importPath.replaceFirst("lib/", "");
    String typeClassPath = Utils.toSnakeCase(typeClassName);
    return Directive.export('package:$packageName/$importPath/$typeClassPath.dart');
  }

  /// /////////////////////////////////////////////////////////
  /// Convert between graphql schema types and dart types.
  /// /////////////////////////////////////////////////////////
  static String gqlTypeToDartType(String type) {
    switch (type) {
      case "Int":
        return "int";
      case "Float":
        return "double";
      case "Boolean":
        return "bool";
      case "string":
        return "String";
      case "color":
      case "Color":
        return "Color";
      default:
        return type;
    }
  }
}
