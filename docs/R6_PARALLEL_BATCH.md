## Parallel Batch

Original goal: continue the Rust + Flutter refactor while preserving the pre-refactor Android Beta behavior on `emulator-5558`.

Acceptance check: the architecture boundary scan removes the assigned Feature-to-service imports, targeted tests pass in the owner checkout, and the final Flutter suite remains green.

Product impact check: `runtime_behavior:` these ports preserve reader settings, source-login state, and source-management preferences while moving feature pages behind application interfaces.

Default native gate: `flutter test --no-pub <affected tests>` and `flutter analyze --no-pub <affected files>`.

Aggregate gate: `flutter test --no-pub --concurrency=1 --reporter compact`, `flutter analyze --no-pub`, `dart format`, `git diff --check`, then Android smoke comparison on `emulator-5558`.

Detour budget: stop a lane after three unresolved runs of the same test; report the cause without weakening tests.

Claim ceiling: the assigned direct service dependencies are removed without changing the protected reader content, table of contents, pagination, chapter identity, UTF-16 reading positions, or line-break rule.

Non-claims: this batch does not validate Web/WASM/PWA, real Android TTS, or formal/mainstream WebDAV.

Acceleration note:
- Saved: independent Feature-to-service boundaries are implemented concurrently.
- Cost/duplication: each lane must update its own port/adapter tests and may require owner integration fixes.
- Future hot path: `scripts/check_architecture_boundaries.ps1` remains the shared selection gate.

| Lane | Scope | Write set | Forbidden paths | Native gate | Terminal state |
| --- | --- | --- | --- | --- | --- |
| L0 | Reader global configuration preferences and font/session ports | `lib/features/reader/reader_page.dart`, `lib/application/reader/`, `lib/infrastructure/reader/`, direct tests | `legado-main/`, other Feature pages, protected reader behavior | reader targeted tests + analyze | integrated to owner |
| L1 | RSS source login | `lib/features/rss/`, `lib/application/rss/`, `lib/infrastructure/rss/`, direct tests | `legado-main/`, reader and sources Feature pages, composition root | RSS targeted tests + analyze | integrated to owner |
| L2 | Source login | `lib/features/sources/source_login_page.dart`, `lib/application/source_login/`, `lib/infrastructure/source_login/`, direct tests | `legado-main/`, reader/RSS pages, composition root | source-login targeted tests + analyze | integrated to owner |
| L3 | Source-management preferences | `lib/features/sources/sources_page.dart`, `lib/application/source_management/`, `lib/infrastructure/source_management/`, direct tests | `legado-main/`, reader/RSS/source-login pages, composition root | source-management targeted tests + analyze | integrated to owner |

## Validation Status

- Passed targeted Flutter gates for rule subscriptions, RSS login/editing, source login WebView/Cookie, source-management preferences, Reader configuration, Reader font/pagination snapshots, and Reader session preferences.
- `flutter analyze --no-pub` and `git diff --check` passed after the final Reader sub-batch.
- The serial full Flutter suite was started, but the command runner closed its output pipe after 122 seconds; the resulting `FileSystemException` is an executor timeout, not an assertion failure. It remains an unproven aggregate gate and must be rerun in an environment without that pipe limit.
- Architecture scan is reduced from 21 to 5 direct Feature-to-service imports. The five remaining imports are all in `ReaderPage`.
- Android reference validation uses `D:\Android\platform-tools\adb.exe`; rebuilt-app installation and comparison remain pending the R6 aggregate gate.
- Android reference baseline was recovered through `D:\Android\platform-tools\adb.exe`: `emulator-5558` runs the pre-refactor package `io.legado.app.releaseS`. Its first-run path is privacy agreement, update log, optional local backup-password prompt, then the bookshelf empty state. The empty bookshelf uses a brown top bar, red active indicator, four bottom tabs (bookshelf/discover/subscriptions/me), and the text `书架还空着，先去搜索书籍或从发现里添加吧!`. Generated screenshots remain local evidence only.

## Partial Results

- The three parallel worker launches received service-side `429 Too Many Requests` before accessing the workspace. They made no changes; their scoped work was completed in the owner checkout.

## Parallel Batch 2

Original goal: remove the final three `ReaderPage` direct business-service imports without changing reading behavior.

