--咲太
sgs.ai_skill_invoke.shuaiyan = function(self, data)
    local use = data:toCardUse()
	if self:isEnemy(use.to:at(0)) and not use.to:at(0):isNude() then return true end
	if self:isFriend(use.to:at(0)) and use.to:at(0):getJudgingArea():length()>0 then return true end
    if self.player:isFriendWith(use.to:at(0)) and use.to:at(0):isFemale() then return true end
end

sgs.ai_skill_invoke.shangxian = function(self, data)
    local damage = data:toDamage()
    if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 and self:getCardsNum("GuangyuCard") == 0 then return false end
	return damage.to:isAlive()
end

--圣人惠
sgs.ai_skill_invoke.dicun = function(self, data)
    local use = data:toCardUse()
	if self.player:getPhase()~=sgs.Player_NotActive and self.player:getHandcardNum()-self.player:getHp()>3 then return false end
	if use.card:getTypeId() == sgs.Card_TypeSkill then return not self:isFriend(use.from) end
	return not use.card:isKindOf("GodSalvation") and self.player:isWounded()
end

sgs.ai_skill_invoke.yuanyu = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

--零
sgs.ai_skill_invoke.zhufa = function(self, data)
    return true
end

local zhufa_skill = {}
zhufa_skill.name = "zhufa"
table.insert(sgs.ai_skills, zhufa_skill)
zhufa_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("ViewAsSkill_zhufaCard") or self.player:isKongcheng() then return end
	local usevalue = 0
	local keepvalue = 0	
	local id
	local card1
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		id = tostring(card:getId())
		card1 = card
		usevalue=self:getUseValue(card)
		keepvalue=self:getKeepValue(card)
		break
	end
	if not id then return end
	local parsed_card = {}
	if self.player:getTag("zhufa_record"):toString() == "" then return end
	local list = self.player:getTag("zhufa_record"):toString():split("+")
	for _,c in ipairs(list) do
		if c ~= "" then
		  table.insert(parsed_card, sgs.Card_Parse(c..":zhufa[to_be_decided:"..card1:getNumberString().."]=" .. id .."&zhufa"))
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

sgs.ai_skill_invoke.fashufengyin = function(self, data)
    local use = data:toCardUse()
    return self:isEnemy(use.from)
end

