# Запросы для Gemini

Готовые запросы для генерации графики по [ART.md](ART.md), в том же порядке. Запросы на английском:
на нём генераторы картинок слушаются точнее.

## Как пользоваться

1. **Один запрос — одна картинка.** Скопировать **блок стиля** (ниже) и сразу за ним строку элемента.
2. **Начать с эталона.** Сначала сделать 1.1 «Костёр» и 1.2 «Стол учёного», перегенерировать, пока не
   понравится. Дальше **прикладывать эти две картинки к каждому запросу** и дописывать в конце:
   `Match the style, camera angle and lighting of the attached images exactly.`
3. **Фон — пурпурный (#FF00FF).** Прозрачный фон Gemini рисует плохо, а пурпур я сам вырежу. Если в
   картинке фон вышел не ровный или объект сам стал пурпурным — перегенерировать.
4. **Проверено на первых картинках:** пурпур любого оттенка вырезается чисто. Если Gemini всё равно
   рисует здание углом к зрителю (ромбом), дописать: `The front wall is a straight horizontal line.`
5. **Размер и тени не важны:** подгоню скриптом. Важно, чтобы объект был целиком, не обрезан, и ракурс
   был как у эталона.
6. **Складывать** в папку `art/incoming/` в репозитории, имя файла — из скобок у элемента (например,
   `sd-campfire.png`). Несколько вариантов: `sd-campfire-2.png`.
7. **Звери и корабли** — отдельный путь, см. раздел «3D».

## Блоки стиля

**Для зданий и объектов на карте (A):**
```
Game asset for a top-down factory-building game in the style of Factorio. Front-facing orthographic top-down view, NOT isometric: the building stands square to the image, its front edge is perfectly horizontal and faces the viewer, the camera looks down from the south at about 45 degrees, so we see the top and the front (south) side, never a corner pointing at the viewer. No perspective distortion. Light comes from the top-left. Realistic painterly rendering like Factorio, no black ink outlines, no cartoon style, fine detail, muted natural colors (stone, clay, wood, leather, charcoal). Primitive stone-age craftsmanship. One single object, centered, fully visible, nothing cropped. Do not draw any ground, grass, soil or cast shadow under it. Plain solid flat magenta background, exact color #FF00FF, uniform, no gradient. No text, no frame, no border, no watermark. Do not use magenta or pink colors on the object itself.
```

**Для иконок предметов (B):**
```
Inventory icon for a Factorio-style game, realistic painterly style like Factorio icons, no black ink outlines, no cartoon style. One single item, centered, filling about 85% of a square 1:1 image, viewed slightly from above, strong clear silhouette that stays readable when shrunk to 32 pixels. Realistic, slightly painterly rendering, muted natural colors, soft light from the top-left. Plain solid flat magenta background, exact color #FF00FF, uniform, no gradient, no cast shadow. No text, no frame, no border, no watermark. Do not use magenta or pink colors on the item itself.
```

**Для россыпей ресурса на земле (C):**
```
Sprite sheet for a Factorio-style game: a 4 by 4 grid of square cells, each cell shows a small cluster of loose pieces of the same material lying flat, seen from above at a 3/4 angle, light from the top-left. Top-left cell: a few tiny scattered pieces; each next cell has more and bigger pieces; bottom-right cell: a dense heap filling the cell. Every cell is a different random arrangement. No ground, no grass, no soil between pieces. Plain solid flat magenta background, exact color #FF00FF. No grid lines, no text.
```

---

## Волна 1. Старт

### Эталоны — делать первыми
- **1.1 Костёр** (`sd-campfire`), блок **A**, 1 клетка:
  `A small campfire: a ring of rough grey stones around burning logs with bright flames and embers, a few spare sticks leaning nearby. Square 1:1 image.`
- **1.2 Стол учёного** (`sd-scholar-desk`), блок **A**, 3×3 клетки:
  `A primitive scholar's work desk made of rough-hewn wooden planks on a stone base: stacks of clay tablets with cuneiform marks, scrolls, a small clay oil lamp with a flame, a stool. The footprint is square. Square 1:1 image.`

### Мир вокруг лагеря
- **1.3 Волчье логово** (`sd-wolf-lair`), блок **A**, 5×5:
  `A wolf den: a dark burrow entrance dug under the roots of a fallen tree and large mossy rocks, scattered animal bones and tufts of grey fur around, trampled earth mound. Square 1:1 image.`
- **1.4 Кабанья лёжка** (`sd-boar-lair`), блок **A**, 5×5:
  `A wild boar wallow: a shallow pit of churned mud, dug-up roots, flattened dry grass bedding, broken branches around the edge. Square 1:1 image.`
- **1.5 Записка** (`sd-note`), блок **A**, 1 клетка:
  `A small weathered stone slab with carved notes lying on the ground next to a rolled leather scroll tied with twine. Square 1:1 image.`
- **1.6 Разрушенная стена** (`sd-ruin-wall`), блок **A**, 1 клетка:
  `A broken chunk of an old concrete wall from a lost modern civilization, overgrown with moss and vines, exposed rusty rebar. Square 1:1 image.`
- **1.7 Глина** (`sd-clay-ore`), блок **C**:
  `Material: lumps of wet orange-red clay.`
- **1.8 Ракушки** (`sd-shells-ore`), блок **C**:
  `Material: white and cream seashells, clams and snail shells.`
- **1.9 Селитра** (`sd-saltpeter-ore`), блок **C**:
  `Material: grey stones covered with a white crystalline salt crust.`

### Иконки старта (блок B)
- **1.10** `sd-fiber`: `A loose bundle of dry pale-green plant fibers tied in the middle.`
- **1.11** `sd-rope`: `A coiled rope of twisted brown plant fiber.`
- **1.12** `sd-charcoal`: `Three pieces of black charcoal with visible wood grain.`
- **1.13** `sd-brick`: `Two stacked fired clay bricks, reddish-orange.`
- **1.14** `sd-clay-tablet`: `A flat rectangular clay tablet with rows of cuneiform wedge marks.`
- **1.15** `sd-bow`: `A simple wooden hunting bow with a taut string, diagonal.`
- **1.16** `sd-stone-arrows`: `Three wooden arrows with knapped grey flint tips and feather fletching, diagonal.`

## Волна 2. Эпоха 1

### Здания (блок A)
- **2.1 Печь для обжига** (`sd-kiln`), 2×2:
  `A dome-shaped clay pottery kiln with a glowing arched fire opening at the front and a small chimney hole on top, built of clay and bricks. Square 1:1 image.`
- **2.2 Верстак** (`sd-workbench`), 2×2:
  `A sturdy wooden workbench with a stone hammer, a flint knife, coils of rope and wooden pegs on it. Square 1:1 image.`
- **2.3 Копатель** (`sd-digger`), 2×2:
  `A primitive wooden digging machine: a timber frame with a heavy stone ram on a rope pulley, a pile of dug soil beside it. Square 1:1 image.`
- **2.4 Жаровня** (`sd-brazier`), 1 клетка:
  `A stone fire bowl on three stone legs, full of glowing red coals and small flames. Square 1:1 image.`
- **2.5 Огород** (`sd-garden`), 3×3:
  `A small square vegetable garden: raised soil beds with berry bushes bearing red fruit, surrounded by a low woven wattle fence. Square 1:1 image.`
- **2.6 Бродильный чан** (`sd-fermentation-vat`), 2×2:
  `A large wooden fermentation vat made of staves and rope hoops, with a wooden lid and a ladle. Square 1:1 image.`
- **2.7 Перегонный куб** (`sd-alembic`), 3×3:
  `A primitive distillation still: a copper pot on a brick furnace with a glowing fire opening, a copper pipe coiling into a wooden cooling barrel, clay jugs collecting the output. Square 1:1 image.`
- **2.8 Камера пробуждения** (`sd-revival-chamber`), 5×5:
  `A large ancient revival chamber: a massive stone and brick vault with a sealed glass-and-stone tank in the middle glowing with soft green liquid light, copper pipes and clay jugs around it, carved stone details. It is the most important building in the game. Square 1:1 image.`
- **2.9 Частокол** (`sd-palisade`), 1 клетка:
  `One segment of a palisade wall: sharpened vertical wooden logs lashed together with rope, seen from the south. Square 1:1 image.`

### Иконки (блок B)
- **2.10** `sd-jug`: `An empty round clay jug with a narrow neck and a small handle.`
- **2.11** `sd-bone-arrows`: `Three wooden arrows with carved white bone tips, diagonal.`
- **2.12** `sd-meat`: `A raw red chunk of meat on a bone.`
- **2.13** `sd-cooked-meat`: `A roasted brown chunk of meat on a bone.`
- **2.14** `sd-hide`: `A rough brown animal hide with fur.`
- **2.15** `sd-bones`: `A few white animal bones.`
- **2.16** `sd-quicklime`: `A small heap of white lime powder.`
- **2.17** `sd-mortar`: `A lump of grey mortar with a wooden trowel stuck in it.`
- **2.18** `sd-fruit`: `A small bunch of red wild berries with leaves.`
- **2.19** `sd-mash-jug`: `A clay jug with brown fermenting bubbly mash overflowing slightly.`
- **2.20** `sd-spirit-jug`: `A clay jug with a clear liquid visible at the top, sealed with a cork.`
- **2.21** `sd-acid-jug`: `A clay jug with yellow liquid visible at the top, sealed with wax.`
- **2.22** `sd-leather`: `A folded piece of tanned brown leather.`
- **2.23** `sd-leather-jacket`: `A simple stitched brown leather jacket.`
- **2.24** `sd-fur-coat`: `A thick fur coat with a white fur collar.`
- **2.25** `sd-light-cloak`: `A light pale linen hooded cloak.`
- **2.26** `sd-revival-charge-1`: `A sealed glass flask with glowing green liquid, one small ring mark on it.` (для II–V: `two/three/four/five ring marks, stronger glow`)

## Волна 3. Эпоха 2

### Здания (блок A)
- **3.1 Жернова** (`sd-millstone`), 2×2:
  `Two large round millstones stacked on a stone base, a wooden turning handle, flour dust around. Square 1:1 image.`
- **3.2 Кайловый копатель** (`sd-pick-digger`), 2×2:
  `A sturdy digging machine of timber and bricks bound with mortar, with iron-tipped picks on a lever arm, a pile of broken hard rock. Square 1:1 image.`
- **3.3 Горн** (`sd-bloomery`), 2×2:
  `A tall clay bloomery furnace shaped like a cone, leather bellows at its base, glowing opening, ingots cooling beside it. Square 1:1 image.`
- **3.4 Стекловарня** (`sd-glassworks`), 2×2:
  `A brick glass furnace with a glowing round opening, a long glassblowing pipe leaning on it, a few glass bottles cooling on a shelf. Square 1:1 image.`
- **3.5 Самострел** (`sd-crossbow`), 2×2 — только эталон вида, для поворотов нужен 3D:
  `A large mounted crossbow ballista on a rotating wooden turntable base, bronze fittings, loaded with a bolt, pointing up-left. Square 1:1 image.`
- **3.6 Бронзовый бур** (`sd-bronze-drill`), 2×2:
  `A mining drill of timber and bronze: a bronze drill bit on a wooden frame with gears and a crank. Square 1:1 image.`

### Россыпи (блок C)
- **3.7** `sd-tin-ore`: `Material: light silvery-grey shiny rocks with metallic glints.`

### Иконки (блок B)
- **3.8** `sd-sand`: `A small heap of golden sand.`
- **3.9** `sd-ash`: `A small heap of grey wood ash.`
- **3.10** `sd-potash`: `A small heap of white crystal granules.`
- **3.11** `sd-tin`: `A light silvery-grey metal ingot.`
- **3.12** `sd-bronze`: `A warm golden-brown bronze ingot.`
- **3.13** `sd-glass`: `A small stack of slightly green glass panes.`
- **3.14** `sd-bottle`: `An empty clear glass bottle.`
- **3.15** `sd-glass-flask`: `A round-bottom glass laboratory flask with a blue liquid.`
- **3.16** `sd-arrows`: `Three wooden arrows with bronze tips and feathers, diagonal.`
- **3.17** `sd-pitch`: `A lump of glossy black pitch on a wooden stick.`
- **3.18** `sd-bone-meal`: `A small cloth sack of white bone powder.`
- **3.19** `sd-rectified-bottle`: `A glass bottle with a crystal-clear liquid, cork stopper.`
- **3.20** `sd-conc-acid-bottle`: `A glass bottle with an orange liquid, wax seal.`

## Дальше

Волны 4–8 (эпоха 3, одомашнивание, море, климат, Луна) — когда первые три будут выглядеть хорошо и
стиль устоится. Запросы допишу по тому же образцу.

---

## 3D: звери и корабли

Шаг 1 — референс в Gemini (белый фон: генераторы 3D с ним работают лучше пурпурного):
```
Full-body reference image of a single [SUBJECT], standing in a neutral pose, seen from a 3/4 front-side angle, entire body visible, realistic proportions and texture, soft even lighting, plain pure white background, no shadow, no text.
```
- `sd-wolf`: `grey wild wolf, lean and hungry`
- `sd-boar`: `brown wild boar with tusks and bristly fur`
- `sd-bear`: `large brown bear`
- `sd-tug`: `small 19th-century steam tugboat with one tall funnel and a wooden deck, seen as a scale model`
- `sd-barge`: `flat wooden cargo barge loaded with crates and sacks, seen as a scale model`
- `sd-fluid-barge`: `flat barge carrying two large wooden-and-iron tanks, seen as a scale model`
- `sd-screw-steamer`: `19th-century screw steamship with two funnels, seen as a scale model`

Шаг 2 — эту картинку загрузить в генератор «картинка → 3D» (Meshy, Tripo или Hunyuan3D) и скачать
**GLB с текстурой**. Для зверей, если генератор умеет, включить авто-риггинг и анимации **бег (run)** и
**атака (attack/bite)**. Если не умеет — модель без анимации тоже годится, движение сделаю сам попроще.

Шаг 3 — GLB в `art/incoming/`. Направления, кадры, тени и нарезку сделаю сам.
