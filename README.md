# opencode-exa-websearch

Веб-поиск через [Exa](https://exa.ai) как **custom tool** для
[opencode](https://opencode.ai). Регистрируется под именем `websearch` и
переопределяет встроенный инструмент, поэтому агент всегда видит его и
использует для поиска в интернете.

Запросы идут напрямую в `api.exa.ai` (не через MCP-эндпоинт `mcp.exa.ai`),
поэтому при необходимости можно завернуть их в SOCKS5-прокси и обойти блок
Cloudflare, из-за которого MCP-эндпоинт часто недоступен.

## Что внутри

```
tools/websearch.ts      # custom tool "websearch" (имя = имя файла)
scripts/exa-search.sh   # curl-обёртка над api.exa.ai/search
.env.example            # шаблон конфига с ключом и прокси
install.sh              # копирует всё в ~/.config/opencode
```

## Требования

- opencode (любая современная версия)
- `bash`, `curl`, `jq` в `PATH`
- ключ Exa API — https://dashboard.exa.ai

## Установка

```bash
git clone https://github.com/nohau1/opencode-exa-websearch.git
cd opencode-exa-websearch
./install.sh
```

Скрипт кладёт:

- `tools/websearch.ts` → `~/.config/opencode/tools/websearch.ts`
- `scripts/exa-search.sh` → `~/.config/opencode/scripts/exa-search.sh`
- `.env.example` → `~/.config/opencode/exa-search.env` (создаётся один раз, `chmod 600`)

Затем откройте `~/.config/opencode/exa-search.env` и укажите ключ:

```bash
EXA_API_KEY=ваш-ключ
EXA_PROXY=1.2.3.4:1080          # опционально
EXA_PROXY_USER=user:pass        # опционально
```

После этого **перезапустите opencode** — конфиг и инструменты читаются при старте.

### Ручная установка

Если не хочется запускать `install.sh`, просто скопируйте два файла:

```bash
mkdir -p ~/.config/opencode/tools ~/.config/opencode/scripts
cp tools/websearch.ts      ~/.config/opencode/tools/
cp scripts/exa-search.sh   ~/.config/opencode/scripts/
chmod 700 ~/.config/opencode/scripts/exa-search.sh
cp .env.example            ~/.config/opencode/exa-search.env
chmod 600 ~/.config/opencode/exa-search.env
```

## Настройка

Переменные читаются из `~/.config/opencode/exa-search.env` (или из окружения,
если файла нет). Путь к env-файлу можно переопределить через `EXA_SEARCH_ENV`.

| Переменная         | Обяз. | Описание                                              |
| ------------------ | :---: | ----------------------------------------------------- |
| `EXA_API_KEY`      |  да   | Ключ Exa API                                          |
| `EXA_PROXY`        |  нет  | SOCKS5-прокси `host:port`                             |
| `EXA_PROXY_USER`   |  нет  | Логин/пароль прокси в формате `user:pass`             |
| `EXA_SEARCH_SCRIPT`|  нет  | Путь к `exa-search.sh` (по умолчанию в config-каталоге)|

## Использование

Ничего специального делать не нужно: просто попросите агента что-нибудь найти.

```
найди в интернете, как в opencode переопределить встроенный инструмент
```

Агент вызовет `websearch` с аргументами `query` и (опционально) `numResults`
(1–20, по умолчанию 8). Ответ — список результатов: заголовок, URL, дата/автор
и до трёх подсвеченных фрагментов.

Проверить обёртку напрямую (без opencode):

```bash
bash ~/.config/opencode/scripts/exa-search.sh "opencode plugins" 3 | jq '.results | length'
```

## Как это работает

`tools/websearch.ts` — это [custom tool](https://opencode.ai/docs/custom-tools/):
opencode сканирует `{tool,tools}/*.{js,ts}` в каждой config-директории и
регистрирует каждый `export default tool({...})`. Имя инструмента берётся из
имени файла, поэтому `websearch.ts` становится инструментом `websearch` и
переопределяет встроенный (custom tools имеют приоритет).

Инструмент запускает `scripts/exa-search.sh`, который через `curl` делает
`POST https://api.exa.ai/search` с `contents.highlights` и возвращает JSON.
Инструмент парсит его и форматирует в читаемый текст.

## Безопасность

- В репозитории **нет** секретов: ключ и прокси живут только в
  `~/.config/opencode/exa-search.env` (`chmod 600`, исключён через `.gitignore`).
- Не коммитьте свой `exa-search.env` и не публикуйте прокси-креды.

## Удаление

```bash
rm ~/.config/opencode/tools/websearch.ts
rm ~/.config/opencode/scripts/exa-search.sh
rm ~/.config/opencode/exa-search.env
```

## Лицензия

MIT
