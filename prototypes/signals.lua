data:extend(
  {{
    type = "item-subgroup",
    name = "virtual-signal-symbol",
    group = "signals",
    order = "e"
  }}
)


local symcount=1
local function create_symsignal(name)
  data:extend(
  {
    {
      type = "virtual-signal",
      name = "signal-" .. name,
      icon = "__nixie-tubes__/graphics/signal/signal_" .. name .. ".png",
      subgroup = "virtual-signal-symbol",
      order = "e[symbols]-[" .. name .. "]"
    }
  })
  symcount = symcount + 1
end

--create_symsignal("negative")

--extended symbols
create_symsignal("stop")
create_symsignal("qmark")
create_symsignal("exmark")
create_symsignal("at")
create_symsignal("sqopen")
create_symsignal("sqclose")
create_symsignal("curopen")
create_symsignal("curclose")
create_symsignal("paropen")
create_symsignal("parclose")
create_symsignal("slash")
create_symsignal("asterisk")
create_symsignal("minus")
create_symsignal("plus")
