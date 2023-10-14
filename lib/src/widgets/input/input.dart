import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/input_clear_mode.dart';
import '../../models/send_button_visibility_mode.dart';
import '../../util.dart';
import '../state/inherited_chat_theme.dart';
import '../state/inherited_l10n.dart';
import 'attachment_button.dart';
import 'camera_button.dart';
import 'input_text_field_controller.dart';
import 'send_button.dart';
import 'package:easy_debounce_throttle/easy_debounce_throttle.dart';

/// A class that represents bottom bar widget with a text field, attachment and
/// send buttons inside. By default hides send button when text field is empty.
class Input extends StatefulWidget {
  /// Creates [Input] widget.
  const Input({
    super.key,
    this.isAttachmentUploading,
    this.onAttachmentPressed,
    this.onCameraPressed,
    required this.onSendPressed,

    this.options = const InputOptions(),
  });

  /// Whether attachment is uploading. Will replace attachment button with a
  /// [CircularProgressIndicator]. Since we don't have libraries for
  /// managing media in dependencies we have no way of knowing if
  /// something is uploading so you need to set this manually.
  final bool? isAttachmentUploading;

  /// See [AttachmentButton.onPressed].
  final VoidCallback? onAttachmentPressed;
  final VoidCallback? onCameraPressed;

  /// Will be called on [SendButton] tap. Has [types.PartialText] which can
  /// be transformed to [types.TextMessage] and added to the messages list.
  final void Function(types.PartialText) onSendPressed;

  /// Customisation options for the [Input].
  final InputOptions options;

  @override
  State<Input> createState() => _InputState();
}

