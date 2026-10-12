fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"
author '_forza'
description 'Custom railway system for RedM Vorp framework'
lua54 'yes'

client_scripts {
	'client/client.lua',
	'client/npc.lua',

}
shared_script 'config.lua'

server_script 'server.lua'

dependency 'vorp_menu'
