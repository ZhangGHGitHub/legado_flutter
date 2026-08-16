import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/rss/rss_source.dart';

part 'rss_state.freezed.dart';

/// RSS 源管理页面的不可变状态。
@freezed
class RssState with _$RssState {
  const factory RssState({@Default(<RssSource>[]) List<RssSource> sources}) =
      _RssState;
}
