--团长
sgs.ai_skill_invoke.mengxian = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_invoke.yuanwang = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_choice.yuanwang = function(self, choices, data)
	local haruhi = self.room:findPlayerBySkillName("yuanwang")
	if not haruhi then return "cancel" end
	if self:isFriend(haruhi) then return "yuanwang_accept" end
	return "yuanwang_accept"
end

sgs.ai_skill_playerchosen.yuanwang = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then return p end
	end
	return
end

sgs.ai_skill_invoke.yuanwangsos = function(self, data)
    local can
	if self.player:getHandcards():length()<=1 then return false end
	if self.player:getMark("ThreatenEmperorExtraTurn") > 0 then return false end
    for _,c in sgs.qlist(self.player:getHandcards()) do
	   if c:isBlack() then
	      can = true
	   end 
	end
	return can
end

sgs.ai_skill_askforag.yuanwang = function(self, card_ids)
   local cards = sgs.QList2Table(self.player:getHandcards())
   self:sortByKeepValue(cards)
   for _,c in ipairs(cards) do
	   if c:isBlack() then
	      return c:getEffectiveId()
	   end 
   end
end

--创真
sgs.ai_skill_invoke.pengtiao = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_use["@@pengtiao"] = function(self, prompt)
    local current = self.room:getCurrent()
	if current and not self:isFriend(current) then
		return "."
	end
	if (self.player:isRemoved()) then
	    return "."
	end
    for _,f in ipairs(self.friends_noself) do
	  if f:objectName()~=current:objectName() and not self.player:isWounded() and f:isWounded() and not f:hasFlag("pengtiao_cancel") and not f:isRemoved() then
	    return "."
	  end
	end
	local cards=sgs.QList2Table(self.player:getHandcards())
	local equips=sgs.QList2Table(self.player:getEquips())
	local needed = {}
	for _,acard in ipairs(cards) do
		if #needed == 0 and (acard:isKindOf("Peach") or acard:isKindOf("Analeptic") or acard:getNumber()==13 or acard:getSubtype()=="food_card") then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	for _,acard in ipairs(equips) do
		if #needed == 0 and (acard:isKindOf("Peach") or acard:isKindOf("Analeptic") or acard:getNumber()==13 or acard:getSubtype()=="food_card") then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if #needed==1 then
		return ("@PengtiaoCard="..table.concat(needed, "+").."&")
	end
	return "."
end

sgs.ai_skill_invoke.shiji = function(self, data)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local OK = false
	for _,card in ipairs(cards) do
		if card:getNumber() > 6 then
			OK =true
		end
	end
	if self:isEnemy(data:toPlayer()) then
        return OK or self.player:getHp() <= data:toPlayer():getHp()     
    end
    return false
end

--sgs.ai_skill_invoke.shiji_recover = true
sgs.ai_skill_choice.shiji = function(self, choices, data)
   if self.player:isWounded() and table.contains(choices:split("+"), "shiji_recover") then return "shiji_recover" end
   if table.contains(choices:split("+"), "shiji_draw") then return "shiji_draw" end
end

sgs.ai_skill_invoke.pengtiao_recover = function(self, data)
	return self:isFriend(data:toPlayer())
end

--间宫明里
sgs.ai_skill_invoke.Takamakuri = function(self, data)
	return self:isEnemy(data:toPlayer()) and not data:toPlayer():hasSkills(sgs.lose_equip_skill)
end

sgs.ai_skill_invoke.Tobiugachi = function(self, data)
	if self:isFriend(self.room:getCurrent()) then
		if self.player:getHandcardNum() - self.player:getHp() + 1 <= 3 and (self:isWeak() or self:getCardsNum("Jink") == 0) then return true end
		return false
	end
	if self.player:getHandcardNum() - self.player:getHp() + 1 <= 5 then return true end
	return false
end

sgs.ai_skill_playerchosen.Tobiugachi = function(self, targets)
	local target = self:findPlayerToDiscard()
	if target then return target end
	return self.enemies[1]
end

sgs.ai_skill_invoke.Fukurouza = true

sgs.ai_skill_invoke.FukurouzaTobi = function(self, data)
	return self:isEnemy(self.room:getCurrent()) and not self.room:getCurrent():hasSkills(sgs.immune_skill)
