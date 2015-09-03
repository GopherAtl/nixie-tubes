data:extend(
{
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
      usage_priority = "secondary-input",
    },
    energy_usage_per_tick = "4KW",
    light = {intensity = 0.0, size = 0, color = {r=1, g=.6, b=.3, a=0}},
    picture_off =
    {
      filename = "__nixie-tubes__/graphics/nixie-base.png",
      priority = "high",
      width = 48,
      height = 72,
      shift = {7/32,-5/32}
    },
    picture_on =
    {
      filename = "__nixie-tubes__/graphics/nixie-base.png",
      priority = "high",
      width = 48,
      height = 72,
      shift = {7/32,-5/32}
    },
    circuit_wire_connection_point =
    {
      shadow =
      {
        red = {26/32, -23/32},
        green = {26/32, -23/32},
      },
      wire =
      {
        red = {12/32, -41/32},
        green = {12/32, -41/32},
      }
    },

    circuit_wire_max_distance = 7.5
  },

  {
    type = "car",
    name = "nixie-tube-sprite",
    icon = "__nixie-tubes__/graphics/nixie-base-icon.png",
    flags = {"placeable-neutral", "placeable-off-grid", "player-creation"},
    minable = {mining_time = 1, result = "nixie-tube"},
    max_health = 200,
    order="z[zebra]",
    corpse = "small-remnants",
    energy_per_hit_point = 1,
    crash_trigger = crash_trigger(),
    resistances =
    {
      {
        type = "fire",
        percent = 50
      },
      {
        type = "impact",
        percent = 30,
        decrease = 30
      }
    },
    collision_box = {{-0.1, -.1}, {.1,.1}},
    collision_mask = { "item-layer", "object-layer", "player-layer", "water-tile"},
    selection_box = {{0,0}, {0,0}},
    effectivity = 0.5,
    braking_power = "200kW",
    burner =
    {
      effectivity = 0.6,
      fuel_inventory_size = 1,
      smoke =
      {
        {
          name = "smoke",
          deviation = {0.25, 0.25},
          frequency = 50,
          position = {0, 1.5},
          starting_frame = 3,
          starting_frame_deviation = 5,
          starting_frame_speed = 0,
          starting_frame_speed_deviation = 5
        }
      }
    },
    consumption = "150kW",
    friction = 2e-3,
    light =
    {
      {
        type = "oriented",
        minimum_darkness = 0.3,
        picture =
        {
          filename = "__core__/graphics/light-cone.png",
          priority = "medium",
          scale = 2,
          width = 200,
          height = 200
        },
        shift = {-0.6, -14},
        size = 2,
        intensity = 0.6
      },
      {
        type = "oriented",
        minimum_darkness = 0.3,
        picture =
        {
          filename = "__core__/graphics/light-cone.png",
          priority = "medium",
          scale = 2,
          width = 200,
          height = 200
        },
        shift = {0.6, -14},
        size = 2,
        intensity = 0.6
      }
    },
    animation =
    {
      layers =
      {
        {
          width = 20,
          height = 44,
          frame_count = 1,
          direction_count = 12,
          shift = {-2/32,-8/32},
          animation_speed = 0.1,
          max_advance = 0.2,
          stripes =
          {
            {
             filename = "__nixie-tubes__/graphics/nixie-digits.png",
             width_in_frames = 1,
             height_in_frames = 12,
            },
          }
        },
      }
    },
    stop_trigger_speed = 0.2,
    stop_trigger =
    {
      {
        type = "play-sound",
        sound =
        {
          {
            filename = "__base__/sound/car-breaks.ogg",
            volume = 0.6
          },
        }
      },
    },
    sound_minimum_speed = 0.2;
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    working_sound =
    {
      sound =
      {
        filename = "__base__/sound/car-engine.ogg",
        volume = 0.6
      },
      activate_sound =
      {
        filename = "__base__/sound/car-engine-start.ogg",
        volume = 0.6
      },
      deactivate_sound =
      {
        filename = "__base__/sound/car-engine-stop.ogg",
        volume = 0.6
      },
      match_speed_to_activity = true,
    },
    open_sound = { filename = "__base__/sound/car-door-open.ogg", volume=0.7 },
    close_sound = { filename = "__base__/sound/car-door-close.ogg", volume = 0.7 },
    rotation_speed = 0.015,
    weight = 700,
    guns = { "vehicle-machine-gun" },
    inventory_size = 80
  },


})