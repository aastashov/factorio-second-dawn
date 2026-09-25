# Графика Second Dawn: вводная для отдельного чата

Ты — Claude Code в репозитории `~/workspace/aastashov/factorio-second-dawn`, мод для Factorio 2.0
(без Space Age). Этот чат занимается **только графикой**: пишет запросы для ChatGPT, принимает
картинки, ставит их в мод. Геймплей, баланс и скрипты не трогай; нашёл там проблему — скажи игроку,
её сделают в основном чате. Общайся по-русски, коротко.

## Правила (от игрока, обязательны)
- **Игру игрока не трогать.** В его папку модов (`~/Library/Application Support/factorio/mods`) ставить
  только собранный zip, **только когда он скажет** и **только когда Factorio закрыт** (проверять
  `pgrep -f factorio.app`). Старый `second-dawn_*.zip` убрать, новый положить. `mod-list*.json` не трогать.
- Проверять самому в изолированном экземпляре (ниже), не в его игре.
- Git с первого дня: коммит на каждую версию, с концовкой `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Версии не на каждую картинку: картинки только импортировать и показывать превью, а выпускать
  пачкой одной версией, когда игрок скажет. Выпуск: поднять `version` в `info.json`, записи в `changelog.txt` (формат Factorio, англ.,
  раздел `Graphics:`) и `CHANGELOG.md` (история проекта, рус.), `bash build.sh` → `dist/2.0/second-dawn_<v>.zip`.
- Игрок любит минимализм: один короткий цельный запрос на одну картинку, без «блоков стиля» и длинных
  списков. Картинки в свой контекст по возможности не загружай: смотри превью, а не исходники.

## Что читать
- `docs/ART.md` — полный список графики в порядке появления для игрока, с размерами в клетках.
- `docs/PROMPTS.md` — как пользоваться и готовые запросы. Раздел «Готово» — что уже сделано.
  Нижняя часть («старые черновики по волнам») — под Gemini, переписывать в новый формат по мере дела.
- `prototypes/art.lua` — как картинки подключаются к зданиям; `tools/import_art.py`, `tools/art.sh`,
  `tools/art_preview.py` — конвейер.

## Конвейер
1. Игрок генерирует в **ChatGPT** (Gemini пробовали — хуже держит ракурс и рисует контуры).
2. Кладёт файлы в `art/incoming/` (любой формат: webp/png/jpg):
   - `<name>.png` — рабочее состояние (горит, работает);
   - `<name>-idle.png` — выключенное, **делается правкой той же картинки в том же чате ChatGPT**, чтобы
     рамка совпала до пикселя;
   - `<name>-fire.png` — по желанию, сетка 4×4 кадров пламени (16 кадров анимации).
3. `tools/art.sh <name> <ширина в клетках> [опции]` — одна команда:
   конвертация → вырезка фона (настоящая прозрачность, нарисованная «шахматка»/белый фон — заливкой от
   края, пурпур — по цветности) → общая обрезка всех состояний → цветокоррекция под палитру игры →
   спрайт 64 px на клетку (scale 0.5) → тень (`-shadow`, draw_as_shadow) → иконка 64×64 →
   `prototypes/art-sizes.lua` → превью `art/preview/<name>.png` на траве рядом с ванильной лабораторией.
   Опции: `--ground <cx>` — пятно выжженной земли (для очагов); `--fire <ширина пламени в клетках>`.
   Строка сохраняется в `art/manifest.txt`; `tools/art.sh` без аргументов переимпортирует всё.
4. `prototypes/art.lua` сам подключает здание по имени. Типы: `furnace`, `assembling-machine`, `lab`.
   Другой тип (бур, манипулятор, стена, турель, логово…) — дописать ветку там же. Сдвиг картинки
   относительно клетки, свет, сдвиг пламени — строкой в таблице `EXTRAS`.
5. Посмотреть превью (увеличить: см. как делалось для `sd-campfire-x3.png`), показать игроку через
   SendUserFile, при необходимости поправить `EXTRAS` / ширину.
6. Проверка без графики (headless не грузит картинки, поэтому проверяем пути и загрузку прототипов):
   ```bash
   dir=/tmp/sd-test; bin="$HOME/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio"
   rm -rf $dir/data/mods/second-dawn; mkdir -p $dir/data/mods/second-dawn
   cp -R info.json data.lua data-final-fixes.lua settings.lua control.lua prototypes scripts locale graphics $dir/data/mods/second-dawn/
   "$bin" --config $dir/config.ini --dump-data > $dir/dump.log 2>&1; grep -A5 Error $dir/data/factorio-current.log
   python3 tests/check_files.py $dir/data/script-output/data-raw-dump.json
   bash tests/run-scenario.sh chain 73100      # цепочка эпохи 1 — ничего не сломано
   ```
   (`$dir/config.ini` и mod-list создаёт `tests/run-scenario.sh`; если папки нет — сначала запусти его.)
   **Этому чату — своя папка:** `export SD_TEST_DIR=/tmp/sd-art-test` и `dir=$SD_TEST_DIR`. `/tmp/sd-test`
   занимает основной чат; при занятом lock `--dump-data` молча оставляет старый дамп — смотреть дату файла.
   Сценарий `wildlife` иногда падает на «raid sent from a predator lair» и без графики (нестабилен).
7. Версия, changelog, `bash build.sh`, коммит. Ставить — только по слову игрока.

## Как писать запрос для ChatGPT (проверено на костре)
Один цельный запрос по образцу:
```
Create a single game sprite of <что> for the video game Factorio, as a PNG with a transparent background.

