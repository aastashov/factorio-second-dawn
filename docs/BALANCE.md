# Баланс в числах

Пишется `tools/balance.py --markdown` при каждом `tests/run.sh` — руками не править. Модель сверяется с прототипами тестом `tests/check_balance_model.py`. Побочные продукты (газ глубокой переработки и т. п.) считаются отходом, машины — дробными.

## Исследования по эпохам

| Эпоха | Наука | Лаб-секунд | На 1 столе | На 3 |
|---|---|---|---|---|
| 1 | 365 табличек | 4800 | 80 мин | 27 мин |
| 2 | 1200 табличек, 700 колб | 26300 | 438 мин | 146 мин |
| 3 | 3295 табличек, 3295 колб, 2050 механизмов | 104600 | 1743 мин | 581 мин |
| 4 | 3600 табличек, 3600 колб, 3600 механизмов, 2150 реактива, 950 морских карт | 124500 | 2075 мин | 692 мин |
| 5 | 2500 табличек, 2500 колб, 2500 механизмов, 2500 реактива, 2500 морских карт, 1850 плат | 99000 | 1650 мин | 550 мин |

## Эпоха 1: табличка 6/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| clay-tablet | 3.00 крафт/мин | workbench | 0.80 | 1 |
| clay | 3.00/мин | сырьё | digger 0.10, pick-digger 0.10, bronze-drill 0.07, electric-drill 0.10 |  |
| charcoal | 3.00 крафт/мин | kiln | 0.16 | 1 |
| wood | 9.00/мин | сырьё |  |  |
| энергия машин | charcoal 0.2/мин, wood 0.5/мин |  |  |  |

## Эпоха 1: заряд I за 30 мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| charge-1 | 0.03 крафт/мин | chamber | 0.33 | 1 |
| nitric-acid | 0.33 крафт/мин | alembic | 0.06 | 1 |
| saltpeter | 1.33/мин | сырьё | digger 0.07, pick-digger 0.07, bronze-drill 0.04, electric-drill 0.07 |  |
| charcoal | 0.33 крафт/мин | kiln | 0.02 | 1 |
| wood | 1.00/мин | сырьё |  |  |
| spirit | 0.33 крафт/мин | alembic | 0.11 | 1 |
| fruit | 2.67/мин | сырьё |  |  |
| энергия машин | charcoal 1.3/мин, wood 0.3/мин |  |  |  |

## Эпоха 2: колба 4/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| glass-flask | 4.00 крафт/мин | workbench | 0.80 | 1 |
| glass | 2.00 крафт/мин | glassworks | 0.21 | 1 |
| sand | 4.00 крафт/мин | millstone | 0.27 | 1 |
| stone | 4.00/мин | сырьё | digger 0.13, pick-digger 0.13, bronze-drill 0.09, electric-drill 0.13 |  |
| potash | 2.00 крафт/мин | kiln | 0.21 | 1 |
| ash | 4.00 крафт/мин | kiln | 0.21 | 1 |
| wood | 16.00/мин | сырьё |  |  |
| quicklime | 2.00 крафт/мин | kiln | 0.11 | 1 |
| shells | 4.00/мин | сырьё | digger 0.13, pick-digger 0.13, bronze-drill 0.09, electric-drill 0.13 |  |
| bronze | 1.00 крафт/мин | bloomery | 0.11 | 1 |
| copper | 3.00 крафт/мин | bloomery | 0.16 | 1 |
| copper-ore | 3.00/мин | сырьё | pick-digger 0.10, bronze-drill 0.07, electric-drill 0.10 |  |
| tin | 1.00 крафт/мин | bloomery | 0.05 | 1 |
| tin-ore | 1.00/мин | сырьё | pick-digger 0.03, bronze-drill 0.02, electric-drill 0.03 |  |
| энергия машин | charcoal 1.8/мин, wood 1.8/мин |  |  |  |

## Эпоха 2: бронза 6/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| bronze | 1.50 крафт/мин | bloomery | 0.16 | 1 |
| copper | 4.50 крафт/мин | bloomery | 0.24 | 1 |
| copper-ore | 4.50/мин | сырьё | pick-digger 0.15, bronze-drill 0.10, electric-drill 0.15 |  |
| tin | 1.50 крафт/мин | bloomery | 0.08 | 1 |
| tin-ore | 1.50/мин | сырьё | pick-digger 0.05, bronze-drill 0.03, electric-drill 0.05 |  |
| энергия машин | charcoal 0.9/мин, wood 0.9/мин |  |  |  |

## Эпоха 2: заряд II за 45 мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| charge-2 | 0.02 крафт/мин | chamber | 0.33 | 1 |
| rectified | 0.22 крафт/мин | alembic | 0.04 | 1 |
| spirit | 0.44 крафт/мин | alembic | 0.15 | 1 |
| fruit | 3.56/мин | сырьё |  |  |
| wood | 1.33/мин | сырьё |  |  |
| conc-acid | 0.22 крафт/мин | alembic | 0.04 | 1 |
| nitric-acid | 0.44 крафт/мин | alembic | 0.07 | 1 |
| saltpeter | 1.78/мин | сырьё | digger 0.09, pick-digger 0.09, bronze-drill 0.06, electric-drill 0.09 |  |
| charcoal | 0.44 крафт/мин | kiln | 0.02 | 1 |
| энергия машин | charcoal 1.5/мин, wood 0.4/мин |  |  |  |

