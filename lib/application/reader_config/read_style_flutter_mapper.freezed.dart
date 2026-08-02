// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'read_style_flutter_mapper.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReadStyleSlotOverride {
  String? get name => throw _privateConstructorUsedError;
  Color? get background => throw _privateConstructorUsedError;
  Color? get text => throw _privateConstructorUsedError;
  Color? get accent => throw _privateConstructorUsedError;
  String? get bgImagePath => throw _privateConstructorUsedError;
  bool get darkStatusIcon => throw _privateConstructorUsedError;
}

/// @nodoc

class _$ReadStyleSlotOverrideImpl extends _ReadStyleSlotOverride {
  const _$ReadStyleSlotOverrideImpl({
    this.name,
    this.background,
    this.text,
    this.accent,
    this.bgImagePath,
    this.darkStatusIcon = true,
  }) : super._();

  @override
  final String? name;
  @override
  final Color? background;
  @override
  final Color? text;
  @override
  final Color? accent;
  @override
  final String? bgImagePath;
  @override
  @JsonKey()
  final bool darkStatusIcon;

  @override
  String toString() {
    return 'ReadStyleSlotOverride(name: $name, background: $background, text: $text, accent: $accent, bgImagePath: $bgImagePath, darkStatusIcon: $darkStatusIcon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadStyleSlotOverrideImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.background, background) ||
                other.background == background) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.accent, accent) || other.accent == accent) &&
            (identical(other.bgImagePath, bgImagePath) ||
                other.bgImagePath == bgImagePath) &&
            (identical(other.darkStatusIcon, darkStatusIcon) ||
                other.darkStatusIcon == darkStatusIcon));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    background,
    text,
    accent,
    bgImagePath,
    darkStatusIcon,
  );
}

abstract class _ReadStyleSlotOverride extends ReadStyleSlotOverride {
  const factory _ReadStyleSlotOverride({
    final String? name,
    final Color? background,
    final Color? text,
    final Color? accent,
    final String? bgImagePath,
    final bool darkStatusIcon,
  }) = _$ReadStyleSlotOverrideImpl;
  const _ReadStyleSlotOverride._() : super._();

  @override
  String? get name;
  @override
  Color? get background;
  @override
  Color? get text;
  @override
  Color? get accent;
  @override
  String? get bgImagePath;
  @override
  bool get darkStatusIcon;
}
