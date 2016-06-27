for _,force in pairs(game.forces) do
  if force.technologies['cathodes'] then
    force.technologies['cathodes'].reload()
    if force.technologies["electric-energy-distribution-1"].researched then 
      force.recipes["nixie-tube-small"].enabled = true
    end
  end
end