## Эпоха 3: механизм 6/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| mechanism | 6.00 крафт/мин | workbench | 1.60 | 2 |
| iron-gear | 12.00 крафт/мин | workbench | 0.20 | 1 |
| iron-plate | 54.00 крафт/мин | blast-furnace | 1.44 | 2 |
| iron-ore | 54.00/мин | сырьё | digger 1.80, pick-digger 1.80, bronze-drill 1.20, electric-drill 1.80 |  |
| copper-cable | 6.00 крафт/мин | workbench | 0.10 | 1 |
| copper | 6.00 крафт/мин | bloomery | 0.32 | 1 |
| copper-ore | 6.00/мин | сырьё | pick-digger 0.20, bronze-drill 0.13, electric-drill 0.20 |  |
| steel | 6.00 крафт/мин | blast-furnace | 0.80 | 1 |
| энергия машин | charcoal 3.6/мин, wood 9.0/мин |  |  |  |

## Эпоха 3: сталь 3/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| steel | 3.00 крафт/мин | blast-furnace | 0.40 | 1 |
| iron-plate | 15.00 крафт/мин | blast-furnace | 0.40 | 1 |
| iron-ore | 15.00/мин | сырьё | digger 0.50, pick-digger 0.50, bronze-drill 0.33, electric-drill 0.50 |  |
| энергия машин | charcoal 1.1/мин, wood 2.2/мин |  |  |  |

## Эпоха 3: заряд III за час

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| charge-3 | 0.02 крафт/мин | electric-chamber | 0.33 | 1 |
| rectified | 0.25 крафт/мин | alembic | 0.04 | 1 |
| spirit | 0.50 крафт/мин | alembic | 0.17 | 1 |
| fruit | 4.00/мин | сырьё |  |  |
| glass | 0.04 крафт/мин | glassworks | 0.00 | 1 |
| sand | 0.08 крафт/мин | millstone | 0.01 | 1 |
| stone | 0.08/мин | сырьё | digger 0.00, pick-digger 0.00, bronze-drill 0.00, electric-drill 0.00 |  |
| potash | 0.04 крафт/мин | kiln | 0.00 | 1 |
| ash | 0.08 крафт/мин | kiln | 0.00 | 1 |
| wood | 1.83/мин | сырьё |  |  |
| quicklime | 0.04 крафт/мин | kiln | 0.00 | 1 |
| shells | 0.08/мин | сырьё | digger 0.00, pick-digger 0.00, bronze-drill 0.00, electric-drill 0.00 |  |
| conc-acid | 0.25 крафт/мин | alembic | 0.05 | 1 |
| nitric-acid | 0.50 крафт/мин | alembic | 0.08 | 1 |
| saltpeter | 2.00/мин | сырьё | digger 0.10, pick-digger 0.10, bronze-drill 0.07, electric-drill 0.10 |  |
| charcoal | 0.50 крафт/мин | kiln | 0.03 | 1 |
| electrode | 0.08 крафт/мин | workbench | 0.01 | 1 |
| copper | 0.17 крафт/мин | bloomery | 0.01 | 1 |
| copper-ore | 0.17/мин | сырьё | pick-digger 0.01, bronze-drill 0.00, electric-drill 0.01 |  |
| энергия машин | charcoal 0.6/мин, электричество 0.67 МВт, wood 0.5/мин |  |  |  |

## Эпоха 4: реактив 4/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| reactive | 2.00 крафт/мин | chemical-plant | 0.33 | 1 |
| bottle | 2.00 крафт/мин | glassworks | 0.07 | 1 |
| glass | 1.00 крафт/мин | glassworks | 0.11 | 1 |
| sand | 2.00 крафт/мин | millstone | 0.13 | 1 |
| stone | 2.00/мин | сырьё | digger 0.07, pick-digger 0.07, bronze-drill 0.04, electric-drill 0.07 |  |
| potash | 1.00 крафт/мин | kiln | 0.11 | 1 |
| ash | 2.00 крафт/мин | kiln | 0.11 | 1 |
| wood | 8.00/мин | сырьё |  |  |
| quicklime | 1.00 крафт/мин | kiln | 0.05 | 1 |
| shells | 2.00/мин | сырьё | digger 0.07, pick-digger 0.07, bronze-drill 0.04, electric-drill 0.07 |  |
| sulfuric-acid | 0.80 крафт/мин | chemical-plant | 0.01 | 1 |
| sulfur | 5.00/мин | сырьё |  |  |
| iron-plate | 0.80 крафт/мин | blast-furnace | 0.02 | 1 |
| iron-ore | 0.80/мин | сырьё | digger 0.03, pick-digger 0.03, bronze-drill 0.02, electric-drill 0.03 |  |
| water | 146.67/мин | сырьё |  |  |
| rubber | 1.00 крафт/мин | chemical-plant | 0.08 | 1 |
| latex | 0.67 крафт/мин | plantation | 0.67 | 1 |
| энергия машин | charcoal 0.8/мин, электричество 0.09 МВт, wood 0.7/мин |  |  |  |

