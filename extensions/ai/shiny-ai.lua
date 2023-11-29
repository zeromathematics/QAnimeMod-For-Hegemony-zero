--樱内梨子
sgs.ai_skill_playerchosen.qinban = function(self, targets)
	targets = sgs.QList2Table(targets)
	local friend = self.room:getCurrent()
	if not friend:isWounded() then --下女装和竹刀
		if (friend:isMale() and friend:getArmor() and friend:getArmor():objectName() == "Josou") or (friend:getWeapon() and friend:getWeapon():objectName() == "Shinai") then
			return friend
		else
			return nil
		end
	end
	if friend:getEquips():length() == 1 and friend:getArmor() and friend:getArmor():objectName() == "PeaceSpell" and friend:getHp() == 1 then --1血单太平要术的情况
		if self.player ~= friend and self.player:getEquips() > 0 then
			return self.player
		else
			if self:getCardsNum({"Peach", "GuangyuCard"}) > 0 then
				return friend
			end
		end
		return nil
	end
	if self.player:getArmor() and self.player:getArmor():objectName() == "SilverLion" and self.player:isWounded() then --梨子刷自己的白银
		return self.player
	end
	if friend:getEquips():isEmpty() then
		return self.player
	else
		return friend
	end
end	

sgs.ai_skill_cardchosen.qinban = function(self, who, flags)
	local cards = sgs.QList2Table(who:getCards("e"))
	self:sortByKeepValue(cards)	
	if who:getWeapon() and who:getWeapon():objectName() == "Shinai" then --下女装和竹刀
		return who:getWeapon():getId()
	end
	if who:isMale() and who:getArmor() and who:getArmor():objectName() == "Josou" then
		return who:getArmor():getId()
	end
	if cards[1]:isKindOf("PeaceSpell") then --规避太平要术
		if #cards > 1 then
			return cards[2]:getId()
		else
			return nil
		end
	end
	if who:getArmor() and who:getArmor():objectName() == "SilverLion" and who:isWounded() then --刷白银
		return who:getArmor():getId()
	end
	return cards[1]:getId()
end

sgs.ai_skill_choice.qinban = "recoverRiko" --暂定为无脑回血

local function card_for_zhiyuan(self, who, return_prompt) --以下内容改编自时崎狂三
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() and not noNeedToRemoveJudgeArea(who) then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if judge:isKindOf("Key") and not who:isWounded() then --满血队友不需要移键，直接跳转到下一张判定牌
					continue
				end
				if judge:isKindOf("Key") then
					if who:isWounded() then
						for _, friend in ipairs(self.friends) do
							if not friend:containsTrick(judge:objectName()) and self:hasTrickEffective(judge, friend, self.player) then
								target = friend
								break
							end
						end
						if target then break end
						for _, p in sgs.qlist(self.room:getAlivePlayers()) do --如果队友选不了，也可以移给他人
							if not p:containsTrick(judge:objectName()) and self:hasTrickEffective(judge, p, self.player) then
								target = p
								break
							end
						end
						if target then break end
					end
				else --兵乐电
					for _, enemy in sgs.qlist(self.room:getAlivePlayers()) do
						if not self:isFriend(enemy) and not enemy:containsTrick(judge:objectName()) and self:hasTrickEffective(judge, enemy, self.player) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end
		local equips = who:getCards("e")
		local weak = false
		if not target and not equips:isEmpty() and who:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") then --新增与逢坂大河的相关判断
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or (who:getArmor() and who:getArmor():objectName() == "SilverLion")) then
					card = equip
					break
				end
			end
			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and friend:hasShownSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill .. "|zhudao") then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if card == nil or target == nil then
			if not who:hasEquip() or who:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end
			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and friend:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	end
	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		return (card and target)
	end
end

sgs.ai_skill_invoke.zhiyuan = true

sgs.ai_skill_choice.zhiyuan = function(self, choices, data)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	for _, friend in ipairs(self.friends) do
		if not friend:getCards("j"):isEmpty() and card_for_zhiyuan(self, friend, ".") then
			return "AskForZhiyuan"
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not friend:getCards("e"):isEmpty() and friend:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") and card_for_zhiyuan(self, friend, ".") then
			return "AskForZhiyuan"
		end
	end
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if card_for_zhiyuan(self, enemy, ".") then
			table.insert(targets, enemy)
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		return "AskForZhiyuan"
	end
	return "draw"
