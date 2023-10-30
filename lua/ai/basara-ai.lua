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

--珠联璧合标记
local companion_skill = {}
companion_skill.name = "companion"
table.insert(sgs.ai_skills, companion_skill)
companion_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@companion") < 1 then return end
	return sgs.Card_Parse("@CompanionCard=.&")
end

sgs.ai_skill_use_func.CompanionCard= function(card, use, self)
	--Global_room:writeToConsole("珠联璧合判断开始")
	local card_str = ("@CompanionCard=.&_companion")
	local nofreindweak = true
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			nofreindweak = false
		end
	end
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak then
		--Global_room:writeToConsole("桃回复")
		use.card = sgs.Card_Parse(card_str)
		return
	end
--暂不考虑摸牌
--[[如何获取当前或上一张杀的目标？可参考野心家标记补牌
	情况1：能出杀，预测杀目标血量为1且无闪或手牌小于等于2
	情况2：敌方目标血量为1且自身或团队状态良好，有桃
]]--
end

sgs.ai_skill_choice["companion"] = function(self, choices)
	return "peach"
end

function sgs.ai_cardsview.companion(self, class_name, player, cards)
	if class_name == "Peach" then
		if player:getMark("@companion") > 0 and not player:hasFlag("Global_PreventPeach") then
			--Global_room:writeToConsole("珠联璧合标记救人")
			return "@CompanionCard=.&_companion"
		end
	end
end

sgs.ai_card_intention.CompanionCard = -140
sgs.ai_use_priority.CompanionCard= 0.1

--阴阳鱼标记
sgs.ai_skill_choice.halfmaxhp = function(self, choices)
	local can_tongdu = false
	local liuba = sgs.findPlayerByShownSkillName("tongdu")
	if liuba and self.player:isFriendWith(liuba) then
		can_tongdu = true
	end
	if (self.player:getHandcardNum() - self.player:getMaxCards()) > 1 + (can_tongdu and 3 or 0) then
		return "yes"
	end
	return "no"
end

local halfmaxhp_skill = {}
halfmaxhp_skill.name = "halfmaxhp"
table.insert(sgs.ai_skills, halfmaxhp_skill)
halfmaxhp_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@halfmaxhp") < 1 then return end
	return sgs.Card_Parse("@HalfMaxHpCard=.&")
end

sgs.ai_skill_use_func.HalfMaxHpCard= function(card, use, self)
	--Global_room:writeToConsole("阴阳鱼摸牌判断开始")
	if self.player:isKongcheng() and self:isWeak() and not self:needKongcheng() and self.player:getMark("@firstshow") < 1 then
		use.card = card
		return
	end
	--暂不考虑找进攻牌
end

sgs.ai_use_priority.HalfMaxHpCard = 0

--先驱标记
local firstshow_skill = {}
firstshow_skill.name = "firstshow"
table.insert(sgs.ai_skills, firstshow_skill)
firstshow_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@firstshow") < 1 then return end
	return sgs.Card_Parse("@FirstShowCard=.&")
end