## Эпоха 4: морская карта 2/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| navigation | 2.00 крафт/мин | workbench | 0.67 | 1 |
| tungsten | 2.00 крафт/мин | electric-furnace | 0.11 | 1 |
| tungsten-ore | 4.00/мин | сырьё |  |  |
| glass | 2.00 крафт/мин | glassworks | 0.21 | 1 |
| sand | 4.00 крафт/мин | millstone | 0.27 | 1 |
| stone | 4.00/мин | сырьё | digger 0.13, pick-digger 0.13, bronze-drill 0.09, electric-drill 0.13 |  |
| potash | 2.00 крафт/мин | kiln | 0.21 | 1 |
| ash | 4.00 крафт/мин | kiln | 0.21 | 1 |
| wood | 16.00/мин | сырьё |  |  |
| quicklime | 2.00 крафт/мин | kiln | 0.11 | 1 |
| shells | 4.00/мин | сырьё | digger 0.13, pick-digger 0.13, bronze-drill 0.09, electric-drill 0.13 |  |
| mechanism | 2.00 крафт/мин | workbench | 0.53 | 1 |
| iron-gear | 4.00 крафт/мин | workbench | 0.07 | 1 |
| iron-plate | 18.00 крафт/мин | blast-furnace | 0.48 | 1 |
| iron-ore | 18.00/мин | сырьё | digger 0.60, pick-digger 0.60, bronze-drill 0.40, electric-drill 0.60 |  |
| copper-cable | 2.00 крафт/мин | workbench | 0.03 | 1 |
| copper | 2.00 крафт/мин | bloomery | 0.11 | 1 |
| copper-ore | 2.00/мин | сырьё | pick-digger 0.07, bronze-drill 0.04, electric-drill 0.07 |  |
| steel | 2.00 крафт/мин | blast-furnace | 0.27 | 1 |
| энергия машин | charcoal 2.4/мин, электричество 0.02 МВт, wood 4.2/мин |  |  |  |

## Эпоха 4: заряд IV за час

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| charge-4 | 0.02 крафт/мин | electric-chamber | 0.42 | 1 |
| rectified | 0.33 крафт/мин | alembic | 0.06 | 1 |
| spirit | 1.00 крафт/мин | alembic | 0.33 | 1 |
| fruit | 8.00/мин | сырьё |  |  |
| jug | 0.33 крафт/мин | kiln | 0.02 | 1 |
| clay | 1.00/мин | сырьё | digger 0.03, pick-digger 0.03, bronze-drill 0.02, electric-drill 0.03 |  |
| glass | 0.04 крафт/мин | glassworks | 0.00 | 1 |
| sand | 0.08 крафт/мин | millstone | 0.01 | 1 |
| stone | 0.08/мин | сырьё | digger 0.00, pick-digger 0.00, bronze-drill 0.00, electric-drill 0.00 |  |
| potash | 0.04 крафт/мин | kiln | 0.00 | 1 |
| ash | 0.08 крафт/мин | kiln | 0.00 | 1 |
| wood | 2.33/мин | сырьё |  |  |
| quicklime | 0.04 крафт/мин | kiln | 0.00 | 1 |
| shells | 0.08/мин | сырьё | digger 0.00, pick-digger 0.00, bronze-drill 0.00, electric-drill 0.00 |  |
| conc-acid | 0.33 крафт/мин | alembic | 0.07 | 1 |
| nitric-acid | 0.67 крафт/мин | alembic | 0.11 | 1 |
| saltpeter | 2.67/мин | сырьё | digger 0.13, pick-digger 0.13, bronze-drill 0.09, electric-drill 0.13 |  |
| charcoal | 0.67 крафт/мин | kiln | 0.04 | 1 |
| ether | 0.17 крафт/мин | chemical-plant | 0.01 | 1 |
| sulfuric-acid | 0.03 крафт/мин | chemical-plant | 0.00 | 1 |
| sulfur | 0.17/мин | сырьё |  |  |
| iron-plate | 0.03 крафт/мин | blast-furnace | 0.00 | 1 |
| iron-ore | 0.03/мин | сырьё | digger 0.00, pick-digger 0.00, bronze-drill 0.00, electric-drill 0.00 |  |
| water | 3.33/мин | сырьё |  |  |
| tungsten-electrode | 0.08 крафт/мин | workbench | 0.01 | 1 |
| tungsten | 0.08 крафт/мин | electric-furnace | 0.00 | 1 |
| tungsten-ore | 0.17/мин | сырьё |  |  |
| энергия машин | charcoal 1.0/мин, электричество 0.84 МВт, wood 0.8/мин |  |  |  |

