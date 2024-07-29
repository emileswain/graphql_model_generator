/// The type of directive.
enum ModificationType {
  /// for not found in firstWhere
  none,

  /// Set the class to a const class.
  constClass,

  /// Set a default Value to the field.
  defaultValue,
}

///
class Modifiers {
  ///
  final List<Modifier> modifiers = List<Modifier>.empty(growable: true);

  ///
  Modifiers(String comment) {
    _parseComment(comment);
  }

  ///
  List<Modifier> _parseComment(String comments) {
    comments.split('\n').forEach((element) {
      try {
        var modifier = Modifier.parseComment(element);
        if (modifier.type != ModificationType.none) {
          modifiers.add(modifier);
          // print("Parsed and added an instruction. ${modifier.type}");
        }
      } catch (e) {
        // print("ignoring line ");
      }
    });
    return modifiers;
  }

  /// Whether or not the modifiers includes the specified modifier
  bool hasModifier(ModificationType type) {
    var foundIndex = modifiers.indexWhere((element) {
      return element.type == type;
    });
    return foundIndex != -1;
  }

  /// Returns a modifier matching the type. returns A modifier with type None is not found.
  Modifier getModifier(ModificationType type) {
    return modifiers.firstWhere((element) => element.type == type,
        orElse: () => Modifier(type: ModificationType.none, comment: "notfound"));
  }
}

/// An instruction within the graphql comments to customise the
/// builder behaviour. I.e. set default values, const Classes, etc.
class Modifier {
  /// The original comment source
  final String comment;

  /// The type of customisation.
  final ModificationType type;

  /// A default value.
  final dynamic value;

  /// A directive may provide details of how to configure the builder.
  Modifier({required this.type, required this.comment, this.value});

  /// Parse a directive comment and return a valid configured Directive.
  /// TODO(emile.swain): rewrite to factory with hash lookup.
  static Modifier parseComment(String comment) {
    if (comment.startsWith("@const")) {
      return Modifier(type: ModificationType.constClass, comment: comment);
    } else if (comment.startsWith("@DefaultValue")) {
      var v = "test";
      v = comment.substring(comment.indexOf("(")+1, comment.lastIndexOf(")"));
      return Modifier(type: ModificationType.defaultValue, comment: comment, value: v);
    } else {
      throw Exception("invalid Directive comment");
    }
  }
}