sgs.ai_skill_use_func.FirstShowCard= function(card, use, self)
	sgs.ai_use_priority.FirstShowCard = 0.1--挟天子之前
	--Global_room:writeToConsole("先驱判断开始")
	local target
	local not_shown = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not p:hasShownAllGenerals() then
			table.insert(not_shown, p)
		end
	end
	if #not_shown > 0 then
		for _, p in ipairs(not_shown) do
			if not self:isFriend(p) and not self:isEnemy(p) then
				target = p
				break
			end
		end
		if not target then
			for _, p in ipairs(not_shown) do
				if not p:hasShownOneGeneral() and self:isEnemy(p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in ipairs(not_shown) do
				if self:isFriend(p) and not p:hasShownGeneral1() then
					target = p
					break
				end
			end
		end
		if not target then
			target = not_shown[1]
		end
	end

	if self.player:getHandcardNum() <= 1 and self:slashIsAvailable() then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			local dummy_use = { isDummy = true }
			if c:isKindOf("BasicCard") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card then
				return--先用光牌
			end
		end
		sgs.ai_use_priority.FirstShowCard = 2.4--杀之后
		use.card = card
		if target and use.to then
			use.to:append(target)
		end
		return
	end

	local freindisweak = false
	for _, friend in ipairs(self.friends) do
		if friend:getHp() == 1 and self:isWeak(friend) then
			freindisweak = true
			break
		end
	end
	if self.player:getHandcardNum() <= 2 and self:getCardsNum("Peach") == 0 and freindisweak then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			local dummy_use = { isDummy = true }
			if c:isKindOf("BasicCard") then
				self:useBasicCard(c, dummy_use)
			elseif c:isKindOf("EquipCard") then
				self:useEquipCard(c, dummy_use)
			elseif c:isKindOf("TrickCard") then
				self:useTrickCard(c, dummy_use)
			end
			if dummy_use.card then
				return--先用光牌
			end
		end
		sgs.ai_use_priority.FirstShowCard = 0.9--桃之后
		use.card = card
		if target and use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_skill_choice["firstshow_see"] = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "head_general") then
		return "head_general"
	end
	return choices[#choices]
end

sgs.ai_choicemade_filter.skillChoice.firstshow_see = function(self, from, promptlist)
	local choice = promptlist[#promptlist]
	for _, to in sgs.qlist(self.room:getOtherPlayers(from)) do
		if to:hasFlag("XianquTarget") then
			to:setMark(("KnownBoth_%s_%s"):format(from:objectName(), to:objectName()), 1)
			local names = {}
			if from:getTag("KnownBoth_" .. to:objectName()):toString() ~= "" then
				names = from:getTag("KnownBoth_" .. to:objectName()):toString():split("+")
			else
				if to:hasShownGeneral1() then
					table.insert(names, to:getActualGeneral1Name())
				else
					table.insert(names, "anjiang")
				end
				if to:hasShownGeneral2() then
					table.insert(names, to:getActualGeneral2Name())
				else
					table.insert(names, "anjiang")
				end
			end
			if choice == "head_general" then
				names[1] = to:getActualGeneral1Name()
			else
				names[2] = to:getActualGeneral2Name()
			end
			from:setTag("KnownBoth_" .. to:objectName(), sgs.QVariant(table.concat(names, "+")))
			break
		end
	end
end

--野心家标记
local careerman_skill = {}
careerman_skill.name = "careerman"
table.insert(sgs.ai_skills, careerman_skill)
careerman_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@careerist") < 1 then return end
	--Global_room:writeToConsole("野心家标记生成")
	return sgs.Card_Parse("@CareermanCard=.&")
end

sgs.ai_skill_use_func.CareermanCard= function(card, use, self)
	sgs.ai_use_priority.CareermanCard = 0.1--挟天子之前
	self.careerman_case = 2--记录选择情况
	--Global_room:writeToConsole("野心家标记判断开始")
	local card_str = ("@CareermanCard=.&_careerman")
	local nofreindweak = true
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			nofreindweak = false
		end
	end
	if self:getOverflow() > 2 and self.player:getHp() == 1 and nofreindweak then
		--Global_room:writeToConsole("野心家标记回复")
		self.careerman_case = 3
		use.card = sgs.Card_Parse(card_str)
		return
	end
	if self.player:getHandcardNum() <= 1 and self:slashIsAvailable() then
		local should_draw = false
		local dummy_slash = { isDummy = true, to = sgs.SPlayerList() }
		local slash = sgs.cloneCard("slash")
		self:useCardSlash(slash, dummy_slash)
		if use.card and use.to then
			for _, p in sgs.qlist(use.to) do
				if p:getHp() == 1 and self:isWeak(p) and sgs.getDefenseSlash(p, self) < 2 then
					should_draw = true
					break
				end
			end
		end
		if should_draw then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				local dummy_use = { isDummy = true }
				if c:isKindOf("BasicCard") then
					self:useBasicCard(c, dummy_use)
				elseif c:isKindOf("EquipCard") then
					self:useEquipCard(c, dummy_use)
				elseif c:isKindOf("TrickCard") then
					self:useTrickCard(c, dummy_use)
				end
				if dummy_use.card then
					return--先用光牌
				end
			end
			sgs.ai_use_priority.CareermanCard = 2.4--杀之后
			--Global_room:writeToConsole("野心家标记补牌")
			self.careerman_case = 4
			use.card = card
			return
		end
	end
	--暂时不考虑摸2牌
end

--[[
	all_choices << "draw1card" << "draw2cards" << "peach" << "firstshow";
	对应self.careerman_case 1 2 3 4 有必要可以加入table.indexOf判断
]]--

sgs.ai_skill_choice["careerman"] = function(self, choices)
	if self.careerman_case == 3 then
		return "peach"
	end
	if self.careerman_case == 4 then
		return "firstshow"
	end
	return "draw2cards"--默认情况case2
end

sgs.ai_skill_playerchosen["careerman"] = function(self, targets)
	local not_shown = sgs.QList2Table(targets)
	local target
	for _, p in ipairs(not_shown) do
		if not self:isFriend(p) and not self:isEnemy(p) then
			target = p
			break
		end
	end
	if not target then
		for _, p in ipairs(not_shown) do
			if not p:hasShownOneGeneral() and self:isEnemy(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(not_shown) do
			if self:isFriend(p) and not p:hasShownGeneral1() then
				target = p
				break
			end
		end
	end
	if not target then
		target = not_shown[1]
	end
	return target
end

function sgs.ai_cardsview.careerman(self, class_name, player, cards)
	if class_name == "Peach" then
		if player:getMark("@careerist") > 0 and not player:hasFlag("Global_PreventPeach") then
			--Global_room:writeToConsole("野心家标记救人")
			return "@CareermanCard=.&_careerman"
		end
	end
end

sgs.ai_card_intention.CareermanCard = -140

--暴露野心
sgs.ai_skill_choice["GameRule:CareeristShow"]= function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "yes") then
		return "yes"
	end
	return "no"
end

--拉拢人心
sgs.ai_skill_choice["GameRule:CareeristSummon"]= function(self, choices)
	return "yes"
end

sgs.ai_skill_choice["GameRule:CareeristAdd"]= function(self, choices)
	return math.random(1, 3) > 1 and "no" or "yes"
end

sgs.ai_skill_invoke["userdefine:halfmaxhp"] = function(self)
	return not self:needKongcheng(self.player, true) or self.player:getPhase() == sgs.Player_Play
end

sgs.ai_skill_invoke["userdefine:changetolord"] = function(self)
	return math.random() < 0.8
end

sgs.ai_skill_choice.CompanionEffect = function(self, choice, data)
	if ( self:isWeak() or self:needKongcheng(self.player, true) ) and string.find(choice, "recover") then return "recover"
	else return "draw" end
end

sgs.ai_skill_invoke["userdefine:FirstShowReward"] = function(self, choice, data)
	if self.room:getMode() == "jiange_defense" then return false end
	return true
end


sgs.ai_skill_choice.heg_nullification = function(self, choice, data)
	local effect = data:toCardEffect()
	if effect.card:isKindOf("AOE") or effect.card:isKindOf("GlobalEffect") then
		if self:isFriendWith(effect.to) then return "all"
		elseif self:isFriend(effect.to) then return "single"
		elseif self:isEnemy(effect.to) then return "all"
		end
	end
	local targets = sgs.SPlayerList()
	local players = self.room:getTag("targets" .. effect.card:toString()):toList()
	for _, q in sgs.qlist(players) do
		targets:append(q:toPlayer())
	end
	if effect.card:isKindOf("FightTogether") then
		local ed, no = 0
		for _, p in sgs.qlist(targets) do
			if p:objectName() ~= targets:at(0):objectName() and p:isChained() then
				ed = ed + 1
			end
			if p:objectName() ~= targets:at(0):objectName() and not p:isChained() then
				no = no + 1
			end
		end
		if targets:at(0):isChained() then
			if no > ed then return "single" end
		else
			if ed > no then return "single" end
		end
	end
	return "all"
end


sgs.ai_skill_choice["GameRule:TriggerOrder"] = function(self, choices, data)
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")

	local firstShow = ("luanji|qianhuan"):split("|")
	local bothShow = ("luanji+shuangxiong|luanji+huoshui|huoji+jizhi|luoshen+fangzhu|guanxing+jizhi"):split("|")
	local followShow = ("qianhuan|duoshi|rende|cunsi|jieyin|xiongyi|shouyue|hongfa"):split("|")

	local notshown, shown, allshown, f, e, eAtt = 0, 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self.player:getKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
		if p:hasShownAllGenerals() then
			allshown = allshown + 1
		end
	end

	local showRate = math.random() + shown/20

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end

	if (firstShowReward or self:willShowForAttack()) and not self:willSkipPlayPhase() then
		for _, skill in ipairs(bothShow) do
			if self.player:hasSkills(skill) then
				if canShowHead and showRate > 0.7 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.7 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
	end

	if firstShowReward and not self:willSkipPlayPhase() then
		for _, skill in ipairs(firstShow) do
			if self.player:hasSkill(skill) and not self.player:hasShownOneGeneral() then
				if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.8 then
					return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.8 then
					return "GameRule_AskForGeneralShowDeputy"
				end
			end
		end
		if not self.player:hasShownOneGeneral() then
			if canShowHead and showRate > 0.9 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.9 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") ~= 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") ~= 0) then
			canShowHead = false
		end
	end
	if self.player:inHeadSkills("baoling") then
		if (self.player:hasSkill("mingshi") and allshown >= (self.room:alivePlayerCount() - 1))
			or (self.player:hasSkill("luanwu") and self.player:getMark("@chaos") == 0)
			or (self.player:hasSkill("xiongyi") and self.player:getMark("@arise") == 0) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			end
		end
	end

	if self.player:hasSkill("guixiu") and not self.player:hasShownSkill("guixiu") then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase() ) then
			if self.player:inHeadSkills("guixiu") and canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:hasSkill("xichou") and self.player:getMark("xichou") == 0 then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3) or (self.player:hasSkill("huashen") and not self.player:hasShownSkill("huashen")) then
			if self.player:inHeadSkills("xichou") and canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _,p in ipairs(self.friends) do
		if p:hasShownSkill("jieyin") then
			if canShowHead and self.player:getGeneral():isMale() then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and self.player:getGeneral():isFemale() and self.player:getGeneral2():isMale() then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("CompanionEffect") > 0 then
		if self:isWeak() or (shown > 0 and eAtt > 0 and e - f < 3 and not self:willSkipPlayPhase()) then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:getMark("HalfMaxHpLeft") > 0 then
		if self:isWeak() and self:willShowForDefence() then
			if canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate >0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	if self.player:hasTreasure("JadeSeal") then
		if not self.player:hasShownOneGeneral() then
			if canShowHead then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end

	for _, skill in ipairs(followShow) do
		if ((shown > 0 and e < notshown) or self.player:hasShownOneGeneral()) and self.player:hasSkill(skill) then
			if self.player:inHeadSkills(skill) and canShowHead and showRate > 0.6 then
				return "GameRule_AskForGeneralShowHead"
			elseif canShowDeputy and showRate > 0.6 then
				return "GameRule_AskForGeneralShowDeputy"
			end
		end
	end
	for _, skill in ipairs(followShow) do
		if not self.player:hasShownOneGeneral() then
			for _,p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if p:hasShownSkill(skill) and p:getKingdom() == self.player:getKingdom() then
					if canShowHead and canShowDeputy and showRate > 0.2 then
						local cho = { "GameRule_AskForGeneralShowHead", "GameRule_AskForGeneralShowDeputy"}
						return cho[math.random(1, #cho)]
					elseif canShowHead and showRate > 0.2 then
						return "GameRule_AskForGeneralShowHead"
					elseif canShowDeputy and showRate > 0.2 then
						return "GameRule_AskForGeneralShowDeputy"
					end
				end
			end
		end
	end

	local skillTrigger = false
	local skillnames = choices:split("+")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowHead")
	table.removeOne(skillnames, "GameRule_AskForGeneralShowDeputy")
	table.removeOne(skillnames, "cancel")
	if #skillnames ~= 0 then
		skillTrigger = true
	end

	if skillTrigger then
		--偶像卖血顺序，暂时只写这么点
		if string.find(choices, "qiaoyuan") then return "qiaoyuan" end
		if string.find(choices, "lvgui") then return "lvgui" end

		if string.find(choices, "jieming") then return "jieming" end
		if string.find(choices, "wangxi") and string.find(choices, "fankui") then 
			local from = data:toDamage().from
			if from and from:isNude() then return "wangxi" end
		end
		if table.contains(skillnames, "fankui") and table.contains(skillnames, "ganglie") then return "fankui" end
		if string.find(choices, "wangxi") and table.contains(skillnames, "ganglie") then return "ganglie" end
		if string.find(choices, "luoshen") and string.find(choices, "guanxing") then return "guanxing" end
		if string.find(choices, "wangxi") and string.find(choices, "fangzhu") then return "fangzhu" end
		if string.find(choices, "qianxi") and sgs.ai_skill_invoke.qianxi(sgs.ais[self.player:objectName()]) then return "qianxi" end

		if table.contains(skillnames, "tiandu") then
			local judge = data:toJudge()
			if judge.card:isKindOf("Peach") or judge.card:isKindOf("Analeptic") then
				return "tiandu"
			end
		end
		if table.contains(skillnames, "yiji") then return "yiji" end
		if table.contains(skillnames, "haoshi") then return "haoshi" end

		local except = {}
		for _, skillname in ipairs(skillnames) do
			local invoke = self:askForSkillInvoke(skillname, data)
			if invoke == true then
				return skillname
			elseif invoke == false then
				table.insert(except, skillname)
			end
		end
		if string.find(choices, "cancel") and not canShowHead and not canShowDeputy and not self.player:hasShownOneGeneral() then
			return "cancel"
		end
		table.removeTable(skillnames, except)

		if #skillnames > 0 then return skillnames[math.random(1, #skillnames)] end
	end

	return "cancel"
end

sgs.ai_skill_choice["GameRule:TurnStart"] = function(self, choices, data)
	local canShowHead = string.find(choices, "GameRule_AskForGeneralShowHead")
	local canShowDeputy = string.find(choices, "GameRule_AskForGeneralShowDeputy")
	local choice = sgs.ai_skill_choice["GameRule:TriggerOrder"](self, choices, data)
	if choice == "cancel" then
		local showRate = math.random()

		if canShowHead and showRate > 0.8 then
			if self.player:isDuanchang() then return "GameRule_AskForGeneralShowHead" end
			for _, p in ipairs(self.enemies) do
				if p:hasShownSkills("mingshi|huoshui") then return "GameRule_AskForGeneralShowHead" end
			end
		elseif canShowDeputy and showRate > 0.8 then
			if self.player:isDuanchang() then return "GameRule_AskForGeneralShowDeputy" end
			for _, p in ipairs(self.enemies) do
				if p:hasShownSkills("mingshi|huoshui") then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
		if not self.player:hasShownOneGeneral() then
			local gameProcess = sgs.gameProcess():split(">>")
			if self.player:getKingdom() == gameProcess[1] and (self.player:getLord() or sgs.shown_kingdom[self.player:getKingdom()] < self.player:aliveCount() / 2) then
				if self.player:hasSkill("xichou") and self.player:getMark("xichou") == 0 then
					if self.player:inHeadSkills("xichou") and canShowHead then
						return "GameRule_AskForGeneralShowHead"
					elseif canShowDeputy then
						return "GameRule_AskForGeneralShowDeputy"
					end
				end
				if canShowHead and showRate > 0.6 then return "GameRule_AskForGeneralShowHead"
				elseif canShowDeputy and showRate > 0.6 then return "GameRule_AskForGeneralShowDeputy" end
			end
		end
	end
	return choice
end

sgs.ai_skill_choice["armorskill"] = function(self, choice, data)
	local choices = choice:split("+")
	for _, name in ipairs(choices) do
		skill_names = name:split(":")
		if #skill_names == 2 then
			if self:askForSkillInvoke(skill_names[2], data) then return name end
		end
	end
	return "cancel"
end

sgs.ai_skill_invoke.GameRule_AskForArraySummon = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_invoke.SiegeSummon = true
sgs.ai_skill_invoke["SiegeSummon!"] = false

sgs.ai_skill_invoke.FormationSummon = true
sgs.ai_skill_invoke["FormationSummon!"] = false

sgs.ai_skill_choice["GuanxingShowGeneral"] = function(self, choices, data)
	if self.room:alivePlayerCount() >= 5 then
		local cho = { "show_head_general", "show_deputy_general"}
		return cho[math.random(1, #cho)]
	end
	return "show_both_generals"
end