## Эпоха 5: приборная плата 3/мин

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| board | 1.50 крафт/мин | workbench | 0.50 | 1 |
| circuit | 4.50 крафт/мин | workbench | 0.07 | 1 |
| plastic | 3.75 крафт/мин | chemical-plant | 0.06 | 1 |
| basic-oil | 1.67 крафт/мин | refinery | 0.14 | 1 |
| crude-oil | 166.67/мин | сырьё |  |  |
| coal | 3.75/мин | сырьё | pick-digger 0.12, bronze-drill 0.08, electric-drill 0.12 |  |
| copper-cable | 6.75 крафт/мин | workbench | 0.11 | 1 |
| copper | 6.75 крафт/мин | bloomery | 0.36 | 1 |
| copper-ore | 6.75/мин | сырьё | pick-digger 0.23, bronze-drill 0.15, electric-drill 0.23 |  |
| iron-plate | 4.50 крафт/мин | blast-furnace | 0.12 | 1 |
| iron-ore | 4.50/мин | сырьё | digger 0.15, pick-digger 0.15, bronze-drill 0.10, electric-drill 0.15 |  |
| tungsten | 1.50 крафт/мин | electric-furnace | 0.08 | 1 |
| tungsten-ore | 3.00/мин | сырьё |  |  |
| энергия машин | charcoal 0.8/мин, электричество 0.09 МВт, wood 2.2/мин |  |  |  |

## Эпоха 5: часть ракеты 1/мин (30 на ракету)

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| rocket-part | 1.00 крафт/мин | rocket-silo | 0.05 | 1 |
| low-density | 2.00 крафт/мин | workbench | 0.67 | 1 |
| steel | 4.00 крафт/мин | blast-furnace | 0.53 | 1 |
| iron-plate | 30.00 крафт/мин | blast-furnace | 0.80 | 1 |
| iron-ore | 30.00/мин | сырьё | digger 1.00, pick-digger 1.00, bronze-drill 0.67, electric-drill 1.00 |  |
| copper | 25.00 крафт/мин | bloomery | 1.33 | 2 |
| copper-ore | 25.00/мин | сырьё | pick-digger 0.83, bronze-drill 0.56, electric-drill 0.83 |  |
| plastic | 8.00 крафт/мин | chemical-plant | 0.13 | 1 |
| basic-oil | 3.56 крафт/мин | refinery | 0.30 | 1 |
| crude-oil | 444.44/мин | сырьё |  |  |
| coal | 8.00/мин | сырьё | pick-digger 0.27, bronze-drill 0.18, electric-drill 0.27 |  |
| rocket-fuel | 2.00 крафт/мин | chemical-plant | 0.33 | 1 |
| oil-processing | 0.89 крафт/мин | refinery | 0.07 | 1 |
| water | 44.44/мин | сырьё |  |  |
| fuel-oil | 2.00 крафт/мин | chemical-plant | 0.07 | 1 |
| control-unit | 2.00 крафт/мин | workbench | 0.67 | 1 |
| circuit | 10.00 крафт/мин | workbench | 0.17 | 1 |
| copper-cable | 15.00 крафт/мин | workbench | 0.25 | 1 |
| tungsten | 2.00 крафт/мин | electric-furnace | 0.11 | 1 |
| tungsten-ore | 4.00/мин | сырьё |  |  |
| энергия машин | charcoal 4.2/мин, электричество 0.30 МВт, wood 9.4/мин |  |  |  |

## Эпоха 5: заряд V за час

| Что | Поток | Машина | Машин | Целых |
|---|---|---|---|---|
| charge-5 | 0.02 крафт/мин | electric-chamber | 0.50 | 1 |
| rectified | 0.42 крафт/мин | alembic | 0.07 | 1 |
| spirit | 1.33 крафт/мин | alembic | 0.44 | 1 |
| fruit | 10.67/мин | сырьё |  |  |
| jug | 0.50 крафт/мин | kiln | 0.03 | 1 |
| clay | 1.50/мин | сырьё | digger 0.05, pick-digger 0.05, bronze-drill 0.03, electric-drill 0.05 |  |
| wood | 2.50/мин | сырьё |  |  |
| conc-acid | 0.42 крафт/мин | alembic | 0.08 | 1 |
| nitric-acid | 0.83 крафт/мин | alembic | 0.14 | 1 |
| saltpeter | 3.33/мин | сырьё | digger 0.17, pick-digger 0.17, bronze-drill 0.11, electric-drill 0.17 |  |
| charcoal | 0.83 крафт/мин | kiln | 0.04 | 1 |
| ether | 0.25 крафт/мин | chemical-plant | 0.02 | 1 |
| sulfuric-acid | 0.05 крафт/мин | chemical-plant | 0.00 | 1 |
| sulfur | 0.25/мин | сырьё |  |  |
| iron-plate | 0.47 крафт/мин | blast-furnace | 0.01 | 1 |
| iron-ore | 0.47/мин | сырьё | digger 0.02, pick-digger 0.02, bronze-drill 0.01, electric-drill 0.02 |  |
| water | 5.00/мин | сырьё |  |  |
| control-unit | 0.08 крафт/мин | workbench | 0.03 | 1 |
| circuit | 0.42 крафт/мин | workbench | 0.01 | 1 |
| plastic | 0.25 крафт/мин | chemical-plant | 0.00 | 1 |
| basic-oil | 0.11 крафт/мин | refinery | 0.01 | 1 |
| crude-oil | 11.11/мин | сырьё |  |  |
| coal | 0.25/мин | сырьё | pick-digger 0.01, bronze-drill 0.01, electric-drill 0.01 |  |
| copper-cable | 0.62 крафт/мин | workbench | 0.01 | 1 |
| copper | 0.62 крафт/мин | bloomery | 0.03 | 1 |
| copper-ore | 0.62/мин | сырьё | pick-digger 0.02, bronze-drill 0.01, electric-drill 0.02 |  |
| tungsten | 0.08 крафт/мин | electric-furnace | 0.00 | 1 |
| tungsten-ore | 0.17/мин | сырьё |  |  |
| энергия машин | charcoal 1.3/мин, электричество 1.01 МВт, wood 1.2/мин |  |  |  |

