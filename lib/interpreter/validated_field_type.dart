import 'package:gql/ast.dart';
import 'package:graphql_model_generator/interpreter/utils.dart';

/// Given the FieldDefinitionNode from ast for the GraphQL type,
/// determine various properties that will be used to write the class model
/// For example, is the field a List, is it a dartType or a custom Model type.
class ValidatedFieldType {
  static String doubleUnderscoreReplacement = "mt";

  final String name;
  final String fieldType;
  final bool isList;
  final bool isDartType;
  final bool isColorType;

  ValidatedFieldType(
      {required this.name,
      required this.fieldType,
      required this.isList,
      required this.isDartType,
      required this.isColorType});

  factory ValidatedFieldType.parseGqlField(FieldDefinitionNode gqlField) {
    String fieldType;
    bool isList = false;
    bool isColorType = false;
    String fieldName = gqlField.name.value;
    // print("Parsing field type: ${fieldName}");

    /// /////////////////////////////////////////////////////////
    /// Validate field name for flutter
    /// /////////////////////////////////////////////////////////
    /// Convert graphql field names with double underscore to a valid flutter field name.
    /// Edit ValidatedFieldType.doubleUnderscoreReplacement static member (default mt)
    /// __SomeFieldName -> mtSomeFieldName
    if (fieldName.startsWith("__")) {
      fieldName = fieldName.replaceFirst("__", "");
      fieldName = fieldName[0].toUpperCase() + fieldName.substring(1);
      fieldName = '$doubleUnderscoreReplacement${Utils.capitalise(fieldName)}';
      // print("  converted invalid field name to : $fieldName");
    }

    /// /////////////////////////////////////////////////////////
    /// Determine fieldType
    /// /////////////////////////////////////////////////////////
    if (gqlField.type is NamedTypeNode) {
      fieldType = (gqlField.type as NamedTypeNode).name.value;
    } else if (gqlField.type is ListTypeNode) {
      fieldType = ((gqlField.type as ListTypeNode).type as NamedTypeNode).name.value;
      isList = true;
    } else {
      throw Exception(
          "Unhandled ast.type cast in gql_class_builder.dart in build_runner graphql_model_generator|graphql_model_builder");
    }
    // Ensure base types are valid Dart types.
    fieldType = Utils.gqlTypeToDartType(fieldType);

    /// /////////////////////////////////////////////////////////
    /// Check for specific edge cases such as if type requires
    /// specific import directives.
    /// /////////////////////////////////////////////////////////
    if (fieldType.toLowerCase() == "color") {
      isColorType = true;
    }

    /// /////////////////////////////////////////////////////////
    /// done
    /// /////////////////////////////////////////////////////////
    return ValidatedFieldType(
        name: fieldName,
        fieldType: fieldType,
        isList: isList,
        isDartType: Utils.isDartType(fieldType),
        isColorType: isColorType);
  }
}
