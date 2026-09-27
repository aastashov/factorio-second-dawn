# Страница мода на mods.factorio.com

Что вставлять на портал при загрузке. Длинное описание — блок ниже целиком (портал понимает Markdown).

- **Категория:** Overhaul
- **Теги:** Combat, Enemies, Environment, Mining, Manufacturing, Logistics, Transportation, Map generation
  (на портале выбирается из списка — брать те, что там есть)
- **Лицензия:** на выбор автора (по умолчанию на портале — «All rights reserved»; для открытого мода
  подойдёт MIT)
- **Картинки галереи:** `thumbnail.png`, `docs/img/shots/camp.jpg`, `docs/img/shots/workshop.jpg`,
  `docs/img/shots/tech-tree.png`, `docs/img/shots/recipes.png`, `docs/img/shots/camp-night.jpg`,
  `docs/img/shots/wolves.jpg`, `docs/img/map-777.png`. Скриншоты снимает `tools/screenshots.sh` (сцены —
  `tests/scenarios/shots.lua`); дерево технологий и рецепты игра в скриншот не отдаёт — их рисует
  `tools/portal_sheets.py <data-raw-dump.json>` по данным мода. Заменить галерею:
  `tools/publish.sh --gallery <картинки…>`

---

## Длинное описание (English + Русский)

```markdown
# Second Dawn — BETA

**Rebuild civilisation from clay and fire to a rocket to the Moon — before the next petrification wave.**

Humanity is stone. Your factory is the only way back: automate a revival charge before each wave, cross an
ocean for scarce resources, and reach the Moon to stop the source.

Inspired by *Dr. Stone*. Made with AI, directed and playtested by a human.

### Why play

- **A full five-epoch overhaul:** clay → bronze → steam → chemistry → rocket.
- **Waves are the clock:** one shared revival chamber keeps the team alive while the factory runs on.
- **A world worth crossing:** animals raid at night; the cold north holds tungsten, the hot south oil and
  rubber. Dress for the climate and build ships to reach both.
- **Factory-first logistics:** waterways, tugs, barges, piers and buoys work like a rail network.
- **A real ending:** launch suited players to the Moon with limited oxygen and dismantle the emitter.

Multiplayer supported: shared research, notes and revival chamber. Factorio 2.0.77+, base game only; **not
compatible with Space Age or Space Exploration.** Start a new map. This is a public beta; balance and saves
may change between releases.

---

# Second Dawn — БЕТА

**Подними цивилизацию от глины и огня до ракеты на Луну — прежде чем придёт новая волна окаменения.**

Человечество стало камнем. Завод — единственный путь назад: автоматизируй заряд пробуждения до каждой
волны, пересекай океан за редкими ресурсами и доберись до Луны, чтобы остановить источник.

По мотивам *Dr. Stone*. Создано с ИИ, под руководством и с игровым тестированием человека.

### Зачем играть

- **Полная переделка на пять эпох:** глина → бронза → пар → химия → ракета.
- **Волны задают темп:** одна общая камера пробуждения держит команду в строю, пока завод работает.
- **Мир, который надо исследовать:** ночные набеги зверей, холодный север с вольфрамом, жаркий юг с нефтью
  и каучуком. Одежда, корабли и экспедиции нужны по делу.
- **Заводская логистика на воде:** фарватеры, буксиры, баржи, причалы и буи работают как железная дорога.
- **Настоящий финал:** лети на Луну в скафандре с ограниченным воздухом и разбери излучатель.

Мультиплеер поддерживается: общие исследования, записки и камера пробуждения. Нужна Factorio 2.0.77+,
только базовая игра; **Space Age и Space Exploration несовместимы.** Нужна новая карта. Это публичная
бета: баланс и сохранения могут меняться между версиями.
```
