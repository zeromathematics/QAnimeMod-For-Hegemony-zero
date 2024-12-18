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

-- translation for StrategicAdvantage Package

return {
	["strategic_advantage"] = "君临天下·势备篇",

	["transfer"] = "连横",

	["Blade"] = "楼观剑",
        [":Blade"] = "装备牌·武器\n\n攻击范围：3\n技能：锁定技，你使用【杀】时，目标角色不能明置人物牌直到此次使用牌结算完毕。",

	["Halberd"] = "湖中剑",
	[":Halberd"] = "装备牌·武器\n\n攻击范围：4\n技能：你使用的【杀】可以指定任意名势力各不相同的角色及未确定势力的角色为目标。当此【杀】被一名目标角色使用【闪】抵消时，此【杀】对其他目标角色无效。",
	["#HalberdUse"] = "%from 发动了【<font color=\"yellow\"><b>湖中剑</b></font>】效果",
	["#HalberdNullified"] = "由于【%arg】的效果，%from 对 %to 使用的【%arg2】无效",
	["@halberd_extra_targets"] = "你可以发动【湖中剑】为此【杀】选择额外目标",
	["@Halberd"] = "你发动了【湖中剑】，请选择本次使用【杀】的目标",

	["Breastplate"] = "AT力场",
	[":Breastplate"] = "装备牌·防具\n\n技能：每当你受到伤害时，若此伤害不小于你的体力值，你可以将此牌从装备区置入弃牌堆，防止此伤害。",
	["#Breastplate"] = "%from 防止了 %to 对其造成的 %arg 点伤害[%arg2]",

	["IronArmor"] = "湛蓝",
        [":IronArmor"] = "装备牌·防具\n\n技能：每当你成为【天破壤碎】、【异端审判】或火【杀】的目标时，你取消自己；若你是小势力角色，你的人物牌不能被横置。",
	["#IronArmor"] = "%from 的装备技能【%arg】被触发",

	["WoodenOx"] = "虚茧",
	[":WoodenOx"] = "装备牌·宝物\n\n技能：\n" ..
					"1. 出牌阶段限一次，你可以将一张手牌置于【虚茧】下，若如此做，你可以将【虚茧】移动至一名其他角色的装备区。\n" ..
					"2. 你可以将【虚茧】下的牌视为手牌使用或打出。\n" ..
					"◆每当你失去装备区的【虚茧】后，若【虚茧】未移动至装备区，其下的牌置入弃牌堆，否则这些牌仍置于【虚茧】下。\n◆【虚茧】下的牌为移出游戏。",
	["@wooden_ox-move"] = "你可以将【虚茧】移动至一名其他角色的装备区",
	["wooden_ox"] = "虚茧",
	["#WoodenOx"] = "%from 使用/打出了 %arg 张 %arg2 牌",

	["JadeSeal"] = "圣杯",
        [":JadeSeal"] = "装备牌·宝物\n\n技能：锁定技，若你有明置的人物牌，则：你所属的势力成为唯一的大势力；摸牌阶段摸牌时，你额外摸一张牌；出牌阶段开始时，你视为使用一张【心灵读取】。",
	["@JadeSeal"] = "你可以发动【圣杯】，视为你使用一张【心灵读取】",
	["~JadeSeal"] = "选择【心灵读取】的目标→点击确定",

	["drowning"] = "超电磁炮",
	[":drowning"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：一名装备区里有牌的其他角色。\n作用效果：目标角色选择一项：1.弃置装备区里的所有牌；2.受到你造成的1点雷电伤害。",
	["drowning:throw"] = "弃置装备区里的所有牌",
	["drowning:damage"] = "受到其造成的1点雷电伤害",

	["burning_camps"] = "天破壤碎",
	[":burning_camps"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：你的下家和除其外与其处于同一队列的所有角色。\n作用效果：目标角色受到你造成的1点火焰伤害。",

	["lure_tiger"] = "存在缺失",
	[":lure_tiger"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：至多两名其他角色。\n作用效果：目标角色于此回合结束之前不计入距离和座次计算且不能使用牌且不是牌的合法目标。\n执行动作：此牌结算结束时，你摸一张牌。",
	["lure_tiger_effect"] = "存在缺失",
	["#lure_tiger-prohibit"] = "存在缺失",

	["fight_together"] = "八方鬼缚",
	[":fight_together"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有大势力角色或所有小势力角色。\n作用效果：若目标角色：不处于连环状态，其横置；处于连环状态，其摸一张牌。\n◆此牌能重铸。",
	["fight_together:big"] = "大势力",
	["fight_together:small"] = "小势力",

	["alliance_feast"] = "狂欢聚会",
	[":alliance_feast"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：你和你选择的除你的势力外的一个势力的所有角色。\n作用效果：若目标对应的角色：为你，你摸X张牌，回复（Y-X）点体力（Y为该势力的角色数）（X为你选择的自然数且不大于Y）；不为你，其摸一张牌，重置。",
	["alliance_feast:recover"] = "回复1点体力",
	["alliance_feast:draw"] = "摸一张牌，然后重置",
	["alliancefeast_draw"] = "选择回复的体力值",

	["threaten_emperor"] = "SOS社团活动",
	[":threaten_emperor"] = "锦囊牌\n\n使用时机：非此锦囊牌获得的额外回合的出牌阶段。\n使用目标：为大势力角色的你。\n作用效果：以下情况，此牌对目标无效：1，当前回合为以此法获得的额外回合；2，当前回合为使用者的额外回合且目标不为使用者。否则执行：阶段一：使用者若处在出牌阶段，结束出牌阶段，阶段持续到当前回合结束时；阶段二：目标可以弃置一张手牌，获得一个额外的回合。",
	["@threaten_emperor"] = "受到【SOS社团活动】影响，你可以弃置一张手牌，获得一个额外的回合",

	["imperial_order"] = "令咒",
        [":imperial_order"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：所有没有势力的角色。\n作用效果：目标角色选择一项：1. 明置一张人物牌，然后摸一张牌；2. 弃置一张装备牌；3. 失去1点体力。\n\n※若此牌未因使用此效果而进入弃牌堆时，则改为将此牌移出游戏，然后于此回合结束时当前回合角色可以视为对所有未确定势力的角色使用此牌。",
	["@imperial_order-equip"] = "令咒效果，选择一张装备牌弃置",
        ["imperial_order:show"] = "明置一张人物牌，然后摸一张牌",
	["imperial_order:losehp"] = "失去1点体力",
	["#RemoveImperialOrder"] = "【%arg】因使用其效果以外的原因进入弃牌堆，将被移出游戏",
	["#ImperialOrderEffect"] = "%from 的回合结束，【%arg】因被移出游戏生效",
	["#CancelOutsideCardMovement"] = "【%arg】因在游戏外，不参与此次移动",
}
