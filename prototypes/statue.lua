-- The statue drawn over a petrified player's character: the first frame of the vanilla idle animation
-- (facing south), in stone grey.
data:extend{
  {
    type = "animation",
    name = "sd-statue",
    layers = {
      {
        filename = "__base__/graphics/entity/character/level1_idle.png",
        width = 92, height = 116, x = 0, y = 4 * 116,
        frame_count = 1,
        shift = util.by_pixel(0, -21),
        scale = 0.5,
        tint = {0.55, 0.55, 0.53},
      },
    },
  },
}

-- On screen while petrified: stone creeping in from the edges (graphics/gui/petrified-vignette.png, drawn
-- by a script: a squircle gradient with value noise), and a green flash when the wave hits.
data:extend{
  {type = "sprite", name = "sd-petrified-vignette", filename = "__second-dawn__/graphics/gui/petrified-vignette.png",
   size = 256, flags = {"gui"}},
  {type = "sprite", name = "sd-petrified-flash", filename = "__second-dawn__/graphics/gui/petrified-flash.png",
   size = 8, flags = {"gui"}},
}
