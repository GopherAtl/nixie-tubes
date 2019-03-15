-- luacheck: globals global settings game defines script
local signalCharMap = {
  ["signal-0"] = "0",
  ["signal-1"] = "1",
  ["signal-2"] = "2",
  ["signal-3"] = "3",
  ["signal-4"] = "4",
  ["signal-5"] = "5",
  ["signal-6"] = "6",
  ["signal-7"] = "7",
  ["signal-8"] = "8",
  ["signal-9"] = "9",
  ["signal-A"] = "A",
  ["signal-B"] = "B",
  ["signal-C"] = "C",
  ["signal-D"] = "D",
  ["signal-E"] = "E",
  ["signal-F"] = "F",
  ["signal-G"] = "G",
  ["signal-H"] = "H",
  ["signal-I"] = "I",
  ["signal-J"] = "J",
  ["signal-K"] = "K",
  ["signal-L"] = "L",
  ["signal-M"] = "M",
  ["signal-N"] = "N",
  ["signal-O"] = "O",
  ["signal-P"] = "P",
  ["signal-Q"] = "Q",
  ["signal-R"] = "R",
  ["signal-S"] = "S",
  ["signal-T"] = "T",
  ["signal-U"] = "U",
  ["signal-V"] = "V",
  ["signal-W"] = "W",
  ["signal-X"] = "X",
  ["signal-Y"] = "Y",
  ["signal-Z"] = "Z",
  ["signal-negative"] = "negative",

  --extended symbols
  ["signal-stop"] = "dot",
  ["signal-qmark"]="?",
  ["signal-exmark"]="!",
  ["signal-at"]="@",
  ["signal-sqopen"]="[",
  ["signal-sqclose"]="]",
  ["signal-curopen"]="{",
  ["signal-curclose"]="}",
  ["signal-paropen"]="(",
  ["signal-parclose"]=")",
  ["signal-slash"]="slash",
  ["signal-asterisk"]="*",
  ["signal-minus"]="-",
  ["signal-plus"]="+",
  ["signal-percent"]="%",
}

function RegisterStrings()
  if remote.interfaces['signalstrings'] and remote.interfaces['signalstrings']['register_signal'] then
    local syms = {
      ["signal-stop"] = ".",
      ["signal-qmark"]="?",
      ["signal-exmark"]="!",
      ["signal-at"]="@",
      ["signal-sqopen"]="[",
      ["signal-sqclose"]="]",
      ["signal-curopen"]="{",
      ["signal-curclose"]="}",
      ["signal-paropen"]="(",
      ["signal-parclose"]=")",
      ["signal-slash"]="/",
      ["signal-asterisk"]="*",
      ["signal-minus"]="-",
      ["signal-plus"]="+",
	  ["signal-percent"]="%",
    }
    for name,char in pairs(syms) do
      remote.call('signalstrings','register_signal',name,char)
    end
  end
end

function RegisterPicker()
  if remote.interfaces["picker"] and remote.interfaces["picker"]["dolly_moved_entity_id"] then
    script.on_event(remote.call("picker", "dolly_moved_entity_id"), function(event)
      onRemoveEntity(event.moved_entity)
      onPlaceEntity({created_entity=event.moved_entity})
    end)
  end
end