sgs.ai_skill_discard["fashufengyin"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end

liqi_skill={}
liqi_skill.name="liqi"
table.insert(sgs.ai_skills,liqi_skill)
liqi_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("@liqi")==0 then return end
	return sgs.Card_Parse("#LiqiCard:.:&liqi")
end

sgs.ai_skill_use_func["#LiqiCard"] = function(card,use,self)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isFriendWith(self.player) then
			target = p
		end
	end
	if target then
		use.card = sgs.Card_Parse("#LiqiCard:.:&liqi")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.liqi = function(self, data)
    local n = self.player:getHandcardNum() + self.player:getEquips():length()
    local m = self.room:getCurrent():getHandcardNum() + self.room:getCurrent():getEquips():length()
    return n >= m
end

--狗哥
sgs.ai_skill_invoke.bishi = function(self, data)
    return true
end

sgs.ai_skill_invoke.cichuan = function(self, data)
    local a
    local b
    for _,e in ipairs(self.enemies) do
       if self.player:inMyAttackRange(e) and e:getPile("qiang"):length()==0 then a = true end          
    end
    for _,c in sgs.qlist(self.player:getHandcards()) do
       if c:getSuitString()=="diamond" then b = true end          
    end
    return a and b
end

sgs.ai_skill_use["@@cichuan"] = function(self, prompt)
	local target
	local card
	for _,p in ipairs(self.enemies) do
	  if self.player:inMyAttackRange(p) and p:getPile("qiang"):length()==0 then target = p end
	end
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:getSuitString()=="diamond" then card = c end          
	 end
	if target and card then
		return ("#CichuanCard:"..card:getEffectiveId()..":&->" .. target:objectName())
	end
	return "."
end

--黑
sgs.ai_skill_invoke.yingdi = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.diansuo = function(self, data)
	local damage = data:toDamage()
	if damage.from:objectName() == self.player:objectName() then
		return true
	else
		if self:isFriend(damage.to) then return true end
		return false
	end
end

-- TODO 需求更高效率的做法
sgs.ai_skill_playerchosen.diansuo = function(self, targets)
	if self.player:isChained() then
		for _, target in sgs.qlist(targets) do
		   if self:isEnemy(target) then return target end
		end
	else
		for _, target in sgs.qlist(targets) do
		   if self:isEnemy(target) then return target end
		end
	end

end

--诗乃
sgs.ai_skill_invoke.sjuji = function(self, data)
    local target = data:toPlayer()
	if target then return self:isEnemy(target) end
end

jianyu_skill={}
jianyu_skill.name="jianyu"
table.insert(sgs.ai_skills,jianyu_skill)
jianyu_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("ViewAsSkill_jianyuCard") then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#JianyuCard:.:&jianyu")
end

sgs.ai_skill_use_func["#JianyuCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	local n = self.player:getLostHp()
	n = math.max(n , 1)
	for _,enemy in ipairs(self.enemies) do
		if targets:length() < n and not enemy:inMyAttackRange(self.player) and self.player:inMyAttackRange(enemy) and self:slashIsEffective(sgs.cloneCard("slash"), enemy, self.player) then
			targets:append(enemy)
		end
	end
	if targets:length() < n then
		for _,enemy1 in ipairs(self.enemies) do
			if targets:length() < n and enemy1:inMyAttackRange(self.player) and self.player:inMyAttackRange(enemy1) and self:slashIsEffective(sgs.cloneCard("slash"), enemy1, self.player) then
				targets:append(enemy1)
			end
		end
	end
	if targets:length() > 0 then
		use.card = sgs.Card_Parse("#JianyuCard:.:&jianyu")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["JianyuCard"] = 8
sgs.ai_use_priority["JianyuCard"]  = 2
sgs.ai_card_intention["JianyuCard"] = 100

--久远
sgs.ai_skill_invoke.yaoshi = function(self, data)
	local dying = data:toDying()
	local has
	for _,c in sgs.qlist(self.player:getHandcards()) do
       if c:getSuitString() == "heart" then has = true end
	end
	for _,c in sgs.qlist(self.player:getEquips()) do
		if c:getSuitString() == "heart" then has = true end
	 end
	if dying.who ~= nil then return self:isFriend(dying.who) and has end
    return (self:willShowForAttack() or self:willShowForDefence()) and self:isEnemy(self.room:getCurrent())
end

sgs.ai_skill_invoke.shenxue = function(self, data)
    return not self.player:faceUp() or #self.friends_noself <= #self.enemies
end

sgs.ai_skill_playerchosen.shenxue = function(self)
    local result = {}
	for _,name in ipairs(self.enemies)do
		if  #result< 2 and not name:isFriendWith(self.player) then table.insert(result, findPlayerByObjectName(name:objectName())) end
	end
	return result
end

sgs.ai_skill_discard.shenxue = function(self, discard_num, min_num, optional, include_equip)
	local sp = sgs.findPlayerByShownSkillName("shenxue")
	if sp and self:needToLoseHp(self.player, sp) then return {} end
	local to_discard = {} --copy from V2 
	local cards = sgs.QList2Table(self.player:getHandcards())
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return {} end
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == 2 then break end
		end
	end
	if #to_discard < 2 then return {}
	else
		return to_discard
	end
end

--佑树
sgs.ai_skill_invoke.pquanneng = function(self, data)
    local damage = data:toDamage()
    return (self:willShowForAttack() or self:willShowForDefence()) and self:isFriend(damage.from)
end

sgs.ai_skill_choice.pquanneng = function(self, choices, data)
	if table.contains(choices:split("+"), "pquanneng_losemark") and self.player:isWounded() then
	  return "pquanneng_losemark"
	end
    local player = data:toPlayer()
    if not player:isKongcheng() and (self:isEnemy(player) or self.player:isKongcheng()) then
       return "pquanneng_seehandcards"
    end
    if self.player:getMark("@xuli") == 0 then
	  return "pquanneng_gainmark"
	end
end

sgs.ai_skill_invoke.plianjie = function(self, data)
    local damage = data:toDamage()
    if damage then return true end
    if self.player == self.room:getCurrent() then return true end
    return math.random(1,2) == 1
end

--萨尼亚
sgs.ai_skill_invoke.tancha = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.tancha = function(self, targets)
	for _,p in sgs.qlist(targets)do
		if not self:isFriend(p) and (not p:isKongcheng() or  not p:hasShownAllGenerals()) then return p end
	end
	return
end

sgs.ai_skill_invoke.boxi = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.boxi = function(self, targets)
	return targets:at(math.random(1,targets:length())-1)
end

--文伽
sgs.ai_skill_invoke.youji = function(self, data)
    return true
end

sgs.ai_skill_invoke.songxin = function(self, data)
    local death = data:toDeath()
	local killer = death.damage and death.damage.from or nil
	if killer and killer:isAlive() and self:isEnemy(killer) and killer:getHandcardNum()>3 then return true end
	if death.who:getHandcardNum()>0 and #self.friends_noself>0 then return true end
end

sgs.ai_skill_choice.songxin = function(self, choices, data)
	local death = data:toDeath()
	local killer = death.damage and death.damage.from or nil
	if death.who:getHandcardNum()>0 and #self.friends_noself>0 then
		return "songxin_choose" 
	elseif killer and killer:isAlive() and self:isEnemy(killer) and killer:getHandcardNum()>3 then
		return "songxin_source"
	end
end

sgs.ai_skill_playerchosen.songxin = function(self, targets)
	for _,p in ipairs(self.friends_noself) do
		return p
    end
end

--折棒
sgs.ai_skill_invoke.linggan = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.jieneng = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.tuili = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_askforag.tuili = function(self, card_ids)
	local use = self.player:property("tuili_pattern"):toCardUse()
	for _,i in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(i):objectName() == use.card:objectName() then
			return i
		end
	end
	return -1
end

sgs.ai_skill_cardask["@tuili"] = function(self, data)
    local use = self.player:property("tuili_pattern"):toCardUse()
	for _,i in sgs.qlist(self.player:handCards()) do
		if sgs.Sanguosha:getCard(i):objectName() == use.card:objectName() then
			return "$"..i
		end
	end
end
	
sgs.ai_skill_playerchosen.tuili = function(self)
	local result = {}
	for _,name in ipairs(self.friends)do
		if  #result< 2 then table.insert(result, findPlayerByObjectName(name:objectName())) end
	end
	return result
end

sgs.ai_skill_choice.tuili = function(self, choices, data)
	return "tuili_hide"
end	

--空白
sgs.ai_skill_invoke.youzheng = function(self, data)
	local can
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:getNumber()>10 then can = true end
	end
    return (self:willShowForAttack() or self:willShowForDefence()) and #self.enemies>0 and can
end

sgs.ai_skill_playerchosen.youzheng = function(self, targets)
	return self:getPriorTarget()
end

sgs.ai_skill_invoke.sorazhi = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.sorazhi = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and not target:isNude() then
			return target
		end
	end
end

sgs.ai_skill_choice.sorazhi = function(self, choices, data)
	local target = findPlayerByObjectName(self.player:property("sorazhi_target"):toString())
	if self:isFriend(target) then
	  return "sora_draw"
    else
	  return "sora_discard"
	end 
end

sgs.ai_skill_invoke.shiroshi = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.shiroshi = function(self, targets)
	for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
end

--塔兹米
sgs.ai_skill_invoke.lizhan = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.caokai = function(self, data)
	local has
	for _,v in ipairs(self.enemies) do
		if self.player:inMyAttackRange(v) then
			for _,c in sgs.qlist(self.player:getHandcards()) do
               if c:isKindOf("Slash") and self:slashIsEffective(c, v, self.player) then has = true end
			end
		end
	end
	return (self:willShowForAttack() or self:willShowForDefence()) and has
end

sgs.ai_skill_invoke.longhua = function(self, data)
	return true
end

---樱满集

local void_skill={}
void_skill.name="void"
table.insert(sgs.ai_skills,void_skill)
void_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("ViewAsSkill_voidCard") then return end
	if self.player:isNude() then return end
	return sgs.Card_Parse("#VoidCard:.:&void")
end

sgs.ai_skill_use_func["#VoidCard"] = function(card,use,self)
	local room = self.room
	local source = self.player
    local targets = sgs.SPlayerList()
	local target
	local card
	for _,p in sgs.qlist(room:getOtherPlayers(source)) do
           if not p:getCards("he"):isEmpty() then targets:append(p) end
    end
	for _,who in sgs.qlist(targets) do
       local cd = sgs.ai_skill_cardchosen["zhudao"](self, who, "he")
	   if cd then 
		  target = who
		  break
	   end
	end
	local cards = sgs.QList2Table(source:getCards("he"))
	self:sortByKeepValue(cards)
	card = cards[1]
	if target and card then
        use.card = sgs.Card_Parse("#VoidCard:"..card:getEffectiveId()..":&void")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority.VoidCard = 3


----十六夜咲夜
local huanshen_skill = {}
huanshen_skill.name = "huanshen"
table.insert(sgs.ai_skills, huanshen_skill)
huanshen_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_huanshenCard") then return end
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("#HuanshenCard:.:&huanshen")
end

sgs.ai_skill_use_func["#HuanshenCard"] = function(card, use, self)
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if not c:isAvailable(self.player) and #needed < self.player:getHandcardNum() then
			table.insert(needed, c:getEffectiveId())
		end
	end
	if #needed > 0 then
    	use.card = sgs.Card_Parse("#HuanshenCard:"..table.concat(needed, "+")..":&huanshen")
		return
	end
	return "."
end

sgs.ai_skill_invoke["sshiji_recover"] = true
sgs.ai_skill_invoke["sshiji_turnover"] = function(self, data)
  if not self.player:faceUp() and self.player == self.room:getCurrent() then
     return true
  end
  return false
end
sgs.ai_skill_invoke["sshiji_obtain"] = true



--艾斯蒂尔
fenglun_skill={}
fenglun_skill.name="fenglun"
table.insert(sgs.ai_skills,fenglun_skill)
fenglun_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("ViewAsSkill_fenglunCard") then return end
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	return sgs.Card_Parse("#FenglunCard:.:&fenglun")
end

sgs.ai_skill_use_func["#FenglunCard"] = function(card,use,self)
	local target = self:getPriorTarget()
	local card
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _,e in sgs.qlist(self.player:getEquips()) do
       table.insert(cards, e)
	end
    self:sortByKeepValue(cards, true)
	if #cards > 0 then card = cards[1] end
	if target and card then
		use.card = sgs.Card_Parse("#FenglunCard:"..card:getEffectiveId()..":&fenglun")
		if use.to then use.to:append(target) end
		return
	end
end

--Nagi
sgs.ai_skill_invoke.tianzi = function(self)
	if not self:willShowForAttack() and not self:willShowForDefence() then
		return false
	end
	return true
end

sgs.tianzi_keep_value = {
	ExNihilo = 0,
	BefriendAttacking = 0,
	Indulgence = 0,
	SupplyShortage = 0,
	Snatch = 0,
	Dismantlement = 0,
	Duel = 0,
	Drownning = 0,
	BurningCamps = 0,
	Collateral = 0,
	ArcheryAttack = 0,
	SavageAssault = 0,
	KnownBoth = 0,
	IronChain = 0,
	GodSalvation = 0,
	Fireattack = 0,
	AllianceFeast = 0,
	FightTogether = 0,
	LureTiger = 0,
	ThreatenEmperor = 0,
	AwaitExhausted = 0,
	ImperialOrder = 0
}

sgs.ai_skill_playerchosen.yuzhai = function(self, targets)
	return self:findPlayerToDiscard("he", false, sgs.Card_MethodDiscard, targets)
end

sgs.ai_skill_cardchosen.yuzhai = function(self, who, flags)
	return self:askForCardChosen(who, flags, "dismantlement")
end

--沙耶
sgs.ai_skill_invoke.qiangdou = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

local jiaoti_skill = {}
jiaoti_skill.name = "jiaoti"
table.insert(sgs.ai_skills, jiaoti_skill)
jiaoti_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("ViewAsSkill_jiaotiCard") or self.player:isKongcheng() or (not self:willShowForAttack() and not self:willShowForDefence()) then return end
	local id
	local card
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	card = cards[1]
	id = tostring(card:getId())
	if card then return  sgs.Card_Parse("keyCard"..":jiaoti["..card:getSuitString()..":"..card:getNumberString().."]=" .. id .."&jiaoti") end
end

sgs.ai_skill_choice.jiaoti = function(self, choices, data)
	local use = data:toCardUse()
	if use.from ~= nil and self:isFriend(use.from) and math.random(1,2) == 2 then return "jiaoti_ex" end
end

--瑞鹤
--[[local youdiz_skill = {}
youdiz_skill.name = "youdiz"
table.insert(sgs.ai_skills, youdiz_skill)
youdiz_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("ViewAsSkill_youdizCard") or self.player:isNude() or (not self:willShowForAttack() and not self:willShowForDefence()) then return end
	local id
	local card
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local equips = self.player:getEquips()
	equips = sgs.QList2Table(equips)
	self:sortByKeepValue(equips)
	for _,c in ipairs(cards) do
		if c:isKindOf("EquipCard") then 
			card = c
			break
        end
	end
	if not c then
		for _,c in ipairs(equips) do
			if c:isKindOf("EquipCard") then 
				card = c
				break
			end
		end
	end
	if card then
		id = tostring(card:getId()) 
		return sgs.Card_Parse("lure_tiger"..":youdiz["..card:getSuitString()..":"..card:getNumberString().."]=" .. id .."&youdiz")
	end
end]]

sgs.ai_skill_invoke.eryu = function(self, data)
	return true
end

--黑子
shunshan_skill={}
shunshan_skill.name="shunshan"
table.insert(sgs.ai_skills,shunshan_skill)
shunshan_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#ShunshanCard") then return end
	if self.player:isNude() then return end
	return sgs.Card_Parse("#ShunshanCard:.:&shunshan")
end

sgs.ai_skill_use_func["#ShunshanCard"] = function(card,use,self)
	local room = self.room
	local source = self.player
    local targets = sgs.SPlayerList()
	local target
	local card
	for _,p in sgs.qlist(room:getAlivePlayers()) do
           if source:distanceTo(p) <= 1 and source:distanceTo(p)>-1 and not p:getCards("hej"):isEmpty() then targets:append(p) end
    end
	for _,who in sgs.qlist(targets) do
       local cd = sgs.ai_skill_cardchosen["zhudao"](self, who, "hej")
	   if cd then 
		  target = who
		  break
	   end
	end
	local cards = sgs.QList2Table(source:getCards("he"))
	self:sortByKeepValue(cards)
	card = cards[1]
	if target and card then
        use.card = sgs.Card_Parse("#ShunshanCard:"..card:getEffectiveId()..":&shunshan")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_cardchosen.shunshan = function(self, who, flags)
	local card = sgs.ai_skill_cardchosen["zhudao"](self, who, flags)
	if card then
		self.room:setPlayerProperty(who, "shunshan_id", sgs.QVariant(card:getEffectiveId() + 1))
		return card
	end
end

sgs.ai_skill_playerchosen.shunshan = function(self, targets)
	local source = self.player
	local room = self.room
	local from = room:getTag("shunshanTarget"):toPlayer()
    local id = from:property("shunshan_id"):toInt()-1
	room:setPlayerProperty(from, "shunshan_id", sgs.QVariant())
	local card = sgs.Sanguosha:getCard(id)

    if not from then return targets:at(0) end
	if from:getJudgingArea():contains(card) then
		for _, target in sgs.qlist(targets) do
			if self:isEnemy(target) and not card:isKindOf("Key") then
				return target
			end
			if self:isFriend(target) and card:isKindOf("Key") then
				return target
			end
		end
	end
	if not source:getArmor() then
		for _,player in sgs.qlist(targets) do
			if self:isEnemy(player) and player:getArmor() and player:getArmor():getEffectiveId() == id and not player:hasSkills(sgs.lose_equip_skill) then
				return source
			end
		end
	end
	if not source:getTreasure() then
		for _,player in sgs.qlist(targets) do
			if self:isEnemy(player) and player:getTreasure() and player:getTreasure():getEffectiveId() == id and not player:hasSkills(sgs.lose_equip_skill) then
				return source
			end
		end
	end
	if not source:getDefensiveHorse() then
		for _,player in sgs.qlist(targets) do
			if self:isEnemy(player) and player:getDefensiveHorse() and player:getDefensiveHorse():getEffectiveId() == id and not player:hasSkills(sgs.lose_equip_skill) then
				return source
			end
		end
	end
	if not source:getWeapon() then
		for _,player in sgs.qlist(targets) do
			if self:isEnemy(player) and player:getWeapon() and player:getWeapon():getEffectiveId() == id and not player:hasSkills(sgs.lose_equip_skill) then
				return source
			end
		end
	end
	if not source:getOffensiveHorse() then
		for _,player in sgs.qlist(targets) do
			if self:isEnemy(player) and player:getOffensiveHorse() and player:getOffensiveHorse():getEffectiveId() == id and not player:hasSkills(sgs.lose_equip_skill) then
				return source
			end
		end
	end

	if #self.enemies == 1 then
		for _,badpeople in ipairs(self.enemies) do
			if badpeople:isAlive() and badpeople:getHandcards():contains(card) then
				return source
			end
		end
	end

	for _,badpeople in ipairs(self.enemies) do
		if badpeople:isAlive() and badpeople:getWeapon() and badpeople:getWeapon():getEffectiveId() == id then
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getWeapon() then
					if player:hasSkills(sgs.lose_equip_skill) then
						return player
					end
				end
			end
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getWeapon() then
					return player
				end
			end
		end
	end

	for _,badpeople in ipairs(self.enemies) do
		if badpeople:isAlive() and badpeople:getOffensiveHorse() and badpeople:getOffensiveHorse():getEffectiveId() == id then
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getOffensiveHorse() then
					if player:hasShownSkill(sgs.lose_equip_skill) then
						return player
					end
				end
			end
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getOffensiveHorse() then
					return player
				end
			end
		end
	end
	for _,badpeople in ipairs(self.enemies) do
		if badpeople:isAlive() and badpeople:getArmor() and badpeople:getArmor():getEffectiveId() == id then
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getArmor() then
					if player:hasShownSkill(sgs.lose_equip_skill) then
						return player
					end
				end
			end
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getArmor() then
					return player
				end
			end
		end
	end
	for _,badpeople in ipairs(self.enemies) do
		if badpeople:isAlive() and badpeople:getDefensiveHorse() and badpeople:getDefensiveHorse():getEffectiveId() == id then
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getDefensiveHorse() then
					if player:hasShownSkill(sgs.lose_equip_skill) then
						return player
					end
				end
			end
			for _,player in sgs.qlist(targets) do
				if self:isFriend(player) and not player:getDefensiveHorse() then
					return player
				end
			end
		end
	end

	local cardNumMin = 100
	local bestguy = source
	for _,player in ipairs(self.enemies) do
		if player:isAlive() and not player:isKongcheng() then
			for _,goodguy in sgs.qlist(targets) do
				local cardNum = goodguy:getHandcardNum()
				if cardNum < cardNumMin and self:isFriend(goodguy) then
					cardNumMin = cardNum
					bestguy = goodguy
				end
			end
			return bestguy
		end
	end
	return source
end

sgs.ai_skill_invoke.dingshen = function(self, data)
	local damage = data:toDamage()
	return (self:willShowForAttack() or self:willShowForDefence()) and self:isEnemy(damage.to)
end

--千百合
huanyuan_skill={}
huanyuan_skill.name="huanyuan"
table.insert(sgs.ai_skills,huanyuan_skill)
huanyuan_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#HuanyuanCard") then return end
	if #self.friends < 1 and #self.enemies < 1 then return end
	if self.player:isKongcheng() then return end
	for _,friend in ipairs(self.friends) do
		if friend:getTag("huanyuan_Pre_Hp"..self.player:objectName()):toInt() - friend:getHp() + (friend:getTag("huanyuan_Pre_MaxHp"..self.player:objectName()):toInt() - friend:getMaxHp())*2 > 0 then
			return sgs.Card_Parse("#HuanyuanCard:.:&huanyuan")
		end
		if friend:getTag("huanyuan_Pre_Handcards"..self.player:objectName()):toInt() > friend:getHandcardNum() then
			return sgs.Card_Parse("#HuanyuanCard:.:&huanyuan")
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHp() - enemy:getTag("huanyuan_Pre_Hp"..self.player:objectName()):toInt() + (enemy:getMaxHp() - enemy:getTag("huanyuan_Pre_MaxHp"..self.player:objectName()):toInt())*2>0 then
			return sgs.Card_Parse("#HuanyuanCard:.:&huanyuan")
		end
		if enemy:getTag("huanyuan_Pre_Handcards"..self.player:objectName()):toInt() < enemy:getHandcardNum() then
			return sgs.Card_Parse("#HuanyuanCard:.:&huanyuan")
		end
	end
	return
end

sgs.chengling_type = "huanyuan_Draw"
sgs.ai_skill_use_func["#HuanyuanCard"] = function(card,use,self)
	local target
	local value = 0
	local c
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isKindOf("BasicCard") then c = card end
    end
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		local p_v = 0
		local type = "huanyuan_Draw"
		if self:isFriend(p) then
			if p:getTag("huanyuan_Pre_Hp"..self.player:objectName()):toInt() - p:getHp() + (p:getTag("huanyuan_Pre_MaxHp"..self.player:objectName()):toInt() - p:getMaxHp())*2> p_v then
				p_v = p:getTag("huanyuan_Pre_Hp"..self.player:objectName()):toInt() - p:getHp() + (p:getTag("huanyuan_Pre_MaxHp"..self.player:objectName()):toInt() - p:getMaxHp())*2
				type = "huanyuan_Hp"
			end
			if p:getTag("huanyuan_Pre_Handcards"..self.player:objectName()):toInt() - p:getHandcardNum() > p_v*2 then
				p_v = (p:getTag("huanyuan_Pre_Handcards"..self.player:objectName()):toInt() - p:getHandcardNum())/2
				type = "huanyuan_Draw"
			end
		elseif self:isEnemy(p) then
			if p:getHp() - p:getTag("huanyuan_Pre_Hp"..self.player:objectName()):toInt() + (p:getMaxHp() - p:getTag("huanyuan_Pre_MaxHp"..self.player:objectName()):toInt())*2> p_v then
				p_v = p:getHp() - p:getTag("huanyuan_Pre_Hp"..self.player:objectName()):toInt() + (p:getMaxHp() - p:getTag("huanyuan_Pre_MaxHp"..self.player:objectName()):toInt())*2
				type = "huanyuan_Hp"
			end
			if p:getHandcardNum() - p:getTag("huanyuan_Pre_Handcards"..self.player:objectName()):toInt() > p_v*2 then
				p_v = (p:getHandcardNum() - p:getTag("huanyuan_Pre_Handcards"..self.player:objectName()):toInt())/2
				type = "huanyuan_Draw"
			end
		end
		if p_v > value then
			value = p_v
			target = p
			sgs.chengling_type = type
		end
	end
	if target and c then
		use.card = sgs.Card_Parse("#HuanyuanCard:"..c:getEffectiveId()..":&huanyuan")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_choice["huanyuan"] = function(self, choices, data)
	return sgs.chengling_type
end



sgs.ai_use_value["HuanyuanCard"] = 10
sgs.ai_use_priority["HuanyuanCard"]  = 2
sgs.ai_card_intention.HuanyuanCard = -20

chengling_skill={}
chengling_skill.name="chengling"
table.insert(sgs.ai_skills,chengling_skill)
chengling_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("@LimeBell") < 1 then return end
	if #self.friends < 2 then return end
	local OK = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and p:getMaxHp() - p:getHp() >= 2 then
			OK = OK + 1
		end
		if self:isFriend(p) and self.player:getHp() == 1 and p:getMaxHp() - p:getHp() >= 1 then
			OK = OK + 1
		end
		if self:isEnemy(p) and p:getMark("@waked") > 0 and p:getHp() > 2 then
			OK = OK + 1
		end
	end
	if #self.friends == 1 then OK = OK + 1 end
	if OK > 1 then
		return sgs.Card_Parse("#ChenglingCard:.:&chengling")
	end
	return
end

sgs.ai_skill_use_func["#ChenglingCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	for _,friend in ipairs(self.friends_noself) do
		if (friend:getMaxHp() - friend:getHp() >= 2 or (self.player:getHp() == 1 and friend:getMaxHp() - friend:getHp() >= 1)) and targets:length() < 2 and friend:hasShownAllGenerals() then
			targets:append(friend)
		end
	end
	if targets then
		use.card = sgs.Card_Parse("#ChenglingCard:.:&chengling")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["ChenglingCard"] = 10
sgs.ai_use_priority["ChenglingCard"]  = 7
sgs.ai_card_intention.ChenglingCard = -100

--爱蜜莉雅
local bingshu_skill = {}
bingshu_skill.name = "bingshu"
table.insert(sgs.ai_skills, bingshu_skill)
bingshu_skill.getTurnUseCard = function(self,room,player,data)
	if  self.player:isKongcheng() or (not self:willShowForAttack() and not self:willShowForDefence()) then return end
	self:sort(self.enemies, "defense")
	local useAll = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and --[[self.player:distanceTo(enemy) <= self.player:getAttackRange() ]] self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 + getCardsNum("GuangyuCard", enemy, self.player) then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then disCrossbow = true end

	local hecards = self.player:getCards("he")
	for _, id in sgs.qlist(self.player:getHandPile()) do
		hecards:prepend(sgs.Sanguosha:getCard(id))
	end
	local cards = {}
	for _, card in sgs.qlist(hecards) do
		if card:isBlack() and card:isKindOf("BasicCard") then
			local suit = card:getSuitString()
			local number = card:getNumberString()
			local card_id = card:getEffectiveId()
			local card_str = ("ice_slash:bingshu[%s:%s]=%d&bingshu"):format(suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
			assert(slash)
			if self:slashIsAvailable(self.player, slash) then
				table.insert(cards, slash)
			end
		end
	end

	if #cards == 0 then return end

	self:sortByUsePriority(cards)
	return cards[1]
end

function sgs.ai_cardneed.bingshu(to, card)
	return to:getHandcardNum() < 3 and card:isBlack() and card:isKindOf("BasicCard")
end

sgs.ai_view_as.bingshu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getHandPile():contains(card_id)) and card:isBlack() and card:isKindOf("BasicCard") then
		return ("ice_slash:bingshu[%s:%s]=%d&bingshu"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.lingshi = function(self, data)
	local current = self.room:getCurrent()
	if current == self.player then
		return self:willShowForAttack() or self:willShowForDefence()
	end
end

--琴里
zhuogui_skill={}
zhuogui_skill.name="zhuogui"
table.insert(sgs.ai_skills,zhuogui_skill)
zhuogui_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#ZhuoguiCard") then return end
	return sgs.Card_Parse("#ZhuoguiCard:.:&zhuogui")
end

sgs.ai_skill_use_func["#ZhuoguiCard"] = function(card,use,self)
	local count = 0
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if not c:isKindOf("Basic") then
			count = count+1
		end
	end
	local targets = sgs.SPlayerList()
	local enemies = self.enemies
	self:sort(enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("fire_slash")
	for _,e in ipairs(enemies) do
		if targets:length() < count and (not e:hasShownSkill("huansha") or self.player:getMark("drank")>0) and not e:hasShownSkill("tianhuo") and self:slashIsEffective(slash, e, self.player) then
			targets:append(e)
		end
	end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if not c:isKindOf("BasicCard") and #needed < targets:length() then
			table.insert(needed, c:getEffectiveId())
		end
	end
	if targets:length()>0 and #needed == targets:length() then
		use.card = sgs.Card_Parse("#ZhuoguiCard:"..table.concat(needed, "+")..":&zhuogui")
		if use.to then
			use.to = targets
		end
		return
	end
end

sgs.ai_use_priority["ZhuoguiCard"]  = 5

sgs.ai_skill_choice.zhuogui = function(self, choices, data)
	local damage = data:toDamage()
	if not self:isEnemy(damage.to) then return "zhuogui_draw" end
	for _,c in sgs.qlist(damage.to:getCards("e")) do
		if self:getKeepValue(c) >=5 then
			return "zhuogui_discard"
		end
	end
	return "zhuogui_draw"
end

sgs.ai_skill_invoke.tongyu = function(self, data)
	if #self.friends_noself > 1 then return true end
	if #self.friends_noself > 0 then
       if self.player:getHandcardNum()>self.friends_noself[1]:getHandcardNum() then return true end
	   for _,e in ipairs(self.enemies) do
          if self.friends_noself[1]:inMyAttackRange(e) and getCardsNum("Slash", self.friends_noself[1], self.player)>0 then
			return true
		  end
	   end
	end
end

sgs.ai_skill_playerchosen.tongyu = function(self, targets)
   local result = {}
   local friends = self.friends
   self:sort(friends, "handcard")
   if #friends >1 then
	  table.insert(result, friends[1])
	  table.insert(result, friends[2])
   elseif #friends == 1 then
	  table.insert(result, friends[1])
   end
   return result
end

--枣玲
sgs.ai_skill_invoke.maoqun = function(self, data)
	return true
end

maoqun_skill={}
maoqun_skill.name="maoqun"
table.insert(sgs.ai_skills,maoqun_skill)
maoqun_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#MaoqunCard") then return end
	return sgs.Card_Parse("#MaoqunCard:.:&maoqun")
end

sgs.ai_skill_use_func["#MaoqunCard"] = function(card,use,self)
	local target 
	local card
	local pile = self.player:getPile("RinNeko")
	for _,e in ipairs(self.enemies) do
       if e:getHandcardNum()<=e:getMaxCards() and not e:hasShownSkill("jilan") and not e:hasShownSkill("jiyi") and not e:hasShownSkill("wuming") then
           for _,id in sgs.qlist(pile) do
			 local c = sgs.Sanguosha:getCard(id)
			 if c:getSuitString()=="spade" then
				target = e
				card = c
				break
			 end
		   end
		   if target and c then break end
	   end
	   if e:getHandcardNum()>e:getMaxCards() then
		for _,id in sgs.qlist(pile) do
		  local c = sgs.Sanguosha:getCard(id)
		  if c:getSuitString()=="club" then
			 target = e
			 card = c
			 break
		  end
		end
		if target and c then break end
	   end
	   if self:isWeak(e) then
		for _,id in sgs.qlist(pile) do
		  local c = sgs.Sanguosha:getCard(id)
		  if c:getSuitString()=="heart" then
			 target = e
			 card = c
			 break
		  end
		end
		if target and c then break end
	   end
	   if self:isWeak(e) then
		for _,id in sgs.qlist(pile) do
		  local c = sgs.Sanguosha:getCard(id)
		  if c:getSuitString()=="diamond" then
			 target = e
			 card = c
			 break
		  end
		end
		if target and c then break end
	   end
	end
	if target and card then
		use.card = sgs.Card_Parse("#MaoqunCard:"..card:getEffectiveId()..":&maoqun")
		if use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_skill_invoke.rinjiuyuan = function(self, data)
	local dying = data:toDying()
	local damage = data:toDamage()
	if dying.who then return self:isFriendWith(dying.who) end
	if damage then return self:isFriendWith(damage.to) end
end

sgs.ai_skill_invoke.pasheng = function(self, data)
	local use = data:toCardUse()
	return getTrickIntention(use.card:getClassName(), self.player)>0
end

--珂朵莉
sgs.ai_skill_invoke.ranxin = function(self, data)
	local damage = data:toDamage()
	if damage and damage.from then return true end
	return not self:isWeak() and (self:willShowForAttack() or self:willShowForDefence())
end

--夜斗
sgs.ai_skill_invoke.zhanyuan = function(self, data)
	local damage = data:toDamage()
	if damage then return self:isEnemy(damage.to) or (self:isFriendWith(damage.to) and not noNeedToRemoveJudgeArea(damage.to) and damage.to:getJudgingArea():length()>0) end
end

sgs.ai_skill_invoke.shenqi = function(self, data)
	local use = data:toCardUse()
	if use then return math.random(1,2) == 1 end
	return true
end

--宁子

sgs.ai_skill_invoke.nekojiyi = true

local moshi_skill = {}
moshi_skill.name = "moshi"
table.insert(sgs.ai_skills, moshi_skill)
moshi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("ViewAsSkill_moshiCard") then return end
	if #self.enemies < 1 or self.player:getMark("Nekojiyi_suit")< 1 then return end
	return sgs.Card_Parse("#moshiCard:.:&moshi")
end

sgs.ai_skill_use_func["#moshiCard"] = function(card, use, self)
	local target
	local targets = {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and not p:isNude() then
			table.insert(targets, p)
		end
	end
	if #targets > 0 then
    	self:sort(targets, "chaofeng")
    	target = targets[1]
		use.card = sgs.Card_Parse("#moshiCard:.:&moshi")
		if use.to then
			use.to:append(target)
		end
	end 
end

sgs.ai_skill_choice.moshi = "moshi_bottom"

sgs.ai_skill_playerchosen.moshi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")	
	for _, target in ipairs(targets) do
		if self:isFriend(target) then
			return target
		end
	end
	return nil
end
--[[sgs.ai_skill_invoke.nekojiyi = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.moshi = function(self, data)
	return true
end

sgs.ai_skill_choice.moshi= function(self, choices, data)
	local use = data:toCardUse()
	local has
	for _,p in sgs.qlist(use.to) do
		if self:isEnemy(p) and self:isWeak(p) then has = true end
	end
	if table.contains(choices:split("+"), "3") and has then return "3" end
	return "1"
end

sgs.ai_skill_playerchosen.moshi = function(self, targets)   
    local result = {}
	for _,name in sgs.qlist(targets)do
		if  self:isEnemy(name) then table.insert(result, findPlayerByObjectName(name:objectName())) end
	end
	return result
end]]

--芬格尔
sgs.ai_skill_invoke.yizhigame = function(self, data)
	local death = data:toDeath()
	if death and death.who and death.who:objectName() ~= self.player:objectName() then return not self:isEnemy(death.who) end
	if death and death.who and death.who:objectName() == self.player:objectName() then return #self.friends_noself>0 end
	local source = data:toPlayer()
	if source then return self:isFriend(source) end
end

sgs.ai_skill_playerchosen.yizhigame = function(self, targets)   
	for _,p in sgs.qlist(targets)do
		if self:isFriend(p) then return p end
	end
	return nil
end

sibie_skill={}
sibie_skill.name="sibie"
table.insert(sgs.ai_skills,sibie_skill)
sibie_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#sibieCard:.:&sibie")
end

sgs.ai_skill_use_func["#sibieCard"] = function(card,use,self)
	local target
	local min = 999
	local can = true
	local needdie = false
	local has
	for _,p in sgs.qlist(self.player:getAliveSiblings()) do
		if self.player:hasFlag("sibie"..p:objectName()) then
			has = p
		end
	end
	for _,e in ipairs(self.enemies) do
		if e:getHp() > self.player:getHp() and e:getHp() < min and (not has or has:objectName() == e:objectName()) then
			min = e:getHp()
		end
	end
	for _,e in ipairs(self.enemies) do
		if 	e:getHp() > self.player:getHp() and e:getHp() == min and (not has or has:objectName() == e:objectName()) then
			target = e
			break
		end
	end
	if self.player:getHp()<=1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 and self:getCardsNum("GuangyuCard") == 0 then can = false end
	if (self.player:getMark("@yizhigame1") > 0 or self.player:getMark("@yizhigame2") > 0 or self.player:getMark("@yizhigame3") > 0 or self.player:getMark("@yizhigame4") > 0) and #self.friends_noself > 0 then
       if target and self:isWeak(target) and #self.friends_noself >= #self.enemies -1 then needdie = true end
	end
	if target and (can or needdie) then
		use.card = sgs.Card_Parse("#sibieCard:.:&sibie")
		if use.to then use.to:append(target) end
		return
	end
end

--成步堂
sgs.ai_skill_invoke.quzheng = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_askforag.quzheng = function(self, card_ids)
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		local pile = self.player:getPile("evidence")
		if pile:isEmpty() and card:isBlack() then
			return id
		end
		if pile:length()==1 and sgs.Sanguosha:getCard(pile:at(0)):getColor() ~= card:getColor() then
			return id
		end
		if pile:length()==2 then
			if sgs.Sanguosha:getCard(pile:at(0)):isBlack() and sgs.Sanguosha:getCard(pile:at(1)):isBlack() then
				if card:isRed() then return id end
			else
				if card:isBlack() then return id end
			end
		end
	end
 end

sgs.ai_view_as.nizhuan = function(card, player, card_place)
    local list = player:getPile("evidence")
	if list:length()<1 then return end
	local card1
	local slash = player:getRoom():getTag("IgiariCard"):toCard()
	if not slash:isKindOf("Slash") then slash = false end
	local h = 0
	local b = 0
	for _,i in sgs.qlist(list) do
	    local c = sgs.Sanguosha:getCard(i)
	    if c:isRed() then h = h+1 end
	    if c:isBlack() then b = b+1 end
	end
	for _,i in sgs.qlist(list) do
	    local c = sgs.Sanguosha:getCard(i)
	    if slash and c:getColor() == slash:getColor() then
			card1 = c
			break
	    end
		if (not slash or not card1) and h>=b and c:isRed() then
           card1 = c
		   break
		end
		if (not slash or not card1) and h<b and c:isBlack() then
			card1 = c
			break
		end
	end
	if not card1 then
	   card1 = sgs.Sanguosha:getCard(list:at(0))
	end
	
	local id = card1:getEffectiveId()
	local str = ("igiari:%s[%s:%s]=%d&nizhuan"):format("nizhuan", "to_be_decided", "-", id)
	return str
end

--四宫辉夜
sgs.ai_skill_invoke.jinchi = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

slianji_skill={}
slianji_skill.name="slianji"
table.insert(sgs.ai_skills,slianji_skill)
slianji_skill.getTurnUseCard=function(self,inclusive)
	if self.player:isNude() or self.player:hasUsed("#SlianjiCard") then return end
	if not self:willShowForAttack() and not self:willShowForDefence() then return end
	return sgs.Card_Parse("#SlianjiCard:.:&slianji")
end

sgs.ai_skill_use_func["#SlianjiCard"] = function(card,use,self)
	local target
	local card
	local min = 999
	for _,e in ipairs(self.enemies) do
		if e:getHandcardNum() < min and not e:isKongcheng() then
			min = e:getHandcardNum()
		end
	end
	for _,e in ipairs(self.enemies) do
		if 	e:getHandcardNum() == min then
			target = e
			break
		end
	end
    if not target then
       for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		  if p:getHandcardNum()>4 then
			 target = p
			 break
		  end
	   end
	end
	local equips = sgs.QList2Table(self.player:getCards("e"))
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(equips)
	self:sortByKeepValue(cards)
	if self.player:hasSkill("zhudao") and #equips>0 then card = equips[1] end
	if not card and #cards>0 and (not self:isWeak() or self.player:getHandcardNum()>self.player:getMaxCards()) then
        card = cards[1]
	end
	if not card and #equips>0 then
        card = equips[1]
	end
	if target and card then
		use.card = sgs.Card_Parse("#SlianjiCard:"..card:getEffectiveId()..":&slianji")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_choice.slianji = function(self, choices, data)
	local id = data:toInt()
	local card = sgs.Sanguosha:getCard(id)
	local choices = choices:split("+")
	table.removeOne(choices, card:getSuitString())
	if card:isKindOf("BasicCard") then
		table.removeOne(choices, "BasicCard")
	elseif card:isKindOf("TrickCard") then
		table.removeOne(choices, "TrickCard")
	elseif card:isKindOf("EquipCard") then
		table.removeOne(choices, "EquipCard")
	end
	local n = math.random(1,8)
    if table.contains(choices, "heart") and n<=3 then
		return "heart"
	elseif table.contains(choices, "TrickCard") and n<=6 and n>3 then
		return "TrickCard"
	elseif n<= 6 then
        if table.contains(choices, "heart") then
			return "heart"
		else
			return "TrickCard"
		end
	end
end

--Saki
sgs.ai_skill_invoke.lingshang = function(self, data)
	local move = data:toMoveOneTime()
	if move then
		return self:willShowForAttack() or self:willShowForDefence()
	else
		return true
	end
end

sgs.ai_skill_use["@@lingshang"] = function(self, prompt)
	if self:isWeak() and self.player:getHandcardNum()<3 and self.player:getPhase() == sgs.Player_NotActive then return "." end
	if (#self.enemies + math.min(self.player:getLostHp(), (self.room:getOtherPlayers(self.player)):length())<=self.player:getMark("#SakiMark") or self.player:hasUsed("#guilingCard") or not self.player:hasSkill("guiling")) 
	and self.player:getHandcardNum()<self.player:getMaxCards()+2 and self.player:getPhase() ~= sgs.Player_NotActive then return "." end
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		for _,d in ipairs(cards) do
			if c:getId()~=d:getId() and c:getTypeId() == d:getTypeId() and #needed == 0 then
			    table.insert(needed, c:getEffectiveId())
				table.insert(needed, d:getEffectiveId())
				break
			end          
		end        
	end
	if #needed==2 then
		return ("#lingshangCard:"..table.concat(needed, "+")..":&->")
	end
	return "."
end

guiling_skill={}
guiling_skill.name="guiling"
table.insert(sgs.ai_skills,guiling_skill)
guiling_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#guilingCard") then return end
	return sgs.Card_Parse("#guilingCard:.:&guiling")
end

sgs.ai_skill_use_func["#guilingCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	local n = math.min(self.player:getMark("#SakiMark"), 3)
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		local targets_table = sgs.QList2Table(targets)
		if targets:length() < n and not e:hasShownSkill("huansha") and add_different_kingdoms(e, targets_table) then
			targets:append(e)
		end
	end
	if targets:length() < n then
	   local a = targets:length()
       local x = math.min(n - a, self.player:getLostHp())
       for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		  local targets_table = sgs.QList2Table(targets)
		  if targets:length() < a+x and not targets:contains(p) and add_different_kingdoms(p, targets_table) then
			targets:append(p)
		  end
	   end
    end
	if targets:length()>0 then
		use.card = sgs.Card_Parse("#guilingCard:.:&guiling")
		if use.to then
			use.to = targets
		end
		return
	end
end

sgs.ai_skill_choice.guiling = function(self, choices, data)
	local choices = choices:split("+")
	local source = data:toPlayer()
	if self:isFriend(source) and table.contains(choices, "guilingRecover") then return "guilingRecover" end
end

--惠惠
sgs.ai_skill_invoke.yinchang = function(self, data)
	local damage = data:toDamage()
	local has
	for _,id in sgs.qlist(self.player:getPile("yinchang")) do
		local card = sgs.Sanguosha:getCard(id)
		if self:getKeepValue(card)>=5 then has = true end
	end
	if damage and damage.to then
       return self:isWeak() and has
	end
	local pile = self.player:getPile("yinchang")
	if self:isWeak() and self.player:getCards("he"):length() <3 and pile:isEmpty() then return false end 
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_askforag.yinchang = function(self, card_ids)
	local cards = {}
	local own
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if self.player:getCards("he"):contains(card) then own = true end
		table.insert(cards, card)
	end
    if own then
	   self:sortByKeepValue(cards)
	   return cards[1]:getId()
    else
	   self:sortByKeepValue(cards, true)
	   return cards[1]:getId()
	end
 end

sgs.ai_skill_invoke.baolie = function(self, data)
	return #self.enemies>0
end

sgs.ai_skill_use["@@baolie"] = function(self, prompt)
	if #self.enemies == 0 then return "." end
	local targets = {}
	local n = self.player:getPile("yinchang"):length()
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		if #targets < n-1 and not e:hasShownSkill("tianhuo") then
			table.insert(targets, e:objectName())
			table.insert(targets, e:objectName())
			continue
		end
		if #targets < n and not e:hasShownSkill("tianhuo") and not e:hasShownSkill("huansha")then
			table.insert(targets, e:objectName())
		end
	end
	if #targets > 0 then
		return ("#BaolieCard:.:&->"..table.concat(targets, "+"))
	end
	return "."
end

sgs.ai_skill_choice.guiling = function(self, choices, data)
	local choices = choices:split("+")
	local source = data:toPlayer()
	if self:isFriend(source) and table.contains(choices, "guilingRecover") then return "guilingRecover" end
end

--露西
sgs.ai_skill_invoke.lingqi = true

sgs.ai_skill_invoke["#xinglingShown"] = function(self, data)
	local use = data:toCardUse()
	if use and use.card then return true end
	local f = 0 
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == self.player:objectName() then
			for _,c in sgs.qlist(p:getCards("j")) do
                if c:getSuitString() == "diamond" then f = f+1 end
			end
		elseif self:isFriend(p) then
            for _,c in sgs.qlist(p:getCards("e")) do
                if c:getSuitString() == "diamond" then f = f-0.5 end
			end
			for _,c in sgs.qlist(p:getCards("j")) do
				if c:isKindOf("Key") and not p:isWounded() then
					continue
				elseif c:getSuitString() == "diamond" then
					f = f+1
				end
			end
		elseif self:isEnemy(p) then
			for _,c in sgs.qlist(p:getCards("e")) do
                if c:getSuitString() == "diamond" then f = f+1 end
			end
			for _,c in sgs.qlist(p:getCards("j")) do
				if c:isKindOf("Key") and not p:isWounded() then
					f = f+1
				elseif c:getSuitString() == "diamond" then
					f = f-1
				end
			end
		else
			for _,c in sgs.qlist(p:getCards("ej")) do
                if c:getSuitString() == "diamond" then f = f+1 end
			end
        end
	end
	return f>0
 end

sgs.ai_skill_choice.xingling = function(self, choices, data)
	if string.find(self.player:getActualGeneral2Name(), "sujiang") then return "xingling_change" end
end

local xingling_skill = {}
xingling_skill.name = "xingling"
table.insert(sgs.ai_skills, xingling_skill)
xingling_skill.getTurnUseCard = function(self,room,player,data)
	if self.player:hasUsed("ViewAsSkill_xinglingCard") or self.player:isNude() or (not self:willShowForAttack() and not self:willShowForDefence()) then return end
	local id
	local card
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local equips = self.player:getEquips()
	equips = sgs.QList2Table(equips)
	self:sortByKeepValue(equips)
	for _,c in ipairs(cards) do
		if c:getSuitString()=="diamond" and (self.player:getHandcardNum()> self.player:getMaxCards() or self:getKeepValue(c)<3) then 
			card = c
			break
        end
	end
	if not c then
		for _,c in ipairs(equips) do
			if c:getSuitString()=="diamond" and self:getKeepValue(c)<5 then 
				card = c
				break
			end
		end
	end
	if card then
		id = tostring(card:getId()) 
		return sgs.Card_Parse("eirei_shoukan"..":xingling["..card:getSuitString()..":"..card:getNumberString().."]=" .. id .."&xingling")
	end
end

--紫苑老鼠
sgs.ai_skill_invoke.kangshi = true

kangshi_skill={}
kangshi_skill.name="kangshi"
table.insert(sgs.ai_skills,kangshi_skill)
kangshi_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#KangshiCard") then return end
	local list = self.player:getBigKingdoms("kangshi",sgs.Max)
	if  not sgs.isBigKingdom(self.player, "kangshi") and #list == 1 then
	    return sgs.Card_Parse("#KangshiCard:.:&kangshi")
	end
end

sgs.ai_skill_use_func["#KangshiCard"] = function(card,use,self)
	local can
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if sgs.isBigKingdom(p, "kangshi") and self:isEnemy(p) then
			can = true
			break
		end
	end
	if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 and self:getCardsNum("GuangyuCard") == 0  then can = false end
	if not can then return end
	use.card = sgs.Card_Parse("#KangshiCard:.:&kangshi")
	return
end

sgs.ai_skill_invoke.qingban = function(self, data)
	local dest = data:toDying().who
	return self:isFriend(dest)
end

--食蜂操祈
sgs.ai_skill_invoke.paifa = function(self, data)
	return self:isFriend(data:toPlayer())
end

sgs.ai_skill_choice.paifa = function(self, choices, data)
	if self:isFriend(data:toPlayer()) then return "paifa_accept" end
end

sgs.ai_skill_invoke["#paifatr"] = function(self, data)
	return true
end

sgs.ai_skill_choice["#paifatr"] = function(self, choices, data)
	local count = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasClub("nvking") and not p:isNude() then count = count+1 end
	end
    if self.player:isNude() then return "paifa_recast" end
    if count >=3 and math.random(1,3) == 3 then return "paifa_recast" end
	return "paifa_draw"
end

sgs.ai_skill_invoke.xinkong = function(self, data)
	return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.xinkong = function(self, targets)
	local uni
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if not targets:contains(p) then
			uni = p
			break
		end
	end
	if not uni then return nil end
	if uni == self.player then
	   local enemies = self.enemies
	   self:sort(enemies, "defense")
       return enemies[1]
	else
		local enemies = self.enemies
		self:sort(enemies, "defense")
		for _e in ipairs(enemies) do
			if e ~= uni then return e end
		end
		for _,p in sgs.qlist(self.room:getOtherPlayers(uni)) do
		   if not uni:inMyAttackRange(p) then return p end
		end
	end
end

sgs.ai_skill_choice.xinkong = function(self, choices, data)
	local enemies = self.enemies
	self:sort(enemies, "defense")
	if #enemies > 0 and (self:isWeak(enemies[1]) or math.random(1,2) == 2) and self.player:getHandcardNum()<= self.player:getMaxCards()+2 then
		return "@xinkong2"
	end
	return "@xinkong1"
end

--玲
sgs.ai_skill_invoke.lianwu = function(self, data)
	local damage = data:toDamage()
	return (self:willShowForAttack() or self:willShowForDefence()) and self:isEnemy(damage.to)
end

local chahui_skill = {}
chahui_skill.name = "chahui"
table.insert(sgs.ai_skills, chahui_skill)
chahui_skill.getTurnUseCard = function(self)
	if self:willShowForAttack() and not self.player:hasUsed("#ChahuiCard") and not self.player:isKongcheng() then return sgs.Card_Parse("#ChahuiCard:.:&chahui") end
end

sgs.ai_skill_use_func["#ChahuiCard"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			use.card = sgs.Card_Parse("#ChahuiCard:.:&chahui")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

--射命丸文
local shenfeng_skill = {}
shenfeng_skill.name = "shenfeng"
table.insert(sgs.ai_skills, shenfeng_skill)
shenfeng_skill.getTurnUseCard = function(self)
	if (self:willShowForAttack() or self:willShowForDefence()) and not self.player:hasUsed("#ShenfengCard") and not self.player:isKongcheng() then return sgs.Card_Parse("#ShenfengCard:.:&shenfeng") end
end

sgs.ai_skill_use_func["#ShenfengCard"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local enemies = sgs.reverse(self.enemies)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, enemy in ipairs(enemies) do
		if not enemy:isKongcheng() and (enemy:getHandcardNum()>2 or self:isWeak(enemy)) then
			use.card = sgs.Card_Parse("#ShenfengCard:"..cards[1]:getEffectiveId()..":&shenfeng")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_skill_askforag.shenfeng = function(self, card_ids)
	local cards = {}
	local id1 = self.player:property("shenfeng_firstid"):toInt()-1
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
    self:sortByKeepValue(cards, true)
	for _,card in ipairs(cards) do
		if id1 > -1 and card:getId() == id1 then continue end
		if not card:isKindOf("BasicCard") then return card:getId() end
	end
	for _,card in ipairs(cards) do
		if id1 > -1 and card:getId() == id1 then continue end
		if card:isKindOf("Peach") then return card:getId() end
	end
	for _,card in ipairs(cards) do
		if id1 > -1 and card:getId() == id1 then continue end
		if card:isKindOf("GuangyuCard") then return card:getId() end
	end
	for _,card in ipairs(cards) do
		if id1 > -1 and card:getId() == id1 then continue end
		if card:isKindOf("Analeptic") then return card:getId() end
	end
	for _,card in ipairs(cards) do
		if id1 > -1 and card:getId() == id1 then continue end
		if self:getKeepValue(card) >= 5 then return card:getId() end
	end
	return -1
 end

sgs.ai_skill_invoke.jilan = function(self, data)
	for _,f in ipairs(self.friends) do
		local hasjudge
	    for _,c in sgs.qlist(f:getCards("j")) do
	      if not c:isKindOf("Key") then hasjudge = true end
        end
	    if hasjudge then return true end
	end
	for _,e in ipairs(self.enemies) do
		local hasgood
	    for _,c in sgs.qlist(e:getCards("e")) do
	      if self:getKeepValue(c) >= 5 then hasgood = true end
        end
	    if hasgood then return true end
	end
	for _,f in ipairs(self.friends) do
		local needremovekey
	    for _,c in sgs.qlist(f:getCards("j")) do
	      if c:isKindOf("Key") and f:isWounded() then needremovekey = true end
        end
	    if needremovekey then return true end
	end
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash")
		if self:isWeak(e) and self.player:canSlash(e, nil, false) and self:slashIsEffective(slash, e, self.player) then
			return true
		end
	end
end

sgs.ai_skill_choice.jilan = function(self, choices, data)
	local card  = data:toCard()
	for _,f in ipairs(self.friends) do
	    for _,c in sgs.qlist(f:getCards("j")) do
	      if not c:isKindOf("Key") and c:getSuit()~=card:getSuit() then return "jilan_obtain" end
        end
	end
	for _,e in ipairs(self.enemies) do
	    for _,c in sgs.qlist(e:getCards("e")) do
	      if self:getKeepValue(c) >= 5 and c:getSuit()~=card:getSuit() then return "jilan_obtain" end
        end
	end
	for _,f in ipairs(self.friends) do
	    for _,c in sgs.qlist(f:getCards("j")) do
	      if c:isKindOf("Key") and f:isWounded() and c:getSuit()~=card:getSuit() then return "jilan_obtain" end
        end
	end
	local enemies = self.enemies
	self:sort(enemies, "defense")
	for _,e in ipairs(enemies) do
		local slash = sgs.Sanguosha:cloneCard("slash")
		if self:isWeak(e) and self.player:canSlash(e, nil, false) and self:slashIsEffective(slash, e, self.player) then
			return "jilan_slash"
		end
	end
end

sgs.ai_skill_playerchosen.jilan = function(self, targets)
	local card = self.player:property("jilan_card"):toCard()
	for _,f in ipairs(self.friends) do
	    for _,c in sgs.qlist(f:getCards("j")) do
	      if not c:isKindOf("Key") and c:getSuit()~=card:getSuit() then return f end
        end
	end
	for _,e in ipairs(self.enemies) do
	    for _,c in sgs.qlist(e:getCards("e")) do
	      if self:getKeepValue(c) >= 5 and c:getSuit()~=card:getSuit() then return e end
        end
	end
	for _,f in ipairs(self.friends) do
	    for _,c in sgs.qlist(f:getCards("j")) do
	      if c:isKindOf("Key") and f:isWounded() and c:getSuit()~=card:getSuit() then return f end
        end
	end
end

sgs.ai_skill_askforag.jilan = function(self, card_ids)
	local target = self.player:property("jilan_target"):toPlayer()
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if self:isFriend(target) and target:getCards("j"):contains(card) and not card:isKindOf("Key") then
			return id
		end
		if self:isEnemy(target) and target:getCards("e"):contains(card) and self:getKeepValue(card) >= 5 then
			return id
		end
		if self:isFriend(target) and target:getCards("j"):contains(card) and card:isKindOf("Key") and target:isWounded() then
			return id
		end
	end
 end

 sgs.ai_skill_use["@@jilan"] = function(self, prompt)
	local slash = sgs.cloneCard("slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")
	local tos = {}
	if dummy_use.card and not dummy_use.to:isEmpty() then
		for _, to in sgs.qlist(dummy_use.to) do
			table.insert(tos, to:objectName())
		end
		return "#JilanCard:.:&->"..table.concat(tos, "+")
	end
	return "."
end


---夜刀神十香
aosha_skill={}
aosha_skill.name="aosha"
table.insert(sgs.ai_skills,aosha_skill)
aosha_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#aoshaCard") then return end
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("#aoshaCard:.:&aosha")
end

sgs.ai_skill_use_func["#aoshaCard"] = function(card,use,self)
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
	    if not c:isKindOf("BasicCard") and #needed < 1 then----not c:isAvailable(self.player)and
			table.insert(needed, c:getEffectiveId())
		end
	end
	if #needed > 0 then
    	use.card = sgs.Card_Parse("#aoshaCard:"..table.concat(needed, "+")..":&aosha")
		return
	end
	return "."
end

sgs.ai_use_priority.aoshaCard = 5

sgs.ai_skill_invoke.jiankai_discard = true
sgs.ai_skill_invoke.jiankai_draw = true

--薇尔莉特·伊芙加登
vshouji_skill={}
vshouji_skill.name="vshouji"
table.insert(sgs.ai_skills,vshouji_skill)
vshouji_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("#vshoujiCard") then return end
	return sgs.Card_Parse("#vshoujiCard:.:&vshouji")
end

sgs.ai_skill_use_func["#vshoujiCard"] = function(card,use,self)
	local targets = sgs.SPlayerList()
	for _, friend in ipairs(self.friends) do
		if targets:length() < 1 and not friend:isNude() then
			targets:append(friend)
		end
	end
	if targets:length()>0 then
		use.card = sgs.Card_Parse("#vshoujiCard:.:&vshouji")
		if use.to then
			use.to = targets
		end
		return
	end
end

sgs.ai_skill_invoke.gongqing = function(self, data)
	local target = data:toPlayer()
	if target then
		return not self:isEnemy(target)
	end
end

sgs.ai_skill_discard["gongqing"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end

--ZeroTwo
sgs.ai_skill_invoke.xieyu = function(self, data)
    if self.player:isRemoved() then return end
	local target = 0
    for _,enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self.player:getHp() > 1 then
			target = target + 1
			break
		end
	end
	if target == 1then
	    return true
	end
	return false
end
sgs.ai_skill_use["@@xieyu"] = function(self, prompt)
	local slash = sgs.cloneCard("slash")
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash, dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")
	local tos = {}
	if dummy_use.card and not dummy_use.to:isEmpty() then
		for _, to in sgs.qlist(dummy_use.to) do
			table.insert(tos, to:objectName())
		end
		return "#xieyuCard:.:&->"..table.concat(tos, "+")
	end
	return "."
end

sgs.ai_skill_invoke.kuanghe = function(self, data)
	if self.player:getHp() == 1 and self.player:getHandcardNum() < 4 then
	    return true
	end
	return false
end

--惣流·明日香·兰格雷
sgs.ai_skill_invoke.aoshi = true
sgs.ai_skill_playerchosen.aoshi = function(self, targets)
	targets = sgs.QList2Table(targets)
	local drawTarget
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not target:isKongcheng() then drawTarget = target end 
	end
	if drawTarget then return drawTarget end
end

sgs.ai_skill_askforag.aoshi = function(self, card_ids)
   for i, id in ipairs(card_ids) do
       for j, id2 in ipairs(card_ids) do
		   if i ~= j and sgs.Sanguosha:getCard(id):getNumber() >= sgs.Sanguosha:getCard(id2):getNumber() then
			  return id
		   end
		end   
   end
   return card_ids[2]
   ----return -1
end

sgs.ai_skill_invoke.xinshang = true
sgs.ai_skill_choice.xinshang = "xinshang_draw"

--佐久名
sgs.ai_skill_invoke.gengzhong = true
sgs.ai_skill_invoke.xuemai = true

--秦心
sgs.ai_skill_invoke.ranxv = function(self, data)
    if (self.player == self.room:getCurrent() or self.player:isFriendWith(self.room:getCurrent())) and self.player:inMyAttackRange(self.room:getCurrent())then return true end
	return false
end
sgs.ai_skill_invoke.ranxv_recast = true

--宫园薰

sgs.ai_skill_invoke["#zhiliansShown"] = true

sgs.ai_skill_playerchosen["#zhiliansShown"] = function(self)
	local result = {}
	local names = self.friends_noself
	if #names >1 then
		table.insert(result, names[1])
	elseif #names == 1 then
		table.insert(result, names[1])   
	end
	return result
end
sgs.ai_skill_invoke.yixins = true
sgs.ai_skill_invoke.zhilians = function(self, data)
   if not (self.player:hasSkills("jinqu") or self.player:hasSkills("wenchang")or self.player:hasSkills("yuanshu")or self.player:hasSkills("jinchi")or self.player:hasSkills("maoqun"))then return true end
end

--古河渚

sgs.ai_skill_choice.yanju = function(self, choices, data)
	if self:isFriend(data:toPlayer()) then return "yanju_accept" end
	return "cancel"
end
