-- luacheck: globals global settings game defines script

function removeSpriteObj(obj)
  if obj.valid then
    obj.destroy()
  end
end

function removeSpriteObjs(nixie)
  for _,obj in pairs(global.spriteobjs[nixie.unit_number]) do
    removeSpriteObj(obj)
  end
end

local stateOrientMap =
  { -- state map for big nixies
  ["0"]=1,
  ["1"]=2,
  ["2"]=3,
  ["3"]=4,
  ["4"]=5,
  ["5"]=6,
  ["6"]=7,
  ["7"]=8,
  ["8"]=9,
  ["9"]=10,
  ["A"]=11,
  ["B"]=12,
  ["C"]=13,
  ["D"]=14,
  ["E"]=15,
  ["F"]=16,
  ["G"]=17,
  ["H"]=18,
  ["I"]=19,
  ["J"]=20,
  ["K"]=21,
  ["L"]=22,
  ["M"]=23,
  ["N"]=24,
  ["O"]=25,
  ["P"]=26,
  ["Q"]=27,
  ["R"]=28,
  ["S"]=29,
  ["T"]=30,
  ["U"]=31,
  ["V"]=32,
  ["W"]=33,
  ["X"]=34,
  ["Y"]=35,
  ["Z"]=36,
  ["err"]=37,
  ["."]=38,
  ["negative"]=39, -- for negative numbers
  ["off"]=40,

  --extended symbols
  ["?"]=41,
  ["!"]=42,
  ["@"]=43,
  ["["]=44,
  ["]"]=45,
  ["{"]=46,
  ["}"]=47,
  ["("]=48,
  [")"]=49,
  ["/"]=50,
  ["*"]=51,
  ["-"]=52, -- for subtraction operation
  ["+"]=53,

  }

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
    local obj = global.spriteobjs[nixie.unit_number][key]
    if obj and obj.valid then
      if nixie.energy > 70 then
        obj.graphics_variation=stateOrientMap[new_state]

        -- allow keeping old color to stretch it for one cycle when updating value

        local color = newcolor
        if color=="keepcolor" then
          --game.print("keepcolor")
          color = obj.color
        end

        if not color then
          --game.print("nocolor")
          color = {r=1.0,  g=0.6,  b=0.2, a=1.0}
        end

        if new_state == "off" then
          --game.print("offcolor")
          color={r=1.0,  g=1.0,  b=1.0, a=1.0}
        end

        obj.color=color
      else
      --  game.print("nopower")
        if obj.graphics_variation ~= stateOrientMap["off"] then
          obj.graphics_variation = stateOrientMap["off"]
        end
        obj.color={r=1.0,  g=1.0,  b=1.0, a=1.0}
      end
    else
      game.print("invalid nixie sprite for " .. nixie.unit_number)
    end
  end
end

-- from binbinhfr/SmartDisplay, modified to check both wires and add them
function get_signal_value(entity,sig)
	local behavior = entity.get_control_behavior()
	if behavior == nil then
    return nil
  end

	local condition = behavior.circuit_condition
	if condition == nil then
    return nil
  end

  local signal
  if sig then
    signal = sig
  else
    signal = condition.condition.first_signal
  end

	if signal == nil or signal.name == nil then
    return(nil)
  end

	local redval,greenval=0,0

	local network = entity.get_circuit_network(defines.wire_type.red)
	if network then
	  redval = network.get_signal(signal)
	end

	network = entity.get_circuit_network(defines.wire_type.green)
	if network then
	  greenval = network.get_signal(signal)
	end


	local val = redval + greenval

  if not sig and not condition.fulfilled then
    -- use >= MININT32 to ensure always-on
    condition.condition.comparator="≥"
    condition.condition.constant=-0x80000000
    condition.condition.second_signal=nil
    behavior.circuit_condition = condition
  end

  return val
end

local validEntityName = {
  ['nixie-tube']       = 1,
  ['nixie-tube-alpha'] = 1,
  ['nixie-tube-small'] = 2
}

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

function getAlphaSignals(entity,wire_type,charsig)
  local net = entity.get_circuit_network(wire_type)

  local ch = charsig

  if net and net.signals and #net.signals > 0 then
    for _,s in pairs(net.signals) do
      if signalCharMap[s.signal.name] then
        if ch then
          ch = "err"
        else
          ch = signalCharMap[s.signal.name]
        end
      end
    end
  end

  return ch,co
end

function onTickController(entity)
  local v = get_signal_value(entity)
  --game.print("got v=" .. (v or "nil"))
  if v then
    local control = entity.get_or_create_control_behavior()

    local float = get_signal_value(entity,{name="signal-float",type="virtual"}) ~= 0
    --game.print("float=" .. (float and "true" or "false"))
    local hex = get_signal_value(entity,{name="signal-hex",type="virtual"}) ~= 0
    --game.print("hex=" .. (hex and "true" or "false"))
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
    displayValString(entity)
  end
end

function onTickAlpha(entity)
  if not entity then return end

  if not entity.valid then
    onRemoveEntity(entity)
    return
  end

  local charsig = nil

  charsig=getAlphaSignals(entity,defines.wire_type.red,  charsig)
  charsig=getAlphaSignals(entity,defines.wire_type.green,charsig)
  charsig = charsig or "off"

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
      local name, position
      if num == 1 then -- large tube, one sprite
        name = "nixie-tube-simple-sprite"
        position = {x=pos.x+1/32, y=pos.y+1/32}
      else
        name = "nixie-tube-simple-sprite-small"
        position = {x=pos.x-4/32+((n-1)*10/32), y=pos.y+4/32}
      end
      local sprite=surf.create_entity(
        {
          name=name,
          position=position,
          force=entity.force,
          color = {r=1.0,  g=1.0,  b=1.0, a=1.0},
          variation = stateOrientMap["off"]
        })
      sprite.active=false
      sprites[n]=sprite
    end
    global.spriteobjs[entity.unit_number] = sprites

    if entity.name == "nixie-tube-alpha" then
      global.alphas[entity.unit_number] = entity
    else

      -- properly reset nixies when (re)added
      local behavior = entity.get_or_create_control_behavior()
    	local condition = behavior.circuit_condition
      condition.condition.comparator="="
      condition.condition.constant=val
      condition.condition.second_signal=nil
      behavior.circuit_condition = condition

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
      removeSpriteObjs(entity)

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

    -- and re-index the world
    for _,surf in pairs(game.surfaces) do
      -- Destroy old sprite objects
      for _,sprite in pairs(surf.find_entities_filtered{name="nixie-tube-simple-sprite"}) do
        removeSpriteObj(sprite)
      end
      for _,sprite in pairs(surf.find_entities_filtered{name="nixie-tube-simple-sprite-small"}) do
        removeSpriteObj(sprite)
      end

      -- And re-index all nixies. non-nixie lamps will be ignored by onPlaceEntity
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