Acceptance check: architecture scan reaches zero Feature-to-service violations and owner-checkout Reader tests pass.

Product impact check: `runtime_behavior:` reading-progress sync, bookmarks, and content-edit raw refetch retain their current observable behavior behind application ports.

Default native gate: targeted Flutter tests and targeted analyze for each lane.

Aggregate gate: architecture scan, serial Flutter suite, full analyze, `git diff --check`, and rebuilt-app smoke on `emulator-5558`.

Detour budget: three unresolved repetitions of the same test failure.

Claim ceiling: Reader Feature-to-service imports are removed with protected content, pagination, chapter identity, UTF-16 positions, and line breaking unchanged.

| Lane | Scope | Write set | Forbidden paths | Native gate | Direct fix | Terminal state |
| --- | --- | --- | --- | --- | --- | --- |
| B2-L0 | Content-edit raw refetch | owner: new reader application/infrastructure port and tests | `legado-main/`, protected reader algorithms | content-edit tests + analyze | yes | integrated to owner |
| B2-L1 | Reading-progress sync port | new reader application/infrastructure files and direct tests | `ReaderPage`, composition root, docs, other lanes | progress-sync tests + analyze | yes | integrated to owner |
| B2-L2 | Bookmark readiness port | new reader application/infrastructure files and direct tests | `ReaderPage`, composition root, docs, other lanes | bookmark tests + analyze | yes | integrated to owner |
| B2-L3 | Read-only boundary review | none | all writes | report exact integration risks/tests | no | reported to parent |

Batch 2 validation status:

- Owner targeted merge regression: `31/31` passed.
- Architecture boundary scan: zero violations.
- Reader progress tests preserve UTF-16 chapter positions and WebDAV ETag/412 retry semantics.
- Read-only review found no blocking integration defect; it confirmed the content-refetch provider must remain after `SourceProvider` and alternate Reader hosts must inject the three new ports.
- Aggregate Flutter suite: `813` passed, `3` existing conditional skips.
- Android `emulator-5558`: Module 3 single-chapter Reader snapshot `1/1` passed; multi-chapter boundary snapshot `1/1` passed. Both built and installed the debug APK, loaded Rust engine v0.5.6, and preserved pagination geometry.
- The hand-built Android Reader test hosts now register all Reader ports, including the no-op progress port used because these snapshot cases do not exercise WebDAV.
- Theme reference: the legacy Beta bookshelf colors are treated as theme-derived values. The captured brown top bar/red active state is a baseline for the selected theme, not a hard-coded color contract.
- Full Flutter suite, full analyze, format/diff checks, and rebuilt Android smoke remain aggregate gates.

## Parallel Batch 3

Original goal: continue R6 application-boundary convergence without touching the current dirty Reader/RSS/Source integration set.

Acceptance check: each implementation lane removes its assigned Widget-to-service dependency, preserves existing behavior through an application port, and passes its native targeted tests in the owner checkout; the review lane returns an exact next split for provider dependencies.

Product impact check: `runtime_behavior:` bookmark, bookplate, group-management, source-rule and replacement helper behavior remain unchanged while their service ownership moves behind application ports.

Default native gate: `flutter test --no-pub --concurrency=1 <affected tests>` and `flutter analyze --no-pub <affected files>`.

Aggregate gate: architecture boundary check, affected owner regression, Flutter serial suite, full analyze, `dart format`, and `git diff --check`.

Detour budget: stop a lane after three unresolved repetitions of the same test failure; do not weaken assertions or alter the legacy baseline.

