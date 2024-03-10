# example_project

A new Flutter project.

## Getting Started


# Installing

```
flutter pub add --dev graphql_model_generator build_runner
```

### To put in your project's build.yaml file

Be super specific about the `generate_for` option, especially if you are
using graphql queries etc.
```
targets:
  $default:
    builders:
      graphql_model_generator|basic_builder:
        # Only run this builder on the specified input.
        generate_for:
          - lib/models/*.graphql
```

### running builder
```
    dart run build_runner build
```
