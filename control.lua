require "config"

local nixie_map = {}
local mod_version="0.2.1"
local mod_data_version="0.2.1"

local ticksPerRefresh = math.ceil(60 / refresh_rate)

---[[
local function print(...)
  return game.player.print(...)
end
--]]

--swap comment to toggle debug prints
--local function debug() end
local debug = function() end

if debug_mode then
  debug=print
end

function trace_nixies()
  debug("tracing nixie positions")
  for k,v in pairs(nixie_map) do
    str=k.." = { "
    for k2,v2 in pairs(v) do
      str=str..","..k2.." = { "
        for k3,v3 in pairs(v2) do
        str=str..","..k3
      end
    end
    str=str.."}}"
    debug(str)
  end
end

local function removeSpriteObjs(nixie_desc)
  if nixie_desc and nixie_desc.spriteobjs then
    for k,obj in ipairs(nixie_desc.spriteobjs) do
      if obj.valid then
        obj.clear_items_inside()
        obj.destroy()
  end
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

local function updateSprite(nixie_desc,key)
  local obj = nixie_desc.spriteobjs[key]
  if nixie_desc.has_power then
    obj.orientation=stateOrientMap[nixie_desc.states[key]]
    --nixie_desc.entity.active= (nixie_desc.state~="off")
  else
    obj.orientation=0 --off state
    --nixie_desc.entity.active=false
  end
end

local function updateSprites(nixie_desc)
  for key,obj in ipairs(nixie_desc.spriteobjs) do
    updateSprite(nixie_desc,key)
  end
end

--sets the state, for now destroying and replacing the spriteobj if necessary
local function setStates(nixie_desc,newstates)
  for key,new_state in ipairs(newstates) do
    if new_state ~= nixie_desc.states[key] then
      debug("states["..key.."] changed to "..new_state)
      debug("and nixie is "..(nixie_desc.spriteobjs[key]==nil and "nil" or "NOT nill"))
      nixie_desc.states[key]=new_state
      updateSprite(nixie_desc,key)
end
  end
end

local function deduceSignalValue(entity)
  local t=2^31
  local v=0

  local condition=entity.get_circuit_condition(1)
  if condition.condition.first_signal.name==nil then
    --no signal selected, so can't do anything
    return nil
  end
  if condition.condition.comparator=="=" and condition.fulfilled then
    --we leave the condition set to "= constant" where the constant is the deduced value; if
    --it's still so set, and still true, we can just return the constant.
    return condition.condition.constant
  end
  condition.condition.comparator="<"
  while t~=1 do
    condition.condition.constant=v
    entity.set_circuit_condition(1,condition)
    t=t/2
    if entity.get_circuit_condition(1).fulfilled==true then
      v=v-t
    else
      v=v+t
    end
  end
  condition.condition.constant=v
  entity.set_circuit_condition(1,condition)
  if entity.get_circuit_condition(1).fulfilled then
    --is still true, so value is still 1 less than v
    v=v-1
  end
  --set the state to = v, so we can quickly test out true if it hasn't changed
  condition.condition.constant=v
  condition.condition.comparator="="
  entity.set_circuit_condition(1,condition)
  return v
end


local function checkForMigration(old_version, new_version)
  -- TODO: when a migration is necessary, trigger it here or set a flag.
end


