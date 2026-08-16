# Local WebDAV for Smoke Tests

Use the local WebDAV server when a real endpoint is needed for backup, restore,
sync, ETag, or MOVE smoke tests.

## Start

```powershell
.\scripts\start_local_webdav.ps1
```

The script uses Docker Compose when Docker Desktop is running. If Docker is not
available, it starts the bundled zero-dependency Node.js WebDAV server in the
background.

Defaults:

- Windows/Desktop URL: `http://127.0.0.1:19080/`
- Android emulator URL: `http://10.0.2.2:19080/`
- LDPlayer/雷电通常不能访问 `10.0.2.2`；请使用宿主机在模拟器网段可达的局域网地址，例如本机验证使用的 `http://192.168.100.52:19080/`。
- Username: `legado`
- Password: `legado-test`
- Data directory: `.local-webdav/data`

The app's default WebDAV directory can remain `legado`; the client will create
`/legado/` and child folders during setup.

## Stop

```powershell
.\scripts\stop_local_webdav.ps1
```

This stops both the Docker Compose service and the Node fallback process when
present.

## Override Defaults

```powershell
$env:LOCAL_WEBDAV_PORT = "19081"
$env:LOCAL_WEBDAV_USER = "tester"
$env:LOCAL_WEBDAV_PASSWORD = "secret"
.\scripts\start_local_webdav.ps1
```

Use `http://127.0.0.1:$env:LOCAL_WEBDAV_PORT/` for desktop tests and
`http://10.0.2.2:$env:LOCAL_WEBDAV_PORT/` from the Android emulator.

For an LDPlayer run, pass the reachable host address to the integration test:

```powershell
flutter test integration_test/r5_android_webdav_application_smoke_test.dart `
  -d emulator-5556 `
  --dart-define=R5_WEBDAV_URL=http://192.168.100.52:19080/
```

## Reset Data

Stop the server, then delete `.local-webdav/data`.

## R5 Gates

The local Node/Docker server is the development exit gate. The external service
gate is a separate release gate and must be run against an official or widely
used WebDAV service before publishing. A local result must not be reported as
external-service evidence.

Run the local development gate on Android:

```powershell
flutter test integration_test/r5_android_webdav_application_smoke_test.dart `
  integration_test/r5_android_webdav_cross_client_conflict_test.dart `
  integration_test/r5_android_webdav_backup_restore_failure_test.dart `
  -d emulator-5556 `
  --dart-define=R5_WEBDAV_URL=http://192.168.100.52:19080/
```

Run the release external gate on an Android device/emulator with an HTTPS or
HTTP WebDAV endpoint:

```powershell
flutter test integration_test/r5_external_webdav_smoke_test.dart `
  -d emulator-5556 `
  --dart-define=R5_EXTERNAL_WEBDAV_URL=https://dav.example.com/remote/ `
  --dart-define=R5_EXTERNAL_WEBDAV_USER=account `
  --dart-define=R5_EXTERNAL_WEBDAV_PASSWORD=secret
```

Optional `R5_EXTERNAL_WEBDAV_BAD_PASSWORD` verifies an authentication failure.
Proxy settings use `R5_EXTERNAL_WEBDAV_PROXY_TYPE`, `..._HOST`, `..._PORT`,
`..._USER`, and `..._PASSWORD`. The gate covers authenticated directory
access, optional permission failure, server ETag/`412`, MOVE, and ZIP upload
and download. A local Node/Docker server is not external-service evidence.
