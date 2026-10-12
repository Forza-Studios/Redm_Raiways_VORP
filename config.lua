--######################### edit for VORP by: outsider ########################
Config = {}

-- https://alloc8or.re/rdr3/doc/enums/eTrainConfig.txt  >>>>>>>>>> full list imported below

-- Add new trains in Config.Trains, menu + client support any count automatically
Config = {
	Job = "police", -- the only job to open train menu
	AllowDriving = false, -- false = passengers only, driver seat locked (like coi_train_rob)
	ShowExperimental = false, -- true = also list all 70+ _0x... configs from eTrainConfig (many are broken/test, can crash)
}

-- Full usable set from https://alloc8or.re/rdr3/doc/enums/eTrainConfig.txt
-- Named = Rockstar tested. Numeric = works but unidentified (kept from old trainmodel1-14).
Config.Trains = {
	{ label = "passenger long",      hash = 0x3ADC4DA9, desc = "spawn a long train" },
	{ label = "passenger consist",   hash = 0xCD2C7CA1, desc = "stable passenger (same as train_rob)" },
	{ label = "prisoner escort",     hash = 0x515E31ED, desc = "spawn a train" },
	{ label = "winter4",             hash = 0x487B2BE7, desc = "spawn a train" },
	{ label = "appleseed",           hash = 0x8EAC625C, desc = "spawn an electric train" },
	{ label = "bountyhunter",        hash = 0xF9B038FC, desc = "spawn a train" },
	{ label = "locomotive (engine)", hash = 0x3260CE89, desc = "spawn a locomotive" },
	{ label = "dummy engine",        hash = 0x26509FBB, desc = "engine test shell" },
	{ label = "ghost train",         hash = 0x0E62D710, desc = "spawn a train" },
	{ label = "gunslinger3",         hash = 0x3D72571D, desc = "spawn a train" },
	{ label = "gunslinger4",         hash = 0x5AA369CA, desc = "spawn a long train" },
	{ label = "handcart",            hash = 0x3EDA466D, desc = "spawn a hand cart" },
	{ label = "mine cart",           hash = 0xC75AA08C, desc = "spawn a mine cart" },
	{ label = "industry2 (real)",    hash = 0x767DEB32, desc = "spawn a train" },
	{ label = "trolley (city)",      hash = 0xBF69518F, desc = "city trolley, short track only" },
	{ label = "big train 2",         hash = 0x005E03AD, desc = "spawn a train" },
	{ label = "industry2 (alt)",     hash = 0x0660E567, desc = "spawn a train" },
	{ label = "big train",           hash = 0x0392C83A, desc = "spawn a train" },
}

-- Back-compat for old trainmodel1-14 references (mapped to above)
Config.trainmodel1 = 0x3ADC4DA9
Config.trainmodel2 = 0x515E31ED
Config.trainmodel3 = 0x487B2BE7
Config.trainmodel4 = 0x8EAC625C
Config.trainmodel5 = 0xF9B038FC
Config.trainmodel6 = 0x005E03AD
Config.trainmodel7 = 0x3260CE89
Config.trainmodel8 = 0x0E62D710
Config.trainmodel9 = 0x3D72571D
Config.trainmodel10 = 0x5AA369CA
Config.trainmodel11 = 0x3EDA466D
Config.trainmodel12 = 0x0660E567
Config.trainmodel13 = 0xC75AA08C
Config.trainmodel14 = 0x0392C83A