## Дерево технологий

Тупиков нет.


## Эпоха 1: технологии

| Технология | Стоимость | Наука | Требует |
|---|---|---|---|
| pottery | 10 × 10 с | tablet | — |
| workbench | 15 × 10 с | tablet | pottery |
| levers | 20 × 10 с | tablet | pottery |
| wooden-logistics | 30 × 10 с | tablet | levers |
| quicklime | 15 × 10 с | tablet | pottery |
| fermentation | 25 × 15 с | tablet | pottery |
| distillation | 30 × 15 с | tablet | fermentation, quicklime |
| awakening | 50 × 20 с | tablet | distillation |
| hunting | 15 × 10 с | tablet | — |
| tanning | 25 × 15 с | tablet | quicklime, fermentation |
| brazier | 20 × 10 с | tablet | pottery |
| warm-clothing | 30 × 10 с | tablet | tanning |
| light-clothing | 30 × 10 с | tablet | tanning |
| arrowheads-1 | 50 × 15 с | tablet | hunting |

## Эпоха 1: рецепты

| Рецепт | Где | Время | Вход | Выход | Открывает |
|---|---|---|---|---|---|
| charcoal | kiln | 3.2 с | wood 3 | charcoal 1 | старт |
| fiber | workbench | 1 с | wood 1 | fiber 2 | старт |
| rope | workbench | 1 с | fiber 3 | rope 1 | старт |
| clay-tablet | workbench | 8 с | clay 1, charcoal 1 | tablet 2 | старт |
| brick | kiln | 3.2 с | clay 2 | brick 1 | старт |
| jug | kiln | 4 с | clay 3 | jug 1 | pottery |
| quicklime | kiln | 3.2 с | shells 2 | quicklime 1 | quicklime |
| mortar | workbench | 1 с | quicklime 1, stone 2 | mortar 2 | quicklime |
| grow-fruit | garden | 60 с | fruit 2 | fruit 6 | fermentation |
| spirit | alembic | 20 с | fruit 8, jug 1 | spirit-jug 1 | distillation |
| nitric-acid | alembic | 10 с | jug 1, saltpeter 4, charcoal 1 | acid-jug 1 | distillation |
| charge-1 | chamber | 600 с | acid-jug 10, spirit-jug 10 | charge-1 1, jug 20 | awakening |
| bow | workbench | 3 с | wood 5, rope 2 | bow 1 | старт |
| stone-arrows | workbench | 1 с | wood 1, stone 1 | stone-arrows 5 | старт |
| bone-arrows | workbench | 1 с | wood 1, bones 1 | bone-arrows 5 | hunting |
| palisade | workbench | 1 с | wood 6, rope 1 | palisade 2 | hunting |
| leather | fermentation-vat | 20 с | hide 2, quicklime 1 | leather 2 | tanning |
| leather-jacket | workbench | 5 с | leather 10, rope 5 | leather-jacket 1 | tanning |
| brazier | workbench | 1 с | brick 5, stone 5 | brazier 1 | brazier |
| fur-coat | workbench | 5 с | leather 20, hide 10, rope 5 | fur-coat 1 | warm-clothing |
| light-cloak | workbench | 5 с | fiber 40, leather 5 | light-cloak 1 | light-clothing |

## Эпоха 2: технологии

| Технология | Стоимость | Наука | Требует |
|---|---|---|---|
| mining | 50 × 15 с | tablet | awakening |
| smelting | 60 × 15 с | tablet | mining |
| millstone | 40 × 15 с | tablet | awakening |
| potash | 40 × 15 с | tablet | awakening |
| glass | 75 × 20 с | tablet | millstone, potash |
| bronze | 75 × 20 с | tablet | smelting |
| glass-flask | 100 × 20 с | tablet | glass, bronze |
| bronze-tools | 100 × 25 с | tablet, flask | glass-flask |
| logistics-2 | 75 × 25 с | tablet, flask | glass-flask |
| rectification | 100 × 25 с | tablet, flask | glass-flask |
| second-awakening | 150 × 30 с | tablet, flask | rectification |
| bow | 60 × 20 с | tablet | bronze |
| crossbow | 75 × 25 с | tablet, flask | bow, glass-flask, tanning |
| gunpowder | 100 × 20 с | tablet, flask | millstone, bronze, glass-flask |
| arrowheads-2 | 100 × 20 с | tablet, flask | arrowheads-1, bow, glass-flask |

