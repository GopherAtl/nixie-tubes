circuit_connector_definitions["nixie"] = circuit_connector_definitions.create
(
  universal_connector_template,
  {
    --{ variation = 26, main_offset = util.by_pixel(4.5, 7.5), shadow_offset = util.by_pixel(3.5, 7.5), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(2.5, 18.0), shadow_offset = util.by_pixel(2.0, 18.0), show_shadow = true },
  }
)

circuit_connector_definitions["nixie-small"] = circuit_connector_definitions.create
(
  universal_connector_template,
  {
    { variation = 26, main_offset = util.by_pixel(2.5, 10.0), shadow_offset = util.by_pixel(2.0, 10.0), show_shadow = true },
  }
)


data:extend{

  -- original 2x1 tile one-digit nixie tube
  {
    type = "recipe",
    name = "nixie-tube",
    enabled = "false",
    ingredients =
    {
      {"electronic-circuit",1},
      {"iron-plate",2},
      {"iron-stick", 10},
    },
    result = "nixie-tube"
  },
  {
    type = "item",
    name = "nixie-tube",
    icon = "__nixie-tubes__/graphics/nixie-base-icon.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "circuit-network",
    order = "c-a",
    place_result = "nixie-tube",
    stack_size = 50
  },
  {
    type = "lamp",
    name = "nixie-tube",
    icon = "__nixie-tubes__/graphics/nixie-base-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral","player-creation", "not-on-map"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "nixie-tube"},
    max_health = 55,
    order = "z[zebra]",
    corpse = "small-remnants",
    collision_box = {{-0.4, -0.9}, {0.4, .9}},
    selection_box = {{-.5, -1.0}, {0.5, 1.0}},
    energy_source =
    {
      type = "electric",
      usage_priority = "lamp",
    },
    energy_usage_per_tick = "4KW",
    light = {intensity = 0.0, size = 0, color = {r=1, g=.6, b=.3, a=0}},
    picture_off =
    {
      filename = "__nixie-tubes__/graphics/nixie-base.png",
      priority = "high",
      width = 40,
      height = 64,
      shift = {0,0}
    },
    picture_on =
    {
      filename = "__nixie-tubes__/graphics/empty.png",
      priority = "high",
      width = 1,
      height = 1,
      shift = {0,0}
    },
    circuit_wire_connection_point =
    {
      shadow =
      {
        red = {22.5/32, 23.5/32},
        green = {18.5/32, 28.5/32},
      },
      wire =
      {
        red = {12/32, 23/32},
        green = {12/32, 28/32},
      }
    },
    circuit_wire_connection_point = circuit_connector_definitions["nixie"].points,
    circuit_connector_sprites = circuit_connector_definitions["nixie"].sprites,
    circuit_wire_max_distance = 7.5
  },

  -- 2x1 tile one-charater alpha nixie tube
  {
    type = "recipe",
    name = "nixie-tube-alpha",
    enabled = "false",
    ingredients =
    {
      {"electronic-circuit",1},
      {"iron-plate",2},
      {"iron-stick", 10},
    },
    result = "nixie-tube-alpha"
  },
  {
    type = "item",
    name = "nixie-tube-alpha",
    icon = "__nixie-tubes__/graphics/nixie-alpha-base-icon.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "circuit-network",
    order = "c-a",
    place_result = "nixie-tube-alpha",
    stack_size = 50
  },
  {
    type = "lamp",
    name = "nixie-tube-alpha",
    icon = "__nixie-tubes__/graphics/nixie-alpha-base-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral","player-creation", "not-on-map"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "nixie-tube-alpha"},
    max_health = 55,
    order = "z[zebra]",
    corpse = "small-remnants",
    collision_box = {{-0.4, -0.9}, {0.4, .9}},
    selection_box = {{-.5, -1.0}, {0.5, 1.0}},
    energy_source =
    {
      type = "electric",
      usage_priority = "secondary-input",
    },
    energy_usage_per_tick = "4KW",
    light = {intensity = 0.0, size = 0, color = {r=1, g=.6, b=.3, a=0}},
    picture_off =
    {
      filename = "__nixie-tubes__/graphics/nixie-base.png",
      priority = "high",
      width = 40,
      height = 64,
      shift = {0,0}
    },
    picture_on =
    {
      filename = "__nixie-tubes__/graphics/empty.png",
      priority = "high",
      width = 1,
      height = 1,
      shift = {0,0}
    },
    circuit_wire_connection_point =
    {
      shadow =
      {
        red = {22.5/32, 23.5/32},
        green = {18.5/32, 28.5/32},
      },
      wire =
      {
        red = {12/32, 23/32},
        green = {12/32, 28/32},
      }
    },
    circuit_wire_connection_point = circuit_connector_definitions["nixie"].points,
    circuit_connector_sprites = circuit_connector_definitions["nixie"].sprites,
    circuit_wire_max_distance = 7.5
  },

  -- small 1x1 tile two-digit nixie tube
  {
    type = "recipe",
    name = "nixie-tube-small",
    enabled = "false",
    ingredients =
    {
      {"electronic-circuit",1},
      {"iron-plate", 1},
      {"iron-stick", 5},
    },
    result = "nixie-tube-small"
  },
  {
    type = "item",
    name = "nixie-tube-small",
    icon = "__nixie-tubes__/graphics/nixie-small-base-icon.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "circuit-network",
    order = "c-a",
    place_result = "nixie-tube-small",
    stack_size = 50
  },
  {
    type = "lamp",
    name = "nixie-tube-small",
    icon = "__nixie-tubes__/graphics/nixie-small-base-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral","player-creation", "not-on-map"},
    minable = {hardness = 0.2, mining_time = 0.5, result = "nixie-tube-small"},
    max_health = 40,
    order = "z[zebra]",
    corpse = "small-remnants",
    collision_box = {{-0.4, -0.4}, {0.4, .4}},
    selection_box = {{-.5, -0.5}, {0.5, 0.5}},
    energy_source =
    {
      type = "electric",
      usage_priority = "secondary-input",
    },
    energy_usage_per_tick = "4KW",
    light = {intensity = 0.0, size = 0, color = {r=1, g=.6, b=.3, a=0}},
    light_when_colored = {intensity = 1, size = 6, color = {r=1.0, g=1.0, b=1.0}},
    picture_off =
    {
      filename = "__nixie-tubes__/graphics/nixie-small-base.png",
      priority = "high",
      width = 48,
      height = 42,
      shift = {4/32,-5/32}
    },
    picture_on =
    {
      filename = "__nixie-tubes__/graphics/empty.png",
      priority = "high",
      width = 1,
      height = 1,
      shift = {0,0}
    },
    circuit_wire_connection_point =
    {
      shadow =
      {
        red = {12/32, 15/32},
        green = {12/32, 19/32},
      },
      wire =
      {
        red = {12/32, 13/32},
        green = {12/32, 18/32},
      }
    },
    circuit_wire_max_distance = 7.5,

    circuit_wire_connection_point = circuit_connector_definitions["nixie-small"].points,
    circuit_connector_sprites = circuit_connector_definitions["nixie-small"].sprites,
  },

  {
    type = "simple-entity-with-owner",
    name = "nixie-tube-simple-sprite",
    render_layer = "higher-object-above",
    icon = "__nixie-tubes__/graphics/nixie-alpha-base-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral", "placeable-off-grid"},
    order = "s-e-w-o",
    --minable = false,
    max_health = 100,
    corpse = "small-remnants",
    collision_box = nil,
    selection_box = nil,
    pictures =
    {
      sheet =
      {
        filename = "__nixie-tubes__/graphics/nixie-chars-mono.png",
        line_length = 10,
        width = 20,
        height = 44,
        variation_count = 80,
        apply_runtime_tint = true,
        axially_symmetrical = false,
        direction_count = 1,
        shift = {-5/32,-7/32},
      },
    }
  },

  {
    type = "simple-entity-with-owner",
    name = "nixie-tube-simple-sprite-small",
    render_layer = "higher-object-above",
    icon = "__nixie-tubes__/graphics/nixie-alpha-base-icon.png",
    icon_size = 32,
    flags = {"placeable-neutral", "placeable-off-grid"},
    order = "s-e-w-o",
    --minable = false,
    max_health = 100,
    corpse = "small-remnants",
    collision_box = nil,
    selection_box = nil,
    pictures =
    {
      sheet =
      {
        filename = "__nixie-tubes__/graphics/nixie-chars-mono.png",
        line_length = 10,
        width = 20,
        height = 44,
        variation_count = 80,
        apply_runtime_tint = true,
        axially_symmetrical = false,
        direction_count = 1,
        shift = {-5/32,-7/32},
        scale = 0.5,
      },
    }
  },
}

-- still present for loading old saves
local colorman = table.deepcopy(data.raw['player']['player'])
colorman.name = "nixie-colorman"
data:extend{colorman}
