-- The notes that ruins can hold. Texts are in locale: [sd-note-title] and [sd-note-text] by id.
-- kind: "journal" (in the diary from the start), "hint", "recipe" (unlocks `recipe`), "cache" (repeats).
return {
  {id = "journal-1", kind = "journal"},
  {id = "first-steps", kind = "hint"},
  {id = "fruit", kind = "hint"},
  {id = "heat", kind = "hint"},
  {id = "jugs", kind = "hint"},
  {id = "chamber", kind = "hint"},
  {id = "waves", kind = "hint"},
  {id = "metal", kind = "hint"},
  {id = "charcoal-pit", kind = "recipe", recipe = "sd-alt-charcoal-pit"},
  {id = "lime-acid", kind = "recipe", recipe = "sd-alt-lime-acid"},
  {id = "compost", kind = "recipe", recipe = "sd-alt-compost"},
  {id = "double-firing", kind = "recipe", recipe = "sd-alt-double-firing"},
  {id = "cache", kind = "cache"},
}