## Эпоха 2: рецепты

| Рецепт | Где | Время | Вход | Выход | Открывает |
|---|---|---|---|---|---|
| arrows | workbench | 2 с | wood 1, bronze 1, fiber 2 | arrows 10 | bow |
| hand-crossbow | workbench | 5 с | bronze 5, wood 5, rope 3 | hand-crossbow 1 | bow |
| gunpowder | millstone | 4 с | saltpeter 3, charcoal 1 | gunpowder 2 | gunpowder |
| pistol | workbench | 5 с | bronze 5, wood 2 | pistol 1 | gunpowder |
| firearm-magazine | workbench | 1 с | bronze 1, gunpowder 1 | firearm-magazine 1 | gunpowder |
| crossbow | workbench | 5 с | bronze 10, wood 10, rope 5, leather 2 | crossbow 1 | crossbow |
| sand | millstone | 2 с | stone 1 | sand 2 | millstone |
| ash | kiln | 3.2 с | wood 4 | ash 2 | potash |
| potash | kiln | 6.4 с | ash 4 | potash 1 | potash |
| copper | bloomery | 3.2 с | copper-ore 1 | copper 1 | smelting |
| tin | bloomery | 3.2 с | tin-ore 1 | tin 1 | smelting |
| bronze | bloomery | 6.4 с | copper 3, tin 1 | bronze 4 | bronze |
| glass | glassworks | 6.4 с | sand 4, potash 1, quicklime 1 | glass 2 | glass |
| bottle | glassworks | 2 с | glass 1 | bottle 1 | glass |
| glass-flask | workbench | 6 с | glass 1, bronze 1 | flask 1 | glass-flask |
| rectified | alembic | 10 с | spirit-jug 2, bottle 1 | rectified-bottle 1, jug 2 | rectification |
| conc-acid | alembic | 12 с | acid-jug 2, bottle 1 | conc-acid-bottle 1, jug 2 | rectification |
| charge-2 | chamber | 900 с | rectified-bottle 10, conc-acid-bottle 10 | charge-2 1, bottle 20 | second-awakening |

## Эпоха 3: технологии

| Технология | Стоимость | Наука | Требует |
|---|---|---|---|
| firearms | 150 × 30 с | tablet, flask, mechanism | gunpowder, blast-furnace, mechanism |
| steel-bolts | 150 × 30 с | tablet, flask, mechanism | blast-furnace, mechanism, crossbow |
| arrowheads-3 | 150 × 30 с | tablet, flask, mechanism | arrowheads-2, steel-bolts |
| wrought-iron | 75 × 25 с | tablet, flask | bronze-tools |
| ironworking | 75 × 25 с | tablet, flask | wrought-iron |
| fluid-handling | 100 × 25 с | tablet, flask | ironworking |
| steam-power | 100 × 30 с | tablet, flask | fluid-handling |
| electricity | 100 × 30 с | tablet, flask | steam-power |
| blast-furnace | 120 × 30 с | tablet, flask | ironworking |
| electromechanics | 150 × 30 с | tablet, flask | electricity, blast-furnace |
| mechanism | 150 × 30 с | tablet, flask | electromechanics |
| radio | 100 × 30 с | tablet, flask, mechanism | mechanism |
| logistics-3 | 150 × 30 с | tablet, flask, mechanism | mechanism |
| automation-2 | 150 × 30 с | tablet, flask, mechanism | mechanism |
| electric-chamber | 200 × 40 с | tablet, flask, mechanism | mechanism |
| third-awakening | 250 × 45 с | tablet, flask, mechanism | electric-chamber, rectification |
| steam-heating | 100 × 30 с | tablet, flask | steam-power |
| cooling | 100 × 30 с | tablet, flask | fluid-handling, electricity |
| land-reclamation | 100 × 30 с | tablet, flask | fluid-handling |
| deep-landfill | 150 × 30 с | tablet, flask, mechanism | mechanism, land-reclamation |
| pitch | 75 × 20 с | tablet, flask | distillation, glass-flask |
| shipbuilding | 200 × 40 с | tablet, flask, mechanism | mechanism, steam-power, pitch |
| buoys | 100 × 30 с | tablet, flask, mechanism | shipbuilding |
| fluid-barges | 150 × 30 с | tablet, flask, mechanism | shipbuilding, fluid-handling |
| lab-glassware-1 | 150 × 30 с | tablet, flask, mechanism | mechanism |

## Эпоха 3: рецепты