end

sgs.ai_skill_invoke.FukurouzaTaka = true

--艾拉
sgs.ai_skill_invoke.kioku = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_playerchosen.kioku = function(self, targets, max_num, min_num)
    for _, target in sgs.qlist(targets) do	     
		if self.player:isFriendWith(target) then return target end
	end
	for _, target in sgs.qlist(targets) do	     
		if self:isFriend(target) then return target end
	end
end

local xiangsui_skill={}
xiangsui_skill.name="xiangsui"
table.insert(sgs.ai_skills,xiangsui_skill)
xiangsui_skill.getTurnUseCard=function(self,inclusive)
    if self.player:hasUsed("XiangsuiCard") or self.player:getPile("memory"):length()==0 then return false end
	return sgs.Card_Parse("@XiangsuiCard=.&xiangsui")
end

sgs.ai_skill_use_func.XiangsuiCard = function(card,use,self)
	local target
	local n=-1
	for _,f in ipairs(self.friends) do
		if f:getLostHp()>n then
			n = f:getLostHp()
		end
	end
	for _,f in sgs.list(self.friends) do
		if f:getLostHp()==n then
			target = f
		end
	end
	local needed
	--local cards = sgs.QList2Table(self.player:getPile("memory"))
	needed = self.player:getPile("memory"):at(0)
	if target and needed then
		use.card = sgs.Card_Parse("@XiangsuiCard="..needed.."&xiangsui")
		if use.to then use.to:append(target) end
		return
	end
end

--未来
sgs.ai_skill_invoke.zhouxue = true

sgs.ai_skill_invoke.caoxue = function(self, data)
	return (self:isEnemy(data:toPlayer()) and not data:toPlayer():isNude()) or (self:isFriend(data:toPlayer()) and data:toPlayer():getJudgingArea():length()>0) 
end

local xueren_skill = {}
xueren_skill.name = "xueren"
table.insert(sgs.ai_skills, xueren_skill)
xueren_skill.getTurnUseCard = function(self)
	if self.player:getPile("zhouxue_blood"):isEmpty() or self.player:hasFlag("xueren_used") then
		return
	end
	self:sort(self.enemies, "defense")
	local useAll = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end

	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkill("paoxiao") then disCrossbow = true end
	
	local can_use = false
	local cards = {}
	for i = 0, self.player:getPile("zhouxue_blood"):length() - 1, 1 do
		local slash = sgs.Sanguosha:getCard(self.player:getPile("zhouxue_blood"):at(i))
		local slash_str = ("slash:xueren[%s:%s]=%d&xueren"):format(slash:getSuitString(), slash:getNumberString(), self.player:getPile("zhouxue_blood"):at(i))
		local xuerenslash = sgs.Card_Parse(slash_str)
		assert(xuerenslash)
        if self:slashIsAvailable(self.player, xuerenslash) then
			table.insert(cards, xuerenslash)
		end
	end
	if #cards == 0 then return end
	return cards[1]
end

sgs.ai_view_as.xueren = function(card, player, card_place)
    if player:hasFlag("xueren_used") then
		return
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local ask = sgs.Sanguosha:getCurrentCardUsePattern()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "zhouxue_blood" and ask == "slash" then
		return ("slash:xueren[%s:%s]=%d%s"):format(suit, number, card_id, "&xueren")
	end
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "zhouxue_blood" and ask == "jink" then
		return ("jink:xueren[%s:%s]=%d%s"):format(suit, number, card_id, "&xueren")
	end
end

sgs.ai_skill_choice["zhouxue"] = "zhouxue_yes"

--艾露莎
sgs.ai_skill_invoke.huanzhuang = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

--饼
function SmartAI:useCardTacos(card, use)
	--[[for _,p in ipairs(self.enemies) do
		if p:hasSkill("eastfast") then return end
	end
	for _,p in ipairs(self.friends) do
		if p:hasSkill("SE_Jiawu") then return end
	end]]
	local can
	for _,id in sgs.qlist(self.room:getDiscardPile()) do
        if sgs.Sanguosha:getCard(id):objectName() ~= "tacos" then can = true end
	end
	if not can then return end
	use.card = card