--sets the state(s) and update the sprite for a nixie
function setStates(nixie,newstates,newcolor)
  for key,new_state in pairs(newstates) do
    if not new_state then new_state = "off" end
    -- printing floats sometimes hands us a literal '.', needs to be renamed
    if new_state == '.' then new_state = "dot" end
    local obj = global.spriteobjs[nixie.unit_number][key]
    if obj and rendering.is_valid(obj) then
      if nixie.energy > 70 then
        rendering.set_sprite(obj,"nixie-tube-sprite-" .. new_state)

        local color = newcolor

        if not color then
          --game.print("nocolor")
          color = {r=1.0,  g=0.6,  b=0.2, a=1.0}
        end

        if new_state == "off" then
          --game.print("offcolor")
          color={r=1.0,  g=1.0,  b=1.0, a=1.0}
        end

        rendering.set_color(obj,color)
      else
      --  game.print("nopower")
        if rendering.get_sprite(obj) ~= "nixie-tube-sprite-off" then
          rendering.set_sprite(obj,"nixie-tube-sprite-off")
        end
        rendering.set_color(obj,{r=1.0,  g=1.0,  b=1.0, a=1.0})
      end
    else
      game.print("invalid nixie sprite for " .. nixie.unit_number)
      --TODO: if this happens a lot, jsut recreate them?
    end
  end
end

function get_selected_signal(entity)
  local behavior = entity.get_control_behavior()
	if behavior == nil then
    return nil
  end

	local condition = behavior.circuit_condition
	if condition == nil then
    return nil
  end

  local signal = condition.condition.first_signal
  if signal and not condition.fulfilled then
    -- use >= MININT32 to ensure always-on
    condition.condition.comparator="≥"
    condition.condition.constant=-0x80000000
    condition.condition.second_signal=nil
    behavior.circuit_condition = condition
  end

  return signal
end

function get_signal_from_set(signal,set)
  for _,sig in pairs(set) do
    if sig.signal.type == signal.type and sig.signal.name == signal.name then
      return sig.count
    end
  end
  return nil
end

local validEntityName = {
  ['nixie-tube']       = 1,
  ['nixie-tube-alpha'] = 1,
  ['nixie-tube-small'] = 2
}

local sigFloat = {name="signal-float",type="virtual"}
local sigHex = {name="signal-hex",type="virtual"}

function displayValString(entity,vs,color)

  local nextdigit = global.nextdigit[entity.unit_number]
  local chcount = #global.spriteobjs[entity.unit_number]

  if not vs then
    --game.print("off")
    setStates(entity,(chcount==1) and {"off"} or {"off","off"})
  elseif #vs < chcount then
    --game.print("pastend")
    setStates(entity,{"off",vs},color)
  elseif #vs >= chcount then
    --game.print("digit " .. serpent.line(color))
    setStates(entity,(chcount==1) and {vs:sub(-1)} or {vs:sub(-2,-2),vs:sub(-1)},color)
  end

  if nextdigit then
    if nextdigit.valid then
      if vs and #vs>chcount then
        displayValString(nextdigit,vs:sub(1,-(chcount+1)),color)
      else
        displayValString(nextdigit)
      end
    else
      --when a nixie in the middle is removed, it doesn't have the unit_number to it's right to remove itself
      global.nextdigit[entity.unit_number] = nil
    end
  end
end

function float_from_int(i)
  local sign = bit32.btest(i,0x80000000) and -1 or 1
  local exponent = bit32.rshift(bit32.band(i,0x7F800000),23)-127
  local significand = bit32.band(i,0x007FFFFF)

  if exponent == 128 then
    if significand == 0 then
      return sign/0 --[[infinity]]
    else
      return 0/0 --[[nan]]
    end
  end

  if exponent == -127 then
    if significand == 0 then
      return sign * 0 --[[zero]]
    else
      return sign * math.ldexp(significand,-149) --[[denormal numbers]]
    end
  end

  return sign * math.ldexp(bit32.bor(significand,0x00800000),exponent-23) --[[normal numbers]]
end

function getAlphaSignals(entity)
  local signals = entity.get_merged_signals()
  local ch = nil

  if signals and #signals > 0 then
    for _,s in pairs(signals) do
      if signalCharMap[s.signal.name] then
        if ch then
          ch = "err"
        else
          ch = signalCharMap[s.signal.name]
        end
      end
    end
  end

  return ch
end

