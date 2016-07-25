require "config"

local ticksPerRefresh = math.ceil(60 / refresh_rate)

local function removeSpriteObjs(nixie)
  for k,obj in pairs(global.spriteobjs[nixie.unit_number]) do
    if obj.valid then
      obj.clear_items_inside()
      obj.destroy()
    end
  end
end

--12 frames for the light, so a step is 1/12...
local step=1/12
--build LuT to convert states into orientation values.
local stateOrientMap = {
  ["off"]=step*0,
  ["0"]=step*1,
  ["1"]=step*2,
  ["2"]=step*3,
  ["3"]=step*4,
  ["4"]=step*5,
  ["5"]=step*6,
  ["6"]=step*7,
  ["7"]=step*8,
  ["8"]=step*9,
  ["9"]=step*10,
  ["minus"]=step*11,
}

local function updateSprite(nixie,key)
  local obj = global.spriteobjs[nixie.unit_number][key]
  if obj and obj.valid then
    if nixie.energy > 70 then
      obj.orientation=stateOrientMap[global.states[nixie.unit_number][key]]
    else
      obj.orientation=0 --off state
    end
  else
    game.players[1].print("invalid nixie?")
  end
end

--sets the state, for now destroying and replacing the spriteobj if necessary
local function setStates(nixie,newstates)
  for key,new_state in pairs(newstates) do
    if new_state ~= global.states[nixie.unit_number][key] then
      global.states[nixie.unit_number][key]=new_state
      updateSprite(nixie,key)
    end
  end
end

-- from binbinhfr/SmartDisplay, modified to check both wires and add them
local function get_signal_value(entity)
	local behavior = entity.get_control_behavior()
	if behavior == nil then	return(nil)	end
	
	local condition = behavior.circuit_condition
	if condition == nil then return(nil) end
	
	local signal = condition.condition.first_signal
	
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

	return(val)
end

local function searchbox(nixie,direction)
  local offset = direction=="right" and 1 or -1
  return {
    {nixie.position.x+offset-0.1,nixie.position.y-0.1},
    {nixie.position.x+offset+0.1,nixie.position.y+0.1}
    }
end


local function onPlaceEntity(event)
  
  local entity=event.created_entity
  if not entity.valid then return end
  if entity.name=="nixie-tube" or entity.name=="nixie-tube-small" then
    local num = (entity.name=="nixie-tube-small") and 2 or 1
    local pos=entity.position
    local surf=entity.surface
    
    global.states[entity.unit_number]={}
    global.spriteobjs[entity.unit_number]={}
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
      local sprite=entity.surface.create_entity(
        {
              name=name,
              position=position,
            force=entity.force
        })
      sprite.orientation=0
      sprite.insert({name="coal",count=1})
      global.states[entity.unit_number][n]="off"
      global.spriteobjs[entity.unit_number][n]=sprite
    end
    --enslave guy to left, if there is one
    local neighbors=entity.surface.find_entities_filtered{area=searchbox(entity,"left"),name=entity.name}
    for _,n in pairs(neighbors) do
      if n.valid then
        global.controllers[n.unit_number] = nil
        global.nextdigit[entity.unit_number] = n
      end 
    end
    

    --slave self to right, if any
    local neighbors=entity.surface.find_entities_filtered{area=searchbox(entity,"right"),name=entity.name}
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

local function displayBlank(entity)
  local nextdigit = global.nextdigit[entity.unit_number]
  
  setStates(entity,(#global.states[entity.unit_number]==1) and {"off"} or {"off","off"})
  if nextdigit and nextdigit.valid then 
    displayBlank(nextdigit)
  end
end

local function displayMinus(entity)
  local nextdigit = global.nextdigit[entity.unit_number]
  
  setStates(entity,(#global.states[entity.unit_number]==1) and {"minus"} or {"off","minus"})
  if nextdigit and nextdigit.valid then 
    displayBlank(nextdigit)
  end
end 


local function displayValue(entity,v)
  local minus=v<0
  if minus then v=-v end
  local nextdigit = global.nextdigit[entity.unit_number]
  
  if #global.states[entity.unit_number] == 1 then
    local m=v%10
    v=(v-m)/10
    state = tostring(m)
    setStates(entity,{state})
    if nextdigit and nextdigit.valid then 
      if v == 0 and minus then 
        displayMinus(nextdigit)
      elseif minus then
        displayValue(nextdigit,-v)
      elseif v == 0 then
        displayBlank(nextdigit)
      else  
        displayValue(nextdigit,v)
      end
    end  
  else
    local m=v%100 -- two digits for this pair of nixies
    v=(v-m)/100 -- remove two digits from what's left
    local n=m%10 -- ones digit for this pair
    m=(m-n)/10 -- tens digit for this pair
    state2 = tostring(n)
    if m>0 or v>0 then
      state1 = tostring(m)
    elseif minus then
      state1 = "minus"
      minus = nil
    else
      state1 = "off"
    end
    setStates(entity,{state1,state2})
    
    if nextdigit and nextdigit.valid then 
      if v == 0 and minus then 
        displayMinus(nextdigit)
      elseif minus then
        displayValue(nextdigit,-v)
      elseif v == 0 then
        displayBlank(nextdigit)
      else  
        displayValue(nextdigit,v)
      end
    end
  end
end  

local function onTickController(entity) 
  if not entity.valid then
    onRemoveEntity(entity)
    return
  end
  
  local open=false
  for k,v in pairs(game.players) do
    if v.opened==entity then return end
  end
  
  local v=get_signal_value(entity)
  if v then 
    displayValue(entity,v)
  else
    displayBlank(entity)
  end
end 

local function onTick(event)
  if event.tick%ticksPerRefresh == 0 then
    for _,nixie in pairs(global.controllers) do
      onTickController(nixie) 
    end
  end
end


local function onRemoveEntity(entity)
  if entity.valid then
    if entity.name=="nixie-tube" or entity.name=="nixie-tube-small" then
      removeSpriteObjs(entity)
      --if I was a controller, deregister
      global.controllers[entity.unit_number]=nil
      --if I had a next-digit, register it as a controller
      local nextdigit = global.nextdigit[entity.unit_number]
      if nextdigit and nextdigit.valid then
        global.controllers[nextdigit.unit_number] = nextdigit
        displayBlank(nextdigit)
      end
    end
  end
end

script.on_init(function(data)
  global.controllers = {}
  global.states = {}
  global.spriteobjs = {}
  global.nextdigit = {}
end)  


script.on_configuration_changed(function(data)
  if data.mod_changes and data.mod_changes["nixie-tubes"] and global.nixie_tubes then
    global.controllers = {}
    global.states = {}
    global.spriteobjs = {}
    global.nextdigit = {}
    for _,surf in pairs(global.nixie_tubes.nixies) do
      for _,row in pairs(surf) do
        for _,desc in pairs(row) do
          if desc.entities[1] and desc.entities[1].valid then
            for _,s in pairs(desc.spriteobjs) do if s.valid then s.clear_items_inside() s.destroy() end end
            onPlaceEntity({created_entity=desc.entities[1]})
          end  
        end
      end
    end
    global.nixie_tubes = nil
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