end

sgs.ai_card_intention.Tacos = -40

sgs.ai_keep_value.Tacos = 2.5
sgs.ai_use_value.Tacos = 8
sgs.ai_use_priority.Tacos = 4

sgs.dynamic_value.benefit.Tacos = true

--辣
function SmartAI:useCardMapoTofu(card, use)
	local targets = {}
	for _,p in sgs.list(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) <= 1 then table.insert(targets, p) end
	end
	if #targets == 0 then return end
	local f_target
	for _,target in ipairs(targets) do
		if self:isFriend(target) then
			if target:hasSkills(sgs.masochism_by_self_skill) then f_target = target end
			if target:hasSkills("tianhuo") and target:getLostHp() > 0 then return target end
		else
			if self.player:hasSkills(sgs.weak_killer_skill) and target:getLostHp() == 0 then f_target = target end
		end
	end
	if not f_target then
		for _,target in ipairs(targets) do
			if self:isFriend(target) and target:getLostHp() > 0 then
				f_target = target
			end
		end
	end
	if f_target then
		for _,v in ipairs(targets) do
			if v:objectName() == f_target:objectName() then
				use.card = card
				if use.to and not (sgs.Sanguosha:isProhibited(self.player, v, card) or v:isRemoved()) then use.to:append(v) end
				return
			end
		end
	end
end
sgs.ai_use_priority.MapoTofu = 10
sgs.ai_use_value.MapoTofu = 8
sgs.ai_keep_value.MapoTofu = 1.0
sgs.ai_card_intention.MapoTofu = 0

function SmartAI:useCardLinkStart(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	use.card = card
end
sgs.ai_use_priority.LinkStart = 3
sgs.ai_use_value.LinkStart = 6.5
sgs.ai_keep_value.LinkStart = 3
sgs.ai_card_intention.LinkStart= -60

sgs.ai_nullification.LinkStart = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) then
			return true, true
		end
	else
		if self:isFriend(to) then return true, true end
	end
	return
end

function SmartAI:useCardRenkinChouwa(card, use)
    if not card:isAvailable(self.player) then return end
	if not self:hasTrickEffective(card, self.player, self.player) then return end
	if (not self.player:hasSkill("mengfeng") or card:getSuitString()~= "heart") and self.player:getHandcardNum()<2 and self.player:getEquips():length()==0 then return end
	use.card = card
end
sgs.ai_use_priority.RenkinChouwa = 3
sgs.ai_use_value.RenkinChouwa = 6.5
sgs.ai_keep_value.RenkinChouwa = 3
sgs.ai_card_intention.RenkinChouwa= -60

sgs.ai_nullification.RenkinChouwa = function(self, card, from, to, positive, keep)
	if positive then
		if self:isEnemy(to) and not to:isNude() then return true, true end
	else
		if to:getCards("he"):length() == 1 and self.player:objectName() == to:objectName() then
			if self:getCard("Nullification"):getEffectiveId() == self.player:getCards("he"):first():getEffectiveId() then return false end
		end
		if self:isFriend(to) and not to:isNude() then return true, true end
	end
	return
end

sgs.ai_skill_use["@@renkin"] = function(self, prompt)
	local cards=sgs.QList2Table(self.player:getHandcards())
	local equips=sgs.QList2Table(self.player:getEquips())
	local card
	for _,acard in ipairs(cards) do
		if not card and self:getKeepValue(acard)<5  then
			card = acard
		end
	end
	for _,acard in ipairs(equips) do
		if not card and self:getKeepValue(acard)<5  then
			card = acard
		end
	end
	if card then
		return ("@RenkinCard="..card:getEffectiveId().."&")
	end
	return "."
end

--永琳
local penglai_skill={}
penglai_skill.name="penglai"
table.insert(sgs.ai_skills,penglai_skill)
penglai_skill.getTurnUseCard=function(self,inclusive)
    if self.player:hasUsed("PenglaiCard") then return false end
	return sgs.Card_Parse("@PenglaiCard=.&penglai")
end

