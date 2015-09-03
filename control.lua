require "config"

local nixie_map = {}
local mod_version="0.1.6"
local mod_data_version="0.1.0"

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
      str=str..k2
    end
    str=str.."}"
    debug(str)
  end
end

local function removeSpriteObj(nixie_desc)
  if nixie_desc and nixie_desc.spriteobj and nixie_desc.spriteobj.valid then
    nixie_desc.spriteobj.clear_items_inside()
    nixie_desc.spriteobj.destroy()
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

local function updateSprite(nixie_desc)
  if nixie_desc.has_power then
    nixie_desc.spriteobj.orientation=stateOrientMap[nixie_desc.state]
    --nixie_desc.entity.active= (nixie_desc.state~="off")
  else
    nixie_desc.spriteobj.orientation=0 --off state
    --nixie_desc.entity.active=false
  end
end

--sets the state, for now destroying and replacing the spriteobj if necessary
local function setState(nixie_desc,newstate)
  if newstate==nixie_desc.state then
    return
  end


  debug("state changed to "..newstate)
  debug("and nixie is "..(nixie_desc.spriteobj==nil and "nil" or "NOT nill"))
  nixie_desc.state=newstate
  updateSprite(nixie_desc)
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

function onSave()
  global.nixie_tubes={nixies=nixie_map, version=mod_version, data_version=mod_data_version}
end



function onLoad()

  if not global.nixie_tubes then
    global.nixie_tubes={
        nixies={},
        version=mod_version,
        data_version=mod_data_version,
      }
  end

  nixie_map=global.nixie_tubes.nixies
end

local function onPlaceEntity(event)
  local entity=event.created_entity
  if entity.name=="nixie-tube" then
    debug("placing")
    --place the /real/ thing at same spot
    local pos=entity.position
    local nixie=entity.surface.create_entity(
        {
            name="nixie-tube-sprite",
            position={x=pos.x+1/32, y=pos.y+1/32},
            force=entity.force
        })
    nixie.orientation=0
    nixie.insert({name="coal",count=1})
    --set me to look up the current entity from the interactive one
    if not nixie_map[entity.position.y] then
      nixie_map[entity.position.y]={}
    end
    debug("lamp pos = "..pos.x..","..pos.y)
    debug("car pos = "..nixie.position.x..","..nixie.position.y)
    local desc={
          pos=pos,
          state="off",
          entity=entity,
          spriteobj=nixie,
       }
    trace_nixies()
    --enslave guy to left, if there is one
    local neighbor=nixie_map[pos.y][pos.x-1]
    if neighbor then
      debug("enslaving dude on the left")
      neighbor.slave = true
      while neighbor do
        setState(neighbor,"off")
        neighbor=nixie_map[neighbor.pos.y][neighbor.pos.x-1]
      end
    end
    --slave self to right, if any
    neighbor=nixie_map[pos.y][pos.x+1]
    if neighbor then
      debug("slaving to dude on the right")
      desc.slave=true
    end
    nixie_map[pos.y][pos.x] = desc

  end
end

local function onRemoveEntity(entity)
  if entity.name=="nixie-tube" then
    local pos=entity.position
    local nixie_desc=nixie_map[pos.y] and nixie_map[pos.y][pos.x]
    if nixie_desc then
      removeSpriteObj(nixie_desc)
      nixie_map[pos.y][pos.x]=nil
      --if I had a slave, unslave him
      local slave=nixie_map[pos.y][pos.x-1]
      if slave then
        slave.slave=nil
        while slave do
          setState(slave,"off")
          slave=nixie_map[slave.pos.y][slave.pos.x-1]
        end
      end
    end
  end
end

local function onTick(event)
  --only update five times a second, rather than *every* tick.
  --7th of 12 picked at random.
  if event.tick%12 == 7 then
    for y,row in pairs(nixie_map) do
      for x,desc in pairs(row) do
        if desc.entity.valid then
          if desc.entity.energy<70 then
            if desc.has_power then
              desc.has_power=false
              updateSprite(desc)
            end
          elseif not desc.has_power then
            desc.has_power=true
            updateSprite(desc)
          end
          if not desc.slave then
            local v=deduceSignalValue(desc.entity)
            local state="off"
            if v and desc.has_power then
              local minus=v<0
              if minus then v=-v end
              local d=desc
              repeat
                local m=v%10
                v=(v-m)/10
                state = tostring(m)
                setState(d,state)
                d=nixie_map[d.pos.y][d.pos.x-1]
              until d==nil or v==0
              if d~=nil and minus then
                setState(d,"minus")
                d=nixie_map[d.pos.y][d.pos.x-1]
              end
              while d do
                if d.energy==0 then
                  break
                end
                setState(d,"off")
                d=nixie_map[d.pos.y][d.pos.x-1]
              end
            else
              local d=desc
              while d do
                setState(d,"off")
                d=nixie_map[d.pos.y][d.pos.x-1]
              end
            end
          end
        else
          onRemoveEntity(desc.entity)
        end
      end
    end
  end
end



game.on_init(onLoad)
game.on_load(onLoad)

game.on_save(onSave)

game.on_event(defines.events.on_tick,function() end)

game.on_event(defines.events.on_built_entity,onPlaceEntity)
game.on_event(defines.events.on_robot_built_entity,onPlaceEntity)

game.on_event(defines.events.on_preplayer_mined_item, function(event) onRemoveEntity(event.entity) end)
game.on_event(defines.events.on_robot_pre_mined, function(event) onRemoveEntity(event.entity) end)
game.on_event(defines.events.on_entity_died, function(event) onRemoveEntity(event.entity) end)

game.on_event(defines.events.on_tick, onTick)

game.on_event(defines.events.on_player_driving_changed_state,
    function(event)
      local player=game.players[event.player_index]
      if player.vehicle and player.vehicle.name=="nixie-tube-sprite" then
        player.vehicle.passenger=nil
      end
    end
  )
