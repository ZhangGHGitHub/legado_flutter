import 'dart:io';

/// Online source smoke tests are opt-in so the full suite stays deterministic.
bool get runOnlineSmoke => Platform.environment['RUN_ONLINE_SMOKE'] == '1';

String? get onlineSmokeSkipReason =>
    runOnlineSmoke ? null : 'online smoke disabled; set RUN_ONLINE_SMOKE=1';