sgs.ai_skill_use_func.PenglaiCard = function(card,use,self)
	local target
	for _,f in ipairs(self.friends_noself) do
		if f:getLostHp()>0 and f:getHp() == 1 and not f:isKongcheng() then
			target = p
			break
		end
	end
	if not target then
	   for _,f in sgs.list(self.friends_noself) do
		if f:getLostHp()>0 and f:getHandcardNum()>1 then
			target = p
			break
		end
	   end
	end
	if not target then
	   for _,e in sgs.list(self.enemies) do
		if e:getLostHp()==0 and not e:isKongcheng() then
			target = e
			break
		end
	   end
	end
	if target then
		use.card = sgs.Card_Parse("@PenglaiCard=.&penglai")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_invoke.jiansi = function(self, data)
	return self:willShowForDefence() or self:willShowForAttack()
end

sgs.ai_skill_use["@@jiansi"] = function(self, prompt)
   if self.player:isRemoved() then return end
   local id = self.player:property("jiansi_number"):toInt()
   local card = sgs.Sanguosha:getCard(id)
   local use_card = card
	assert(use_card)
	if not card:isAvailable(self.player) then return end 
	local use = {isDummy = true,to = sgs.SPlayerList()}
	if use_card:isKindOf("BasicCard") then 
	self:useBasicCard(use_card, use)
	elseif use_card:isKindOf("EquipCard") then 
	self:useEquipCard(use_card, use)
	else 
	self:useTrickCard(use_card, use)
	end
    if not use.card then return "." end
	if use_card:isKindOf("EquipCard") or use_card:targetFixed() then return use_card:toString() end	
	local targets = {}
	for _,to in sgs.qlist(use.to) do
		table.insert(targets, to:objectName())
	end
	if #targets == 0 then 
		if use_card:canRecast() then return use_card:toString() end
	return "." end
	return use_card:toString() .. "->" .. table.concat(targets, "+")
   --return sgs.Card_Parse(pattern..":jiansi["..card:getSuitString()..":"..card:getNumberString().."]=" .. id .."&jiansi")
   --return pattern..":jiansi["..card:getSuitString()..":"..card:getNumberString().."]=" .. id .."&jiansi"
end

sgs.ai_skill_askforag.jiansi = function(self, card_ids)
   for _,id in ipairs(card_ids) do
       local card = sgs.Sanguosha:getCard(id)
	   if card:isAvailable(self.player) then
	      return id
	   end 
   end
   return -1
end

--悟
sgs.ai_skill_invoke.revival = function(self, data)
	return self:isFriend(data:toPlayer())
end

sgs.ai_skill_invoke.fhuanxing = true

sgs.ai_skill_playerchosen.fhuanxing = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then return p end
	end
	return
end

sgs.ai_skill_choice.revival = function(self, choices, data)
	if self.player:isWounded() and self.player:getMaxHp()>1 then
	  return "revival_back"
	end
end

sgs.ai_skill_choice.fhuanxing = "revival_recover"

--爱丽丝
sgs.ai_skill_invoke.zhenghe = true

zhenghe_skill={}
zhenghe_skill.name="zhenghe"
table.insert(sgs.ai_skills,zhenghe_skill)
zhenghe_skill.getTurnUseCard=function(self,inclusive)
	if not sgs.Slash_IsAvailable(self.player) or self.player:getMark("@zhenghe") < 1 then return end
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Slash") then
			return
		end
	end
	--if #self.friends >= #self.enemies then return end
	--local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit,0)
	return sgs.Card_Parse(("slash:zhenghe[%s:%s]=.&zhenghe"):format("no_suit","-"))
end


sgs.ai_view_as.zhenghe = function(card, player, card_place)
     local ask = sgs.Sanguosha:getCurrentCardUsePattern()
	if ask == "jink" then
		if player:getMark("@zhenghe") < 1 then return end
		local cards = player:getCards("h")
		cards=sgs.QList2Table(cards)
		for _,c in ipairs(cards)  do
			if c:isKindOf("Jink") then
				return
			end
		end
		return ("jink:zhenghe[%s:%s]=.&zhenghe"):format("no_suit","-")
	elseif ask == "slash" then
		if player:getMark("@zhenghe") < 1 then return end
		local cards = player:getCards("h")
		cards=sgs.QList2Table(cards)
		for _,c in ipairs(cards)  do
			if c:isKindOf("Slash") then
				return
			end
		end
		return ("slash:zhenghe[%s:%s]=.&zhenghe"):format("no_suit","-")
	else
		if player:getMark("@zhenghe") < 1 then return end
		local cards = player:getCards("h")
		cards=sgs.QList2Table(cards)
		for _,c in ipairs(cards)  do
			if c:isKindOf("Nullification") then--null部分有问题
				return
			end
		end
		return ("nullification:zhenghe[%s:%s]=.&zhenghe"):format("no_suit","-")
	end
