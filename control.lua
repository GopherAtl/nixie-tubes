-- luacheck: globals global settings game defines script

local function removeSpriteObj(obj)
  if obj.valid then
    if obj.passenger then
      obj.passenger.destroy()
    end
    obj.clear_items_inside()
    obj.destroy()
  end
end

local function removeSpriteObjs(nixie)
  for _,obj in pairs(global.spriteobjs[nixie.unit_number]) do
    removeSpriteObj(obj)
  end
end

local bigstep=1/80
--build LuT to convert states into orientation values.
local function projected_orientation(turn)
  local x = math.sin(turn * math.pi * 2)
  local y = -math.cos(turn * math.pi * 2)

  y = y * math.cos(math.pi / 4)

  return math.atan2(x, -y) / (math.pi * 2)
end

local stateOrientMap =
  { -- state map for big nixies
  ["0"]=projected_orientation(0*bigstep),
  ["1"]=projected_orientation(1*bigstep),
  ["2"]=projected_orientation(2*bigstep),
  ["3"]=projected_orientation(3*bigstep),
  ["4"]=projected_orientation(4*bigstep),
  ["5"]=projected_orientation(5*bigstep),
  ["6"]=projected_orientation(6*bigstep),
  ["7"]=projected_orientation(7*bigstep),
  ["8"]=projected_orientation(8*bigstep),
  ["9"]=projected_orientation(9*bigstep),
  ["A"]=projected_orientation(10*bigstep),
  ["B"]=projected_orientation(11*bigstep),
  ["C"]=projected_orientation(12*bigstep),
  ["D"]=projected_orientation(13*bigstep),
  ["E"]=projected_orientation(14*bigstep),
  ["F"]=projected_orientation(15*bigstep),
  ["G"]=projected_orientation(16*bigstep),
  ["H"]=projected_orientation(17*bigstep),
  ["I"]=projected_orientation(18*bigstep),
  ["J"]=projected_orientation(19*bigstep),
  ["K"]=projected_orientation(20*bigstep),
  ["L"]=projected_orientation(21*bigstep),
  ["M"]=projected_orientation(22*bigstep),
  ["N"]=projected_orientation(23*bigstep),
  ["O"]=projected_orientation(24*bigstep),
  ["P"]=projected_orientation(25*bigstep),
  ["Q"]=projected_orientation(26*bigstep),
  ["R"]=projected_orientation(27*bigstep),
  ["S"]=projected_orientation(28*bigstep),
  ["T"]=projected_orientation(29*bigstep),
  ["U"]=     projected_orientation(30*bigstep),
  ["V"]=     projected_orientation(31*bigstep),
  ["W"]=     projected_orientation(32*bigstep),
  ["X"]=     projected_orientation(33*bigstep),
  ["Y"]=     projected_orientation(34*bigstep),
  ["Z"]=     projected_orientation(35*bigstep),
  ["err"]=   projected_orientation(36*bigstep),
  ["."]=   projected_orientation(37*bigstep),
  ["negative"]= projected_orientation(38*bigstep), -- for negative numbers
  ["off"]=   projected_orientation(39*bigstep),

  --extended symbols
  ["?"]=projected_orientation(40*bigstep),
  ["!"]=projected_orientation(41*bigstep),
  ["@"]=projected_orientation(42*bigstep),
  ["["]=projected_orientation(43*bigstep),
  ["]"]=projected_orientation(44*bigstep),
  ["{"]=projected_orientation(45*bigstep),
  ["}"]=projected_orientation(46*bigstep),
  ["("]=projected_orientation(47*bigstep),
  [")"]=projected_orientation(48*bigstep),
  ["/"]=projected_orientation(49*bigstep),
  ["*"]=projected_orientation(50*bigstep),
  ["-"]=projected_orientation(51*bigstep), -- for subtraction operation
  ["+"]=projected_orientation(52*bigstep),

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

local function RegisterStrings()
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


--sets the state(s) and update the sprite for a nixie
local function setStates(nixie,newstates,newcolor)
  for key,new_state in pairs(newstates) do
    if not new_state then new_state = "off" end
    local obj = global.spriteobjs[nixie.unit_number][key]
    if obj and obj.valid then
      if nixie.energy > 70 then
        obj.orientation=stateOrientMap[new_state]
        local color = newcolor
        if not color then color={r=1.0,  g=0.6,  b=0.2, a=1.0} end
        if new_state == "off" then color={r=1.0,  g=1.0,  b=1.0, a=1.0} end
        -- create and color a passenger
        if not obj.passenger then
          obj.passenger = obj.surface.create_entity{name="nixie-colorman", position=obj.position,force=obj.force}
          obj.passenger.active=false
        end
        obj.passenger.color=color
      else
        obj.orientation=stateOrientMap["off"]
      end
    else
      game.print("invalid nixie?")
    end
  end
end

-- from binbinhfr/SmartDisplay, modified to check both wires and add them
local function get_signal_value(entity,sig)
	local behavior = entity.get_control_behavior()
	if behavior == nil then	return nil end

	local condition = behavior.circuit_condition
	if condition == nil then return nil end

  -- shortcut, return stored value if unchanged
  if not sig and condition.fulfilled and condition.condition.comparator=="=" then
    return condition.condition.constant,false
  end

	local signal
  if sig then
    signal = sig
  else
    signal = condition.condition.first_signal
  end

	if signal == nil or signal.name == nil then return(nil)	end

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

  if not sig then
    condition.condition.comparator="="
    condition.condition.constant=val
    condition.condition.second_signal=nil
    behavior.circuit_condition = condition
  end

  return val,true
end

local validEntityName = {
  ['nixie-tube']       = 1,
  ['nixie-tube-alpha'] = 1,
  ['nixie-tube-small'] = 2
}

local function displayValString(entity,vs,color)

  if not (entity and entity.valid) then return end

  local nextdigit = global.nextdigit[entity.unit_number]
  local chcount = #global.spriteobjs[entity.unit_number]

  if not vs then
    setStates(entity,(chcount==1) and {"off"} or {"off","off"})
  elseif #vs < chcount then
    setStates(entity,{"off",vs},color)
  elseif #vs >= chcount then
    setStates(entity,(chcount==1) and {vs:sub(-1)} or {vs:sub(-2,-2),vs:sub(-1)},color)
  end

  if nextdigit then
    if vs and #vs>chcount then
      displayValString(nextdigit,vs:sub(1,-(chcount+1)),color)
    else
      displayValString(nextdigit)
    end
  end
end

local function float_from_int(i)
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

local function getAlphaSignals(entity,wire_type,charsig)
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

local function onTickController(entity)
  if not entity.valid then
    onRemoveEntity(entity)
    return
  end

  local v,changed=get_signal_value(entity)
  if v then
    local color,updatecolor
    local control = entity.get_or_create_control_behavior()
    if control.use_colors then
      color = control.color
      --TODO: smarter fail-fast for color
      updatecolor = true
    end
    if changed or updatecolor then
      local float = get_signal_value(entity,{name="signal-float",type="virtual"}) ~= 0
      local hex = get_signal_value(entity,{name="signal-hex",type="virtual"}) ~= 0
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

      local vs = format:format(v)
      displayValString(entity,vs,color)
    end
  else
    displayValString(entity)
  end
end

local function onTickAlpha(entity)
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


local function onTick(event)

  for _=1, settings.global["nixie-tube-update-speed-numeric"].value do
    local nixie
    if global.next_controller and not global.controllers[global.next_controller] then
      game.print("Invalid next_controller??")
      global.next_controller=nil
    end
    global.next_controller,nixie = next(global.controllers,global.next_controller)
    if nixie then onTickController(nixie) end
  end

  for _=1, settings.global["nixie-tube-update-speed-alpha"].value do
    local nixie
    if global.next_alpha and not global.alphas[global.next_alpha] then
      game.print("Invalid next_alpha??")
      global.next_alpha=nil
    end
    global.next_alpha,nixie = next(global.alphas,global.next_alpha)
    if nixie then onTickAlpha(nixie) end
  end
end

local function onPlaceEntity(event)

  local entity=event.created_entity
  if not entity.valid then return end

  local num = validEntityName[entity.name]
  if num then
    local pos=entity.position
    local surf=entity.surface

    local sprites = {}
    for n=1, num do
      --place the /real/ thing(s) at same spot
      local name, position
      if num == 1 then -- large tube, one sprite
        name = "nixie-tube-sprite"
        position = {x=pos.x+1/32, y=pos.y+1/32}
      else
        name = "nixie-tube-small-sprite"
        position = {x=pos.x-4/32+((n-1)*10/32), y=pos.y+4/32}
      end
      local sprite=surf.create_entity(
        {
              name=name,
              position=position,
            force=entity.force
        })
      sprite.orientation=0
      sprite.insert({name="coal",count=1})
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

local function onRemoveEntity(entity)
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
      local nextdigit = global.nextdigit[entity.unit_number]
      if nextdigit and nextdigit.valid then
        global.controllers[nextdigit.unit_number] = nextdigit
        displayValString(nextdigit)
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
end)

script.on_load(function()
  RegisterStrings()
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
      for _,sprite in pairs(surf.find_entities_filtered{name="nixie-tube-sprite"}) do
        removeSpriteObj(sprite)
      end
      for _,sprite in pairs(surf.find_entities_filtered{name="nixie-tube-small-sprite"}) do
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

script.on_event(defines.events.on_preplayer_mined_item, function(event) onRemoveEntity(event.entity) end)
script.on_event(defines.events.on_robot_pre_mined, function(event) onRemoveEntity(event.entity) end)
script.on_event(defines.events.on_entity_died, function(event) onRemoveEntity(event.entity) end)

script.on_event(defines.events.on_tick, onTick)

script.on_event(defines.events.on_player_driving_changed_state,
    function(event)
      local player=game.players[event.player_index]
      if player.vehicle and
        (player.vehicle.name=="nixie-tube-sprite" or
          player.vehicle.name=="nixie-tube-small-sprite") then
        player.vehicle.passenger=nil
      end
    end
  )