Claim ceiling: only the assigned widget boundary is proven; this batch does not claim provider migration, Android TTS, Web/WASM/PWA, or formal WebDAV completion.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | Book-group widget implementer | Move group edit/manage/select widgets behind an application port and add focused tests | `lib/widgets/book_group_*.dart`, new `lib/application/bookshelf/book_group_management_port.dart`, new `lib/infrastructure/bookshelf/book_group_management_port_adapter.dart`, new focused tests | `lib/bootstrap/app_composition_root.dart`, Reader/RSS/Source pages, `legado-main/` | group widget/application tests + analyze | yes |
| W2 | Annotation widget implementer | Move bookmark editor, bookplate overlay and note editor service calls behind application ports | `lib/widgets/bookmark_editor_sheet.dart`, `lib/widgets/bookplate_overlay.dart`, `lib/widgets/note_editor_sheet.dart`, new annotation application/infrastructure files, new focused tests | `lib/bootstrap/app_composition_root.dart`, `lib/features/reader/`, `lib/features/sources/`, `legado-main/` | annotation widget/application tests + analyze | yes |
| W3 | Source-rule widget implementer | Move source-check, dictionary lookup and replacement-preview helper calls behind application ports | `lib/widgets/check_source_config_dialog.dart`, `lib/widgets/check_source_keyword_dialog.dart`, `lib/widgets/dict_lookup_sheet.dart`, `lib/widgets/replace_preview_panel.dart`, new application/infrastructure files, new focused tests | `lib/bootstrap/app_composition_root.dart`, all Reader/RSS pages, Provider files, `legado-main/` | helper widget/application tests + analyze | yes |
| W4 | Provider boundary reviewer | Audit remaining Provider/widget service imports and propose the next disjoint implementation slice; no code edits | none | all source files and docs | read-only report | no |

Integration order: W1-W3 changes were accepted only after the owner added composition-root bindings and reran the affected gates; W4 remains advisory only. No lane may stage, commit, push, or edit `legado-main/`.

Batch 3 validation status:

- W1 BookGroup widget lane: focused and store regression `11/11` passed; terminal state `integrated_to_owner`.
- W2 annotation widget lane: focused `10/10` passed; terminal state `integrated_to_owner`.
- W3 source-rule helper lane: focused `14/14` passed; terminal state `integrated_to_owner`.
- W4 Provider review: no writes; remaining direct service imports are limited to `book_provider.dart`, `replace_provider.dart`, `rss_provider.dart` and `source_provider.dart`; terminal state `reported_to_parent`.
- Owner added the W1-W3 composition-root providers, then the combined affected regression passed `33/33`; W4-W0 bottom navigation/font lane passed `4/4`.
- `scripts/check_architecture_boundaries.ps1` passed; an extended Widget/Feature/Provider scan shows no remaining Widget/Feature direct service imports. Provider backlog remains intentionally unmodified for the next batch.
- `flutter analyze --no-pub` passed with no issues; serial Flutter aggregate passed `829` tests with `3` existing conditional skips; `git diff --check` exited `0` with existing LF/CRLF warnings only.
- `test/model/read_book_async_test.dart` now waits for active preloading keys before deleting its temporary directory. This fixes a Windows file-lock teardown race without changing assertions or Reader behavior; the test passed `3/3` independently and in the aggregate run.

## Parallel Batch 4

Original goal: continue the Provider boundary backlog after the Widget/Feature direct-service scan reached zero.

Acceptance check: each Provider consumes an application contract for its assigned concern, existing provider/repository and widget host tests pass, and no lane changes Reader content, chapter order, pagination, chapter identity, UTF-16 positions, or line-break behavior.

Product impact check: `runtime_behavior:` Provider defaults, source validation/login headers, RSS source persistence and replacement preset selection retain their existing keys, ordering, fallback and error semantics.

Default native gate: each lane's targeted provider/application/infrastructure tests plus `flutter analyze --no-pub` on its write set.

Aggregate gate: owner composition-root integration, extended service-import scan, serial Flutter suite, full analyze, `dart format`, and `git diff --check`.