end

jianwu_skill={}
jianwu_skill.name="jianwu"
table.insert(sgs.ai_skills,jianwu_skill)
jianwu_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if source:getMark("@zhenghe") < 1 or source:getMark("@jianwu")<1 then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("@JianwuCard=.&jianwu")
end

sgs.ai_skill_use_func.JianwuCard = function(card,use,self)
    local target
	local n = 0
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if enemy:getFormation():length()>n then
			n = enemy:getFormation():length()
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getFormation():length() == n and enemy:faceUp() and self.player:inMyAttackRange(enemy) then
			target = enemy
		end
	end
	if target then
		use.card = sgs.Card_Parse("@JianwuCard=.&jianwu")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority["jianwucard"] = 6
sgs.ai_card_intention["jianwucard"]  = 100

kanhu_skill={}
kanhu_skill.name="kanhu"
table.insert(sgs.ai_skills,kanhu_skill)
kanhu_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if source:hasUsed("KanhuCard") then return end
	if source:getMark("@zhenghe") < 1 then return end
	local target = 0
	for _,friend in ipairs(self.friends) do
		if friend:getHp()~=friend:getMaxHp() then
			target = 1
		end
	end
	if target == 1 then
		return sgs.Card_Parse("@KanhuCard=.&kanhu")
	end
end

sgs.ai_skill_use_func.KanhuCard = function(card,use,self)
	local target
	local minHp = 100
	for _,friend in ipairs(self.friends) do
		local hp = friend:getHp()
		if friend:getHp()==friend:getMaxHp() then
			hp = 1000
		end
		if self:hasSkills(sgs.masochism_skill, friend) then
			hp = hp - 1
		end
		if friend:isLord() then
			hp = hp - 1
		end
		if hp < minHp then
			minHp = hp
			target = friend
		end
	end
	if target then
		use.card = sgs.Card_Parse("@KanhuCard=.&kanhu")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.KanhuCard = 6
sgs.ai_use_priority.KanhuCard = 9
sgs.ai_card_intention.KanhuCard  = -100


--凌波
taxian_skill={}
taxian_skill.name="taxian"
table.insert(sgs.ai_skills,taxian_skill)
taxian_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("TaxianCard") then return end
	if not self:willShowForAttack()	then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) and not p:inMyAttackRange(self.player) then return sgs.Card_Parse("@TaxianCard=.&taxian") end
	end
	if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 then return end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p) then return sgs.Card_Parse("@TaxianCard=.&taxian") end
	end
end

sgs.ai_skill_use_func.TaxianCard = function(card,use,self)
	local targets = sgs.SPlayerList()
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) then
			--TODO if friend need maixie
			if not p:inMyAttackRange(self.player) then
				targets:append(p)
			elseif p:getHandcardNum() < 2 then
				targets:append(p)
			elseif self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 then
				targets:append(p)
			elseif #targets == 2 then
				targets:append(p)
			end
		end
	end

	if targets:length() > 0 then
		use.card = sgs.Card_Parse("@TaxianCard=.&taxian")
		use.to = targets
		return
	end
end

sgs.ai_use_value.TaxianCard = 8
sgs.ai_use_priority.TaxianCard = 1
sgs.ai_card_intention.TaxianCard = 100

sgs.ai_skill_invoke.guishen = function(self, data)
	return self.player:getMark("@Guishen")-self.player:getHp()>0 or self.player:getMaxHp()- self.player:getHandcardNum() >0
end