| Рецепт | Где | Время | Вход | Выход | Открывает |
|---|---|---|---|---|---|
| submachine-gun | workbench | 10 с | gear 10, steel 5, wood 5 | submachine-gun 1 | firearms |
| gun-turret | workbench | 8 с | gear 10, steel 10, copper 10 | gun-turret 1 | firearms |
| steel-bolts | workbench | 2 с | steel 1, wood 1 | steel-bolts 10 | steel-bolts |
| repeating-crossbow | workbench | 10 с | crossbow 1, steel 10, gear 10 | repeating-crossbow 1 | steel-bolts |
| bloomery-iron | bloomery | 6.4 с | iron-ore 2, coal 1 | iron 1 | wrought-iron |
| iron-gear | workbench | 0.5 с | iron 2 | gear 1 | ironworking |
| pipe | workbench | 0.5 с | iron 1 | pipe 1 | fluid-handling |
| offshore-pump | workbench | 1 с | pipe 2, gear 1, bronze 2 | offshore-pump 1 | fluid-handling |
| boiler | workbench | 1 с | pipe 4, brick 10 | boiler 1 | steam-power |
| steam-engine | workbench | 2 с | gear 8, pipe 5, iron 10 | steam-engine 1 | steam-power |
| copper-cable | workbench | 0.5 с | copper 1 | cable 2 | electricity |
| small-pole | workbench | 0.5 с | wood 1, cable 2 | small-pole 2 | electricity |
| radar | workbench | 1 с | iron 10, gear 5, cable 10, glass 5 | radar 1 | radio |
| blast-furnace | workbench | 3 с | brick 20, iron 10 | blast-furnace 1 | blast-furnace |
| iron-plate | blast-furnace | 3.2 с | iron-ore 1 | iron 1 | blast-furnace |
| steel | blast-furnace | 16 с | iron 5 | steel 1 | blast-furnace |
| electric-drill | workbench | 2 с | gear 5, cable 6, iron 10 | electric-drill 1 | electromechanics |
| inserter | workbench | 0.5 с | gear 1, cable 2, iron 1 | inserter 1 | electromechanics |
| assembler-1 | workbench | 0.5 с | gear 5, cable 6, iron 9 | assembler-1 1 | electromechanics |
| lab | workbench | 2 с | gear 10, cable 10, glass 10 | lab 1 | electromechanics |
| mechanism | workbench | 8 с | gear 2, cable 2, steel 1 | mechanism 1 | mechanism |
| radiator | workbench | 2 с | pipe 10, iron 10, copper 5 | radiator 1 | steam-heating |
| cooler | workbench | 2 с | pipe 10, gear 5, cable 10, iron 10 | cooler 1 | cooling |
| landfill | workbench | 1 с | stone 20 | landfill 1 | land-reclamation |
| deep-landfill | workbench | 1 с | stone 150, steel 5, mortar 10 | deep-landfill 1 | deep-landfill |
| pitch | alembic | 15 с | wood 10 | pitch 2, charcoal 3 | pitch |
| waterway | workbench | 1 с | wood 2, rope 1, iron 1 | waterway 2 | shipbuilding |
| tug | workbench | 10 с | steel 20, gear 20, pipe 10, wood 50, pitch 20 | tug 1 | shipbuilding |
| barge | workbench | 5 с | wood 60, steel 10, pitch 20 | barge 1 | shipbuilding |
| pier | workbench | 2 с | wood 20, steel 5, cable 5 | pier 1 | shipbuilding |
| buoy | workbench | 1 с | wood 5, cable 2, glass 1 | buoy 1 | buoys |
| fluid-barge | workbench | 5 с | steel 30, pipe 20, pitch 20 | fluid-barge 1 | fluid-barges |
| electrode | workbench | 3 с | copper 2, glass 1 | electrode 1 | third-awakening |
| charge-3 | electric-chamber | 1200 с | rectified-bottle 15, conc-acid-bottle 15, electrode 5 | charge-3 1, bottle 30 | third-awakening |

## Эпоха 4: технологии

| Технология | Стоимость | Наука | Требует |
|---|---|---|---|
| sulfur-gunpowder | 150 × 30 с | tablet, flask, mechanism | sulfur-processing, firearms |
| sulfur-processing | 200 × 30 с | tablet, flask, mechanism | mechanism, fluid-handling |
| oil-extraction | 200 × 30 с | tablet, flask, mechanism | electromechanics, fluid-barges |
| oil-processing | 250 × 30 с | tablet, flask, mechanism | oil-extraction |
| rubber | 200 × 30 с | tablet, flask, mechanism | sulfur-processing |
| reactive | 250 × 30 с | tablet, flask, mechanism | rubber |
| tungsten | 200 × 30 с | tablet, flask, mechanism | mechanism |
| navigation | 250 × 30 с | tablet, flask, mechanism, reactive | tungsten, reactive |
| cracking | 250 × 30 с | tablet, flask, mechanism, reactive | oil-processing, reactive |
| fuel-oil | 200 × 30 с | tablet, flask, mechanism, reactive | cracking |
| screw-steamer | 300 × 45 с | tablet, flask, mechanism, reactive, navigation | shipbuilding, rubber, navigation |
| ether | 250 × 30 с | tablet, flask, mechanism, reactive | reactive, rectification |
| tungsten-electrodes | 250 × 30 с | tablet, flask, mechanism, reactive, navigation | navigation, third-awakening |
| fourth-awakening | 400 × 60 с | tablet, flask, mechanism, reactive, navigation | ether, tungsten-electrodes |
| lab-glassware-2 | 250 × 30 с | tablet, flask, mechanism, reactive | lab-glassware-1, reactive |

