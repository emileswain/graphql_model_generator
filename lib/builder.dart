
import 'package:build/build.dart';
import 'package:graphql_model_generator/builders/gql_to_model_builder.dart';

/// https://pub.dev/packages/build_runner
Builder graphqlModelBuilder(BuilderOptions options) => GQLToModelBuilder();
