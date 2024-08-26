--樱内梨子
local function has_idol_masochism_skill(player)
	return player:hasShownSkills("zhiyuan|jiesi|qiesheng|lvgui|jinduan|aoji|xinxing|jiaoxin|yuanshu|qiuyu")
end

sgs.ai_skill_playerchosen.qinban = function(self, targets)
	targets = sgs.QList2Table(targets)
	local friend = self.room:getCurrent()
	if not friend:isWounded() then --队友满血也能用，下竹刀、卖血将下藤甲
		if friend:hasWeapon("Shinai") or (friend:getArmor() and friend:getArmor():objectName() == "Vine" and has_idol_masochism_skill(friend)) then --武器和宝物可以直接用has，防具只能老老实实get再判断名字
			return friend
		end
		return nil
	end
	if friend:isLord() and friend:hasTreasure("Idolyousei") and friend:getEquips():length() == 1 then --君穗乃果的偶像养成得保住
		if self.player ~= friend and self.player:getEquips():length() > 0 and not (self.player:getEquips():length() == 1 and self.player:getArmor() and self.player:getArmor():objectName() == "PeaceSpell" and self.player:getHp() == 1) then
			return self.player
		end
		return nil
	end
	if friend:getEquips():length() == 1 and friend:getArmor() and friend:getArmor():objectName() == "PeaceSpell" and friend:getHp() == 1 then --1血单太平要术的情况
		if self.player ~= friend and self.player:getEquips():length() > 0 then
			return self.player
		end
		return nil
	end
	if self.player:getArmor() and self.player:getArmor():objectName() == "SilverLion" and self.player:isWounded() then --梨子刷自己的白银
		return self.player
	end
	if friend:getEquips():length() == 0 then
		return self.player
	else
		return friend
	end
end	

sgs.ai_skill_cardchosen.qinban = function(self, who, flags)
	local cards = sgs.QList2Table(who:getCards("e"))
	self:sortByKeepValue(cards)
	if who:hasWeapon("Shinai") then --下竹刀
		return who:getWeapon():getId()
	end
	if who:getArmor() and who:getArmor():objectName() == "Vine" and has_idol_masochism_skill(who) then --卖血将下藤甲
		return who:getArmor():getId()
	end
	if cards[1]:isKindOf("PeaceSpell") then --规避太平要术
		if #cards > 1 then
			return cards[2]:getId()
		else
			return nil
		end
	end
	if cards[1]:isKindOf("Idolyousei") and who:isLord() then --规避君穗乃果的偶像养成
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

sgs.ai_skill_choice.qinban = "recoverRiko"

local function card_for_zhiyuan(self, who, return_prompt) --以下内容改编自时崎狂三
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if who:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(who) then
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
		if not target and who:getEquips():length() > 0 and who:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") then --防逢坂大河
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
		if friend:getJudgingArea():length() > 0 and card_for_zhiyuan(self, friend, ".") then
			return "AskForZhiyuan"
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > 0 and friend:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") and card_for_zhiyuan(self, friend, ".") then
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

sgs.ai_skill_playerchosen.zhiyuan = function(self, targets)
	local who = self.room:getTag("zhiyuanTarget"):toPlayer()
	if who then
		if not card_for_zhiyuan(self, who, "target") then
			self.room:writeToConsole("NULL")
		end
		return card_for_zhiyuan(self, who, "target")
	else
		self:updatePlayers()
		self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if friend:getJudgingArea():length() > 0 and card_for_zhiyuan(self, friend, ".") then
				return friend
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if friend:getEquips():length() > 0 and friend:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") and card_for_zhiyuan(self, friend, ".") then
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

sgs.ai_skill_cardchosen.zhiyuan = function(self, who, flags)
	if flags == "ej" then
		return card_for_zhiyuan(self, who, "card")
	end
end

