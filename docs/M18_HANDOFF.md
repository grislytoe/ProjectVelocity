# Передача M18 на следующий этап проверки

**Вердикт: BLOCKED. Готово к developer review, не к production EOS или M19.**

PR: [#19](https://github.com/grislytoe/ProjectVelocity/pull/19),
ветка `feature/m18-eos-compatibility-gate`, база dev
`28336864d9e76ec8f483558be6f7bce183049379`. PR пока не слит.
Состояние последнего коммита и CI проверять по PR перед продолжением; не считать
исторические успешные run IDs проверкой нового HEAD.

## Что подготовлено

- [Технический отчёт и матрица](M18_COMPATIBILITY.md): точный EOSG2.3.0,
  commit `e84320567a3a17d305478f5796707e69d2bdac4f`, SDK1.19.1.2-53289219,
  проверенные SHA256/SHA512, источники и границы лицензий.
- Native-only opt-in harness: Windows/Linux load, API, глобальные init/shutdown,
  malformed platform config. Он не содержит online executor и не является EOS transport.
- Повторная проверка обвязки: cleanup при раннем отказе, удаление временных user/cache
  директорий, точное восстановление отсутствующих и существующих env-переменных.
  Отдельный regression test `dev_tools/test_eosg_launcher.ps1` запускается в CI.
- Cold import в native CI отклоняет не только ненулевой exit code, но и Godot errors/warnings.
- Build0.18.0-dev/24, protocol3/wire2, schema5; ENet остаётся default, игровое ядро не изменено.

Подтверждённая историческая база до исправлений обвязки: `b52a12350764bb368d61ae2150ed165ef2967a8b`.
Её CI повторно проверен: native PR34751480581/push34751478969 и полный Windows
PR34751480583/push34751478967 — success. Расширенная13-сценарная матрица M17 на этой базе
прошла, включая rendered30/144, reconnect, profile changes, host exit и combined30 retry.
Новый полный локальный прогон: `builds/validation/m18-recheck-full.log` — PASS, exit0,
`M0-M17 validation passed`, включая отдельные ENet-процессы и обязательные stress cases.
Windows native20+3+5 и оба archive-варианта failure cleanup — PASS. Новый head CI
проверяется и фиксируется при передаче в PR; исторический CI его не заменяет.

## Входные условия следующего этапа

| Что требуется | Что нужно проверить/получить | Что это разблокирует |
|---|---|---|
| Developer review PR19 | Явное решение принять BLOCKED delivery; merge только отдельно разрешённый | Принятую базу дальнейшей работы |
| Точный SDK1.19.1.2 | Законно полученный полный пакет, notices, состав Distributable Code, XAudio notices и решение по упаковке | Полное подключение кандидата и проверку EOS-bearing exports; это не утверждение, что локальные export-тесты запрещены |
| Epic test configuration | Product/sandbox/deployment, client policy, Auth application/scopes/access и две разные test identities | Configured platform, Auth→Connect, настоящий Lobby/P2P |
| Dev Auth Tool и сеть | Доступный тестовым процессам endpoint, разрешённые accounts и consent | Воспроизводимый login без передачи токенов в чате/CLI |
| Linux и SteamOS execution | Linux CI с export templates; отдельный SteamOS/Deck runner | Debug/release/staging packaging и реальное SteamOS runtime evidence |

Секреты передавать только через защищённое окружение/секреты runner. Контракт имён:
`PV_EOS_PRODUCT_ID`, `PV_EOS_SANDBOX_ID`, `PV_EOS_DEPLOYMENT_ID`,
`PV_EOS_CLIENT_ID`, `PV_EOS_CLIENT_SECRET`, `PV_EOS_DEV_AUTH_ENDPOINT`,
`PV_EOS_DEV_AUTH_NAME_A`, `PV_EOS_DEV_AUTH_NAME_B`, `PV_EOS_SDK_ARCHIVE`.
Это предложенные имена для будущего online harness; текущий native harness их не читает.
Никаких ClientSecret, exchange codes, токенов, DeviceID или account IDs в чате,
репозитории, аргументах запуска, выводе SDK или артефактах.

## Последовательность после отдельного разрешения продолжить M18

1. Проверить актуальные Git/PR/CI, пакет SDK и наличие входных условий без вывода значений.
   Отсутствующий input означает BLOCKED соответствующей ячейки, а не несовместимость ABI.
2. В той же основной папке проверить полный plugin import/autoload/disable/export lifecycle.
   Исходники содержат10 autoload; disable hook не удаляет HSessions. Это review concern,
   не доказанный runtime failure. Не менять версию EOSG и не переписывать ядро игры.
3. Проверить созданную платформу, настоящий tick, scene reload и порядок teardown.
   SDK после глобального shutdown не переинициализировать в том же процессе.
4. Реализовать узкий opt-in online harness по фактическому API2.3.0: Auth identity и
   Connect PUID различать; token и continuance handling держать только в памяти.
5. Два реальных процесса: Lobby create/search/join/member update/leave/destroy и
   P2P через EOSGMultiplayerPeer, явная accept policy, данные в обе стороны, socket/channel,
   malformed/oversize packet, потеря peer и cleanup. Mock не считать service proof.
6. Отдельно проверить Windows/Linux debug/release/staging exports с native placement,
   отсутствие credentials/network при обычном старте и SteamOS runtime.
7. Сохранить M0–M17 validator/ENet acceptance и map hashes. Обновить матрицу PASS/BLOCKED/FAIL,
   доказательства и снова остановиться для review. PROVEN только при реальном подтверждении
   всех обязательных ячеек; M19/production не начинаются автоматически.

## Готовый контекст для следующего чата

> Продолжи незавершённый M18 EOS Compatibility Gate после developer review PR19.
> Общайся по-русски. Это CRITICAL gate, общий вердикт пока BLOCKED.
> Каждый milestone — отдельный чат; ВСЕГДА основная папка
> C:/Godot Projects/ProjectVelocity. Не создавай worktree/копию и не меняй папку.
> Прочитай WORKFLOW.md, DEPENDENCIES.md, NETWORKING.md, M15/M16/M17 validation,
> docs/M18_COMPATIBILITY.md, docs/M18_HANDOFF.md и EOS/critical разделы master specification.
> Сначала fetch и проверка Git/CI. Если PR19 не слит, не считай его содержимое частью dev
> и не выполняй merge без отдельного явного разрешения. Сохрани project.godot byte-for-byte:
> SHA256 5b9713aca5045dd697ea09df21e9de658283b782b3b0c8f2cc540539fabb65ac;
> пользовательское оформление не коммить. Build0.18.0-dev/24, protocol3/wire2, schema5.
> Продолжать только доступные и отдельно разрешённые проверки M18 по таблице входных
> условий. Не проси секреты в чат и не предполагай наличие credentials, полного SDK,
> export- или SteamOS-среды. Не заменяй EOSG2.3.0, не переписывай transport-independent
> core, не подключай production EOS, не начинай M19. Документированный BLOCKED допустим;
> при неполной проверке обнови технический отчёт и остановись для developer review.

Это контекст, а не разрешение запустить следующий milestone или подтверждение merge.
