data:extend(
{
	{
		type = "item",
		name = "widget",
		icon = "__gophers-test__/graphics/slot-icon-robot.png",
		flags = {"goes-to-main-inventory"},
		subgroup = "barrel",
		order = "b[widget]",
		stack_size = 10
	},
  {
    type = "recipe",
    name = "craft-widget",
    category = "crafting",
    energy_required = 1,
    order = "c-widget",
    enabled = "true",
    icon = "__gophers-test__/graphics/slot-icon-robot.png",
    ingredients =
    {
      {type="item", name="iron-plate", amount=1},
      {type="item", name="copper-plate", amount=1},
    },
    results=
    {
      {type="item", name="widget", amount=1},
    }
  },

})