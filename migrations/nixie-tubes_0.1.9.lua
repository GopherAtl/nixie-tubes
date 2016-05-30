for _,force in pairs(game.forces) do
  force.technologies['cathodes'].reload()
  if force.technologies["electric-energy-distribution-1"].researched then 
   force.recipes["nixie-tube-small"].enabled = true
  end
end