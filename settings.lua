data:extend{
  {
    type = "string-setting",
    name = "sd-wave-difficulty",
    setting_type = "runtime-global",
    default_value = "normal",
    allowed_values = {"relaxed", "normal", "hard", "off"},
    order = "a",
  },
  {
    type = "bool-setting",
    name = "sd-petrify-newcomers",
    setting_type = "runtime-global",
    default_value = true,
    order = "b",
  },
}