--高坂穗乃果
huqing_skill = {}
huqing_skill.name = "huqing"
table.insert(sgs.ai_skills, huqing_skill)
huqing_skill.getTurnUseCard = function(self, inclusive)
	if not self:willShowForAttack() and not self:willShowForDefence() then return end --不需要亮将不发动
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if pattern ~= "@@huqing" then
		if self.player:hasUsed("#huqingCard") then return end
		return sgs.Card_Parse("#huqingCard:.:&huqing")
	end
end

sgs.ai_skill_use_func["#huqingCard"] = function(card, use, self)
	local target
	local target1, target2
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,p in ipairs(enemies) do
		local damage = {}
		damage.from = self.player
		damage.to = p
		damage.nature = sgs.DamageStruct_Fire
		damage.damage = 1
		if self:damageIsEffective_(damage) then --判断伤害是否有效
			target1 = p --选出防御最低的
			break
		end
	end
	self:sort(enemies, "handcard")  --没考虑明牌的情况
    for _,p in ipairs(enemies) do
		local damage = {}
		damage.from = self.player
		damage.to = p
		damage.nature = sgs.DamageStruct_Fire
		damage.damage = 1
		if self:damageIsEffective_(damage) then
			target2 = p --选出手牌最多的
		end
	end

	local suit_list = {"spade", "heart", "club", "diamond"}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		local suit = c:getSuitString()
		if table.contains(suit_list, suit) then
			table.removeOne(suit_list, suit)
		end
	end

    if target1 and target1:getHandcardNum()>2 and #suit_list <= 1 then -- 包含3种以上花色且对面手牌大于2则选择
		target = target1
	elseif target2 then --否则选手牌最多的
		target = target2
	end

	if not target and #enemies>0 then target = enemies[math.random(1,#enemies)] end --没人选就随便攻心一个敌人
	if not target then target = self.room:getOtherPlayers(self.player):at(math.random(1,self.room:getOtherPlayers(self.player))-1) end --还没人选就随便攻心一个人

	if target then
		use.card = sgs.Card_Parse("#huqingCard:.:&huqing")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority.huqingCard = 6 --较早使用

sgs.ai_skill_use["@@huqing"] = function(self, prompt)  -- for "huqingfireCard"
	local to = self.player:getTag("huqingTarget"):toPlayer()
	local damage = {}
	damage.from = self.player
	damage.to = to
	damage.nature = sgs.DamageStruct_Fire
	damage.damage = 1
	if not to or not self:isEnemy(to) or not self:damageIsEffective_(damage) then return end
    local needed = {}
	local huqing_suits = self.player:property("huqingSuits"):toString():split("+") 
	local n = #huqing_suits
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		local cardSuit = card:getSuitString()
		if #needed < n and table.contains(huqing_suits, cardSuit) then
			table.removeOne(huqing_suits, cardSuit) --把已经选的除去
			table.insert(needed, card:getEffectiveId()) --加入卡牌
		end
	end
    if #needed == n then
		return ("#huqingfireCard:"..table.concat(needed, "+")..":&->")
	end
end

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
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_cardchosen.tuibian = function(self, who, flags)
	return self:askForCardChosen(who, "he", "dismantlement")
end

sgs.ai_skill_invoke.xunjiRin = function(self, data)
	if self.player:hasFlag("idol_lord_discard") and self.player:getMark("MiracleChampionFlag_Limited") <= 0 then --准备开大
		return false
	end
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

