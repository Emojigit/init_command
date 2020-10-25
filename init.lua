init_command = {}
local ms = minetest.get_mod_storage()
-- ms:set_string(key, value)
-- ms:get_string(key)
-- minetest.serialize(table)
-- minetest.deserialize(string,true)
init_command.run_command = function(owner,command)
  local pos = command:find(" ")
  local cmd, param = command, ""
  if pos then
    cmd = command:sub(1, pos - 1)
    param = command:sub(pos + 1)
  end
  if cmd == "initc" or cmd == "leftc" then
    return
  end
  local cmddef = minetest.chatcommands[cmd]
  if not cmddef then
    minetest.chat_send_player(owner, "The command "..cmd.." does not exist")
    return
  end
  local has_privs, missing_privs = minetest.check_player_privs(owner, cmddef.privs)
  if not has_privs then
    minetest.chat_send_player(owner, "You don't have permission "
      .."to run "..cmd
      .." (missing privileges: "
      ..table.concat(missing_privs, ", ")..")")
    return
  end
  cmddef.func(owner, param)
end

minetest.register_chatcommand("initc",{
  params = "[command] [param]",
  description = "Set up command that auto run on startup, leave blank to disable.",
  func = function(name,param)
    local cmds = minetest.deserialize(ms:get_string("initc"),true) or {}
    cmds[name] = param
    ms:set_string("initc",minetest.serialize(cmds))
  end,
})

minetest.register_chatcommand("leftc",{
  params = "[command] [param]",
  description = "Set up command that auto run on startup, leave blank to disable.",
  func = function(name,param)
    local cmds = minetest.deserialize(ms:get_string("leftc"),true) or {}
    cmds[name] = param
    ms:set_string("leftc",minetest.serialize(cmds))
  end,
})

minetest.register_on_leaveplayer(function(ObjectRef, timed_out)
  local name = ObjectRef:get_player_name()
  if not name then return end
  local cmds = minetest.deserialize(ms:get_string("leftc"),true)
  local cmd = cmds and cmds[name]
  init_command.run_command(name,cmd or "")
end)

minetest.register_on_joinplayer(function(ObjectRef, last_login)
  local name = ObjectRef:get_player_name()
  if not name then return end
  local cmds = minetest.deserialize(ms:get_string("initc"),true)
  local cmd = cmds and cmds[name]
  minetest.after(1,init_command.run_command,name,cmd or "")
end)
