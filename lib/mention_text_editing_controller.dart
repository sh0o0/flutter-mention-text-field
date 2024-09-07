import 'dart:developer';

import 'package:flutter/material.dart';

const zeroSpaceText = '\u200b';

class Mention {
  const Mention({
    required this.userId,
    required this.name,
    this.style,
  });

  final String userId;
  final String name;
  final TextStyle? style;
}

class MentionTextEditingController extends TextEditingController {
  MentionTextEditingController({
    super.text,
    List<Mention> mentions = const [],
  }) : _mentions = mentions;

  List<Mention> _mentions;

  List<Mention> get mentions => _mentions;

  set mentions(List<Mention> value) {
    _mentions = value;
    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    BuildContext? context,
    TextStyle? style,
    bool? withComposing,
  }) {
    final children = <InlineSpan>[];

    text.splitMapJoin(
      RegExp(r'@([a-zA-Z0-9_]+)(\u200b*)'),
      onMatch: (Match match) {
        final allWords = match[0]!;
        final userId = match[1]!;
        final emptyWords = match[2]!;
        final annotation = allWords.replaceAll(emptyWords, '');

        log(
          'annotation: $annotation, userId: $userId, '
          'emptyWordsLength: ${emptyWords.length}, '
          'text: $text, ',
        );

        final mentionIndex = mentions.indexWhere(
          (element) => element.userId == userId,
        );

        if (mentionIndex == -1) {
          if (_willRemoveAnnotationUserId(userId)) {
            _removeRangeTextAfterBuild(match.start, match.end);
            return '';
          }
          children.add(TextSpan(text: annotation, style: style));
          return '';
        }

        final mention = mentions[mentionIndex];

        // textと表示されてる文字数が違うと、カーソルの位置がおかしくなるので補正。
        // textの文字数が少ない時は、\u200b（ゼロ幅スペース）を追加
        // 表示されてる文字数が足りない時は、WidgetSpan()を追加,
        // 参考: https://github.com/flutter/flutter/issues/107432
        final differentLength = allWords.length - mention.name.length;
        log(
          'allWordsLength: ${allWords.length}, '
          'annotationLength: ${annotation.length}, '
          'displayLength: ${mention.name.length}, '
          'differentLength: $differentLength, '
          'matchStart: ${match.start}, matchEnd: ${match.end}, ',
        );

        // annotationを消そうとしてると判断し、annotationを全削除
        if (differentLength == 0 && emptyWords.isNotEmpty) {
          _removeRangeTextAfterBuild(match.start, match.end);
          return '';
        }

        if (differentLength < 0) {
          if (emptyWords.isNotEmpty) {
            _removeRangeTextAfterBuild(match.start, match.end);
            return '';
          }
          _replaceRangeTextAfterBuild(
            match.start,
            match.end,
            // +1してるのは、differentLengthが-1の時に、最後の\u200bを削除すると再度この_replaceRangeTextAfterBuildが走ってしまうため。
            // +1して、\u200bが2つ以上になるようにし、differentLength == 0 && emptyWords.isNotEmptyの時に、annotationを全削除するようにしてる。
            annotation + zeroSpaceText * (differentLength.abs() + 1),
          );
          children.add(
            TextSpan(
              style: style,
              children: [
                TextSpan(text: annotation),
                // 上述の\u200b +1の分
                const WidgetSpan(child: SizedBox()),
              ],
            ),
          );
          return '';
        }

        final filledSpaces = List.generate(
          differentLength,
          (index) => const WidgetSpan(child: SizedBox()),
        );
        children.add(
          TextSpan(
            style: mention.style,
            children: [
              TextSpan(text: mention.name),
              ...filledSpaces,
            ],
          ),
        );

        return '';
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }

  void _replaceRangeTextAfterBuild(int start, int end, String replacingText) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      text = text.replaceRange(start, end, replacingText);
    });
  }

  void _removeRangeTextAfterBuild(int start, int end) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      text = text.replaceRange(start, end, '');
    });
  }

  bool _willRemoveAnnotationUserId(String removingUserId) =>
      removingUserId.length > 25 &&
      mentions.any((e) => e.userId.contains(removingUserId));
}