local qianjin_skill = {}
qianjin_skill.name = "qianjin"
table.insert(sgs.ai_skills, qianjin_skill)
qianjin_skill.getTurnUseCard = function(self, inclusive)
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	if self.player:hasUsed("qianjinCard") then return end
	local spadeX, clubX, heartX, diamondX = 0, 0, 0, 0
	for _,p in sgs.qlist(self.player:getAliveSiblings()) do
		local cards = p:getCards("ej")
		cards = sgs.QList2Table(cards)
		for _,card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade then
				spadeX = spadeX + 1
			end
			if card:getSuit() == sgs.Card_Club then
				clubX = clubX + 1
			end
			if card:getSuit() == sgs.Card_Heart then
				heartX = heartX + 1
			end
			if card:getSuit() == sgs.Card_Diamond then
				diamondX = diamondX + 1
			end
		end
	end	
	local cardsA = self.player:getCards("j")
	cardsA = sgs.QList2Table(cardsA)
	for _,card in ipairs(cardsA) do
		if card:getSuit() == sgs.Card_Spade then
			spadeX = spadeX + 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubX = clubX + 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartX = heartX + 1
		end
		if card:getSuit() == sgs.Card_Diamond then
			diamondX = diamondX + 1
		end
	end
	local cardsB = self.player:getCards("he")
	cardsB = sgs.QList2Table(cardsB)
	for _,card in ipairs(cardsB) do
		if card:getSuit() == sgs.Card_Spade then
			spadeX = spadeX - 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubX = clubX - 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartX = heartX - 1
		end
		if card:getSuit() == sgs.Card_Diamond then
			diamondX = diamondX - 1
		end
	end
	if math.max(spadeX, clubX, heartX, diamondX) < 0 then return end
	return sgs.Card_Parse("#qianjinCard:.:&qianjin")
end

sgs.ai_skill_use_func.qianjinCard = function(card,use,self)
	use.card = sgs.Card_Parse("#qianjinCard:.:&qianjin")
	return
end

sgs.ai_skill_suit["qianjin"] = function(self)
	local spadeX, clubX, heartX, diamondX = 0, 0, 0, 0
	for _,p in sgs.qlist(self.player:getAliveSiblings()) do
		local cards = p:getCards("ej")
		cards = sgs.QList2Table(cards)
		for _,card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade then
				spadeX = spadeX + 1
			end
			if card:getSuit() == sgs.Card_Club then
				clubX = clubX + 1
			end
			if card:getSuit() == sgs.Card_Heart then
				heartX = heartX + 1
			end
			if card:getSuit() == sgs.Card_Diamond then
				diamondX = diamondX + 1
			end
		end
	end	
	local cardsA = self.player:getCards("j")
	cardsA = sgs.QList2Table(cardsA)
	for _,card in ipairs(cardsA) do
		if card:getSuit() == sgs.Card_Spade then
			spadeX = spadeX + 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubX = clubX + 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartX = heartX + 1
		end
		if card:getSuit() == sgs.Card_Diamond then
			diamondX = diamondX + 1
		end
	end
	local cardsB = self.player:getCards("he")
	cardsB = sgs.QList2Table(cardsB)
	for _,card in ipairs(cardsB) do
		if card:getSuit() == sgs.Card_Spade then
			spadeX = spadeX - 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubX = clubX - 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartX = heartX - 1
		end
		if card:getSuit() == sgs.Card_Diamond then
			diamondX = diamondX - 1
		end
	end
	spadeX = math.min(spadeX, 5)
	clubX = math.min(clubX, 5)
	heartX = math.min(heartX, 5)
	diamondX = math.min(diamondX, 5)
	local most = math.max(spadeX, clubX, heartX, diamondX)
	if spadeX == most then return 0 end
	if clubX == most then return 1 end
	if heartX == most then return 2 end
	if diamondX == most then return 3 end
end

--高海千歌
sgs.ai_skill_invoke.jiesi = true