Detour budget: three unresolved repetitions of the same test failure; do not widen ports or weaken assertions to make a lane pass.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| P0 | Replace preset implementer | Move `ReplaceProvider` built-in preset loading behind a narrow application port | `lib/providers/replace_provider.dart`, new `lib/application/replace/replace_preset_port.dart` extension/files, new infrastructure adapter/tests, provider tests | `lib/bootstrap/app_composition_root.dart`, Reader/RSS/Source providers, `legado-main/` | replace preset/provider tests + analyze | yes |
| P1 | Book progress migration implementer | Move pure chapter-progress migration strategy into application layer | `lib/providers/book_provider.dart`, `lib/application/book/chapter_progress_migrator.dart`, compatibility export/service tests | `lib/bootstrap/app_composition_root.dart`, Replace/RSS/Source providers, Reader algorithms, `legado-main/` | chapter migrator/provider tests + analyze | yes |
| P2 | Source provider implementer | Consume existing source-login header and source-check preference ports for the assigned Provider paths | `lib/providers/source_provider.dart`, provider tests and new focused tests | `lib/bootstrap/app_composition_root.dart`, Book/Replace/RSS providers, W1-W4 files, `legado-main/` | source provider/login/validation tests + analyze | yes |
| P3 | RSS source persistence implementer | Introduce a narrow source-list store port and remove direct SharedPreferences from `RssProvider` | `lib/providers/rss_provider.dart`, new `lib/application/rss/rss_source_store_port.dart`, new `lib/infrastructure/rss/` adapter/tests, RSS provider tests | `lib/bootstrap/app_composition_root.dart`, Book/Replace/Source providers, current RSS Feature pages, `legado-main/` | RSS source/provider tests + analyze | yes |

Owner integration: only the parent edits `lib/bootstrap/app_composition_root.dart` after all lanes pass; each lane must report `integrated_to_owner` only after owner reruns its native gate. No lane may stage, commit, push, or modify `legado-main/`.

Batch 4 validation status:

- P0 Replace preset: focused `4/4` passed; `ReplaceProvider` loads only the four built-in rules through `ReplacePresetPort`; terminal state `integrated_to_owner`.
- P1 Book progress migration: chapter migration `6/6` and Provider `2/2` passed; pure strategy moved to application with compatibility export; terminal state `integrated_to_owner`.
- P2 Source provider: source header/validation/repository regression `24/24` passed; Provider consumes existing application ports and no longer imports their infrastructure adapters; terminal state `integrated_to_owner`.
- P3 RSS source persistence: application/provider/Feature regression `10/10` passed; `RssSourceStorePort` preserves `legado_rss_sources`, ordering and URL deduplication; terminal state `integrated_to_owner`.
- Owner combination regression: `42/42` passed. The composition root explicitly binds `ReplacePresetPort`, `SourceLoginPagePort`, `CheckSourcePrefsPort` and `RssSourceStorePort`; Provider fallbacks are application-only unavailable ports.
- Architecture script passed; extended scan has no Feature/Widget direct service or infrastructure imports. Remaining Provider service imports are the explicitly deferred BookSource/SourceGroup/Validation/Sync concerns from W4 review.
- `flutter analyze --no-pub` passed with no issues; serial Flutter aggregate passed `838` tests with `3` existing conditional skips; `git diff --check` remains clean apart from existing LF/CRLF warnings.

## Parallel Batch 5

Original goal: reduce the remaining Provider service backlog while designing high-risk aggregation boundaries before implementation.

Acceptance check: the implementation lane moves only source-group catalog/tag ownership behind an application boundary; review lanes return exact disjoint write sets and preserved behavior contracts for validation storage, BookProvider service aggregation, and batch progress sync.

Product impact check: `runtime_behavior:` source-group CRUD/filter semantics are unchanged; review-only lanes cannot claim implementation or runtime behavior changes.

Default native gate: implementation lane targeted source-provider/group tests and analyze; review lanes are read-only evidence only.

Aggregate gate: owner composition-root integration, extended scan, affected regression, serial Flutter suite, full analyze, format, and `git diff --check`.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| S1 | Source group implementer | Move SourceGroupCatalog/SourceGroupTags usage out of SourceProvider behind a narrow application contract | `lib/providers/source_provider.dart`, new `lib/application/source_management/source_group_catalog_port.dart`, new `lib/infrastructure/source_management/` adapter/tests | `lib/bootstrap/app_composition_root.dart`, BookProvider, Reader/RSS pages, SourceValidationStore, `legado-main/` | source group/provider tests + analyze | yes |
| S2 | Source validation reviewer | Read-only design for SourceValidationStore/result persistence boundary | none | all writes | report exact contract/tests only | no |
| B1 | BookProvider aggregation reviewer | Read-only audit of BookSourceService and LocalBookService dependencies and a safe staged port plan | none | all writes | report behavior risks/tests | no |
| B2 | Progress sync reviewer | Read-only audit of BookProgressSync batch download/apply semantics versus existing ReaderProgressSyncPort | none | all writes | report contract and compatibility risks | no |