function onTickController(entity)
  local signals = entity.get_merged_signals()
  if signals then
    local v = get_signal_from_set(get_selected_signal(entity),signals) or 0
    --game.print("got v=" .. (v or "nil"))
    local control = entity.get_or_create_control_behavior()

    local float = (get_signal_from_set(sigFloat,signals) or 0 ) ~= 0
    local hex = (get_signal_from_set(sigHex,signals) or 0 ) ~= 0
    local format = "%i"
    if float and hex then
      format = "%A"
      v = float_from_int(v)
    elseif hex then
      format = "%X"
      if v < 0 then v = v + 0x100000000 end
    elseif float then
      format = "%G"
      v = float_from_int(v)
    end

    displayValString(entity,format:format(v),control.use_colors and control.color)
  else
    displayValString(entity,"0")
  end
end

function onTickAlpha(entity)
  if not entity then return end

  if not entity.valid then
    onRemoveEntity(entity)
    return
  end

  local charsig = getAlphaSignals(entity) or "off"

  local color
  local control = entity.get_or_create_control_behavior()
  if control.use_colors then
    control.circuit_condition = {
      condition={
        first_signal={name="signal-anything",type="virtual"},
        comparator="≠",
        constant=0,
        second_signal=nil
      },
      connect_to_logistic_network=false
    }
    color = control.color
  end

  setStates(entity,{charsig},color)
end


function onTick(event)

  for _=1, settings.global["nixie-tube-update-speed-numeric"].value do
    local nixie
    if global.next_controller and not global.controllers[global.next_controller] then
      game.print("Invalid next_controller " .. global.next_controller)
      global.next_controller=nil
    end

    global.next_controller,nixie = next(global.controllers,global.next_controller)

    if nixie then
      if nixie.valid then
        --game.print("Updating Nixie " .. global.next_controller)
        onTickController(nixie)
      else
        game.print("remvoing damaged nixie tube " .. global.next_controller)
        global.controllers[global.next_controller] = nil
        global.next_controller = nil
      end
    end
  end

  for _=1, settings.global["nixie-tube-update-speed-alpha"].value do
    local nixie
    if global.next_alpha and not global.alphas[global.next_alpha] then
      game.print("Invalid next_alpha " .. global.next_alpha)
      global.next_alpha=nil
    end
    global.next_alpha,nixie = next(global.alphas,global.next_alpha)

    if nixie then
      if nixie.valid then
        --game.print("Updating Nixie " .. global.next_alpha)
        onTickAlpha(nixie)
      else
        game.print("remvoing damaged nixie tube " .. global.next_alpha)
        global.alphas[global.next_alpha] = nil
        global.next_alpha = nil
      end
    end
  end
end

function onPlaceEntity(event)

  local entity=event.created_entity
  if not entity.valid then return end

  local num = validEntityName[entity.name]
  if num then
    --game.print("found nixie " .. entity.unit_number)
    local pos=entity.position
    local surf=entity.surface

    local sprites = {}
    for n=1, num do
      --place the /real/ thing(s) at same spot
      local position
      if num == 1 then -- large tube, one sprite
        position = {x=1/32, y=1/32}
      else
        position = {x=-6/32+((n-1)*10/32), y=1/32}
      end
      local sprite= rendering.draw_sprite{
        sprite = "nixie-tube-sprite-off",
        target = entity,
        target_offset = position,
        surface = entity.surface,
        tint = {r=1.0,  g=1.0,  b=1.0, a=1.0},
        x_scale = 1/num,
        y_scale = 1/num,
        render_layer = "object",
        }

      sprites[n]=sprite
    end
    global.spriteobjs[entity.unit_number] = sprites

    if entity.name == "nixie-tube-alpha" then
      global.alphas[entity.unit_number] = entity
    else

      --enslave guy to left, if there is one
      local neighbors=surf.find_entities_filtered{
        position={x=entity.position.x-1,y=entity.position.y},
        name=entity.name}
      for _,n in pairs(neighbors) do
        if n.valid then
          --game.print(entity.unit_number .. " found neighbor left " .. n.unit_number)
          if global.next_controller == n.unit_number then
            -- if it's currently the *next* controller, claim that too...
            global.next_controller = entity.unit_number
          end

          global.controllers[n.unit_number] = nil
          global.nextdigit[entity.unit_number] = n
        end
      end

      --slave self to right, if any
      neighbors=surf.find_entities_filtered{
        position={x=entity.position.x+1,y=entity.position.y},
        name=entity.name}
      local foundright=false
      for _,n in pairs(neighbors) do
        if n.valid then
          --game.print(entity.unit_number .. " found neighbor right " .. n.unit_number)
          foundright=true
          global.nextdigit[n.unit_number]=entity
        end
      end
      if not foundright then
        global.controllers[entity.unit_number] = entity
      end
    end
  end
