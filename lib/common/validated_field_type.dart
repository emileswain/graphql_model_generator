import 'package:gql/ast.dart';
import 'package:graphql_model_generator/common/comment_attribute.dart';
import 'package:graphql_model_generator/common/utils.dart';

/// A class that determines and returns various facts derived from a graphql's child field.
///
/// Given the FieldDefinitionNode from ast for the GraphQL type,
/// determine various properties that will be used to write the class model
/// For example...
/// * is the field a List
/// * is it a dartType or CustomClass
/// * ensures the field name is valid
/// * ensures the field type is valid
/// * checks edge case scenarios such as if the field is a Color etc.
///
/// These values are used by the writer class to determine how to format the final output.
class ValidatedFieldType {
  /// prefix (default = mt) for unsupported graphql fields such as __somemetafield
  static String doubleUnderscoreReplacement = "mt";

  /// Future mame of class model field
  final String name;

  /// Future type of class model field
  final String fieldType;

  /// Whether the field is a List<type>()
  final bool isList;

  /// Whether or not the field is a standard dart type.
  final bool isDartType;

  /// Whether the field is specifically a Color type.
  final bool isColorType;

  /// Determines if the field can be nullable or not
  final bool nullable;

  /// Default value for field.
  final String defaultValue;

  /// A representation of the graphql field. Used to later write specific code output.
  ValidatedFieldType(
      {required this.name,
      required this.fieldType,
      required this.isList,
      required this.isDartType,
      required this.isColorType,
      required this.nullable,
      required this.defaultValue});

  /// Parse the details of a specific graphql type field definition returning an instance of [ValidatedFieldType]
  factory ValidatedFieldType.parseGqlField(FieldDefinitionNode gqlField) {
    String fieldType;
    bool isList = false;
    bool isColorType = false;
    String defaultValue = "";

    String fieldName = gqlField.name.value;
    // print("Parsing field type: ${fieldName}");

    /// Parse field behaviours
    Modifiers modifiers = Modifiers(gqlField.description?.value ?? "");
    if (modifiers.hasModifier(ModificationType.defaultValue)) {
      Modifier defaultModifier = modifiers.getModifier(ModificationType.defaultValue);
      defaultValue = defaultModifier.value;
    }

    /// Validate field name for flutter
    ///
    /// Convert graphql field names with double underscore to a valid flutter field name.
    /// Edit ValidatedFieldType.doubleUnderscoreReplacement static member (default mt)
    /// __SomeFieldName -> mtSomeFieldName
    if (fieldName.startsWith("__")) {
      fieldName = fieldName.replaceFirst("__", "");
      fieldName = fieldName[0].toUpperCase() + fieldName.substring(1);
      fieldName = '$doubleUnderscoreReplacement${Utils.capitalise(fieldName)}';
      // print("  converted invalid field name to : $fieldName");
    }

    /// Determine fieldType
    ///
    if (gqlField.type is NamedTypeNode) {
      fieldType = (gqlField.type as NamedTypeNode).name.value;
    } else if (gqlField.type is ListTypeNode) {
      fieldType = ((gqlField.type as ListTypeNode).type as NamedTypeNode).name.value;
      isList = true;
    } else {
      throw Exception(
          "Unhandled ast.type cast in gql_class_builder.dart in build_runner graphql_model_generator|graphql_model_builder");
    }

    /// Ensure base types are valid Dart types.
    fieldType = Utils.gqlTypeToDartType(fieldType);

    /// Check for specific edge cases such as if type requires
    /// specific import directives.
    ///
    if (fieldType.toLowerCase() == "color") {
      isColorType = true;
    }

    /// done
    return ValidatedFieldType(
        name: fieldName,
        fieldType: fieldType,
        isList: isList,
        isDartType: Utils.isDartType(fieldType),
        isColorType: isColorType,
        nullable: !gqlField.type.isNonNull,
        defaultValue: defaultValue);
  }
}