No review lane may edit files or claim integration. S1 remains candidate until owner adds the composition-root adapter and reruns native gates; no lane may stage, commit, push, or modify `legado-main/`.

Batch 5 validation status:

- S1 source-group boundary passed its owner-checkout targeted regression `13/13`; `SourceProvider` now consumes `SourceGroupCatalogPort`, and the composition root injects `SourceGroupCatalogPortAdapter`. Terminal state: `integrated_to_owner`.
- S2 validation-store review reported the minimal `load`/`put`/`remove` contract, the existing `source_validation_v1` compatibility requirements, and the current persistence-failure consistency risk. Terminal state: `reported_to_parent`.
- B1 book aggregation review confirmed that `BookSourceService` and `LocalBookService` must be split by behavior before migration because they preserve directory/content fallback, retry, file-size, encoding, TXT and EPUB semantics. Terminal state: `reported_to_parent`.
- B2 progress-sync review confirmed that batch download needs a separate application port preserving remote-newer/position-ahead selection and the rule that sync time advances only after `apply` succeeds. Terminal state: `reported_to_parent`.
- `flutter analyze --no-pub`: no issues. `scripts/check_architecture_boundaries.ps1`: passed. Extended Provider scan now has five explicit service imports: BookProvider book-source/progress/local-book and SourceProvider book-source/validation-store.
- Serial Flutter aggregate: `842` passed with `3` existing conditional skips. `git diff --check` exited `0` with existing LF/CRLF warnings only.
- Acceleration note: Saved: three high-risk contracts were reviewed while S1 implemented the independent source-group boundary. Cost/duplication: owner reran S1 gates and retained all composition-root edits. Future hot path: use the five-import Provider scan as the Batch 6 selection gate.

## Parallel Batch 6

Original goal: remove the five remaining Provider service imports through narrow reviewed application contracts without changing protected reading or import behavior.

Acceptance check: four disjoint lanes pass their native tests; owner then integrates one Provider at a time and the extended Provider scan decreases after each green gate.

Product impact check: `runtime_behavior:` validation cache keys/results, source import/search mapping, local TXT/EPUB import fallback, and WebDAV batch progress selection/apply ordering remain unchanged.

Default native gate: focused application/infrastructure/provider tests plus affected-file `flutter analyze --no-pub`.

Aggregate gate: owner integration regression, architecture scans, serial Flutter suite, full analyze, format, and `git diff --check`.

Detour budget: stop after three unresolved repetitions of the same test failure; never weaken assertions or bypass protected Reader behavior.

Claim ceiling: only service imports whose owner integration and full gates pass may be claimed migrated.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| V1 | Validation-store implementer | Introduce `SourceValidationStorePort`, adapter and inject it into `SourceProvider` | `lib/application/source_validation/source_validation_store_port.dart`, `lib/infrastructure/source_validation/source_validation_store_port_adapter.dart`, `lib/providers/source_provider.dart`, focused validation tests | composition root, all Book files, `legado-main/` | validation adapter/provider tests + analyze | yes |
| P1 | Batch-progress contract implementer | Introduce a batch progress application port and adapter preserving async apply ordering | new application/infrastructure book-progress port files and focused tests only | `BookProvider`, `BookProgressSync`, composition root, Reader files, `legado-main/` | adapter/contract tests + existing sync regression | yes |
| L1 | Local-book contract implementer | Introduce local file/path import port and adapter with application error mapping | new application/infrastructure local-book port files and focused tests only | `BookProvider`, `LocalBookService`, composition root, Reader files, `legado-main/` | adapter/contract tests + local import regression | yes |
| S1 | Source-management facade implementer | Introduce the narrow fetch/search/result-map port needed by `SourceProvider` | new application/infrastructure source-management facade files and focused tests only | `SourceProvider`, `BookProvider`, composition root, `BookSourceService`, `legado-main/` | adapter/contract tests + source search regression | yes |

Owner alone edits the composition root and Provider integrations outside V1. Each candidate remains `accepted_as_input` until its owner-checkout gate passes. No lane may stage, commit, push, or modify `legado-main/`.

Batch 6 validation status:

