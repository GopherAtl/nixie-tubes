data:extend{
  {
    type = "bool-setting",
    name = "nixie-tubes-enable-color-grey",
    setting_type = "runtime-global",
    default_value = false,
    order="nixie-colors-grey"
  },
  {
    type = "bool-setting",
    name = "nixie-tubes-enable-color-white",
    setting_type = "runtime-global",
    default_value = false,
    order="nixie-colors-white"
  },
  {
    type = "bool-setting",
    name = "nixie-tubes-enable-color-black",
    setting_type = "runtime-global",
    default_value = false,
    order="nixie-colors-black"
  },

  {
		type = "int-setting",
		name = "nixie-tube-update-speed-alpha",
		setting_type = "runtime-global",
		minimum_value = 1,
		default_value = 10,
		order = "nixie-speed-alpha",
	},
  {
		type = "int-setting",
		name = "nixie-tube-update-speed-numeric",
		setting_type = "runtime-global",
		minimum_value = 1,
		default_value = 5,
		order = "nixie-speed-numeric",
	},
}