end

function onRemoveEntity(entity)
  if entity.valid then
    if validEntityName[entity.name] then

      --if I was a controller, deregister
      if global.next_controller == entity.unit_number then
        -- if i was the *next* controller, pass it forward...
        if not global.controllers[global.next_controller] then
          game.print("Invalid next_controller removal??")
          global.next_controller=nil
        end
        global.next_controller = next(global.controllers,global.next_controller)
      end
      global.controllers[entity.unit_number]=nil

      --if i was an alpha, deregister
      if global.next_alpha == entity.unit_number then
        -- if i was the *next* alpha, pass it forward...
        if not global.alphas[global.next_alpha] then
          game.print("Invalid next_alpha removal??")
          global.next_alpha=nil
        end
        global.next_alpha = next(global.alphas,global.next_alpha)
      end
      global.alphas[entity.unit_number]=nil

      --if I had a next-digit, register it as a controller
      --if i was a next-digit, unlink
      local nextdigit = global.nextdigit[entity.unit_number]
      if nextdigit and nextdigit.valid then
        global.controllers[nextdigit.unit_number] = nextdigit
        displayValString(nextdigit)
        global.nextdigit[entity.unit_number] = nil
      end
      for k,v in pairs(global.nextdigit) do
        if v == entity then
          global.nextdigit[k] = nil
          break
        end
      end

    end
  end
end

script.on_init(function()
  global.alphas = {}
  global.controllers = {}
  global.spriteobjs = {}
  global.nextdigit = {}

  RegisterStrings()
  RegisterPicker()
end)

script.on_load(function()
  RegisterStrings()
  RegisterPicker()
end)

script.on_configuration_changed(function(data)
  if data.mod_changes and data.mod_changes["nixie-tubes"] then
    --If my data has changed, rebuild all my tables. There are so many old formats, there's no other sensible way to upgrade.

    -- remove ancient config if it's still here
    if global.nixie_tubes then global.nixie_tubes = nil end

    -- clear the tables
    global = {
      alphas = {},
      controllers = {},
      spriteobjs = {},
      nextdigit = {},
    }

    -- wipe out any lingering sprites i've just deleted the references to...
    rendering.clear("nixie-tubes")

    -- and re-index the world
    for _,surf in pairs(game.surfaces) do
      -- re-index all nixies. non-nixie lamps will be ignored by onPlaceEntity
      for _,lamp in pairs(surf.find_entities_filtered{type="lamp"}) do
        onPlaceEntity({created_entity=lamp})
      end
    end


  end
end)

script.on_event(defines.events.on_built_entity, onPlaceEntity)
script.on_event(defines.events.on_robot_built_entity, onPlaceEntity)

script.on_event(defines.events.on_pre_player_mined_item, function(event) onRemoveEntity(event.entity) end)
script.on_event(defines.events.on_robot_pre_mined, function(event) onRemoveEntity(event.entity) end)
script.on_event(defines.events.on_entity_died, function(event) onRemoveEntity(event.entity) end)

script.on_event(defines.events.on_tick, onTick)
