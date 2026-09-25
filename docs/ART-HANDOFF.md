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
- Каждая версия: поднять `version` в `info.json`, записи в `changelog.txt` (формат Factorio, англ.,
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
Игроку советовать: скачивать картинку кнопкой ChatGPT (так сохраняется настоящая прозрачность), а не
копировать из чата; класть в `art/incoming/` под точным именем.

## Сделано
- `sd-campfire` (1.2 клетки, `--ground 0.5 --fire 0.5`): погасший, горящий, своё пламя — версия 0.11.4.
- `sd-scholar-desk` (3.2 клетки): одна картинка от Gemini, ракурс почти строго сверху — **переделать
  в ChatGPT** (рабочее: лампа горит; `-idle`: лампа погасла).

## Дальше (по `docs/ART.md`, сверху вниз)
Волна 1: стол учёного (переделка) → волчье логово, кабанья лёжка (тип `unit-spawner` — нужна ветка в
`art.lua`) → ресурсы глина/ракушки/селитра (тип `resource`: листы кусков, 4 варианта × 4 стадии —
нужна отдельная обработка) → записка, разрушенная стена → иконки старта.
Волна 2: печь для обжига, верстак, копатель, жаровня, огород, бродильный чан, перегонный куб, камера
пробуждения, частокол, иконки. Звери и корабли — через 3D (см. ART.md), позже.
Ванильные здания эпохи 3+ (трубы, котлы, сборщики) не трогать.
