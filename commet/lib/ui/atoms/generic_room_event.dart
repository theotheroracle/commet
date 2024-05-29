import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/atoms/avatar.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as m;

class GenericRoomEvent extends StatelessWidget {
  const GenericRoomEvent(this.text,
      {this.icon,
      this.senderImage,
      this.leftPadding = 44,
      this.senderColor,
      this.senderName,
      this.maxLines,
      this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 8),
      super.key});
  final String text;
  final String? senderName;
  final Color? senderColor;
  final IconData? icon;
  final ImageProvider? senderImage;
  final double leftPadding;
  final EdgeInsets padding;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return m.Material(
      color: m.Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: padding,
            child: Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(leftPadding, 0, 8, 0),
                    child: Icon(
                      icon,
                      size: 20,
                    ),
                  ),
                if (senderImage != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(leftPadding, 0, 8, 0),
                    child: Avatar(
                      image: senderImage,
                      radius: 10,
                    ),
                  ),
                if (senderName != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                    child: tiamat.Text.name(
                      senderName!,
                      color: senderColor,
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                          child: tiamat.Text.labelLow(
                        text,
                        maxLines: maxLines,
                      )),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