- V1 validation store: owner regression `20/20`; `SourceProvider` uses `SourceValidationStorePort`, composition root injects the SharedPreferences adapter; terminal state `integrated_to_owner`.
- P1 batch progress: owner regression `20/20`; `BookProvider` and `AppBootstrap` use `BatchBookProgressSyncPort`, composition root wraps the unchanged `BookProgressSync`; terminal state `integrated_to_owner`.
- L1 local import: owner regression `26/26`; `BookProvider` uses `LocalBookImportPort`, composition root wraps `LocalBookService`, and bookshelf adapter accepts both application and legacy exceptions; terminal state `integrated_to_owner`.
- S1 source facade: owner regression `32/32`; `SourceProvider` uses `SourceManagementBookSourcePort`, `BookSourceService` retains compatibility implementation, and composition root injects the facade adapter; terminal state `integrated_to_owner`.
- First aggregate run found one existing test-host compatibility path throwing `LocalBookImportException`; the adapter now maps both legacy and application exceptions to the same bookshelf error without changing assertions. Recheck passed.
- Final aggregate: `flutter analyze --no-pub` no issues; serial Flutter `864` passed with `3` existing conditional skips; architecture script passed; `git diff --check` exited `0` with existing LF/CRLF warnings. Extended Provider scan has one remaining import: `BookProvider -> BookSourceService`.
- Acceleration note: Saved four reviewed Provider boundaries in one batch. Cost/duplication: owner integration required one compatibility catch and one full aggregate rerun. Future hot path: split the remaining BookProvider facade by details/search, TOC and content before changing its constructor.

## Parallel Batch 7

Original goal: remove the final `BookProvider -> BookSourceService` import through a Provider-specific application facade while preserving Reader content, pagination, TOC order and source retry/fallback behavior.

Acceptance check: the implementation lane passes its adapter contract tests; three review lanes identify exact integration hazards; owner changes only the BookProvider/AppBootstrap/composition-root seam and full gates remain green.

Product impact check: `runtime_behavior:` BookProvider source lookup, TOC refresh, chapter-content probe and ReadBook content configuration remain behaviorally identical.

Default native gate: focused facade/adapter tests and existing BookProvider/ReadBook/BookSourceService regressions.

Aggregate gate: owner BookProvider integration, architecture scan, serial Flutter suite, full analyze, format, and `git diff --check`.

Detour budget: three unresolved repetitions of the same test failure; no assertion weakening and no changes to protected Reader algorithms.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| B7-I | BookProvider facade implementer | Define a narrow Provider-specific source facade and legacy adapter covering exact BookProvider calls | new application/infrastructure BookProvider source facade files and focused tests only | `BookProvider`, `AppBootstrap`, composition root, `ReadBook`, `legado-main/` | facade adapter + BookSourceService regression | yes |
| B7-R1 | ReadBook compatibility reviewer | Read-only audit of ReaderContentSourcePort/PaginatedReaderContentSourcePort requirements and integration seam | none | all writes | report exact type/behavior contract | no |
| B7-R2 | BookProvider call-site reviewer | Read-only audit of details/search/Toc/content call sites, retry and mapping semantics | none | all writes | report exact method matrix and test list | no |
| B7-R3 | Consumer impact reviewer | Read-only audit of all BookSourceService consumers and composition-root injection risks | none | all writes | report forbidden widening and migration order | no |

Only owner may modify `BookProvider`, `AppBootstrap`, composition root, tests outside the new facade tests, or docs after lane synthesis. No lane may stage, commit, push, or modify `legado-main/`.

Batch 7 validation status:

- B7-I facade candidate passed focused `2/2`; owner BookProvider/ReadBook/BookSourceService regression passed `41/41`. The facade covers all BookProvider calls and both Reader content capabilities; terminal state `integrated_to_owner`.
- B7-R1 confirmed `nextChapterUrl` must remain nullable and unchanged, including ReadBook last-chapter wraparound and BookSourceService pagination fallback. Terminal state `reported_to_parent`.
- B7-R2 confirmed details/search/TOC/content call matrix, timeout and error isolation, TOC order/dedupe and source retry requirements. Terminal state `reported_to_parent`.
- B7-R3 confirmed other BookSourceService consumers and `Provider<BookSourceService>` remain unchanged. Terminal state `reported_to_parent`.
- Owner changed only the BookProvider/AppBootstrap/composition-root injection seam; `ReadBook` keeps the same content port behavior and legacy service remains available to other consumers.
- Final aggregate: `flutter analyze --no-pub` no issues; serial Flutter `866` passed with `3` existing conditional skips; architecture script passed; extended Provider service scan is empty; `git diff --check` exited `0` with existing LF/CRLF warnings.
- Acceleration note: Saved the final Provider boundary through one implementation lane plus three targeted reviews. Cost/duplication: one corrected test command removed nonexistent paths before the green gate. Future hot path: Provider service import scan is now a zero baseline; remaining work should follow feature/domain backlog rather than Provider cleanup.

