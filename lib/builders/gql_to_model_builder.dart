import 'dart:async';
import 'dart:io';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:gql/ast.dart';
import 'package:graphql_model_generator/writers/basic_class_writer.dart';
import 'package:graphql_model_generator/common/utils.dart';
import 'package:path/path.dart' as p;
import "package:gql/language.dart" as lang;
import 'dart:developer' as developer;

/// ast TypeVisitor. Used to read graphql types.
class TypeVisitor extends RecursiveVisitor {
  /// TypeVisitor types to process
  Iterable<ObjectTypeDefinitionNode> types = [];

  /// Recursive func to parse Nodes.
  @override
  visitObjectTypeDefinitionNode(
    ObjectTypeDefinitionNode node,
  ) {
    types = types.followedBy([node]);
    super.visitObjectTypeDefinitionNode(node);
  }
}

/// The main builder class to manage reading of the files detected by build runner for processing
///
/// Reads the contents of the graphql file, parses them using ast and passes the information to [BasicClassWriter]
/// to write the final output.
///
class GQLToModelBuilder extends Builder {
  /// The main entry point for build runner.
  GQLToModelBuilder();

  /// Process the BuildStep, reading and parsing the file contents with ast and writing model classes to disk.
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    // cleanPreviousModelFiles(buildStep);

    var inputId = buildStep.inputId;
    var packageName = buildStep.inputId.package;
    var importPath = p.dirname(buildStep.inputId.path);
    ListBuilder<Directive> classImportDirectives = ListBuilder<Directive>();
    // developer.log("Processing buildStep $inputId");
    // developer.log(" buildStep.inputId.package :  $packageName");
    // developer.log(" buildStep.inputId.path :  ${buildStep.inputId.path}");
    // developer.log(" importPath :  ${importPath}");

    ///  Read file data & Implement ast graphql document read and loop through graphql types.
    ///
    ///  For each type we'll want to generate a dart model class and save it to disk.
    ///  Note that we are writing many files to disk and not just one file.
    ///  As such we'll need to  perform some file clean up first, manually.
    ///  It may be that we'd need to manually remove old Model classes
    ///  if they are removed from the graphql, because we won't have
    ///  any way of determining if they should be there or not.
    ///
    var graphqlString = await buildStep.readAsString(inputId);
    final DocumentNode doc = lang.parseString(graphqlString);
    final TypeVisitor v = TypeVisitor();
    doc.accept(v);

    /// Write new class model for every GQL type
    ///
    /// Loop through each type, write the class using code_builder and then save to folder
    /// relative to graph file.
    for (var gqlType in v.types) {
      try {
        String typeName = gqlType.name.value;
        // Generate and write class to disk
        BasicClassWriter interpreter =
            BasicClassWriter(gqlType, packageName, importPath);
        String classBody = interpreter.writeClassFromGQLType();
        writeToFile(buildStep, typeName, classBody);

        // generate import directive for builder output class.
        classImportDirectives.add(Utils.getTypeExportPathDirective(
            typeName, packageName, importPath));
      } catch (err) {
        developer.log(err.toString());
      }
    }

    /// write generic import class matching the input file.
    ///
    /// For example a lib/data/model/models.graphql file will be detected by the builder and generate
    /// a lib/data/models.graphql.dart file which will include all of the imports for the generated
    /// model classes.
    var copy = inputId.addExtension('.dart'); // graphql.dart

    final library = Library((l) => l..directives = classImportDirectives);
    final emitter = DartEmitter(
      allocator: Allocator(),
      orderDirectives: true,
    );
    await buildStep.writeAsString(
        copy, DartFormatter().format('${library.accept(emitter)}'));
  }

  /// Write a file to disc.
  ///
  /// For every Type found in the graphql file we will
  /// write a respective flutter class file.
  void writeToFile(
      BuildStep buildStep, String className, String classBody) async {
    String outputSubfolder = "";
    String d = p.dirname(buildStep.inputId.path);
    String fileName = '$className.dart';
    fileName = Utils.toSnakeCase(fileName);
    var file = await File(p.join(p.join(d, outputSubfolder), fileName))
        .create(recursive: true);
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.writeAsString(classBody, mode: FileMode.write);
  }

  /// Clean previously written class model files.
  ///
  /// A builder typically creates files that relate directly
  /// to the file the build is attempting to process. for example
  /// a g.part file.
  ///
  /// However, in this case, we're writing many files as a result of parsing one single
  /// graphql file. What this means is that the builder has no knowledge of those files
  /// existence. Its not designed to detect "other" files created as a result of processing
  /// the file its been told to look for.
  ///
  /// The issue this creates, is that we may end up with residual files that aren't deleted.
  /// Lets say for example we remove a type from the graphql. The previously generated model
  /// class will still exist, and we'll have no way of knowing if it should be deleted or not.
  ///
  /// Two ways to possibly address this. Output all files into a gen/ folder, and somehow delete all contents.
  /// (which is problematic in of itself).
  ///
  /// My preferred approach is to instead check the generated mySchema.graphql.dart file exists, and if so,
  /// read the export definitions, and then remove the files listed.
  ///
  /// TODO (emileswain): (FIX) Seems like the models.graphql.dart file is deleted by builder before I can read it.
  // void cleanPreviousModelFiles(BuildStep buildStep) {
  //   String d = buildStep.inputId.path;
  //   String filePostFix = ".dart";
  //   String filePath = "$d$filePostFix";
  //   filePath = p.absolute(filePath);
  //   var file = File(filePath);
  //  // print("file: = " + filePath);
  //   if (file.existsSync()) {
  //     //print("file exists");
  //     List<String> lines = file.readAsLinesSync();
  //     // for (var e in lines) {
  //     //   print(e);
  //     // }
  //   }
  // }

  /// The extensions to process during execution of the build runner.
  ///
  /// For every *.graphql file found in the targeted builder folders we'll
  /// generate a *.graphql.dart file.
  /// This file will import all of the generated model classes.
  @override
  Map<String, List<String>> get buildExtensions => {
        r'.graphql': ['.graphql.dart'],
      };
}