-- Every other hash in eTrainConfig. Mostly test/duplicate/broken. Only added when ShowExperimental=true.
Config.ExperimentalHashes = {
	0x0941ADB7, 0x09B679D6, 0x0CCC2F70, 0x0D03C58D, 0x10461E19, 0x124A1F89,
	0x19A0A288, 0x1C043595, 0x1C9936BB, 0x1EEC5C2A, 0x1EF82A51, 0x25E5D8FF,
	0x29C81ACB, 0x2D1A6F0C, 0x2D3645FA, 0x31656D23, 0x35D17C43, 0x41436136,
	0x4A73E49C, 0x4C9CCB22, 0x57C209C4, 0x592A5CD0, 0x5D9928A4, 0x68CF495F,
	0x6CC26E27, 0x6D69A954, 0x73722125, 0x761CE0AD, 0x7BD58C4D, 0x8864D73A,
	0x8D0766BC, 0x90CB53CA, 0x9296570E, 0x96563327, 0x98427740, 0x9897FF51,
	0x998A0CBC, 0x9CBE6FEC, 0x9E096E46, 0xA3BF0BEB, 0xA8B1CEB7, 0xA91041A2,
	0xAA3E691E, 0xAC18A9F4, 0xAEE0ECF5, 0xC1F1DD80, 0xC732CDC8, 0xCA19C62A,
	0xD233B18D, 0xD42DD3EE, 0xD5DF2D82, 0xD8CF6395, 0xD92B16AE, 0xD93C36C2,
	0xDA2EDE2F, 0xDC9DD041, 0xDD920DAF, 0xE0898B89, 0xE16CA3EF, 0xEB8B2439,
	0xEF9FC71D, 0xEFBFBDD8, 0xF19E48CA, 0xF6AA98F4, 0xFAB2FFB9, 0xFAC328F0, 0xFD8810E8,
}
Config.Location = vector3(-162.8994, 638.43988, 114.03205) -- location of the menu

--- train stations where the train stops
-- dont touch if you dont know what you are doing
Config.Stops = {

	{ dst = 180.0, dst2 = 4.0, x = -142.67, y = 654.18, z = 113.52, time = 60000, name = "Valentine Station" },
	{ dst = 400.0, dst2 = 4.0, x = 2685.39, y = -1480.33, z = 45.80, time = 60000, name = "Saint Denis Station" },
	{ dst = 220.0, dst2 = 4.0, x = 1197.48, y = -1282.29, z = 76.45, time = 60000, name = "Rhodes Station" },
	{ dst = 220.0, dst2 = 4.0, x = -379.38, y = -369.51, z = 86.44, time = 30000, name = "Flatneck Station" },
	{ dst = 180.0, dst2 = 4.0, x = -1118.27, y = -567.17, z = 82.67, time = 30000, name = "Riggs Station" },
	{ dst = 180.0, dst2 = 4.0, x = -1291.04, y = 440.69, z = 94.36, time = 30000, name = "Wallace Station" },
	{ dst = 180.0, dst2 = 4.0, x = 610.54, y = 1661.53, z = 188.0, time = 30000, name = "Bacchus Station" },
	{ dst = 220.0, dst2 = 4.0, x = 2914.50, y = 1238.53, z = 44.73, time = 60000, name = "Annesburg Station" },
	{ dst = 180.0, dst2 = 4.0, x = 2879.30, y = 592.75, z = 57.84, time = 60000, name = "Van Horn Tradin Post" }
}

--  leave in on place theres only one train that can operate at the time
Config.RailroadNpc = {
	valentine = {
		Model = "U_M_M_RhdTrainStationWorker_01", -- npc model
		Pos = vector3(-162.5611, 638.82128, 114.03203 - 1), -- npc location add the same as the location of the menu
		Heading = 148.31669 -- heading of the npc
	},

}

--################ DONT TOUCH VALUE AND INFO #########################
--ONLY translate LABEL
--ONLY translate DESC
-- Built dynamically from Config.Trains (+ experimental when enabled) so menu supports any count.

Config.Elements = {}
for i, t in ipairs(Config.Trains) do
	Config.Elements[#Config.Elements + 1] = { label = t.label, value = 'train_' .. i, desc = t.desc, info = t.hash }
end
if Config.ShowExperimental then
	for _, h in ipairs(Config.ExperimentalHashes) do
		Config.Elements[#Config.Elements + 1] = { label = string.format("exp_%08X", h), value = 'exp', desc = "experimental, may crash", info = h }
	end
end
--TRANSLATE
Press = "Press"
TrainPrompt = "Valentine Conductor"
MenuTittle = "RAIL ROAD"
MenuSubTittle = "Valentine"