--小日向未来
sgs.ai_skill_invoke.jingming = function(self, data)
	local p = data:toPlayer()
	if self.player:getHandcardNum() > 1 then
		if self:isFriend(p) then
			if p:hasWeapon("Crossbow") then return true end
			if p:getHp() == 1 and p:getHandcardNum() < 2 then return true end
			if p:getHp() == 2 and p:getHandcardNum() < 1 then return true end
			if p:getHandcardNum() + 5 < p:getHp() then return true end
		end
	end
	if self:isEnemy(p) then
		if p:getHandcardNum() > 3 and not p:hasWeapon("Crossbow") then return true end
		if self:isWeak(self.player) and p:inMyAttackRange(self.player) then return true end
	end
	return false
end


sgs.ai_skill_choice.jingming = function(self, choices, data)
	local target
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark(self.player:objectName().."noslash_jm") == 1 then
			target = p
		end
	end
	if not target then return "youdiscard" end
	if self:isEnemy(target) then
		return "youdiscard"
	else
		if target:getMaxHp() - target:getHp()  > 0 and target:getHandcardNum() >= 1 then return "recover" end
		return "eachdraw"
	end
	return "youdiscard"
end

local yingxian_skill={}
yingxian_skill.name="yingxian"
table.insert(sgs.ai_skills,yingxian_skill)
yingxian_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("YingxianCard") then return end
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("@YingxianCard=.&yingxian")
end

sgs.ai_skill_use_func.YingxianCard = function(card,use,self)
    local cards=sgs.QList2Table(self.player:getHandcards())
	local n = 0
	local card
    for _,acard in ipairs(cards) do
		if acard:getNumber()> n then n =  acard:getNumber() end
	end
	for _,acard in ipairs(cards) do
		if acard:getNumber()== n then card = acard end
	end
	if card then use.card = sgs.Card_Parse("@YingxianCard="..card:getEffectiveId().."&yingxian") end
	return
end

sgs.ai_use_value.YingxianCard = 7
sgs.ai_use_priority.YingxianCard = 9

--芽衣子
sgs.ai_skill_invoke.huaming = function(self, data)
	return self:isFriend(data:toPlayer())
end

sgs.ai_skill_choice.huaming= function(self, choices, data)
	if self:isFriend(data:toPlayer()) then
	   return "huaming_show"
	else
	   return "cancel"
	end
end

sgs.ai_skill_invoke.xinyuan = function(self, data)
    for _,p in ipairs(self.friends) do
       return true	
	end
	return false
end

sgs.ai_skill_playerchosen.xinyuan = function(self, targets)
    local n = 0
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getMaxHp()-p:getHandcardNum()>n then
		    n = p:getMaxHp()-p:getHandcardNum()
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getMaxHp()-p:getHandcardNum() == n then
		    return p
		end
	end
	return targets:at(0)
end

--安
sgs.ai_skill_invoke.zhuangjia = true

sgs.ai_skill_invoke.wuzhuang = true

--妖梦
sgs.ai_skill_invoke.shuangreny = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.shuangreny= function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then return target end
	end
	return nil
end

sgs.ai_skill_invoke.zhanwang = function(self, data)
    local damage = data:toDamage()
    return self:isEnemy(damage.to)
end

sgs.ai_skill_invoke.louguan = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.bailou = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.rengui = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.louguan = function(self, targets)
    local result = {}
	for _,name in sgs.qlist(targets)do
		if  self.player:distanceTo(name) == 1 and self:isEnemy(name) then table.insert(result, findPlayerByObjectName(name:objectName())) end
	end
	return result
end

--时雨
sgs.ai_skill_invoke.dstp = true

sgs.ai_skill_invoke.zhongquan = function(self, data)
    for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
       if self.player:willBeFriendWith(p) then
	      return true
	   end
	end
    return false
end

sgs.ai_skill_playerchosen.zhongquan= function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self.player:willBeFriendWith(target) then return target end
	end
	return nil
end

sgs.ai_skill_choice.guihuan = function(self, choices, data)
	local sp = self.room:findPlayerBySkillName("guihuan")
	if not sp then return "cancel" end
	if sp:getHandcardNum()>self.player:getHandcardNum()+2 then return "guihuan_card" end
	if sp:getHp()>self.player:getHp() then return "guihuan_hp" end
	if sp:getHandcardNum()>self.player:getHandcardNum() then return "guihuan_card" end
	return "cancel"