local function checkForDataMigration(old_data_version, new_data_version)
  -- TODO: when a migration is necessary, trigger it here or set a flag.

  if old_data_version < '0.1.9' then
    if global.nixie_tubes then
      for y,row in pairs(global.nixie_tubes.nixies) do
        for x,nixie in pairs(row) do
          -- old style has single values
          -- new style has an array/table of one or more values
          global.nixie_tubes.nixies[y][x].states = {nixie.state}
          global.nixie_tubes.nixies[y][x].state = nil
          global.nixie_tubes.nixies[y][x].entities = {nixie.entity}
          global.nixie_tubes.nixies[y][x].entity = nil
          global.nixie_tubes.nixies[y][x].spriteobjs = {nixie.spriteobj}
          global.nixie_tubes.nixies[y][x].spriteobj = nil
          global.nixie_tubes.nixies[y][x].size = 1
        end
      end
    end
  end
  
  if old_data_version < '0.2.0' then
    -- old style has indexes [y][x]
    -- new style has indexes [s][y][x] and a surface index propery
    local map = global.nixie_tubes.nixies
    local newmap = {}
    for y,v in pairs(map) do
      for x,d in pairs(v) do
        d.surf = d.entity.surface.index
        
		  if not newmap[d.surf] then
		    newmap[d.surf]={}
		  end
        if not newmap[d.surf][y] then
		    newmap[d.surf][y]={}
		  end
		  
		  newmap[d.surf][y][x]=d
      end
    end
    global.nixie_tubes.nixies=newmap
  end
    
  if old_data_version == '0.2.0' then
    for s,surf in pairs(global.nixie_tubes.nixies) do
      for y,row in pairs(surf) do
        for x,nixie in pairs(row) do
          -- old style has single values
          -- new style has an array/table of one or more values
          global.nixie_tubes.nixies[s][y][x].states = {nixie.state}
          global.nixie_tubes.nixies[s][y][x].state = nil
          global.nixie_tubes.nixies[s][y][x].entities = {nixie.entity}
          global.nixie_tubes.nixies[s][y][x].entity = nil
          global.nixie_tubes.nixies[s][y][x].spriteobjs = {nixie.spriteobj}
          global.nixie_tubes.nixies[s][y][x].spriteobj = nil
          global.nixie_tubes.nixies[s][y][x].size = 1
        end
      end
    end
  end
end


function onLoad()
  if not global.nixie_tubes then
    global.nixie_tubes={ nixies={} }
  end

  -- The only reason to have version/data_version is to trigger migrations, so do that here.
  if global.nixie_tubes.version then
    checkForMigration(global.nixie_tubes.version, mod_version)
  end
  if global.nixie_tubes.data_version then
    checkForDataMigration(global.nixie_tubes.data_version, mod_data_version)
  end

  -- After these lines, we can no longer check for migration.
  global.nixie_tubes.version=mod_version
  global.nixie_tubes.data_version=mod_data_version

  nixie_map=global.nixie_tubes.nixies
end