## Parallel Batch 8

Original goal: move MainShell privacy-consent persistence behind an application port while preserving the existing key, startup timing, failure fallback and dialog behavior.

Acceptance check: MainShell no longer imports `shared_preferences_runtime.dart` directly; focused MainShell/privacy tests and owner composition-root regression pass.

Product impact check: `runtime_behavior:` privacy agreement is still shown exactly when the persisted boolean is absent/false, and runtime storage failures continue to degrade without blocking the first UI.

Default native gate: focused MainShell/privacy port tests, affected widget tests, and affected-file analyze.

Aggregate gate: owner composition-root integration, architecture scan, serial Flutter suite, full analyze, format, and `git diff --check`.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| M8-I | Privacy port implementer | Define privacy-consent application port, SharedPreferences adapter and focused tests | new application/infrastructure privacy files and focused tests only | `MainShell`, composition root, `legado-main/` | port/adapter tests + analyze | yes |
| M8-R1 | MainShell lifecycle reviewer | Read-only audit privacy dialog timing, mounted checks and startup lifecycle | none | all writes | report exact integration contract | no |
| M8-R2 | Preference runtime reviewer | Read-only audit SharedPreferencesRuntime failure/retry semantics and test hooks | none | all writes | report compatibility risks | no |
| M8-R3 | UI regression reviewer | Read-only audit MainShell/widget tests and composition-root injection hazards | none | all writes | report focused regression list | no |

Owner alone modifies `MainShell`, composition root and non-lane tests after synthesis. No lane may stage, commit, push, or modify `legado-main/`.

Batch 8 validation status:

- M8-I privacy port: owner focused privacy/runtime/MainShell/Welcome regression `14/14`; adapter preserves `legado_privacy_accepted`, reuses `SharedPreferencesRuntime`, and retries runtime resolution after a failed initialization. Terminal state `integrated_to_owner`.
- M8-R1 confirmed post-frame prompt timing, mounted checks, dialog order, non-dismissible barrier and crash-recovery ordering. Terminal state `reported_to_parent`.
- M8-R2 confirmed runtime coalescing, retry and failure semantics; owner corrected the candidate adapter so a cached null does not suppress later runtime retries. Terminal state `reported_to_parent`.
- M8-R3 confirmed three MainShell hosts require privacy fakes and composition root should register an independent port, without widening MainShellStartupPort. Terminal state `reported_to_parent`.
- Final aggregate: `flutter analyze --no-pub` no issues; serial Flutter `869` passed with `3` existing conditional skips; architecture script passed; Feature/Widget/Provider extended scan is clean; `git diff --check` exited `0` with existing LF/CRLF warnings.
- Acceleration note: Saved one feature boundary while three reviewers checked lifecycle and runtime retry hazards. Cost/duplication: owner added three test-host fakes and corrected retry semantics before the aggregate gate. Future hot path: use the clean feature/widget/provider scan as the next R6 baseline.

## Parallel Batch 9

Original goal: continue the refactor roadmap with evidence-first `<js>` source-rule compatibility validation, without entering Web/WASM/PWA or changing legacy behavior claims without a reproducer.

Acceptance check: existing Rust/Flutter JS compatibility gates are reproduced; independent reviewers identify concrete compatibility gaps; any implementation preserves source-rule output and adds regression evidence before changes are claimed.

Product impact check: `runtime_behavior:` JavaScript rule execution, JSON/string coercion, request bridge behavior and source-rule result mapping remain compatible with the legacy baseline.

Default native gate: `powershell -ExecutionPolicy Bypass -File scripts/run_js_compat.ps1` and affected Rust/Flutter tests.

