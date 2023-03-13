import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/seperator.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

const String exampleText = "The quick brown fox jumped over the lazy dog";

@WidgetbookUseCase(name: 'Label', type: Text)
Widget wb_textLabelUseCase(BuildContext context) {
  return material.Center(
    child: Text.label(exampleText),
  );
}

@WidgetbookUseCase(name: 'Tiny', type: Text)
Widget wb_textTinyUseCase(BuildContext context) {
  return material.Center(
    child: Text.tiny(exampleText),
  );
}

@WidgetbookUseCase(name: 'Body', type: Text)
Widget wb_textBodyUseCase(BuildContext context) {
  return material.Center(
    child: Text.body(exampleText),
  );
}

@WidgetbookUseCase(name: 'Error', type: Text)
Widget wb_textErrorUseCase(BuildContext context) {
  return material.Center(
    child: Text.error(exampleText),
  );
}

@WidgetbookUseCase(name: 'Title', type: Text)
Widget wb_textTitleUseCase(BuildContext context) {
  return material.Center(
    child: material.Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text.largeTitle(exampleText),
    ),
  );
}

@WidgetbookUseCase(name: 'All', type: Text)
Widget wb_textAllUseCase(BuildContext context) {
  return material.Padding(
    padding: const EdgeInsets.all(16.0),
    child: material.Center(
      child: material.Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.largeTitle(exampleText),
          Seperator(),
          Align(alignment: Alignment.centerRight, child: Text.labelEmphasised(exampleText)),
          Align(alignment: Alignment.centerRight, child: Text.label(exampleText)),
          material.Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Text.body(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."),
          ),
          material.Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Text.tiny(
                "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"),
          ),
          Seperator(),
          Align(alignment: Alignment.centerRight, child: Text.error(exampleText)),
        ],
      ),
    ),
  );
}

enum TextType { label, labelEmphasised, error, tiny, body, largeTitle }

class Text extends StatelessWidget {
  const Text(this.text, {super.key, this.type = TextType.label});
  final String text;
  final TextType type;

  Text.label(this.text, {Key? key})
      : type = TextType.label,
        super(key: key);

  Text.labelEmphasised(this.text, {Key? key})
      : type = TextType.labelEmphasised,
        super(key: key);

  Text.error(this.text, {Key? key})
      : type = TextType.error,
        super(key: key);

  Text.tiny(this.text, {Key? key})
      : type = TextType.tiny,
        super(key: key);

  Text.body(this.text, {Key? key})
      : type = TextType.body,
        super(key: key);

  Text.largeTitle(this.text, {Key? key})
      : type = TextType.largeTitle,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle style;

    switch (type) {
      case TextType.label:
        style = material.Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w300);
        break;
      case TextType.labelEmphasised:
        style = material.Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w400);
        break;
      case TextType.error:
        style = material.Theme.of(context)
            .textTheme
            .bodyMedium!
            .copyWith(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.error);
        break;
      case TextType.tiny:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w300, fontSize: 10);
        break;
      case TextType.body:
        style = material.Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w300);
        break;
      case TextType.largeTitle:
        style = material.Theme.of(context).textTheme.titleLarge!;
        break;
    }

    return material.Text(
      text,
      style: style,
    );
  }
}