end

sgs.ai_skill_cardchosen.zhiyuan = function(self, who, flags)
	if flags == "ej" then
		return card_for_zhiyuan(self, who, "card")
	end
end

sgs.ai_skill_playerchosen.zhiyuan = function(self, targets)
	local who = self.room:getTag("zhiyuanTarget"):toPlayer()
	if who then
		if not card_for_zhiyuan(self, who, "target") then self.room:writeToConsole("NULL") end
		return card_for_zhiyuan(self, who, "target")
	else
		self:updatePlayers()
		self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and card_for_zhiyuan(self, friend, ".") then
				return friend
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not friend:getCards("e"):isEmpty() and friend:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") and card_for_zhiyuan(self, friend, ".") then
				return friend
			end
			if not friend:getArmor() then has_armor = false end
		end
		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if card_for_zhiyuan(self, enemy, ".") then
				table.insert(targets, enemy)
			end
		end
		if #targets > 0 then
			self:sort(targets, "defense")
			return targets[#targets]
		end
	end
end

--高坂穗乃果

--[[
	呼晴的攻心卡应该不难，而且保底攻心肯定不亏。问题在于亮太早会被群殴，所以前期不能无脑放。真正的问题在于：1.攻心谁最合适？2.如何弃牌？
	我认为这两个都是大问题，因为涉及到了一个我不知道动漫杀有没有的功能——AI记明牌。如果AI会记明牌（而且这个功能真人玩家一般没有，AI反而有优势），那么在“判断合适的目标”这件事中可以参考的要求就多了一些。如果没有的话，那我能想得到的限制就只有“注意防具”“注意夏娜、血城等防伤害技能”这些了。当然对上面来说只攻心不弃牌打伤害也是可行的。
]]

sgs.ai_skill_invoke.guwu = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_skill_choice.guwu = function(self, choices, data)
	local Honoka = sgs.findPlayerByShownSkillName("guwu")
	if self:isFriend(Honoka) then
		return "guwu_accept"
	end
	return "cancel"
end

--星空凛
sgs.ai_skill_invoke.tuibian = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence() or not self:getCards("j"):isEmpty()
end

sgs.ai_skill_cardchosen.tuibian = function(self, who, flags) --简单抄了梨子
	local cards = sgs.QList2Table(who:getCards("hej"))
	self:sortByKeepValue(cards)	
	if who:getWeapon() and who:getWeapon():objectName() == "Shinai" then --下女装和竹刀
		return who:getWeapon():getId()
	end
	if who:isMale() and who:getArmor() and who:getArmor():objectName() == "Josou" then
		return who:getArmor():getId()
	end
	if cards[1]:isKindOf("PeaceSpell") and #cards > 1 then
		return cards[2]:getId()
	end
	if who:getArmor() and who:getArmor():objectName() == "SilverLion" and who:isWounded() then --刷白银
		return who:getArmor():getId()
	end
	return cards[1]:getId()
end

sgs.ai_skill_invoke.xunjiRin = function(self, data)
	for _, card in sgs.qlist(self.player:getHandcards()) do --优化了逻辑，防止坑寻翡
		if card:isKindOf("TrickCard") and card:isAvailable(self.player) then
			return false
		end
	end
	return self:willShowForAttack() and self:getCardsNum("Slash") > 1
end

--西木野真姬
sgs.ai_skill_invoke.ciqiang = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end
--我觉得千金应该不难，但是就是想不到合适的判断标准。

--高海千歌
sgs.ai_skill_invoke.jiesi = true

sgs.ai_skill_choice.jiesi = function(self, choices, data)
	if #self.friends < self.player:getMark("jiesiCount") and #self.enemies >= self.player:getMark("jiesiCount") then
		local m = 0
		for _,p in ipairs(self.friends) do
			m = m + math.max(1, p:getMaxHp() - p:getHandcardNum())
		end
		if m < math.min(#self.enemies, self.player:getMark("jiesiCount")) then
			return "jiesiThrow"
		end
	end
	for _,p in ipairs(self.friends) do
		local judges = p:getJudgingArea()
		if not judges:isEmpty() and not noNeedToRemoveJudgeArea(p) then
			return "jiesiThrow"
		end
    end
	return "jiesiDraw" --背水太复杂暂不考虑
end

sgs.ai_skill_playerchosen["#jiesiDraw"] = function(self, data) --加了更为精细的判断
	local result = {}
	while (#result < self.player:getMark("jiesiCount") and #result < #self.friends) do
		local x = 0
		for _,name in ipairs(self.friends) do
			local m = name:getMaxHp() - name:getHandcardNum()
			if x < m and not table.contains(result, findPlayerByObjectName(name:objectName())) then
				x = m
			end
		end		
		for _,name in ipairs(self.friends) do
			local m = name:getMaxHp() - name:getHandcardNum()
			if not table.contains(result, findPlayerByObjectName(name:objectName())) and #result < self.player:getMark("jiesiCount") and m <= x and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) then --虹之丘真白的优先级要推后
				table.insert(result, findPlayerByObjectName(name:objectName()))
			end
		end
		for _,name in ipairs(self.friends) do
			local m = name:getMaxHp() - name:getHandcardNum()
			if not table.contains(result, findPlayerByObjectName(name:objectName())) and #result < self.player:getMark("jiesiCount") and m <= x then
				table.insert(result, findPlayerByObjectName(name:objectName()))
			end
		end
	end
	return result
end

sgs.ai_skill_playerchosen["#jiesiThrow"] = function(self, data)
	local result = {}
	for _,name in ipairs(self.friends) do --优先拆队友判定区，然后再拆敌人
		local judges = name:getJudgingArea()
		if not judges:isEmpty() and not noNeedToRemoveJudgeArea(name) and #result < self.player:getMark("jiesiCount") then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	for _,name in ipairs(self.enemies) do
		if not name:isNude() and #result < self.player:getMark("jiesiCount") then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

sgs.ai_skill_invoke.tongzhou = true

--黑泽露比
local heyiX_skill = {}
heyiX_skill.name = "heyiX"
table.insert(sgs.ai_skills, heyiX_skill)
heyiX_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_heyiXCard") or self.player:isNude() then return end
	local usevalue = 0
	local keepvalue = 0	
	local id
	local card1
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart then
			id = tostring(card:getId())
			card1 = card
			usevalue = self:getUseValue(card)
			keepvalue = self:getKeepValue(card)
			break
		end
	end
	if not id then return end
	local suit = card1:getSuitString()
	local number = card1:getNumber()
	local card_id = card1:getId()
	return sgs.Card_Parse(("alliance_feast:heyiX[%s:%s]=%d%s"):format(suit, number, card_id, "&heyiX"))
end

sgs.heyiX_suit_value = {heart = 3.9}

sgs.ai_skill_invoke.qiesheng = true

--中须霞
sgs.ai_skill_invoke.qingyuan = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return false end
	if self.player:isRemoved() then return true end --被调虎离山时可以白嫖
	return self:getCardsNum({"Peach", "GuangyuCard"}) + target:getHp() - self.player:getMark("qingyuanCount") < 1 --桃不够再开大。免得多桃挡1血，血亏
end

sgs.ai_skill_invoke.zilian = function(self, data) --新自恋，仅适合进攻
	return self:willShowForAttack()
end

--朝香果林
sgs.ai_skill_invoke.zhanmei = true
--新技能的对应AI要不要写？怎么写？如何进行博弈？

--艾玛更复杂了，又要涉及控顶又要涉及坑卖血，比想象中困难很多。

--唐可可
sgs.ai_skill_invoke.lvgui = true

sgs.ai_skill_choice.lvgui = function(self, choices, data)
	local room = self.player:getRoom()
	local n = 0
	for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:getHandcardNum() > n then
			n = p:getHandcardNum()
		end				
	end
	local m = math.min(5, n-self.player:getHandcardNum())
	if m > 0 then --比较粗糙的判断标准，当然真人实战会复杂很多
		return "draw"
	else
		return "overseaNEW"
	end
end

sgs.ai_skill_invoke.xiangyun = true

sgs.ai_skill_choice.xiangyun = function(self, choices, data)
	local use = data:toCardUse()
	if self:getUseValue(sgs.Card_Parse((use.card:objectName()..":xiangyun[%s:%s]=.&xiangyun"):format("no_suit","-"))) > 0.2 then --来自古手梨花
		return "xiangyunX"
	else
		return "draw"
	end
end

sgs.ai_skill_use["@@xiangyun"] = function(self, prompt)
	if self.player:isRemoved() then return end
	local card = sgs.Sanguosha:cloneCard(self.player:property("xiangyun_card"):toString())
	assert(card)
	if not card:isAvailable(self.player) then return end 
	local use = {isDummy = true, to = sgs.SPlayerList()}
	if card:isKindOf("BasicCard") then
		self:useBasicCard(card, use)
	else
		self:useTrickCard(card, use)
	end
	if not use.card then return "." end
	if card:targetFixed() then return card:toString() end
	local targets = {}
	for _,to in sgs.qlist(use.to) do
		table.insert(targets, to:objectName())
	end
	if #targets == 0 then 
		if card:canRecast() then
			return card:toString()
		end
		return "."
	end
	return card:toString() .. "->" .. table.concat(targets, "+")
end

--叶月恋
sgs.ai_skill_invoke.jichan = true

--危计……完全想不到怎么写AI。

--东海帝王
sgs.ai_skill_invoke.diwu = true

sgs.ai_skill_askforag.diwu = function(self, card_ids)
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if self.player:hasFlag("diwu"..card:getTypeId()) then
			return id
		end 
	end
	return -1 --这个-1不能省略，否则人机会无视条件强行拿牌
end

sgs.ai_skill_use["@@nisheng"] = function(self, prompt)
	if not self:willShowForAttack() then
		return "."
	end
	local x = self.player:getMark("##ThreeUpBasic") + self.player:getMark("##ThreeUpTrick") + self.player:getMark("##ThreeUpEquip")
	local hp = math.min(x, #self.enemies)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local equips = sgs.QList2Table(self.player:getEquips())
	self:sortByUseValue(cards)
	self:sortByUseValue(equips)	
	local needed = {}
	for _,acard in ipairs(cards) do
		table.insert(needed, acard:getEffectiveId())
		if #needed >= hp then
			break
		end
	end
	for _,acard in ipairs(equips) do
		if #needed < hp then
			table.insert(needed, acard:getEffectiveId())
		end
	end	
	local targets = {}
	self:sort(self.enemies, "hp")
	for _,p in ipairs(self.enemies) do
		if #targets < hp then
			table.insert(targets, p:objectName())
		end
	end
	if type(targets) == "table" and #targets > 0 then
		return ("#nishengCard:"..table.concat(needed,"+")..":&->" .. table.concat(targets, "+"))
	end
	return "."
end

sgs.ai_skill_invoke.ThreeUp = true

sgs.ai_skill_choice.ThreeUp = function(self, choices, data)
	if self.player:getMark("##ThreeUpEquip") == 0 then
		return "equip"
	else
		if self.player:getMark("##ThreeUpTrick") == 0 then
			return "trick"
		else
			return "basic"
		end
	end
end

--爱莲
sgs.ai_skill_invoke.beide = function(self, data)
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getSuit() == sgs.Card_Spade and card:isAvailable(self.player) then
			return true
		end
	end
	return false
end

sgs.beide_suit_value = {spade = 3.9}

sgs.ai_skill_invoke.jinduan = function(self, data)
	--禁断大削弱，要不要修改触发逻辑？
	local target = data:toPlayer()
	return not self:isFriend(target)
end

--无声铃鹿
sgs.ai_skill_invoke.qisu = true

sgs.ai_skill_use["@@qisu"] = function(self, prompt)
	if self.player:isRemoved() then return end
	local id = self.player:property("qisu_card"):toInt()
	local card = sgs.Sanguosha:getCard(id)
	local use_card = card
	assert(use_card)
	if not card:isAvailable(self.player) then return end 
	local use = {isDummy = true, to = sgs.SPlayerList()}
	self:useBasicCard(use_card, use)
	if not use.card then return "." end
	local targets = {}
	for _,to in sgs.qlist(use.to) do
		table.insert(targets, to:objectName())
	end
	if #targets == 0 then return end
	return use_card:toString() .. "->" .. table.concat(targets, "+")
end

--艾恩
sgs.ai_skill_invoke.anyu = true

sgs.ai_skill_choice.anyu = function(self, choices, data)
	if (self.room:getCurrent():getArmor() and self.room:getCurrent():getArmor():objectName() == "PeaceSpell") or self.room:getCurrent():hasShownSkills("zhaolei|huansha") then
		return "anyuDraw" --新增对黄濑弥生、上条当麻的考虑
	end
	if self:isEnemy(self.room:getCurrent()) and self:willShowForAttack() then
		return "anyuDamage"
	else
		return "anyuDraw"
	end
end

--十六夜理子
sgs.ai_skill_invoke.xunfei = true

--花咲蕾
sgs.ai_skill_invoke.lianhui = function(self, data)
	local move = data:toMoveOneTime()
	if move.from then
		return move.from:objectName() == self.player:objectName()
	else
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getSuit() == sgs.Card_Club then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen.lianhui = function(self) --来自折木奉太郎
	local result = {}
	for _,name in ipairs(self.friends) do
		if #result < self.player:getMark("lianhuiCount") and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

sgs.ai_skill_invoke.shixin = function(self, data)
	return #self.friends_noself > 0
end

sgs.ai_skill_playerchosen.shixin = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	return self.friends_noself[1]
end

--剑崎真琴
sgs.ai_skill_invoke.tonghua = true

--感觉耀剑会复杂到很难受……

--绚濑绘里
sgs.ai_skill_invoke.xianju = true

--另外两个核心技能怎么写？

--宫下爱
sgs.ai_skill_invoke.lamei = true

--友爱……肉眼可见的复杂

--初音未来

--现在人机Miku的诟病在于完全不会主动亮，自己摸到非转化音的概率微乎其微，约等于没有，连手牌上限都没有。而且歌姬的转化也是一件需要深思熟虑的事情。

sgs.ai_skill_invoke.geji = true

sgs.ai_skill_playerchosen.geji = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	return targets[1]
end

--黄濑弥生

--猜拳和改判都很复杂，毕竟变数太多。我认为很多时候宁可空劈自己也不能误伤队友。

sgs.ai_skill_invoke.zhaolei = function(self, data)
	local damage = data:toDamage()
	return damage.to and damage.to:objectName() == self.player:objectName() and not self:willShowForMasochism()
end

--优木雪菜
local chixin_skill = {} --来自克鲁特
chixin_skill.name = "chixin"
table.insert(sgs.ai_skills, chixin_skill)
chixin_skill.getTurnUseCard = function(self, room, player, data)
	if self.player:hasUsed("ViewAsSkill_chixinCard") or self.player:isNude() or not self:willShowForAttack() then return end
	local usevalue = 998
	local keepvalue = 998	
	local id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:isRed() and self:getUseValue(card) < usevalue and self:getKeepValue(card) < keepvalue then
			id = tostring(card:getId())
			usevalue = self:getUseValue(card)
			keepvalue = self:getKeepValue(card)
		end
	end
	if not id then return end
	local parsed_card = {}
	for i = 1, 998, 1 do
	   local c = sgs.Sanguosha:getCard(i-1)
	   if c and (c:objectName() == "fire_slash" or c:objectName() == "fire_attack" or c:objectName() == "burning_camps") then
	      table.insert(parsed_card, sgs.Card_Parse(c:objectName()..":chixin[to_be_decided:0]=" .. id .."&chixin"))	
	   end
	end	
	local value = 0
	local tcard
	for _, c in ipairs(parsed_card) do
		assert(c)
		if self:getUseValue(c) > value and self:getUseValue(c) > keepvalue and self:getUseValue(c) > usevalue then
			value = self:getUseValue(c)
			tcard = c
		end
	end
	if tcard and id then
		return tcard
	end
end

sgs.ai_skill_invoke.jinhun = true

sgs.ai_skill_choice.jinhun = function(self, choices, data)
	if self.player:getMaxHp() + self.player:getHp() >= 2 then --能自救优先自救
		return "jinhunRecover"
	elseif #self.friends_noself > 0 then --不能自救再考虑给队友遗产
		return "jinhunFire"
	end
	return "jinhunRecover"
end

sgs.ai_skill_playerchosen.jinhun = function(self, targets)	
	return self:findPlayerToDraw(false, 1)
end

--青天国春
sgs.ai_skill_invoke.yibing = true

sgs.ai_skill_choice["#yibingX"] = function(self, choices, data)
	if self.player:hasFlag("mjianshiDraw") then --注意神尾观铃，下同
		return "no"
	end
	return "yes"
end

sgs.ai_skill_choice["#yibingY"] = function(self, choices, data)
	if self.player:hasFlag("mjianshiPlay") then
		return "no"
	end
	return "yes"
end

sgs.ai_skill_choice["#yibingZ"] = function(self, choices, data)
	if self.player:hasFlag("mjianshiDiscard") then
		return "no"
	end
	return "yes"
end

sgs.ai_skill_choice.neifan = function(self, choices, data)
	local Haru = sgs.findPlayerByShownSkillName("neifan")
	if self.player:isNude() then
		return "neifanRemove"
	else
		if not self:isEnemy(Haru) or (self:getOverflow() > 0) or (self.player:isWounded() and self.player:getArmor() and self.player:getArmor():objectName() == "SilverLion") or (string.find(self.player:getActualGeneral2Name(), "sujiang") and self:isWeak()) or (self.player:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") and self.player:hasEquip()) or (self.player:isMale() and self.player:getArmor() and self.player:getArmor():objectName() == "Josou") or (self.player:getWeapon() and self.player:getWeapon():objectName() == "Shinai") then
			return "neifanDiscard"
		else
			return "neifanRemove"
		end
	end
end

--黑泽黛雅
sgs.ai_skill_invoke.wangzu = true

local yayi_skill = {}
yayi_skill.name = "yayi"
table.insert(sgs.ai_skills, yayi_skill)
yayi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_yayiCard") then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#yayiCard:.:&yayi")
end

sgs.ai_skill_use_func["#yayiCard"] = function(card, use, self)
	local target
	local targets = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(p) and not p:isNude() then
			table.insert(targets, p)
		end
	end
	if #targets > 0 then
    	self:sort(targets, "chaofeng")
    	target = targets[1]
		use.card = sgs.Card_Parse("#yayiCard:.:&yayi")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.yayiCard = 10

--大和赤骥
sgs.ai_skill_invoke.aoji = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_choice.aoji = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return "aojiPD"
	end
	return "aojiLoseHp"
end

sgs.ai_skill_playerchosen.aoji = function(self, targets)
	self:sort(self.enemies, "hp")
	return targets[1]
end

sgs.ai_skill_playerchosen.tuyou = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp") --优先保护体力低的，防止傲骥清忠。铃仙太复杂不考虑
	return targets[1]
end

sgs.ai_skill_choice.tuyou = function(self, choices, data)
	if table.contains(choices:split("+"), "sc_drboth") then
		return "sc_drboth" 
	end
	local friend = data:toPlayer()
	local pd = data:toPindian()
	local x, y = 0, 0
	if friend == pd.from then
		x = pd.from_number
		y = pd.to_number
	else
		x = pd.to_number
		y = pd.from_number
	end
	if x <= y and math.min(13, x+self.player:getMark("tuyouCount")) > y then
		return "tuyouAddNum"
	end
	return "tuyouObtain"
end

sgs.ai_skill_playerchosen.tuyou = function(self, targets)	
	return self:findPlayerToDraw(true, 1)
end

--朝日奈未来
local bowen_skill = {} --目前只会对自己开以逸待劳。有没有更合适的判断？
bowen_skill.name = "bowen"
table.insert(sgs.ai_skills, bowen_skill)
bowen_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_bowenCard") then return end
	return sgs.Card_Parse("#bowenCard:.:&bowen")
end

sgs.ai_skill_use_func["#bowenCard"] = function(card, use, self)
	use.card = sgs.Card_Parse("#bowenCard:.:&bowen")
	if use.to then
		use.to:append(self.player)
	end
end

sgs.ai_skill_choice.bowen = "@bowen1"

sgs.ai_skill_invoke.jijian = true

sgs.ai_skill_playerchosen.jijian = function(self)
	local result = {}
	for _,name in ipairs(self.friends) do
		if #result < 3 and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

--三船栞子

--严律……我自己身为真人来玩都觉得变数太多，灵活是灵活，但是让AI来笨拙地判断各种变数感觉属实是难为AI了……

sgs.ai_skill_invoke.xinxing = true

sgs.ai_skill_playerchosen.xinxing = function(self)
	local result = {}
	for _,name in ipairs(self.friends) do
		local p = findPlayerByObjectName(name:objectName())
		local NoNeed = false
		if #result < self.player:getLostHp() and p:getJudgingArea():length() > 0 then
			for _, judge in sgs.qlist(p:getJudgingArea()) do
				if judge:isKindOf("Key") and not who:isWounded() and p:getJudgingArea():length() == 1 then
					NoNeed = true
				end
			end
		end
		if not NoNeed then
			table.insert(result, p)
		end
	end
	for _,name in ipairs(self.friends) do
		local p = findPlayerByObjectName(name:objectName())
		if #result < self.player:getLostHp() and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) then
			table.insert(result, p)
		end
	end
	return result
end

sgs.ai_skill_choice.xinxing = "xinxingThrow" --如何防止给满血队友空弃Key？

--浅仓透
sgs.ai_skill_invoke.jiaoxin = function(self, data) --感觉交心的AI现在还不够好。
	local target = data:toPlayer()
	return self:isFriend(target) or self.player:getHandcardNum() < target:getHandcardNum()
end

sgs.ai_skill_choice.jiaoxin = function(self, choices, data)
	local Tooru = sgs.findPlayerByShownSkillName("jiaoxin")
	if self:isFriend(Tooru) then
		return "jiaoxinExchange"
	end
	local n = math.random(1,2)
	if n == 1 then
		return "jiaoxinExchange"
	end
	return "jiaoxinDiscard"
end

sgs.ai_skill_playerchosen.xiuxing = function(self, targets)
	return self.player --大多数情况下镇自己足够了
end

--虹之丘真白
--[[
sgs.ai_skill_cardask["@shangyuan-slash"] = function(self, data, pattern, target2, target, prompt)
	local target = data:toPlayer()
	if self:isFriend(target) and (target:hasFlag("AI_needCrossbow") or (getCardsNum("Slash", target, self.player) >= 2 and self.player:getWeapon():isKindOf("Crossbow"))) then
		if target:hasFlag("AI_needCrossbow") then self.room:setPlayerFlag(target, "-AI_needCrossbow") end
		return "."
	end
	local slashes = self:getCards("Slash")
	self:sortByUseValue(slashes)
	local theslash
	if self:isFriend(target2) and self:needLeiji(target2, self.player) then
		for _, slash in ipairs(slashes) do
			if self:slashIsEffective(slash, target2) then
				theslash = slash
				break
			end
		end
	end
	if not theslash and target2 and (self:needDamagedEffects(target2, self.player, true) or self:needToLoseHp(target2, self.player, true)) then
		for _, slash in ipairs(slashes) do
			if self:slashIsEffective(slash, target2) and self:isFriend(target2) then
				theslash = slash
				break
			end
			if not self:slashIsEffective(slash, target2, self.player, true) and self:isEnemy(target2) then
				theslash = slash
				break
			end
		end
		for _, slash in ipairs(slashes) do
			if theslash then break end
			if not self:needDamagedEffects(target2, self.player, true) and self:isEnemy(target2) then
				theslash = slash
				break
			end
		end
	end
	if not theslash and target2 and not self.player:hasSkills(sgs.lose_equip_skill) and self:isEnemy(target2) then
		for _, slash in ipairs(slashes) do
			if self:slashIsEffective(slash, target2) then
				theslash = slash
				break
			end
		end
	end
	if not theslash and target2 and not self.player:hasSkills(sgs.lose_equip_skill) and self:isFriend(target2) then
		for _, slash in ipairs(slashes) do
			if not self:slashIsEffective(slash, target2) then
				theslash = slash
				break
			end
		end
		for _, slash in ipairs(slashes) do
			if theslash then break end
			if (target2:getHp() > 3 or not self:canHit(target2, self.player, self:hasHeavySlashDamage(self.player, slash, target2))) and self.player:getHandcardNum() > 1 then
				theslash = slash
				break
			end
			if self:needToLoseHp(target2, self.player) then
				theslash = slash
				break
			end
		end
	end
	if theslash then
		return theslash:toString()
	end
	return "."
end
]]

sgs.ai_skill_invoke.chaoshi = function(self, data)
	return self.player:getHandcardNum() < 4
end

--宫泽风花
sgs.ai_skill_invoke.moliang = true

sgs.ai_skill_playerchosen.moliang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	return targets[1]
end

sgs.ai_skill_discard.moliang = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if self:getOverflow() > 0 then
		return {cards[1]:getEffectiveId()}
	end
	return {}
end

sgs.ai_skill_invoke.yuanshu = true

sgs.ai_skill_playerchosen.yuanshu = function(self, targets)
	targets = sgs.QList2Table(targets)
	local Yyui
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:hasSkill("wenchang") then Yyui = target end --无脑给团子
	end
	if Yyui then return Yyui end
	self:sort(targets, "handcard")
	return targets[1]
end

--鸣护艾丽莎

--大工程……犯愁……

sgs.ai_skill_invoke.quming = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_skill_invoke.yangming = true

sgs.ai_skill_playerchosen.yangming = function(self)
	local result = {}
	for _,name in ipairs(self.friends) do
		if #result < self.player:getEquips():length() and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

--樱井望

--判断标准也很多、很复杂。目前只能说不是白板，无脑曹昂

sgs.ai_skill_invoke.yueyin = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

--天羽奏
sgs.ai_skill_invoke.juexiang = true

sgs.ai_skill_choice.juexiang = function(self, choices, data)
	local Fubuki = sgs.findPlayerByShownSkillName("qianlei") --防吹雪是第一要务！
	if Fubuki and self.player:getHp() <= 1 and not self:isFriend(Fubuki) then
		return "cancel"
	end		
	local HasSlashTarget = false --判断是否可以出杀
	for _,v in ipairs(self.enemies) do
		for _,c in sgs.qlist(self.player:getHandcards()) do
            if c:isKindOf("Slash") and self:slashIsEffective(c, v, self.player) and self.player:canSlash(v, c, true) then
				HasSlashTarget = true
			end
		end
	end
	local NeedGuangyu = false --有光玉可以多刷一次键
	for _, judge in sgs.qlist(self.player:getJudgingArea()) do
		if judge:isKindOf("Key") then
			NeedGuangyu = true
		end
	end
	local list = sgs.IntList() --详细统计绝响牌的组成
	local x = 1+self.player:getLostHp()
	for i = 0, x, 1 do
		local c = sgs.Sanguosha(i)
		if c then
			list:append(i)
		end
	end
	local table_list = room:getCardIdsOnTable(list)
	local a, b, c, d = 0, 0, 0, 0
	for _,p in sgs.qlist(table_list) do
		if p:isKindOf("BasicCard") then
			a = a+1
		end
		if p:isKindOf("Peach") then
			b = b+1
		end
		if p:isKindOf("Analeptic") then
			c = c+1
		end
		if p:isKindOf("GuangyuCard") then
			d = d+1
		end
	end
	local has_stable_skill = self.player:hasSkills("caibao|boxue")
	if (d > 0 and NeedGuangyu) or b > 0 or ((c > 0 or d > 0) and self.player:getHp() == 1) or (not self:isWeak() and (HasSlashTarget or a > 1 or has_stable_skill)) then
		return "@juexiang1"
	end
	return "cancel"
end