local function onPlaceEntity(event)
  local entity=event.created_entity
  if entity.name=="nixie-tube" or entity.name=="nixie-tube-small" then
    local num = (entity.name=="nixie-tube-small") and 2 or 1
    local pos=entity.position
    local surf=entity.surface.index
    local desc={
          size=num,
          pos=pos,
          surf=surf,
          states={},
          entities={},
          spriteobjs={},
       }
    for n=1, num do
      debug("placing #"..n)
      --place the /real/ thing(s) at same spot
      local name, position
      if num == 1 then -- large tube, one sprite
        name = "nixie-tube-sprite"
        position = {x=pos.x+1/32, y=pos.y+1/32}
      else 
        name = "nixie-tube-small-sprite"
        position = {x=pos.x-4/32+((n-1)*10/32), y=pos.y+4/32}
      end
      local nixie=entity.surface.create_entity(
        {
              name=name,
              position=position,
            force=entity.force
        })
      nixie.orientation=0
      nixie.insert({name="coal",count=1})
      debug("lamp pos = "..pos.x..","..pos.y)
      debug("car pos = "..nixie.position.x..","..nixie.position.y)
      desc.states[#desc.states+1]="off"
      desc.entities[#desc.entities+1]=entity
      desc.spriteobjs[#desc.spriteobjs+1]=nixie
    end
    --set me to look up the current entity from the interactive one
    if not nixie_map[entity.surface.index] then
      nixie_map[entity.surface.index]={}
    end
    if not nixie_map[entity.surface.index][entity.position.y] then
      nixie_map[entity.surface.index][entity.position.y]={}
    end
    trace_nixies()
    --enslave guy to left, if there is one
    local neighbor=nixie_map[surf][pos.y][pos.x-1]
    if neighbor and neighbor.size == desc.size then
      debug("enslaving dude on the left")
      neighbor.slave = true
      while neighbor and neighbor.size == desc.size do
        setStates(neighbor,(num==1) and {"off"} or {"off","off"})
        neighbor=nixie_map[neighbor.surf][neighbor.pos.y][neighbor.pos.x-1]
      end
    end
    --slave self to right, if any
    neighbor=nixie_map[surf][pos.y][pos.x+1]
    if neighbor and neighbor.size == desc.size then
      debug("slaving to dude on the right")
      desc.slave=true
    end
    nixie_map[surf][pos.y][pos.x] = desc

  end
end

local function onRemoveEntity(entity)
  if entity.valid then
    if entity.name=="nixie-tube" or entity.name=="nixie-tube-small" then
      local pos=entity.position
      local surf=entity.surface.index
      local nixie_desc=nixie_map[surf][pos.y] and nixie_map[surf][pos.y][pos.x]
      if nixie_desc then
        removeSpriteObjs(nixie_desc)
      nixie_map[surf][pos.y][pos.x]=nil
      --if I had a slave, unslave him
      local slave=nixie_map[surf][pos.y][pos.x-1]
      if slave and slave.size == nixie_desc.size then
        slave.slave=nil
          while slave and slave.size == nixie_desc.size do
            setStates(slave ,(#slave.states==1) and {"off"} or {"off","off"})
            slave=nixie_map[slave.surf][slave.pos.y][slave.pos.x-1]
          end
        end
      end
    end
  end
end

local function onTick(event)
  if event.tick%ticksPerRefresh == 0 then
    for s,surf in pairs(nixie_map) do
	   for y,row in pairs(surf) do
	     for x,desc in pairs(row) do
          for k,entity in pairs(desc.entities) do
            if entity.valid then
              if entity.energy<70 then
                if desc.has_power then
                  desc.has_power=false
                  updateSprites(desc)
                end
              elseif not desc.has_power then
                desc.has_power=true
                updateSprites(desc)
              end
            local open=false
            for k,v in pairs(game.players) do
              if v.opened==entity then
                open=true
                break
              end
            end
            if not open and not desc.slave then
              local v=deduceSignalValue(entity)
              local state="off"
              if v and desc.has_power then
                local minus=v<0
                if minus then v=-v end
                  local d=desc
                  repeat
                  if #d.states == 1 then
                    local m=v%10
                    v=(v-m)/10
                    state = tostring(m)
                    setStates(d,{state})
                  else
                    local m=v%100 -- two digits for this pair of nixies
                    v=(v-m)/100 -- remove two digits from what's left
                    local n=m%10 -- ones digit for this pair
                    m=(m-n)/10 -- tens digit for this pair
                    state2 = tostring(n)
                    if m>0 or v>0 then
                      state1 = tostring(m)
                    else
                      if minus then
                        state1 = "minus"
                        minus = nil
                      else
                        state1 = "off"
                      end
                    end
                    setStates(d,{state1,state2})
                  end
                  d=nixie_map[d.surf][d.pos.y][d.pos.x-1]
                  until d==nil or v==0 or d.size ~= desc.size
                  if d~=nil and minus and d.size == desc.size then
                    setStates(d,(#d.states==1) and {"minus"} or {"off","minus"})
                    d=nixie_map[d.surf][d.pos.y][d.pos.x-1]
                  end
                  while d and d.size == desc.size do
                    if d.energy==0 then
                      break
                    end
                    setStates(d,(#d.states==1) and {"off"} or {"off","off"})
	                 d=nixie_map[d.surf][d.pos.y][d.pos.x-1]
                  end
                else
                  local d=desc
                  while d and d.size == desc.size do
                    setStates(d,(#d.states==1) and {"off"} or {"off","off"})
	                 d=nixie_map[d.surf][d.pos.y][d.pos.x-1]
                  end
                end
              end
            else
              onRemoveEntity(entity)
            end  
          end
        end
      end
    end
  end
end



script.on_init(onLoad)
script.on_load(onLoad)

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
