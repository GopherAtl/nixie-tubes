for _,surf in pairs(game.surfaces) do
  for _,ent in pairs(surf.find_entities_filtered{name='nixie-colorman'}) do ent.active=false end
  for _,ent in pairs(surf.find_entities_filtered{name='nixie-tube-sprite'}) do ent.active=false end
  for _,ent in pairs(surf.find_entities_filtered{name='nixie-tube-small-sprite'}) do ent.active=false end
end