Aggregate gate: Rust workspace tests, JS compatibility script, affected Flutter tests, full analyze/test only when source changes land, and `git diff --check`.

| Lane | Role | Scope | Write set | Forbidden paths | Native gate | Direct fix |
| --- | --- | --- | --- | --- | --- | --- |
| J9-R1 | Rust JS compatibility auditor | Read-only audit current `js_engine` and compatibility tests against documented legacy cases | none | all writes, `legado-main/` | report exact gaps | no |
| J9-R2 | Legacy behavior auditor | Read-only compare original JS rule behavior/schema and current Rust fixtures | none | all writes, `legado-main/` remains read-only | report mappings | no |
| J9-R3 | Flutter bridge auditor | Read-only inspect FRB/Flutter JS compatibility bridge and test coverage | none | all writes | report bridge risks | no |
| J9-R4 | Test harness auditor | Read-only inspect `run_js_compat.ps1`, Rust/Flutter commands and reproducibility hazards | none | all writes | report command evidence | no |

No implementation is authorized until the four reports agree on a bounded write set and a reproducer. No lane may stage, commit, push, modify tests to weaken expectations, or modify `legado-main/`.

Batch 9 当前证据状态（2026-08-01）：四条审查线已返回。现有 Rust 离线 JS `18/18`、Flutter JS `4/4` 通过；脚本已固定 `--locked --offline` 与 `--no-pub`，工具缺失不再假绿，`docs/JS_COMPAT.md` 统计已更新为 `18`。原版对照确认 `@js:`/`@JS:` 路由大小写不敏感，当前 `BookSource::field_needs_js` 存在明确最小复现；本批仅允许修复该判定并补回归测试。普通宿主变量、完整 API、真实 FRB 链路和对象返回值语义不通过占位值宣称完成，继续作为兼容性 backlog。owner 必须在候选线完成后先通过 Rust 定向测试，再执行 workspace、Flutter、analyze、架构和 diff 门禁。

## Parallel Batch 10

目标：将 Batch 9 已确认的 `@js:`/`<js>` ASCII 大小写契约收口到 Flutter 登录脚本入口和兼容性报告分析器，不扩大到完整 JS 宿主 API。

写集分离：

- A：`lib/services/source_login_service.dart` 与专门的大小写回归测试。
- B：`lib/services/js_compat_analyzer.dart` 与既有分析器测试。

Batch 10 验证状态：A/B 候选各自定向 `3/3`；owner 组合定向 `11/11`；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界脚本、Dart 格式检查和 `git diff --check` 通过。`<js>` 宿主 API 子集、超时/取消、真实 FRB 执行链、在线书源和对象返回值语义继续作为兼容性 backlog，不以默认值或弱断言关闭。

## Parallel Batch 11/12

目标：补齐 Rust 主请求及 `validateSource` 的登录头与 HTTP trace 生命周期，保持成功返回、原始异常和下一轮 trace 语义；调试/裸 HTTP 入口和持久化队列可靠性另行处理。

写集：`lib/bridge/legado_engine_bridge.dart`。六个主请求入口和校验入口在 `finally` 中统一执行“同步登录头 → drain trace”。

验证状态：owner 引擎/source debug 定向 `2` 个可运行测试通过、`2` 个在线 smoke 按既有开关跳过；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界脚本和 `git diff --check` 通过。剩余 `debugSearch`/`debugToc`/`httpFetch`、登录头队列失败重试/空值删除和 Rust loginCheckJs 错误语义不宣称完成。

## Parallel Batch 13

目标：补齐调试搜索、调试目录和裸 HTTP bridge 的 finally 收尾，不改变 Rust API 和业务返回语义。

写集：`lib/bridge/legado_engine_bridge.dart`。`debugSearch`、`debugToc` 在 finally 中同步登录头并 drain trace；`httpFetch` 始终 drain trace，传入 source 时执行防御性同步。

验证状态：owner 定向 `4/4`；Flutter 串行全量 `873` 通过、`3` 项既有条件跳过；`flutter analyze --no-pub`、架构边界脚本和 `git diff --check` 通过。真实持久化链路、异常 trace fixture、队列 ack/重试和空登录头删除继续作为后续 backlog。
