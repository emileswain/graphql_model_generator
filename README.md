# Graphql to model generator
## very, very basic!
A very basic graphql to flutter model class generator. You might say i'm just using graphql as a quick way to define my models, I'm not actually supporting anywhere near the full feature set of graphql.

If you want some basic classes, then this might be the tool for you. If you want fully integrated graphql with backend apis, then go and use https://pub.dev/packages/graphql_codegen. This is not the tool for that.

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
        # be specific, generated files are put in the same parent folder.
        generate_for:
          - lib/data/models/*.graphql
```

### running builder
```
    dart run build_runner build
```

# Possible gotchas

Due to the way additional files (one for each model) are created, and the way builders work you may find that if you remove a Type from your graphql file, you will need to manually remove any previously generated model files. Simply put, builder doesn't know what it's created after the fact.

## What does it do?
Processes `myschema.graphql` files and generates a typical flutter model class for each Type defined.

It will additionally create a `myscheme.graphql.dart` file with the models exported.

# The model structure
It writes a fairly common type of model structure with the following methods...

* constructor()
* factory fromJson(....)
* toJson()
* copyWith(....)

For example a type such as below...
```graphql
...
type ImageCollection{
    name: String!,
    author: Author!,
    altText: String!
    tags: [String]!,
    heroImage: ImageModel!,
    images:[ImageModel]!
}
...
```
Will output a file call `image_collection.dart` with the following code.
```dart
import 'package:your_app_package/data/models/author.dart';
import 'package:your_app_package/data/models/image_model.dart';
import 'package:your_app_package/data/models/image_model.dart';

class ImageCollection {
  ImageCollection({
    required this.name,
    required this.author,
    required this.altText,
    required this.tags,
    required this.heroImage,
    required this.images,
  });

  factory ImageCollection.fromJson(Map<String, dynamic> json) {
    List<String> newTags = [];
    final jsonTags = List<dynamic>.from(json['tags']).toList();
    for (var itemData in jsonTags) {
      final item = itemData;
      if (item != null) {
        newTags.add(item);
      }
    }
    List<ImageModel> newImages = [];
    final jsonImages = List<dynamic>.from(json['images']).toList();
    for (var itemData in jsonImages) {
      final item = ImageModel.fromJson(itemData);
      if (item != null) {
        newImages.add(item);
      }
    }
    return ImageCollection(
      name: json['name'],
      author: json['author'],
      altText: json['altText'],
      tags: newTags,
      heroImage: json['heroImage'],
      images: newImages,
    );
  }

  final String name;
  final Author author;
  final String altText;
  final List<String> tags;
  final ImageModel heroImage;
  final List<ImageModel> images;

  Map<String, dynamic> toJson() => {
        "name": name,
        "author": author.toJson(),
        "altText": altText,
        "tags": tags.map((item) => item).toList(),
        "heroImage": heroImage.toJson(),
        "images": images.map((item) => item.toJson()).toList(),
      };

  ImageCollection copyWith({
    String? name,
    Author? author,
    String? altText,
    List<String>? tags,
    ImageModel? heroImage,
    List<ImageModel>? images,
  }) {
    return ImageCollection(
      name: name ?? this.name,
      author: author ?? this.author,
      altText: altText ?? this.altText,
      tags: tags ?? this.tags,
      heroImage: heroImage ?? this.heroImage,
      images: images ?? this.images,
    );
  }
}

```

### Why?
Simply$put$I$cant$stand$generated$code$that$does$this

It makes writing simple classes super easy and quick in a way that doesn't make my eyes bleed.

And you can remove it, or turn it off without really having to worry about what's left behind.

Its simple, its basic, turn it off when done.

I also wanted to know how builders worked.

It's probably pretty handy for prototyping, initial setups and very basic apps. For enterprise apps you're likely going to want to use https://pub.dev/packages/graphql_codegen instead for some serious functionality.

### Todo
* Will eventually get around to optimising the fromJson() methodology for parsing array types. Sometimes I don't mind if cms data is invalid, other times I do, so this will be updated to support invalid data.
* Might support additional builders with parameters to support other features. Will largely depend on if I need it for a project. like adding Freezed or something, or perhaps supporting extension classes that persist. Its is supposed to be very basic after all.
* support gen/ folder output directory via build-options.

# Resources
Uses https://github.com/dart-lang/code_builder to define and write the classes and uses https://pub.dev/packages/gql to parse the graphql.