sgs.ai_skill_choice.jiesi = function(self, choices, data)
	if #self.friends < self.player:getMark("jiesiCount") and #self.enemies >= self.player:getMark("jiesiCount") then
		local m = 0
		for _,p in ipairs(self.friends) do
			m = m + math.max(0, p:getMaxHp() - p:getHandcardNum())
		end
		if m < math.min(#self.enemies, self.player:getMark("jiesiCount")) then
			return "jiesiThrow"
		end
	end
	for _,p in ipairs(self.friends) do
		if p:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(p) then
			for _, judge in sgs.qlist(p:getJudgingArea()) do
				if (judge:isKindOf("Key") and not p:isWounded()) or (judge:isKindOf("Lightning") and p:hasShownSkills("zhaolei")) then --满血键、弥生的闪电不用拆
					continue
				else
					return "jiesiThrow"
				end
			end
		end
    end
	return "jiesiDraw"
end

sgs.ai_skill_playerchosen["#jiesiDraw"] = function(self, data) --加了更为精细的判断
	local result = {}
	while (#result < self.player:getMark("jiesiCount") and #result < #self.friends) do
		local x = 1
		for _,name in ipairs(self.friends) do
			local m = name:getMaxHp() - name:getHandcardNum()
			if x < m and not table.contains(result, name) then
				x = m
			end
		end		
		for _,name in ipairs(self.friends) do
			local m = name:getMaxHp() - name:getHandcardNum()
			if m < 0 then
				m = 0
			end
			if not table.contains(result, name) and #result < self.player:getMark("jiesiCount") and m == x and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) then --虹之丘真白的优先级要推后
				table.insert(result, findPlayerByObjectName(name:objectName()))
			end
		end
		for _,name in ipairs(self.friends) do
			local m = name:getMaxHp() - name:getHandcardNum()
			if m < 0 then
				m = 0
			end
			if not table.contains(result, name) and #result < self.player:getMark("jiesiCount") and m == x then
				table.insert(result, findPlayerByObjectName(name:objectName()))
			end
		end
	end
	return result
end

sgs.ai_skill_playerchosen["#jiesiThrow"] = function(self, data)
	local result = {}
	for _,name in ipairs(self.friends) do --优先拆队友判定区，然后再拆敌人
		if name:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(name) and #result < self.player:getMark("jiesiCount") and not table.contains(result, name) then
			for _, judge in sgs.qlist(name:getJudgingArea()) do
				if (judge:isKindOf("Key") and not name:isWounded()) or (judge:isKindOf("Lightning") and name:hasShownSkills("zhaolei")) then --满血键、弥生的闪电不用拆
					continue
				else
					table.insert(result, findPlayerByObjectName(name:objectName()))
					break
				end
			end
		end
	end
	for _,name in ipairs(self.enemies) do
		if not name:isNude() and #result < self.player:getMark("jiesiCount") and not table.contains(result, name) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

sgs.ai_skill_cardchosen.jiesi = function(self, who, flags)
	return self:askForCardChosen(who, flags, "dismantlement")
end

sgs.ai_skill_invoke.tongzhou = true

--黑泽露比
--[[
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
]]

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
	local n = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
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
		if #targets < #needed then
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
	local target = data:toPlayer()
	if self.player:objectName() == self.room:getCurrent():objectName() then
		return true
	end
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
		return "anyuDraw" --注意黄濑弥生、上条当麻
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
		if #result < self.player:getMark("lianhuiCount") and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) and not table.contains(result, name) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

sgs.ai_skill_invoke.shixin = function(self, data)
	return #self.friends_noself > 0 and self:getOverflow() > 0
end

sgs.ai_skill_playerchosen.shixin = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	return self.friends_noself[1]
end

--剑崎真琴
sgs.ai_skill_invoke.tonghua = true

sgs.ai_skill_playerchosen.tonghua = function(self, targets)
	self:sort(self.enemies, "hp")
	return self.enemies[1]
end

--感觉耀剑会复杂到很难受……

--绚濑绘里
sgs.ai_skill_invoke.xianju = true

shouwu_skill={}
shouwu_skill.name="shouwu"
table.insert(sgs.ai_skills,shouwu_skill)
shouwu_skill.getTurnUseCard=function(self,inclusive)
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	if self.player:hasUsed("ViewAsSkill_shouwuCard") then return end
	return sgs.Card_Parse("#shouwuCard:.:&shouwu")
end

sgs.ai_skill_use_func["#shouwuCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
    local needed = {}
	local names = {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
       if c:isBlack() and #needed < #self.friends and not table.contains(names, c:objectName()) then
		  table.insert(names, c:objectName())
		  table.insert(needed, c:getEffectiveId())
	   end		   
	end
	for _,p in ipairs(self.friends) do
		if targets:length() < #needed then
			targets:append(p)
		end
	end
	if #needed >0 and targets:length() == #needed then
		use.card = sgs.Card_Parse("#shouwuCard:"..table.concat(needed, "+")..":&shouwu")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority.shouwuCard = 6

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

sgs.ai_skill_playerchosen.jinhun = function(self, targets)	
	return self:findPlayerToDraw(false, 1)
end

--青天国春
sgs.ai_skill_invoke.yibing = true

sgs.ai_skill_choice["#yibingX"] = function(self, choices, data)
	if self.player:hasFlag("mjianshiDraw") or self.player:hasFlag("idol_lord_draw") then --注意神尾观铃，下同
		return "no"
	end
	return "yes"
end

sgs.ai_skill_choice["#yibingY"] = function(self, choices, data)
	if self.player:hasFlag("mjianshiPlay") or self.player:hasFlag("idol_lord_play") then
		return "no"
	end
	return "yes"
end

sgs.ai_skill_choice["#yibingZ"] = function(self, choices, data)
	if self.player:hasFlag("mjianshiDiscard") or self.player:hasFlag("idol_lord_discard") then
		return "no"
	end
	return "yes"
end

sgs.ai_skill_choice.neifan = function(self, choices, data)
	local Haru = sgs.findPlayerByShownSkillName("neifan")
	if self.player:isNude() then
		return "neifanRemove"
	else
		if not self:isEnemy(Haru) or self:getOverflow() > 0 or (self.player:isWounded() and self.player:getArmor() and self.player:getArmor():objectName() == "SilverLion") or (string.find(self.player:getActualGeneral2Name(), "sujiang") and self:isWeak()) or (self.player:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") and self.player:hasEquip()) or self.player:hasWeapon("Shinai") then
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

sgs.ai_skill_playerchosen.yayi = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_cardchosen.yayi = function(self, who, flags)
	return self:askForCardChosen(who, flags, "snatch")
end

--大和赤骥
sgs.ai_skill_invoke.aoji = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_choice.aoji = function(self, choices, data)
	local damage = data:toDamage()
	local target
	if damage.from:objectName() == self.player:objectName() then
		target = damage.to
	else
		target = damage.from
	end
	if self:isFriend(target) then
		return "aojiPD"
	end
	return "aojiLoseHp"
end

sgs.ai_skill_playerchosen.aoji = function(self, targets)
	self:sort(self.enemies, "hp")
	return self.enemies[1]
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
	local friend = self.player:property("tuyouPerson"):toPlayer()
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

--三船栞子
--严律……我自己身为真人来玩都觉得变数太多，灵活是灵活，但是让AI来笨拙地判断各种变数感觉属实是难为AI了……

sgs.ai_skill_invoke.xinxing = true

sgs.ai_skill_playerchosen.xinxing = function(self)
	local result = {}
	self:sort(self.friends, "handcard")
	for _,name in ipairs(self.friends) do
		local p = findPlayerByObjectName(name:objectName())
		local NoNeed = false
		if #result < self.player:getMark("xinxingCount") and p:getJudgingArea():length() > 0 then
			for _, judge in sgs.qlist(p:getJudgingArea()) do
				if judge:isKindOf("Key") and not who:isWounded() and p:getJudgingArea():length() == 1 then
					NoNeed = true
				end
			end			
			if not NoNeed and not table.contains(result, name) then
				table.insert(result, p)
			end
		end
	end
	for _,name in ipairs(self.friends) do
		local p = findPlayerByObjectName(name:objectName())
		if #result < self.player:getMark("xinxingCount") and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) and not table.contains(result, name) then
			table.insert(result, p)
		end
	end
	return result
end

sgs.ai_skill_choice.xinxing = "xinxingThrow" --如何防止给满血队友空弃Key？

sgs.ai_skill_cardchosen.xinxing = function(self, who, flags)
	return self:askForCardChosen(who, "j", "dismantlement")
end

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

--虹之丘真白
sgs.ai_skill_invoke.chaoshi = function(self, data)
	local use = data:toCardUse()
	return use
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
	for _, target in ipairs(targets) do
		if self:isFriendWith(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) then
			return target
		end
	end
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
		if #result < self.player:getEquips():length() and not (name:hasShownSkill("chaoshi") and name:getHandcardNum() >= 4) and not table.contains(result, name) then
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
		if sgs.Sanguosha:getCard(i) then
			list:append(i)
		end
	end
	local table_list = self.room:getCardIdsOnTable(list)
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
	local has_stable_skill = self.player:hasSkills("caibao|boxue|bowen|yayi")
	if (d > 0 and NeedGuangyu) or b > 0 or ((c > 0 or d > 0) and self.player:getHp() == 1) or ((HasSlashTarget or a > 1 or has_stable_skill) and not self:isWeak()) then
		return "@juexiang1"
	end
	return "cancel"
end

--君·高坂穗乃果
sgs.ai_skill_invoke.qingge = true

sgs.ai_skill_choice.MiracleChampionFlag = function(self, choices, data)
	local can_judge, can_draw, can_play, can_discard = false, false, false, false
	for _,p in sgs.qlist(self.room:getAllPlayers()) do --判定阶段
		if self:isFriend(p) then
			if p:hasEquip() then
				if p:hasWeapon("Shinai") or (p:getArmor() and p:getArmor():objectName() == "SilverLion" and p:isWounded()) then
					can_judge = true
				end
			end
			if p:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(p) then
				for _, judge in sgs.qlist(p:getJudgingArea()) do
					if (judge:isKindOf("Key") and not p:isWounded()) or (judge:isKindOf("Lightning") and p:hasShownSkills("zhaolei")) then --满血键、弥生的闪电不用拆
						continue
					else
						can_judge = true
					end
				end
			end
		else
			if p:hasEquip() then
				if p:hasTreasure("Idolyousei") then --拆偶像养成，君穗乃果马上能拿
					can_judge = true
				end
				if (p:isMale() and p:getArmor() and p:getArmor():objectName() == "Josou") or not (p:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") or (p:getEquips():length() == 1 and p:hasWeapon("Shinai") or (p:getEquips():length() == 1 and p:getArmor() and p:getArmor():objectName() == "SilverLion" and p:isWounded()))) then
					can_judge = true
				end
			end
			if p:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(p) then
				for _, judge in sgs.qlist(p:getJudgingArea()) do
					if judge:isKindOf("Key") and not p:isWounded() then
						can_judge = true
					end
				end
			end
		end
	end
	local d, x, beide = 0, 2, 0
	for _,p in ipairs(self.friends) do --摸牌阶段
		if p:getHandcardNum() < self.player:getHandcardNum() and not (p:hasShownSkills("chaoshi") and p:getHandcardNum() > 2) then --至于真白到底怎么处理，到具体选人的时候再说。
			d = d+2
		end
	end
	if self.player:hasTreasure("JadeSeal") then
		x = x+1
	end
	if self.player:hasFlag("yibing-draw") then
		x = x+1
	end
	if self.player:hasShownSkills("beide") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade and card:isAvailable(self.player) then
				beide = beide+1
			end
		end
	end
	if beide > 0 then
		x = x+beide-0.5 --本来要-1，但是这里少扣一些，万一只有1黑桃的爱莲依旧能当场爆发呢？
	end
	if d > x then
		can_draw = true
	end

	--出牌阶段先空着吧！

	if self.player:getMark("MiracleChampionFlag_Limited") > 0 then --弃牌阶段
		can_discard = true
	else
		if self:getCardsNum("Peach") < 4 then --改编自刘巴
			local count = 0
			for _, friend in ipairs(self.friends) do
				if friend:isWounded() and friend:getHandcardNum() < 3 then
					count = count + 1
				end
			end
			if count > 1 or (self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0) then
				can_discard = true
			end
		end
	end
	if not (can_judge or can_draw or can_play or can_discard) then
		return "cancel"
	end
	if table.contains(choices:split("+"), "Discard") and can_discard then
		return "Discard"
	end
	if self.player:getJudgingArea():length() > 0 and table.contains(choices:split("+"), "Judge") then --必要的时候老老实实跳判定，别贪摸牌
		for _, judge in sgs.qlist(self.player:getJudgingArea()) do
			if (judge:isKindOf("Key") and not self.player:isWounded()) or (judge:isKindOf("Lightning") and self.player:hasShownSkills("zhaolei")) then
				continue
			else
				return "Judge"
			end
		end
	end
	if table.contains(choices:split("+"), "Draw") and can_draw then
		return "Draw"
	end
	if table.contains(choices:split("+"), "Judge") and can_judge then
		return "Judge"
	end
	return "cancel"
end

sgs.ai_skill_playerchosen["#MiracleChampionFlag_Skip_Judge"] = function(self, data)
	self:sort(self.friends, "hp") --因为大家都能跳判定，所以拆兵乐反而优先级不高。先给残血角色拆键、白银
	for _,p in ipairs(self.friends) do
		if p:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(p) then
			for _, judge in sgs.qlist(p:getJudgingArea()) do
				if judge:isKindOf("Key") and p:isWounded() then
					return p
				end
			end
		end
	end
	for _,p in ipairs(self.friends) do
		if p:hasEquip() then
			if p:getArmor() and p:getArmor():objectName() == "SilverLion" and p:isWounded() then
				return p
			end
		end
	end
	local targets = {}
	for _,p in ipairs(self.enemies) do
		local condition = false
		if p:getJudgingArea():length() == 1 and not noNeedToRemoveJudgeArea(p) then
			for _, judge in sgs.qlist(p:getJudgingArea()) do
				if judge:isKindOf("Key") and not p:isWounded() then
					condition = true
				end
			end
		end
		if (p:hasEquip() and not (p:hasShownSkills(sgs.lose_equip_skill .. "|zhudao") or (p:getEquips():length() == 1 and p:hasWeapon("Shinai") or (p:getEquips():length() == 1 and p:getArmor() and p:getArmor():objectName() == "SilverLion" and p:isWounded())))) or condition then
			table.insert(targets, p)
		end
	end
	if #targets > 0 then
		self:sort(targets, "defense")
		return targets[#targets]
	end
	for _,p in ipairs(self.friends) do
		if p:getJudgingArea():length() > 0 and not noNeedToRemoveJudgeArea(p) then
			for _, judge in sgs.qlist(p:getJudgingArea()) do
				if (judge:isKindOf("Key") and not p:isWounded()) or (judge:isKindOf("Lightning") and p:hasShownSkills("zhaolei")) then --满血键、弥生的闪电不用拆
					continue
				else
					return p
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.MiracleChampionFlag = function(self, who, flags)
	return self:askForCardChosen(who, flags, "dismantlement")
end

sgs.ai_skill_playerchosen["#MiracleChampionFlag_Skip_Draw"] = function(self, data)
	local result = {}
	for _,name in ipairs(self.friends_noself) do
		if not (name:hasShownSkill("chaoshi") and name:getHandcardNum() > 4) and not table.contains(result, name) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end

sgs.ai_skill_playerchosen["#MiracleChampionFlag_Skip_Discard"] = function(self, data)
	local result = {}
	for _,name in ipairs(self.friends) do
		if not table.contains(result, name) then
			table.insert(result, findPlayerByObjectName(name:objectName()))
		end
	end
	return result
end