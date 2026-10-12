--######################### edit for VORP by: outsider ########################
Config = {}

-- https://alloc8or.re/rdr3/doc/enums/eTrainConfig.txt  >>>>>>>>>> for more train models

-- DONT ADD MORE >>> only replace ^^^^^ in that link you find more
-- replace only the hash number
Config = {
	Job = "police", -- the only job to open train menu
	trainmodel1 = 987516329,
	trainmodel2 = 0x515E31ED,
	trainmodel3 = 0x487B2BE7,
	trainmodel4 = 0x8EAC625C,
	trainmodel5 = 0xF9B038FC,
	trainmodel6 = 0x005E03AD,
	trainmodel7 = 0x3260CE89,
	trainmodel8 = 0x0E62D710,
	trainmodel9 = 0x3D72571D,
	trainmodel10 = 0x5AA369CA,
	trainmodel11 = 0x3EDA466D,
	trainmodel12 = 0x0660E567,
	trainmodel13 = 0xC75AA08C,
	trainmodel14 = 0x0392C83A,
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

Config.Elements = {
	{ label = "passenger train", value = 'hash1', desc = "spawn a long train ", info = Config.trainmodel1 },
	{ label = "prisoner escort", value = 'hash2', desc = "spawn a train ", info = Config.trainmodel2 },
	{ label = "winter4", value = 'hash3', desc = "spawn a train ", info = Config.trainmodel3 },
	{ label = "appleseed", value = 'hash4', desc = "spawn an electric train", info = Config.trainmodel4 },
	{ label = "bountyhunter", value = 'hash5', desc = "spawn a train ", info = Config.trainmodel5 },
	{ label = "big train 2", value = 'hash6', desc = "spawn a train ", info = Config.trainmodel6 },
	{ label = "locomotive", value = 'hash7', desc = "spawn a locomotive ", info = Config.trainmodel7 },
	{ label = "ghost train", value = 'hash8', desc = "spawn a train ", info = Config.trainmodel8 },
	{ label = "gunslinger3", value = 'hash9', desc = "spawn a train ", info = Config.trainmodel9 },
	{ label = "gunslinger4", value = 'hash10', desc = "spawn a long train ", info = Config.trainmodel10 },
	{ label = "handcart", value = 'hash11', desc = "spawn a hand cart ", info = Config.trainmodel11 },
	{ label = "industry2", value = 'hash12', desc = "spawn a train ", info = Config.trainmodel12 },
	{ label = "mine cart", value = 'hash13', desc = "spawn a mine cart ", info = Config.trainmodel13 },
	{ label = "big train", value = 'hash14', desc = "spawn a train ", info = Config.trainmodel14 },


}
--TRANSLATE
Press = "Press"
TrainPrompt = "Valentine Conductor"
MenuTittle = "RAIL ROAD"
MenuSubTittle = "Valentine"