## Эпоха 4: рецепты

| Рецепт | Где | Время | Вход | Выход | Открывает |
|---|---|---|---|---|---|
| piercing-rounds | workbench | 3 с | firearm-magazine 1, steel 1, copper 2 | piercing-rounds 1 | sulfur-gunpowder |
| sulfur-gunpowder | millstone | 4 с | saltpeter 2, charcoal 1, sulfur 1 | gunpowder 4 | sulfur-gunpowder |
| sulfuric-acid | chemical-plant | 1 с | sulfur 5, iron 1, water 100 | sulfuric-acid 50 | sulfur-processing |
| basic-oil | refinery | 5 с | crude-oil 100 | petroleum 45 | oil-processing |
| gas-sulfur | chemical-plant | 1 с | petroleum 30, water 30 | sulfur 2 | oil-processing |
| oil-processing | refinery | 5 с | crude-oil 100, water 50 | heavy-oil 30, light-oil 45, petroleum 55 | cracking |
| latex | plantation | 60 с | water 100 | latex 6 | rubber |
| rubber | chemical-plant | 5 с | latex 4, sulfur 1 | rubber 2 | rubber |
| reactive | chemical-plant | 10 с | bottle 1, sulfuric-acid 20, rubber 1 | reactive 2 | reactive |
| tungsten | electric-furnace | 6.4 с | tungsten-ore 2 | tungsten 1 | tungsten |
| navigation | workbench | 10 с | tungsten 1, glass 2, mechanism 1 | navigation 1 | navigation |
| heavy-cracking | chemical-plant | 2 с | heavy-oil 40, water 30 | light-oil 30 | cracking |
| light-cracking | chemical-plant | 2 с | light-oil 30, water 30 | petroleum 20 | cracking |
| fuel-oil | chemical-plant | 2 с | light-oil 10 | fuel-oil 1 | fuel-oil |
| ether | chemical-plant | 5 с | spirit-jug 2, sulfuric-acid 10, bottle 1 | ether-bottle 1, jug 2 | ether |
| tungsten-electrode | workbench | 3 с | tungsten 1, glass 1 | tungsten-electrode 1 | tungsten-electrodes |
| charge-4 | electric-chamber | 1500 с | rectified-bottle 20, conc-acid-bottle 20, ether-bottle 10, tungsten-electrode 5 | charge-4 1, bottle 50 | fourth-awakening |

## Эпоха 5: технологии

| Технология | Стоимость | Наука | Требует |
|---|---|---|---|
| plastics | 200 × 30 с | tablet, flask, mechanism, reactive, navigation | oil-processing, navigation |
| electronics | 200 × 30 с | tablet, flask, mechanism, reactive, navigation | plastics |
| instrument-board | 250 × 30 с | tablet, flask, mechanism, reactive, navigation | electronics, tungsten |
| rocket-fuel | 250 × 30 с | tablet, flask, mechanism, reactive, navigation, board | instrument-board, fuel-oil |
| light-structures | 250 × 30 с | tablet, flask, mechanism, reactive, navigation, board | instrument-board |
| control-units | 250 × 30 с | tablet, flask, mechanism, reactive, navigation, board | instrument-board |
| rocket-silo | 400 × 60 с | tablet, flask, mechanism, reactive, navigation, board | rocket-fuel, light-structures, control-units |
| spacesuit | 300 × 30 с | tablet, flask, mechanism, reactive, navigation, board | instrument-board, rubber, tanning |
| fifth-awakening | 400 × 60 с | tablet, flask, mechanism, reactive, navigation, board | control-units, fourth-awakening |

## Эпоха 5: рецепты

| Рецепт | Где | Время | Вход | Выход | Открывает |
|---|---|---|---|---|---|
| plastic | chemical-plant | 1 с | petroleum 20, coal 1 | plastic 2 | plastics |
| circuit | workbench | 0.5 с | plastic 1, cable 3, iron 1 | circuit 1 | electronics |
| board | workbench | 10 с | circuit 3, plastic 2, tungsten 1 | board 2 | instrument-board |
| rocket-fuel | chemical-plant | 10 с | light-oil 10, fuel-oil 1 | rocket-fuel 1 | rocket-fuel |
| low-density | workbench | 10 с | steel 2, copper 5, plastic 2 | low-density 1 | light-structures |
| control-unit | workbench | 10 с | circuit 5, tungsten 1, plastic 1 | control-unit 1 | control-units |
| rocket-part | rocket-silo | 3 с | low-density 2, rocket-fuel 2, control-unit 2 | rocket-part 1 | rocket-silo |
| spacesuit | workbench | 20 с | rubber 30, glass 20, tungsten 10, circuit 10, leather 10 | spacesuit 1 | spacesuit |
| oxygen-tank | workbench | 5 с | steel 2, rubber 1 | oxygen-tank 1 | spacesuit |
| charge-5 | electric-chamber | 1800 с | rectified-bottle 25, conc-acid-bottle 25, ether-bottle 15, control-unit 5 | charge-5 1, bottle 65 | fifth-awakening |
