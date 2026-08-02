// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'source_login_page_port.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SourceLoginCommand {
  String get operation => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String get html => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  /// Create a copy of SourceLoginCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SourceLoginCommandCopyWith<SourceLoginCommand> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceLoginCommandCopyWith<$Res> {
  factory $SourceLoginCommandCopyWith(
    SourceLoginCommand value,
    $Res Function(SourceLoginCommand) then,
  ) = _$SourceLoginCommandCopyWithImpl<$Res, SourceLoginCommand>;
  @useResult
  $Res call({
    String operation,
    String text,
    String url,
    String html,
    Map<String, dynamic>? data,
  });
}

/// @nodoc
class _$SourceLoginCommandCopyWithImpl<$Res, $Val extends SourceLoginCommand>
    implements $SourceLoginCommandCopyWith<$Res> {
  _$SourceLoginCommandCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SourceLoginCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? operation = null,
    Object? text = null,
    Object? url = null,
    Object? html = null,
    Object? data = freezed,
  }) {
    return _then(
      _value.copyWith(
            operation: null == operation
                ? _value.operation
                : operation // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            html: null == html
                ? _value.html
                : html // ignore: cast_nullable_to_non_nullable
                      as String,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SourceLoginCommandImplCopyWith<$Res>
    implements $SourceLoginCommandCopyWith<$Res> {
  factory _$$SourceLoginCommandImplCopyWith(
    _$SourceLoginCommandImpl value,
    $Res Function(_$SourceLoginCommandImpl) then,
  ) = __$$SourceLoginCommandImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String operation,
    String text,
    String url,
    String html,
    Map<String, dynamic>? data,
  });
}

/// @nodoc
class __$$SourceLoginCommandImplCopyWithImpl<$Res>
    extends _$SourceLoginCommandCopyWithImpl<$Res, _$SourceLoginCommandImpl>
    implements _$$SourceLoginCommandImplCopyWith<$Res> {
  __$$SourceLoginCommandImplCopyWithImpl(
    _$SourceLoginCommandImpl _value,
    $Res Function(_$SourceLoginCommandImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SourceLoginCommand
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? operation = null,
    Object? text = null,
    Object? url = null,
    Object? html = null,
    Object? data = freezed,
  }) {
    return _then(
      _$SourceLoginCommandImpl(
        operation: null == operation
            ? _value.operation
            : operation // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        html: null == html
            ? _value.html
            : html // ignore: cast_nullable_to_non_nullable
                  as String,
        data: freezed == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc

class _$SourceLoginCommandImpl implements _SourceLoginCommand {
  const _$SourceLoginCommandImpl({
    required this.operation,
    this.text = '',
    this.url = '',
    this.html = '',
    final Map<String, dynamic>? data,
  }) : _data = data;

  @override
  final String operation;
  @override
  @JsonKey()
  final String text;
  @override
  @JsonKey()
  final String url;
  @override
  @JsonKey()
  final String html;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'SourceLoginCommand(operation: $operation, text: $text, url: $url, html: $html, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceLoginCommandImpl &&
            (identical(other.operation, operation) ||
                other.operation == operation) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.html, html) || other.html == html) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    operation,
    text,
    url,
    html,
    const DeepCollectionEquality().hash(_data),
  );

  /// Create a copy of SourceLoginCommand
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceLoginCommandImplCopyWith<_$SourceLoginCommandImpl> get copyWith =>
      __$$SourceLoginCommandImplCopyWithImpl<_$SourceLoginCommandImpl>(
        this,
        _$identity,
      );
}

abstract class _SourceLoginCommand implements SourceLoginCommand {
  const factory _SourceLoginCommand({
    required final String operation,
    final String text,
    final String url,
    final String html,
    final Map<String, dynamic>? data,
  }) = _$SourceLoginCommandImpl;

  @override
  String get operation;
  @override
  String get text;
  @override
  String get url;
  @override
  String get html;
  @override
  Map<String, dynamic>? get data;

  /// Create a copy of SourceLoginCommand
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SourceLoginCommandImplCopyWith<_$SourceLoginCommandImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SourceLoginScriptResult {
  String get output => throw _privateConstructorUsedError;
  List<SourceLoginCommand> get commands => throw _privateConstructorUsedError;
  Map<String, String> get loginInfo => throw _privateConstructorUsedError;

  /// Create a copy of SourceLoginScriptResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SourceLoginScriptResultCopyWith<SourceLoginScriptResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SourceLoginScriptResultCopyWith<$Res> {
  factory $SourceLoginScriptResultCopyWith(
    SourceLoginScriptResult value,
    $Res Function(SourceLoginScriptResult) then,
  ) = _$SourceLoginScriptResultCopyWithImpl<$Res, SourceLoginScriptResult>;
  @useResult
  $Res call({
    String output,
    List<SourceLoginCommand> commands,
    Map<String, String> loginInfo,
  });
}

/// @nodoc
class _$SourceLoginScriptResultCopyWithImpl<
  $Res,
  $Val extends SourceLoginScriptResult
>
    implements $SourceLoginScriptResultCopyWith<$Res> {
  _$SourceLoginScriptResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SourceLoginScriptResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? output = null,
    Object? commands = null,
    Object? loginInfo = null,
  }) {
    return _then(
      _value.copyWith(
            output: null == output
                ? _value.output
                : output // ignore: cast_nullable_to_non_nullable
                      as String,
            commands: null == commands
                ? _value.commands
                : commands // ignore: cast_nullable_to_non_nullable
                      as List<SourceLoginCommand>,
            loginInfo: null == loginInfo
                ? _value.loginInfo
                : loginInfo // ignore: cast_nullable_to_non_nullable
                      as Map<String, String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SourceLoginScriptResultImplCopyWith<$Res>
    implements $SourceLoginScriptResultCopyWith<$Res> {
  factory _$$SourceLoginScriptResultImplCopyWith(
    _$SourceLoginScriptResultImpl value,
    $Res Function(_$SourceLoginScriptResultImpl) then,
  ) = __$$SourceLoginScriptResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String output,
    List<SourceLoginCommand> commands,
    Map<String, String> loginInfo,
  });
}

/// @nodoc
class __$$SourceLoginScriptResultImplCopyWithImpl<$Res>
    extends
        _$SourceLoginScriptResultCopyWithImpl<
          $Res,
          _$SourceLoginScriptResultImpl
        >
    implements _$$SourceLoginScriptResultImplCopyWith<$Res> {
  __$$SourceLoginScriptResultImplCopyWithImpl(
    _$SourceLoginScriptResultImpl _value,
    $Res Function(_$SourceLoginScriptResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SourceLoginScriptResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? output = null,
    Object? commands = null,
    Object? loginInfo = null,
  }) {
    return _then(
      _$SourceLoginScriptResultImpl(
        output: null == output
            ? _value.output
            : output // ignore: cast_nullable_to_non_nullable
                  as String,
        commands: null == commands
            ? _value._commands
            : commands // ignore: cast_nullable_to_non_nullable
                  as List<SourceLoginCommand>,
        loginInfo: null == loginInfo
            ? _value._loginInfo
            : loginInfo // ignore: cast_nullable_to_non_nullable
                  as Map<String, String>,
      ),
    );
  }
}

/// @nodoc

class _$SourceLoginScriptResultImpl implements _SourceLoginScriptResult {
  const _$SourceLoginScriptResultImpl({
    required this.output,
    required final List<SourceLoginCommand> commands,
    final Map<String, String> loginInfo = const <String, String>{},
  }) : _commands = commands,
       _loginInfo = loginInfo;

  @override
  final String output;
  final List<SourceLoginCommand> _commands;
  @override
  List<SourceLoginCommand> get commands {
    if (_commands is EqualUnmodifiableListView) return _commands;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_commands);
  }

  final Map<String, String> _loginInfo;
  @override
  @JsonKey()
  Map<String, String> get loginInfo {
    if (_loginInfo is EqualUnmodifiableMapView) return _loginInfo;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_loginInfo);
  }

  @override
  String toString() {
    return 'SourceLoginScriptResult(output: $output, commands: $commands, loginInfo: $loginInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SourceLoginScriptResultImpl &&
            (identical(other.output, output) || other.output == output) &&
            const DeepCollectionEquality().equals(other._commands, _commands) &&
            const DeepCollectionEquality().equals(
              other._loginInfo,
              _loginInfo,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    output,
    const DeepCollectionEquality().hash(_commands),
    const DeepCollectionEquality().hash(_loginInfo),
  );

  /// Create a copy of SourceLoginScriptResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SourceLoginScriptResultImplCopyWith<_$SourceLoginScriptResultImpl>
  get copyWith =>
      __$$SourceLoginScriptResultImplCopyWithImpl<
        _$SourceLoginScriptResultImpl
      >(this, _$identity);
}

abstract class _SourceLoginScriptResult implements SourceLoginScriptResult {
  const factory _SourceLoginScriptResult({
    required final String output,
    required final List<SourceLoginCommand> commands,
    final Map<String, String> loginInfo,
  }) = _$SourceLoginScriptResultImpl;

  @override
  String get output;
  @override
  List<SourceLoginCommand> get commands;
  @override
  Map<String, String> get loginInfo;

  /// Create a copy of SourceLoginScriptResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SourceLoginScriptResultImplCopyWith<_$SourceLoginScriptResultImpl>
  get copyWith => throw _privateConstructorUsedError;
}
