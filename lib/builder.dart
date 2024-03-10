import 'package:build/build.dart';
import 'package:graphql_model_generator/builders/gql_to_model_builder.dart';

/// Graphql to Model builder implementation. Runs [GQLToModelBuilder]
Builder graphqlModelBuilder(BuilderOptions options) => GQLToModelBuilder();