/// [Input] widget state.
class _InputState extends State<Input> {
  late final _inputFocusNode = FocusNode(
    onKeyEvent: (node, event) {
      if (event.physicalKey == PhysicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.physicalKeysPressed.any(
            (el) => <PhysicalKeyboardKey>{
              PhysicalKeyboardKey.shiftLeft,
              PhysicalKeyboardKey.shiftRight,
            }.contains(el),
          )) {
        if (event is KeyDownEvent) {
          _handleSendPressed();
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  bool _sendButtonVisible = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController =
        widget.options.textEditingController ?? InputTextFieldController();
    _handleSendButtonVisibilityModeChange();
  }

  void _handleSendButtonVisibilityModeChange() {
    _textController.removeListener(_handleTextControllerChange);
    if (widget.options.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.hidden) {
      _sendButtonVisible = false;
    } else if (widget.options.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.editing) {
      _sendButtonVisible = _textController.text.trim() != '';
      _textController.addListener(_handleTextControllerChange);
    } else {
      _sendButtonVisible = true;
    }
  }

  void _handleSendPressed() {
    final trimmedText = _textController.text.trim();
    if (trimmedText != '') {
      final partialText = types.PartialText(text: trimmedText);
      widget.onSendPressed(partialText);

      if (widget.options.inputClearMode == InputClearMode.always) {
        _textController.clear();
      }
    }
  }

  void _handleTextControllerChange() {
    setState(() {
      _sendButtonVisible = _textController.text.trim() != '';
    });
  }

  Widget _inputBuilder() {
    final query = MediaQuery.of(context);
    final buttonPadding = InheritedChatTheme.of(context)
        .theme
        .inputPadding
        .copyWith(left: 16, right: 16);
    final safeAreaInsets = isMobile
        ? EdgeInsets.fromLTRB(
            query.padding.left,
            0,
            query.padding.right,
            query.viewInsets.bottom + query.padding.bottom,
          )
        : EdgeInsets.zero;
    final textPadding = InheritedChatTheme.of(context)
        .theme
        .inputPadding
        .copyWith(left: 0, right: 0)
        .add(
          EdgeInsets.fromLTRB(
            widget.onAttachmentPressed != null ? 0 : 24,
            0,
            _sendButtonVisible ? 0 : 24,
            0,
          ),
        );

    return Focus(
      autofocus: !widget.options.autofocus,
      child: Padding(
        padding: InheritedChatTheme.of(context).theme.inputMargin,
        child: Material(
          borderRadius: InheritedChatTheme.of(context).theme.inputBorderRadius,
          color: InheritedChatTheme.of(context).theme.inputBackgroundColor,
          child: Column(
            children: [
              Container(
                decoration:
                    InheritedChatTheme.of(context).theme.inputContainerDecoration,
                padding: safeAreaInsets,
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: buttonPadding.bottom + buttonPadding.top + 24,
                      ),
                      child: IconButton(onPressed: (){
                        FocusScopeNode currentFocus = FocusScope.of(context);
                        if (!currentFocus.hasPrimaryFocus) {
                        currentFocus.unfocus();
                        }
                        setState(() {
                        show = !show;
                        });
                        },

                        color: InheritedChatTheme.of(context).theme.inputTextColor,
                        icon: SvgPicture.asset("assets/smile.svg",
                          height: 40,
                          // color: InheritedChatTheme.of(context).theme.inputTextColor,
                          package: 'flutter_chat_ui',
                        ),)
                    ),
                    Expanded(
                      child: Padding(
                        padding: textPadding,
                        child: TextField(
                          enabled: widget.options.enabled,
                          autocorrect: widget.options.autocorrect,
                          autofocus: widget.options.autofocus,
                          // canRequestFocus:show? false:true,
                          readOnly: show? true:false,
                          showCursor: true,
                          enableSuggestions: widget.options.enableSuggestions,
                          controller: _textController,
                          cursorColor: InheritedChatTheme.of(context)
                              .theme
                              .inputTextCursorColor,
                          decoration: InheritedChatTheme.of(context)
                              .theme
                              .inputTextDecoration
                              .copyWith(
                                hintStyle: InheritedChatTheme.of(context)
                                    .theme
                                    .inputTextStyle
                                    .copyWith(
                                      color: InheritedChatTheme.of(context)
                                          .theme
                                          .inputTextColor
                                          .withOpacity(0.5),
                                    ),
                                hintText:
                                    InheritedL10n.of(context).l10n.inputPlaceholder,
                              ),
                          focusNode: _inputFocusNode,
                          keyboardType: widget.options.keyboardType,
                          maxLines: 5,
                          minLines: 1,
                          onChanged: widget.options.onTextChanged,
                          onTap: widget.options.onTextFieldTap,
                          style: InheritedChatTheme.of(context)
                              .theme
                              .inputTextStyle
                              .copyWith(
                                color: InheritedChatTheme.of(context)
                                    .theme
                                    .inputTextColor,
                              ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: buttonPadding.bottom + buttonPadding.top + 24,
                      ),
                      child: Visibility(
                        visible: _sendButtonVisible,
                        child: SendButton(
                          onPressed: _handleSendPressed,
                          // padding: buttonPadding,

                        ),
                      ),
                    ),
                    if (widget.onCameraPressed != null)
                      ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: buttonPadding.bottom + buttonPadding.top + 24,
                      ),
                      child: Visibility(
                        visible: !_sendButtonVisible,
                        child: CameraButton(
                          onPressed: widget.onCameraPressed!,
                          // padding: buttonPadding,

                        ),
                      ),
                    ),
                    if (widget.onAttachmentPressed != null)
                      ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: buttonPadding.bottom + buttonPadding.top + 24,
                      ),
                      child: Visibility(
                        visible: !_sendButtonVisible,
                        child:  AttachmentButton(
                          isLoading: widget.isAttachmentUploading ?? false,
                          onPressed: widget.onAttachmentPressed,
                          // padding: buttonPadding,
                        ),
                      ),
                    ),
                    SizedBox(width: 10,)


                  ],
                ),
              ),
              show ? emojiSelect() : Container(),
            ],
          ),
        ),
      ),
    );
  }
  final debouncer = EasyDebounce(delay: Duration(milliseconds: 500));

  Widget emojiSelect() {
    return SizedBox(
      height: 250,
      child:
      EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          // Do something when emoji is tapped (optional)
          print(emoji);
          print(emoji.emoji);

          // setState(() {
          //   _textController.text = _textController.text + emoji.emoji;
          // });
          debouncer.listen((data) {
            final text = _textController.text;
            final selection = _textController.selection;
            final newText = text.replaceRange(
                selection.start, selection.end, emoji.emoji); // Insert emoji at cursor position
            final newCursorPos = selection.start + emoji.emoji.length;

            _textController.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newCursorPos),
            );
            setState(() {

            });
            print(_textController.text);
          });

        },
        onBackspacePressed: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
          setState(() {
            show = !show;
          });
          // Do something when the user taps the backspace button (optional)
          // Set it to null to hide the Backspace-Button
        },
        textEditingController: _textController, // pass here the same [TextEditingController] that is connected to your input field, usually a [TextFormField]
        config: Config(
          columns: 10,
          emojiSizeMax: 20 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0), // Issue: https://github.com/flutter/flutter/issues/28894
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          initCategory: Category.RECENT,
          bgColor: Color(0xFFF2F2F2),
          indicatorColor: Color(0xffA30000),
          iconColor: Colors.grey,
          iconColorSelected:Color(0xffA30000),
          backspaceColor: Color(0xffA30000),
          skinToneDialogBgColor: Colors.white,
          skinToneIndicatorColor: Colors.grey,
          enableSkinTones: true,
          recentTabBehavior: RecentTabBehavior.RECENT,
          recentsLimit: 28,
          noRecents: const Text(
            'No Recents',
            style: TextStyle(fontSize: 20, color: Colors.black26),
            textAlign: TextAlign.center,
          ), // Needs to be const Widget
          loadingIndicator: const SizedBox.shrink(), // Needs to be const Widget
          tabIndicatorAnimDuration: kTabScrollDuration,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.MATERIAL,
        ),
      )
    );
  }
  bool show = false;

  @override
  void didUpdateWidget(covariant Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options.sendButtonVisibilityMode !=
        oldWidget.options.sendButtonVisibilityMode) {
      _handleSendButtonVisibilityModeChange();
    }
  }

  @override
  void dispose() {
    _inputFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => _inputFocusNode.requestFocus(),
        child: _inputBuilder(),
      );
}