end

--焰
qiehuo_skill={}
qiehuo_skill.name="qiehuo"
table.insert(sgs.ai_skills,qiehuo_skill)
qiehuo_skill.getTurnUseCard=function(self,inclusive)
    if not self:willShowForAttack() and not self:willShowForDefence() then return end
	local source = self.player
	if source:hasUsed("QiehuoCard") then return end
	return sgs.Card_Parse("@QiehuoCard=.&qiehuo")
end

sgs.ai_skill_use_func.QiehuoCard = function(card,use,self)
	local target
	local card
	local source = self.player
	for _,enemy in ipairs(self.enemies) do
	    if enemy:getWeapon() then
	      target = enemy
		end
	end
	if not target and self.player:getWeapon() and not self.player:hasUsed("SujiuCard") then
	   target = self.player
	end
    local cards = sgs.QList2Table(self.player:getHandcards())
	local equips=sgs.QList2Table(self.player:getEquips())
	for _,acard in ipairs(equips) do
		if target and (self:getKeepValue(acard)<5 or self:isWeak(target)) then
			card = acard
		end
	end
	for _,acard in ipairs(cards) do
		if self:getKeepValue(acard)<5 then
			card = acard
		end
	end
	if target and card then
		use.card = sgs.Card_Parse("@QiehuoCard="..card:getEffectiveId().."&qiehuo")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["QiehuoCard"] = 7
sgs.ai_use_priority["QiehuoCard"]  = 20
sgs.ai_card_intention.QiehuoCard = 80

sgs.ai_skill_invoke.shiting = function(self, data)
    local use = data:toCardUse()
	if self.player:getPhase() ~= sgs.Player_NotActive then 
	    return not use.card:isKindOf("EquipCard")
	else
	  if self.player:getHp() == 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 and self:getCardsNum("GuangyuCard") == 0 then return false end
	  return true
	end
	return false
end

sujiu_skill={}
sujiu_skill.name="sujiu"
table.insert(sgs.ai_skills,sujiu_skill)
sujiu_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("SujiuCard") then return end
	if not self:willShowForDefence() and not self:willShowForAttack() then return end
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Weapon") then
			return sgs.Card_Parse("@SujiuCard=.&sujiu")
		end
	end
end

sgs.ai_skill_use_func.SujiuCard = function(card,use,self)
	use.card = sgs.Card_Parse("@SujiuCard=.&sujiu")
    return
end

sgs.ai_use_value.SujiuCard = 7
sgs.ai_use_priority.SujiuCard  = 20

--nagase
sgs.ai_skill_invoke.qifen = function(self, data)
    return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_playerchosen.qifen = function(self, targets)
    if not self.player:isWounded() then
	for _,p in sgs.qlist(targets) do
		if self.player:isFriendWith(p) then return p end
	end
	end
	local x = 0
	for _,p in sgs.qlist(targets) do
	    local n = 0
		for _,q in sgs.qlist(targets) do
		  if p:isFriendWith(q) and p:hasShownOneGeneral() then
		      n = n+1
		  end
		end
		if n > x then x = n end
	end
	for _,p in sgs.qlist(targets) do
	    local n = 0
		for _,q in sgs.qlist(targets) do
		  if p:isFriendWith(q) and p:hasShownOneGeneral() then
		      n = n+1
		  end
		end
		if n == x then return p end
	end
	return
end

sgs.ai_skill_invoke.mishi = function(self, data)
	local source = data:toPlayer()
	local mygod = self.player
	local good
	if (self:isFriend(source) and not self:isFriend(mygod)) or (not self:isFriend(source) and self:isFriend(mygod)) then
		good = true
	end
	if not good then return false end
	local peach_num = 0
	local jink_num = 0
	for _,card in sgs.qlist(mygod:getHandcards()) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			peach_num = peach_num + 1
		end
		if card:isKindOf("Jink") then
			jink_num = jink_num + 1
		end
	end
	if good then
		if mygod:getHp() > 0 and peach_num > 2 then return true end
		if mygod:getHp() > 0 and peach_num > 1 and jink_num > 0 then return true end
		if mygod:getHp() > 1 and peach_num > 1 then return true end
		if mygod:getHp() > 1 and peach_num > 0 and jink_num > 0 then return true end
		if mygod:getHp() > 2 and peach_num > 0 then return true end
		if mygod:getHp() > 2 and jink_num > 0 then return true end
	end
	return false
