--[[********************************************************************
	Copyright (c) 2013-2015 Mogara

  This file is part of QSanguosha-Hegemony.

  This game is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License as
  published by the Free Software Foundation; either version 3.0
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  General Public License for more details.

  See the LICENSE file for more details.

  Mogara
*********************************************************************]]

-- this script to store the basic configuration for game program itself
-- and it is a little different from config.ini

config = {
	kingdoms = {"science", "real", "magic", "game", "idol", "careerist", "god"--[["idol|real", "science|idol", "magic|science", "magic|real", "science|real", "real|game", "magic|game", "science|game",]], "WOF", "Titan" },
	kingdom_colors = {
		god = "#96943D",
		wei = "#615E5D",
		shu = "#F00C95",
		wu = "#0CF0EC",
		qun = "#F5ED07",
		science = "#615E5D",
		magic = "#F00C95",
		game = "#0CF0EC",
		real = "#F5ED07",
		WOF = "#C0C0C0",
		careerist = "#A500CC",
        idol = "#FF9EAC",  
	},

	skill_colors = {
		compulsory = "#0000FF",
		once_per_turn = "#008000",
		limited = "#FF0000",
		head = "#00FF00",
		deputy = "#00FFFF",
		array = "#800080",
		lord = "#FFA500",
		linkage = "#EE00FF",
        state = "#9D00FF",
		clubskill = "#C71585",
		clubskilladd = "#C71585",
		clubskilleffect = "#C71585",
		magicskill = "#F00C95",
		scienceskill = "#615E5D",
		realskill = "#F5ED07",
		gameskill = "#0CF0EC",
        idolskill = "#FF9EAC",	
	},

	-- Sci-fi style background
	--dialog_background_color = "#49C9F0";
	--dialog_background_alpha = 75;
	dialog_background_color = "#D6E7DB";
	dialog_background_alpha = 255;

	package_names = {
	    "NewtestCard",
		"RevolutionCard",
		"FadingCard",
		"StandardCard",
		"SpecialCard",
		"FormationEquip",
		"MomentumEquip" ,
		"StrategicAdvantage",
		"TransformationEquip",

		"Newtest",
		"Revolution",
		"Fading",
		"Standard",
		"Test",
		"Formation",
		"Momentum",
		--"JiangeDefense",
		"Transformation",
		"MariaBattle"
	},

	easy_text = {
		"太慢了，做两个俯卧撑吧！",
		"快点吧，我等的花儿都谢了！",
		"高，实在是高！",
		"好手段，可真不一般啊！",
		"哦，太菜了。水平有待提高。",
		"你会不会玩啊？！",
		"嘿，一般人，我不使这招。",
		"呵，好牌就是这么打地！",
		"杀！神挡杀神！佛挡杀佛！",
		"你也忒坏了吧？！"
	},

	robot_names = {
		"正義の味方",
		"俺様最強！", 
		"梨子是我的！！！", 
		"真爱有颜色一定是蓝色",
		"人被杀就会死",
		"战斗力只有五的渣滓",
		"你们都是我的翅膀",
		"爱蜜莉雅紫",
		"这个笑容由我来守护",
		"绿皮杀杀杀",
		"非凡铁索秒大现",
		"红皮gogogo",
		"现世的倔强",
		"大偶像可兴" ,
		"我们画风不一样",
		"我不是蓝皮",
		"男人变态有什么错",
		"自古枪兵幸运E",
		"我不做人啦JOJO！",
		"这腿我能玩一年" ,
		"我变秃了，也变强了" ,
		"比博燃" ,
		"教练，我想学篮球" ,
		"世界线收束" ,
		"快按住老虚" ,
		"自古红蓝出cp" ,
		"都是时辰的错" ,
		"真相只有一个" ,
		"小哥，买苹果吗" ,
		"龙王的狱友" ,
		"遇事不决，量子力学" ,
		"你为什么这么熟练啊" ,
		"茉纳你坐啊" ,
		"橘里橘气" ,
		"为王的诞生献上礼炮" ,
		"可爱即正义" ,
		"诸君，我喜欢战争" ,
		"一切都是世界的错" ,
		"烧死那对异性恋" ,
		"这么可爱一定是" ,
		"还能再战500年" ,
		"自带bgm的男人" ,
		"欠夏娜一个萌王" ,
		"EX咖喱棒" ,
		"不要停下来啊团长" ,
		"你已经死了" ,
	},
}