<Описание: материалы, что на нём/в нём, 2–4 предложения. Каменный век и ремесло, без металла в эпохе 1.>

Camera: exactly like buildings in Factorio — seen from above at a steep angle, looking down from the south; the building stands square to the image, its front edge is a straight horizontal line, we see the top and a little of the front side. Orthographic, no perspective distortion. Light comes from the top-left.

Style: realistic and painterly like the original Factorio graphics, muted natural colors. No black outlines, not a cartoon.

Only the object on a fully transparent background: no ground, no grass, no cast shadow, no text. Square image, object centered and not cropped, filling about 80% of the width.
```
Второе состояние — правкой в том же чате:
`Edit this image: the same <что>, same camera, same size and position, but <что изменилось>. Keep everything else exactly the same. Keep the transparent background.`
Пламя — `Now create a separate sprite sheet on a transparent background: a 4 by 4 grid of 16 equal square cells, each cell is one frame of a looping animation of the flames of this <что> ... same size and position in every cell ...`
Уроки по готовым картинкам (дополнять после каждого ревью):
- Стол: ChatGPT выкинул часть перечисленного (табурет, каменное основание) — перечислять 3–4 главные
  вещи, не больше; важное ставить первым.
- Стол: вышел широким и мелким (3.2 × 2.3 клетки при площадке 3×3) — для квадратных зданий писать
  «seen from above its footprint is square: as deep as it is wide».
- Логово: «края растворяются в прозрачности» ChatGPT не выполнил — земля обрезана резким квадратом.
  Лечится импортом: `--flat 12` (мягкий край 12 px и слабая близкая тень) — для всего, что лежит на
  земле. В запросе вместо этого просить неровное округлое пятно земли: «an irregular rounded patch».
- Логово: руины правкой в том же чате совпали по рамке идеально.
- Лёжка (через Codex, см. ниже): «an irregular rounded patch» сработало — пятно округлое, без квадрата.
  Правка-руины через Codex тоже совпала по рамке.
- Ресурсы: не сетка стадий, а «about 16 separate lumps ... none touching each other» — импорт `--pieces`
  сам режет куски и собирает ванильный лист 8×8 (стадии вложены: беднее — меньше кусков, пыль вокруг).
  Ширина = ширина всей россыпи в клетках: глина/селитра 3, ракушки 2.2. Цвет-признак писать главным
  («the white crust is the main colour»), иначе селитра вышла обычными серыми камнями.
- Иконки: `art/incoming/icons/<name>.png`, `tools/art.sh <name> icon` → `graphics/icons/<name>.png`
  (render_icons.py их больше не перерисовывает; сводный лист — `docs/img/icons.png`). Запрос: «exactly like
  the original Factorio item icons ... a bold simple silhouette ... readable when scaled down to 32 pixels»,
  объект на 90%. Сравнивать со старой в слоте 32 px. Тонкие вещи (лук) в слоте читаются хуже всего.
- Иконки пачкой: 4 параллельных `codex exec` по ~15 иконок — ~25 минут на все. Родственные делать
  «edit of <база>» (кувшины, бутыли, стрелы, слитки, заряды) — форма совпадает. Но отличие правкой
  должно быть крупным и цветным («broad yellow band», «white cloth tied with a blue cord»), иначе
  в слоте 32 px варианты неотличимы (так вышло с кувшинами и бутылью ректификата).
- Ступени (заряды пробуждения) — модель не умеет считать: точки добавляет импорт, `--pips N`.
- Режим подробностей (alt): у маленьких зданий значок рецепта закрывает картинку — `icon` в `EXTRAS`
  (icon_draw_specification: scale, shift), как у костра.
- Ракурс, прозрачность, отсутствие контуров с этим шаблоном держатся хорошо — не трогать.

Через Codex (без копипаста): `CODEX_HOME=~/.codex-personal codex exec --skip-git-repo-check -s workspace-write
-C <scratch> "<задание>" < /dev/null` (без `< /dev/null` виснет, ждёт stdin). В задании: навык `$imagegen`,
текст запроса, имя файла, без обработки кодом; второе состояние — «edit <файл> as the input image».
Идёт ~10 минут на две картинки; запускать в фоне. Потом скопировать в `art/incoming/`.
В браузере игроку советовать: скачивать картинку кнопкой ChatGPT (так сохраняется настоящая прозрачность), а не
копировать из чата; класть в `art/incoming/` под точным именем.

## Сделано
- Здания (2026-09-25), Codex с образцами `vanilla-buildings.png` + арбалет: все эпох 1–3 — костёр, хижина
  учёного (`sd-scholar-desk`, вместо стола), копатель, печь для обжига, верстак, делянка, огород, бродильный
  чан, перегонный куб, жаровня, камера пробуждения, частокол, жернова, горн, стекловарня, кайловый копатель,
  бронзовый бур, самострел, свинарник, псарня, медвежий загон, медвежья берлога (+руины), электрическая
  камера, лаборатория, радиатор, охладитель, плантация, вертлюжная пушка, многозарядный самострел.
  Ветки `art.lua`: mining-drill (одна картинка на все направления), ammo-turret (не поворачивается — временно).
- Временные из локального FLUX.2 Klein (`mflux-generate-flux2-edit`, заменить Codex'ом): излучатель,
  руды олова/вольфрама/серы (`--pieces`), звери волк/кабан/медведь (`--unit`: вид сверху, повёрнут на 16
  направлений, без шагов; вожак/секач/медвежонок — масштабом, `KIN` в `art.lua`).
- Иконки: все 76 предметов и вкладка «Пробуждение» (`sd-group-awakening`, 128 px, в `prototypes/tabs.lua`)
  перерисованы в стиле `docs/ART-STYLE.md` (Codex, образцы арбалет + ванильные иконки). Без выпуска.
- Технологии: все 82 (`art/incoming/tech/`, `tools/art.sh <name> tech`, 256 px) в том же стиле с листом
  ванильных технологий как образцом. Без выпуска.
- `sd-campfire` (1.2 клетки, `--ground 0.5`): перерисован в новом стиле, погасший/тлеющий; пламя ванильное
  через `flame` в `EXTRAS` (своё рисованное выглядело наклейкой), значок рецепта — `icon` в `EXTRAS`. Без выпуска.
- Всё ниже сделано до блока стиля — при случае перерисовать в новом стиле.
- `sd-note` (0.9, `--flat 3`, simple-entity) и `sd-ruin-wall` (1.3, стена: одна картинка на все стыки,
  сдвиг в `EXTRAS`) — через Codex. Без выпуска.
- `sd-clay` (3), `sd-shells` (2.2), `sd-saltpeter` (3), все `--pieces`: ресурсы через Codex. Без выпуска.
- `sd-boar-lair` (5.2 клетки, `--flat 12`): лёжка + `-ruin`, через Codex. Выпуска ещё не было.
- `sd-wolf-lair` (5.2 клетки, `--flat 12`): логово + `-ruin` (труп-руины, тип `unit-spawner` в `art.lua`).
  Выпуска ещё не было.
- `sd-scholar-desk` — **переделать по просьбе игрока**: не стол, а постройка-лаборатория (см. `docs/ART.md`).
  Сейчас (3.2 клетки): из ChatGPT, лампа горит / погасла, свет сдвинут к лампе — версия 0.11.5.

## Дальше
**Отзыв игрока (передан из основной сессии):** иконку подземного жёлоба не узнать — сейчас это ванильный
подземный конвейер в бронзовом цвете. Нужны понятные иконки деревянного и роликового подземного жёлоба и
разделителя: `sd-wooden-underground-chute`, `sd-wooden-splitter-chute`, `sd-underground-chute`,
`sd-splitter-chute`.

Порядок от игрока (2026-09-25): ~~предметы~~ → ~~технологии~~ → ~~здания~~ (кроме манипуляторов,
жёлобов, стыков частокола, поворота турелей) → **звери (анимации) и облик игрока по одежде**, корабли (звери и здания — с анимацией).
Игрок: «больше стиля Factorio, сейчас всё ещё мультяшно». С тех пор в каждое задание Codex идёт блок
стиля из `docs/ART-STYLE.md` (с эпохой: stone age craft / bronze and early metal / industrial) и два
образца: `art/reference/crossbow-icon.png` (главный, от игрока) и лист ванильных иконок — оба
`-i` и «for style only». Проба на верёвке/кувшине/стрелах/мушкете: так приглушённее и потёртее всего.
`-i` принимает несколько файлов — ставить после текста задания, иначе съест задание как файл.
Лимиты: картинки Codex идут в общий лимит плана (5-часовое окно + недельный; браузерный чат — отдельно).
~100 картинок за день = одно 5-часовое окно ≈ 16% недели. Запускать с `-c model_reasoning_effort=low`.
Упёрлись — Codex пишет «usage limit reached… try again at <время>»; ждать фоновым `sleep` до этого времени.
Эксперименты (не основной путь): FLUX schnell локально — слишком фотографично; FLUX.2 Klein 4B
(`~/models/flux2-klein-4b-q8`, `mflux-generate-flux2-edit --image-paths <образцы>`) — годится для черновиков.
Своя LoRA на графике игры — отдельный проект `~/workspace/aastashov/factorio-lora` (учить только на
оригинальной графике игры, не на картинках Codex; модель не публиковать).
Облик игрока по одежде (куртка, шуба, накидка, скафандр) — в `docs/ART.md`, делать вместе со зверями
(тоже анимации персонажа по направлениям).
Ванильные здания эпохи 3+ (трубы, котлы, сборщики) не трогать.
