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