end

sgs.ai_skill_invoke.zhufu = function(self, data)
   return #self.friends_noself > 0 and self.player:getHandcardNum() - self.player:getHp()> 3
end

sgs.ai_skill_askforyiji.zhufu = function(self, card_ids)
   local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end

	if self.player:getHandcardNum() <= 3 then
		return nil, -1
	end

	local new_friends = {}
	for _, friend in ipairs(self.friends) do
		if not self:needKongcheng(friend, true) then table.insert(new_friends, friend) end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards, new_friends)
		if card and target then
			return target, card:getEffectiveId()
		end
		self:sort(new_friends, "defense")
		self:sortByKeepValue(cards, true)
		return new_friends[1], cards[1]:getEffectiveId()
	else
		return nil, -1
	end
end

--有宇
sgs.ai_skill_invoke.duoquyan = function(self, data)
   local current = self.room:getCurrent()
   local has = false
   for _,c in sgs.qlist(self.player:getHandcards()) do
      if (c:isKindOf("BasicCard")) then has = true end
   end
   return self:isEnemy(current) and has
end

--威尔艾米娜
sgs.ai_skill_invoke.qiaoshou = function(self, data)
   if (data:toPlayer() == self.player) then
      return self.player:hasSkill("tianhuo")
   end
   return self:isEnemy(data:toPlayer()) and not data:toPlayer():hasSkill("tianhuo") and not data:toPlayer():hasSkill("huansha") and (not data:toPlayer():getArmor() or data:toPlayer():getArmor():objectName()~="IronArmor") and (not data:toPlayer():getArmor() or data:toPlayer():getArmor():objectName()~="PeaceSpell")
end

sgs.ai_skill_discard["qiaoshou"] = function(self, discard_num, min_num, optional, include_equip)
  return self:askForDiscard("discard", discard_num, min_num, false, include_equip)
end


sgs.ai_skill_invoke.guandai = function(self, data)
   return self:willShowForAttack() or self:willShowForDefence()
end

sgs.ai_skill_invoke.guandai_draw = true

sgs.ai_skill_use["@@guandai"] = function(self, prompt)
	local needed = {}
	for _,id in sgs.qlist(self.player:getPile("duan")) do
		table.insert(needed, id)
    end
	if #needed>0 then
		return ("@GuandaiCard="..table.concat(needed, "+").."&")
	end
	return "."
end

--蕾米莉亚
sgs.ai_skill_invoke.shenqiang = function(self, data)
   local use = data:toCardUse()
   local has = false
   for _,c in sgs.qlist(self.player:getHandcards()) do
      if (c:isKindOf("BasicCard")) then has = true end
   end
   return self:isEnemy(use.to:at(0)) and has and not (self.player:hasSkill("tulong") and self.player:getHandcardNum()<= use.to:at(0):getHandcardNum()) and getCardsNum("Jink", use.to:at(0), self.player) > 0 and not (self.player:hasSkill("xiaowuwan") and getCardsNum("Jink", use.to:at(0), self.player)>0)
end

sgs.ai_skill_invoke.xuecheng = function(self, data)
   local n=0
   local m=0
   for _,p in sgs.qlist(self.room:getAlivePlayers()) do
     if (self:isEnemy(p)) then n=n+1 end
     if (not p:hasShownOneGeneral()) then m=m+1 end
   end
   if n>=3 or m<2 then
     return self:willShowForDefence()
   end
end

sgs.ai_skill_playerchosen.xuecheng = function(self)   
    local result = {}
	for _,name in ipairs(self.enemies)do
		table.insert(result, findPlayerByObjectName(name:objectName()))
	end
	return result
end

sgs.ai_skill_invoke.mingyun = function(self, data)
    return not self.player:isKongcheng() and (self:willShowForAttack() or self:willShowForDefence())
end

sgs.ai_skill_playerchosen.mingyun = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
	return targets:at(0)
end