@immutable
class InputOptions {
  const InputOptions({
    this.inputClearMode = InputClearMode.always,
    this.keyboardType = TextInputType.multiline,
    this.onTextChanged,
    this.onTextFieldTap,
    this.sendButtonVisibilityMode = SendButtonVisibilityMode.editing,
    this.textEditingController,
    this.autocorrect = true,
    this.autofocus = true,
    this.enableSuggestions = true,
    this.enabled = true,
  });

  /// Controls the [Input] clear behavior. Defaults to [InputClearMode.always].
  final InputClearMode inputClearMode;

  /// Controls the [Input] keyboard type. Defaults to [TextInputType.multiline].
  final TextInputType keyboardType;

  /// Will be called whenever the text inside [TextField] changes.
  final void Function(String)? onTextChanged;

  /// Will be called on [TextField] tap.
  final VoidCallback? onTextFieldTap;

  /// Controls the visibility behavior of the [SendButton] based on the
  /// [TextField] state inside the [Input] widget.
  /// Defaults to [SendButtonVisibilityMode.editing].
  final SendButtonVisibilityMode sendButtonVisibilityMode;

  /// Custom [TextEditingController]. If not provided, defaults to the
  /// [InputTextFieldController], which extends [TextEditingController] and has
  /// additional fatures like markdown support. If you want to keep additional
  /// features but still need some methods from the default [TextEditingController],
  /// you can create your own [InputTextFieldController] (imported from this lib)
  /// and pass it here.
  final TextEditingController? textEditingController;

  /// Controls the [TextInput] autocorrect behavior. Defaults to [true].
  final bool autocorrect;

  /// Whether [TextInput] should have focus. Defaults to [false].
  final bool autofocus;

  /// Controls the [TextInput] enableSuggestions behavior. Defaults to [true].
  final bool enableSuggestions;

  /// Controls the [TextInput] enabled behavior. Defaults to [true].
  final bool enabled;
}
