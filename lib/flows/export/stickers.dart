import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sticker_import/export/controllers/model.dart';
import 'package:sticker_import/components/ui/emoji/route.dart';
import 'package:sticker_import/flows/export/finish.dart';
import 'package:sticker_import/generated/l10n.dart';

class StickerChooserRoute extends StatefulWidget {
  const StickerChooserRoute({
    required this.controller,
    this.emojiSuggestions,
    super.key,
  });

  final ExportController controller;
  final List<Set<String>>? emojiSuggestions;

  @override
  StickerChooserRouteState createState() => StickerChooserRouteState();
}

class StickerChooserRouteState extends State<StickerChooserRoute> {
  final enabled = <bool>[];
  late final List<Set<String>> emoji;
  bool isFillMissingMode = false;
  List<int> missingIndexes = [];

  @override
  void initState() {
    super.initState();

    for (final file in widget.controller.result!) {
      imageCache.evict(FileImage(File(file)));
    }

    enabled.addAll(List.filled(widget.controller.result!.length, true));
    emoji = widget.emojiSuggestions ??
        List.generate(widget.controller.result!.length, (_) => {});

    for (var i = 0; i < emoji.length; i++) {
      if (emoji[i].isEmpty) {
        missingIndexes.add(i);
      }
    }

    isFillMissingMode =
        missingIndexes.isNotEmpty && missingIndexes.length != emoji.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).prepare_pack),
        actions: [
          IconButton(
            tooltip: S.of(context).select_all,
            onPressed: () {
              final isEverythingSelected = enabled.every((element) => element);

              setState(() {
                enabled.clear();
                enabled.addAll(
                  List.filled(
                    widget.controller.result!.length,
                    !isEverythingSelected,
                  ),
                );
              });
            },
            icon: const Icon(Icons.select_all_rounded),
          ),
          IconButton(
            tooltip: S.of(context).done,
            onPressed: () {
              final pth = <String>[];
              final emj = <String>[];

              widget.controller.result!.asMap().forEach((index, path) {
                if (!enabled[index]) return;

                pth.add(path);
                if (emoji[index].isNotEmpty) {
                  emj.add(emoji[index].join());
                } else {
                  emj.add('#️⃣');
                }
              });

              Navigator.of(context).push<dynamic>(
                MaterialPageRoute<dynamic>(
                  builder: (BuildContext context) {
                    return ExportFinishRoute(
                      paths: pth,
                      emojis: emj,
                      isAnimated: widget.controller.isAnimated,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.done_rounded),
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.all(15.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10.0),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.info_rounded),
              ),
              title: Text(isFillMissingMode
                  ? S.of(context).stickers_without_suggestions
                  : S.of(context).customize_your_pack),
              subtitle: Text((isFillMissingMode
                      ? S.of(context).stickers_without_suggestions_info
                      : S.of(context).customize_your_pack_info) +
                  (widget.controller.isAnimated
                      ? '\n\n${S.of(context).not_all_animated}'
                      : '')),
            ),
          ),
          if (isFillMissingMode)
            ListTile(title: Text(S.of(context).no_suggestions_section)),
          if (isFillMissingMode)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: missingIndexes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4),
              itemBuilder: (context, n) {
                return _StickerChoice(
                  n: missingIndexes[n],
                  enabled: enabled,
                  emoji: emoji,
                  setState: setState,
                  controller: widget.controller,
                );
              },
            ),
          if (isFillMissingMode)
            ListTile(title: Text(S.of(context).all_stickers_section)),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.controller.result!.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4),
            itemBuilder: (context, n) {
              return _StickerChoice(
                n: n,
                enabled: enabled,
                emoji: emoji,
                setState: setState,
                controller: widget.controller,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StickerChoice extends StatelessWidget {
  const _StickerChoice({
    required this.n,
    required this.enabled,
    required this.emoji,
    required this.setState,
    required this.controller,
  });

  final void Function(void Function()) setState;
  final int n;
  final List<bool> enabled;
  final List<Set<String>> emoji;
  final ExportController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: (enabled[n] ? 1 : .6),
      duration: const Duration(milliseconds: 250),
      child: Semantics(
        checked: enabled[n],
        hint: S.of(context).enable_sticker,
        child: GestureDetector(
          onTap: () {
            setState(() {
              enabled[n] = !enabled[n];
            });
          },
          child: Stack(
            children: [
              if (controller.isAnimated)
                Image.file(File(controller.previews![n])),
              if (!controller.isAnimated)
                Image.file(File(controller.result![n])),
              Checkbox(
                  value: enabled[n],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      enabled[n] = v;
                    });
                  }),
              if (enabled[n])
                Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    child: IconButton(
                      tooltip: S.of(context).choose_emoji,
                      onPressed: () async {
                        final m = await Navigator.of(context).push<Set<String>>(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return EmojiPickerScreen(
                                emojis: emoji[n],
                                placeholder:
                                    S.of(context).pick_emoji_sticker_suggestion,
                              );
                            },
                          ),
                        );

                        setState(() {
                          if (m == null) return;
                          emoji[n] = m;
                        });
                      },
                      icon: (emoji[n].isEmpty
                          ? const Icon(Icons.face_rounded)
                          : Text(
                              emoji[n].first,
                              style: const TextStyle(
                                fontSize: 21,
                                height: 1,
                                fontFamily: 'AppleColorEmoji',
                              ),
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                            )),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
