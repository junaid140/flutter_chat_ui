import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';

/// A class that represents send button widget.
class CameraButton extends StatelessWidget {
  /// Creates send button widget.
  const CameraButton({
    super.key,
    required this.onPressed,
    this.padding = EdgeInsets.zero,
  });

  /// Callback for send button tap event.
  final VoidCallback onPressed;

  /// Padding around the button.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        margin: InheritedChatTheme.of(context).theme.sendButtonMargin ??
            const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
        child: IconButton(
          constraints: const BoxConstraints(
            minHeight: 35,
            minWidth: 35,
          ),
          icon: InheritedChatTheme.of(context).theme.cameraButtonIcon ??
              SvgPicture.asset("assets/camera.svg",
                height: 40,
                // color: InheritedChatTheme.of(context).theme.inputTextColor,
                package: 'flutter_chat_ui',
              ),
          onPressed: onPressed,
          padding: padding,
          splashRadius: 24,
          tooltip: InheritedL10n.of(context).l10n.sendButtonAccessibilityLabel,
        ),
      );
}
