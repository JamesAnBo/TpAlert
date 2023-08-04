addon.name      = 'tpalert';
addon.author    = 'Aesk';
addon.version   = '0.0.1';
addon.desc      = 'Alerts when party members get tp';
addon.link      = 'https://github.com/JamesAnBo/tpalert';

require('common')
local chat = require('chat');
local settings = require('settings');

local default_settings = T{
	messages = true,
	playsound = true,
	sound = 'sound07.wav',
};

local tpalert = T{
	track_member = T{},
	settings = settings.load(default_settings),
};

local function update_settings(s)
    -- Update the settings table..
    if (s ~= nil) then
        tpalert.settings = s;
    end

    -- Save the current settings..
    settings.save();
end

settings.register('settings', 'settings_update', update_settings);

function checkPartyTP()
	local party = AshitaCore:GetMemoryManager():GetParty();

	for i = 0, 5 do
	
		local isInZone = party:GetMemberZone(i) == party:GetMemberZone(0);
		local active = party:GetMemberIsActive(i);
		local serverId = party:GetMemberServerId(i);
		local memberName = string.lower(party:GetMemberName(i));
		local memberTP = party:GetMemberTP(i);
		
		if (isInZone) and (active == 1) and (serverId ~= 0) then
			for k, v in pairs(tpalert.track_member) do
				if (k == memberName) then
					if (memberTP >= 1000) then
						tpalert.track_member[k].count = (tpalert.track_member[k].count + 1)
						if (tpalert.settings.playsound == true) and (tpalert.track_member[k].count <= 1) then
							ashita.misc.play_sound(addon.path:append('\\sounds\\'):append(tpalert.settings.sound));
							PPrint(memberName..' has tp.');
						end
					else
						tpalert.track_member[k].count = 0;
					end
				end
			end
		end
	end
end

ashita.events.register('unload', 'unload_cb', function ()
	settings.save();
end);

ashita.events.register('d3d_present', 'present_cb', function ()
	local next = next
	if next(tpalert.track_member) then
		checkPartyTP();
	end
end);

ashita.events.register('command', 'command_cb', function (e)

    local args = e.command:args();
	
    if (#args == 0 or (args[1] ~= '/tpa' and args[1] ~= '/tpalert')) then
        return;
    else
        e.blocked = true;
        local cmd = args[2];
		
		if (cmd:any('add', 'track')) then
			local name_lower = string.lower(args[3]);
			local tbl = {
				count = 0,
				};
			tpalert.track_member[name_lower] = tbl;
			PPrint(name_lower..' added to tracking list');
		elseif (cmd:any('reset', 'clear')) then
			tpalert.track_member = T{};
			PPrint('tracking list cleared');
		elseif cmd:any('list') then
			local next = next 

			if next(tpalert.track_member) then
				for k, v in pairs(tpalert.track_member) do
					PPrint('['..k..']: '..tpalert.track_member[k].count);
				end
			else
				PPrint('tracking list is empty');
			end
		elseif tpalert.settings:containskey(cmd) then
			if (cmd:any('sound', 'alert', 'ding')) then
				if (#args == 2) then
					tpalert.settings.playsound = not tpalert.settings.playsound;
					local outText = '%s: %s'
					print(chat.header(addon.name):append(chat.message(outText):fmt(cmd, tpalert.settings.playsound and 'on' or 'off')));
				elseif (#args == 3) then
					local num = tonumber(args[3])
					if (num <= 0) or (num > 7) then
						PPrint('Choose alert 1-7.');
					else
						tpalert.settings.sound = ('sound0'..args[3]..'.wav')
						PPrint('Alert changed to '..args[3]);
					end
				end
				if (tpalert.settings.playsound == true) then
					ashita.misc.play_sound(addon.path:append('\\sounds\\'):append(tpalert.settings.sound));
				end
			elseif (#args == 2) then
				tpalert.settings[cmd] = not tpalert.settings[cmd];
				local outText = '%s: %s'
				print(chat.header(addon.name):append(chat.message(outText):fmt(cmd, tpalert.settings[cmd] and 'on' or 'off')));
			end
		end
	end
end);


function PPrint(txt)
	if (tpalert.settings.messages == true) then
		print(chat.header(addon.name):append(chat.message(txt)));
	end
end