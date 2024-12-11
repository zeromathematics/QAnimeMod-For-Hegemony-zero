extension = sgs.Package("Shiny", sgs.Package_GeneralPack)

SRiko = sgs.General(extension, "SRiko", "idol", 3, false)
Honoka = sgs.General(extension, "Honoka", "idol", 4, false)
Rin = sgs.General(extension, "Rin", "idol", 4, false)
Maki = sgs.General(extension, "Maki", "idol", 3, false)
Chika = sgs.General(extension, "Chika", "idol", 3, false)
Ruby = sgs.General(extension, "Ruby", "idol", 3, false)
Kasumi = sgs.General(extension, "Kasumi", "idol", 3, false)
Karin = sgs.General(extension, "Karin", "idol", 4, false)
EmmaVerde = sgs.General(extension, "EmmaVerde", "idol", 4, false)
TangKK = sgs.General(extension, "TangKK", "idol", 3, false)
Ren = sgs.General(extension, "Ren", "idol", 4, false)
TokaiTeio = sgs.General(extension, "TokaiTeio", "idol", 3, false)
Ailian = sgs.General(extension, "Ailian", "idol", 3, false)
SilenceSuzuka = sgs.General(extension, "SilenceSuzuka", "idol", 3, false)
Aien = sgs.General(extension, "Aien", "idol")
Liko = sgs.General(extension, "Liko", "idol", 3, false)
Tsubomi = sgs.General(extension, "Tsubomi", "idol", 3, false)
Makoto = sgs.General(extension, "Makoto", "idol", 3, false)
Eli = sgs.General(extension, "Eli", "idol", 4, false)
Ai = sgs.General(extension, "Ai", "idol", 4, false)
Miku = sgs.General(extension, "Miku", "idol", 3, false)
Yayoi = sgs.General(extension, "Yayoi", "idol", 3, false)
YSetsuna = sgs.General(extension, "YSetsuna", "idol", 4, false)
Haru = sgs.General(extension, "Haru", "idol", 3, false)
Dia = sgs.General(extension, "Dia", "idol", 3, false)
DaiwaScarlet = sgs.General(extension, "DaiwaScarlet", "idol", 3, false)
Asahina = sgs.General(extension, "Asahina", "idol", 3, false)
Shioriko = sgs.General(extension, "Shioriko", "idol", 3, false)
Tooru = sgs.General(extension, "Tooru", "idol", 3, false)
Prism = sgs.General(extension, "Prism", "idol", 3, false)
Fuuka = sgs.General(extension, "Fuuka", "real|idol", 3, false)
Arisa = sgs.General(extension, "Arisa", "science|idol", 4, false)
Nozomi = sgs.General(extension, "Nozomi", "game|idol", 4, false)
AmouKanade = sgs.General(extension, "AmouKanade", "magic|idol", 4, false)
Umi = sgs.General(extension, "Umi", "idol", 4, false)
Hanamaru = sgs.General(extension, "Hanamaru", "idol", 3, false)
Vodka = sgs.General(extension, "Vodka", "idol", 4, false)
MihonoBourbon = sgs.General(extension, "MihonoBourbon", "idol", 4, false)
Kozue = sgs.General(extension, "Kozue", "idol", 3, false)
Harewataru = sgs.General(extension, "Harewataru", "idol", 4, false)
NiceNature = sgs.General(extension, "NiceNature", "idol", 3, false)
PalmerHelios = sgs.General(extension, "PalmerHelios", "idol", 3, false)

qinban = sgs.CreateTriggerSkill{
	name = "qinban",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Start then
			local trigger_list_skill, trigger_list_who = {}, {}
			for _, Riko in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if Riko:isFriendWith(player) then
					if Riko:hasEquip() or player:hasEquip() then
						table.insert(trigger_list_skill, self:objectName()) --发动什么技能
						table.insert(trigger_list_who, Riko:objectName()) --谁决定发动
					end
				end
			end
			return table.concat(trigger_list_skill, "|"), table.concat(trigger_list_who, "|") --如果是这些table是空的话自动就不会发动了
		end
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local targets = sgs.SPlayerList()
		if player:objectName() == ask_who:objectName() then
			targets:append(player)
		else
			if player:hasEquip() then targets:append(player) end
			if ask_who:hasEquip() then targets:append(ask_who) end
		end
		local to = room:askForPlayerChosen(ask_who, targets, self:objectName(), "&qinban", true, true)
		if to then
			local _to = sgs.QVariant() --这三行是为了把to 传递到on_effect 里面
			_to:setValue(to)
			ask_who:setTag("qinbanTarget", _to) --tag 可以记录的值至少有角色和整数
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			room:doLightbox("RikoQinban$", 999)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local id = -1 --准备记录要弃的牌，其实如果不用读取的话不搞这一步也可以
		local to = ask_who:getTag("qinbanTarget"):toPlayer() --把目标从tag 里拿出来，要拿出来的是角色，用toPlayer() 。如果是整数用toInt()
		id = room:askForCardChosen(ask_who, to, "e", self:objectName())
		if id ~= -1 then
			room:throwCard(id, to, ask_who, self:objectName())
		end --选to的牌，弃置
		if ask_who:isAlive() then
			local choice
			if not player:isWounded() then
				choice = "draw"
			else
				choice = room:askForChoice(ask_who, self:objectName(), "draw+recoverRiko", data)
			end
			if choice == "draw" then
				ask_who:drawCards(1, self:objectName())
				player:drawCards(1, self:objectName())
			else
				local recover = sgs.RecoverStruct()
				recover.who = ask_who
				recover.recover = 1
				room:recover(player, recover, true)
			end
		end
	end
}

zhiyuan = sgs.CreateTriggerSkill{
	name = "zhiyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.damage > 0 and damage.from and damage.from:isFriendWith(player) and player:objectName() ~= damage.from:objectName() then
				return self:objectName()
			end
		else
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				return self:objectName()
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		room:doLightbox("RikoZhiyuan$", 999)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			damage.damage = damage.damage - 1
			data:setValue(damage)
			local log = sgs.LogMessage()
			log.type = "#zhiyuan"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			if damage.damage < 1 then
				return true
			end
			data:setValue(damage)
			return false
		else
			local list = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:hasEquip() or p:getJudgingArea():length() > 0 then
					list:append(p)
				end
			end
			local choice
			if list:length() < 1 then
				choice = "draw"
			else
				choice = room:askForChoice(player, self:objectName(), "draw+AskForZhiyuan", data)
			end
			if choice == "draw" then
				player:drawCards(1, self:objectName())
			else
				local from = room:askForPlayerChosen(player, list, self:objectName(), "&zhiyuanA")
				if from:hasEquip() or from:getJudgingArea():length() > 0 then
					local card_id = room:askForCardChosen(player, from, "ej", self:objectName())
					local card = sgs.Sanguosha:getCard(card_id)
					local place = room:getCardPlace(card_id)
					local equip_index = -1
					if place == sgs.Player_PlaceEquip then
						local equip = card:getRealCard():toEquipCard()
						equip_index = equip:location()
					end
					local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if equip_index ~= -1 then
							if not p:getEquip(equip_index) then
								tos:append(p)
							end
						else
							if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
								tos:append(p)
							end
						end
					end
					local tag = sgs.QVariant()
					tag:setValue(from)
					room:setTag("zhiyuanTarget", tag)
					local to = room:askForPlayerChosen(player, tos, self:objectName(), "&zhiyuanB")
					if to then
						local reason = sgs.CardMoveReason(0x09, player:objectName(), self:objectName(), "")
						room:moveCardTo(card, from, to, place, reason)
					end
					room:removeTag("zhiyuanTarget")
				end
			end
		end
	end,
}

guwu = sgs.CreateTriggerSkill{
	name = "guwu",
	frequency = sgs.Skill_Club,
	club_name = "mus",
	events = {sgs.QuitDying, sgs.HpRecover},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.HpRecover then
			for _,Honoka in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if player and player:isAlive() and not player:hasClub("mus") and player:getPhase() == sgs.Player_NotActive and player:objectName() ~= Honoka:objectName() then
					return self:objectName(), Honoka
				end
			end
		end
		if event == sgs.QuitDying then
			local dying = data:toDying()
			local source = dying.who
			for _,Honoka in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				if source:isAlive() and source:hasClub("mus") then
					return self:objectName(), Honoka
				end
			end
		end
		return ""	
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if event == sgs.HpRecover then
			local who = sgs.QVariant()
			who:setValue(player)
			if ask_who:askForSkillInvoke(self, who) then
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		end
		if event == sgs.QuitDying then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		room:doLightbox("guwu$", 999)
		if event == sgs.HpRecover then
			local choice = room:askForChoice(player, self:objectName(), "guwu_accept+cancel", data)
			if choice == "guwu_accept" then
				player:addClub("mus")
			end
		end
		if event == sgs.QuitDying then
			local dying = data:toDying()
			local source = dying.who
			local judge = sgs.JudgeStruct()
			judge.pattern = "."
			judge.good = true
			judge.reason = self:objectName()
			judge.who = source
			room:judge(judge)
			if judge.card:isRed() then
				local recover = sgs.RecoverStruct()
				recover.who = ask_who
				recover.recover = 1
				room:recover(source, recover, true) 
			else
				local muse = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasClub("mus") then
						muse:append(p)
					end
				end
				room:sortByActionOrder(muse)
				for _,p in sgs.qlist(muse) do
					p:drawCards(1, self:objectName())
				end
			end
		end
	end ,
}

huqingCard = sgs.CreateSkillCard{ --攻心
	name = "huqingCard",
	filter = function(self, targets, to_select, Self)
		return #targets == 0 and not to_select:isKongcheng() and to_select:objectName() ~= Self:objectName()
	end,
	on_effect = function(self, effect)
		local to = effect.to
		local from = effect.from
		local room = from:getRoom()
		local suit_list = {"spade", "heart", "club", "diamond"}
		for _, c in sgs.qlist(to:getHandcards()) do
			local suit = c:getSuitString()
			if table.contains(suit_list, suit) then
				table.removeOne(suit_list, suit)
			end
		end
		room:setPlayerProperty(from, "huqingSuits", sgs.QVariant(table.concat(suit_list, "+")))
		local _to = sgs.QVariant()
		_to:setValue(to)
		from:setTag("huqingTarget", _to) --给弃牌伤害目标做标记
		room:doGongxin(from, to, sgs.IntList(), "huqing") --第三个应当是一个 IntList，用来装可以被弃掉的牌（攻心红桃，尚义黑色），这里为空
		room:askForUseCard(from, "@@huqing", "@huqing") --嵌套另一个SkillCard
	end,
}

huqingfireCard = sgs.CreateSkillCard{ --烧
	name = "huqingfireCard",
	target_fixed = true,
	on_use = function(self, room, player, targets)
		local to = player:getTag("huqingTarget"):toPlayer()
		if to and to:isAlive() then
			local damage = sgs.DamageStruct()
			damage.damage = 1
			damage.from = player
			damage.to = to
			damage.nature = sgs.DamageStruct_Fire
			room:damage(damage)
		end
	end,	
}

huqing = sgs.CreateViewAsSkill{
	name = "huqing",
	view_filter = function(self, selected, to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@huqing" then
			local huqing_suits = sgs.Self:property("huqingSuits"):toString():split("+") 
			local n = #huqing_suits
			for _, card in ipairs(selected) do
				local cardSuit = card:getSuitString()
				if table.contains(huqing_suits, cardSuit) then
					table.removeOne(huqing_suits, cardSuit) --把已经选的除去
				end
			end
			return (#selected < n and table.contains(huqing_suits, to_select:getSuitString())) --只要已选的不足n张就可以选，选的必须要在剩余的花色列表里面
		else
			return false
		end
	end,
	view_as = function(self, cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@huqing" then
			local huqing_suits = sgs.Self:property("huqingSuits"):toString():split("+")
			local n = #huqing_suits
			if #cards < n then return nil end
			local vs = huqingfireCard:clone()
			for _,card in ipairs(cards) do
				vs:addSubcard(card:getId())
			end
			return vs
		else
			local vs = huqingCard:clone()
			vs:setShowSkill(self:objectName())
			return vs
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#huqingCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@huqing"
	end,
}

xunjiRin = sgs.CreateTriggerSkill{
	name = "xunjiRin",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		if room:askForUseSlashTo(player, room:getOtherPlayers(player), "&xunjiRin", false) then
			room:setPlayerCardLimitation(player, "use,response", "TrickCard", true)
		end
	end,
}

tuibianVS = sgs.CreateTargetModSkill{
	name = "tuibianVS", --没写pattern就默认是杀
	residue_func = function(self, player)
		if player:getMark("#tuibian") > 0 then
			return player:getMark("#tuibian")
		end
		return 0
	end,
}

tuibian = sgs.CreateTriggerSkill{
	name = "tuibian",
	relate_to_place = "head",
	events = {sgs.CardFinished, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseChanging and change.to == sgs.Player_NotActive and player:getMark("#tuibian") > 0 then
			room:setPlayerMark(player, "#tuibian", 0)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("#tuibian") < 4 and room:getCurrent() == player and use.card:isKindOf("BasicCard") and not player:isNude() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:setPlayerMark(player, "#tuibian", player:getMark("#tuibian")+1)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local idy = room:askForCardChosen(player, player, "he", self:objectName())
		local card = sgs.Sanguosha:getCard(idy)
		if card then
			room:moveCardTo(card, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, player:objectName(), self:objectName(), ""))
			room:broadcastSkillInvoke("@recast")
			local log = sgs.LogMessage()
			log.type = "#UseCard_Recast"
			log.from = player
			log.card_str = tostring(card)
			room:sendLog(log)
			player:drawCards(1, "recast")
		end
	end,
}

qiaoyuanCard = sgs.CreateSkillCard{
	name = "qiaoyuanCard",
	will_throw = false,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName() 
	end,
	on_use = function(self, room, source, targets)
		room:obtainCard(targets[1], self, false)
	end,
}

qiaoyuan = sgs.CreateViewAsSkill{
	name = "qiaoyuan",
	relate_to_place = "deputy",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and not to_select:isAvailable(sgs.Self) and #selected < sgs.Self:getHp()
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local vs = qiaoyuanCard:clone()
			vs:setShowSkill(self:objectName())
			vs:setSkillName(self:objectName())
			for i = 1, #cards, 1 do
				vs:addSubcard(cards[i])
			end
			return vs
		end
	end,	
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_qiaoyuanCard")
	end,
}

--[[
qiaoyuan = sgs.CreateTriggerSkill{
	name = "qiaoyuan",
	relate_to_place = "deputy",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local generals = {}
		for _,g in ipairs(sgs.Sanguosha:getLimitedGeneralNames(true)) do
			if table.contains(sgs.Sanguosha:getGeneral(g):getKingdom():split("|"), "idol") and not table.contains(getUsedGeneral(room), g) then
				table.insert(generals, g)
			end
		end
		generals = table.Shuffle(generals)
		local ava = {}
		for i = 1, 3, 1 do
			if #generals > 0 then
				local a = generals[1]
				table.removeOne(generals, a)
				table.insert(ava, a)
			end
		end
		if #ava > 0 then
			local to = room:askForGeneral(player, table.concat(ava, "+"), nil, true, self:objectName())
			room:transformDeputyGeneralTo(player, to)
		end
	end,
}
]]

ciqiang = sgs.CreateTriggerSkill{
	name = "ciqiang",	
	events = {sgs.TargetConfirming, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseChanging and change.to == sgs.Player_NotActive then
			for _,Maki in sgs.qlist(room:getAlivePlayers()) do
				if Maki:getMark("#ciqiang") > 0 then
					room:setPlayerMark(Maki, "#ciqiang", 0)
				end
			end
		end
	end ,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirming then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHp() <= 0 then
					return ""
				end
			end
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and use.to:length() == 1 and player:getMark("#ciqiang") < player:getHp() and player:getPhase() == sgs.Player_NotActive and use.from and player:objectName() ~= use.from:objectName() and use.to:contains(player) and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard")) and not use.from:isAllNude() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local use = data:toCardUse()
		local who = sgs.QVariant()
		who:setValue(use.from)
		if player:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		if not use.from:isAllNude() then
			local id = room:askForCardChosen(player, use.from, "hej", self:objectName())
			room:throwCard(id, use.from, player, self:objectName())
			room:setPlayerMark(player, "#ciqiang", player:getMark("#ciqiang")+1)
		end
	end ,
}

qianjinCard = sgs.CreateSkillCard{
	name = "qianjinCard",
	target_fixed = true,
	on_use = function(self, room, source, targets)
		local intention = room:askForSuit(source, "qianjin")
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = source
		log.arg = sgs.Card_Suit2String(intention)
		room:sendLog(log)
		local dummy = sgs.DummyCard()
		for _,c in sgs.qlist(source:getEquips()) do
			if c:getSuit() == intention then
				dummy:addSubcard(c)
			end
		end
		for _,c in sgs.qlist(source:getHandcards()) do
			if c:getSuit() == intention then
				dummy:addSubcard(c)
			end
		end
		if dummy:getSubcards():length() > 0 then
			room:throwCard(dummy, source, source, "qianjin")
		end
		dummy:deleteLater()
		local m = 0
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			for _,c in sgs.qlist(p:getJudgingArea()) do
				if c:getSuit() == intention then m = m+1 end
			end
			for _,c in sgs.qlist(p:getEquips()) do
				if c:getSuit() == intention then m = m+1 end
			end
		end
		source:drawCards(math.min(5,m), "qianjin")
	end ,
}

qianjin = sgs.CreateZeroCardViewAsSkill{
	name = "qianjin",
	view_as = function(self)
		local vs = qianjinCard:clone() 
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_qianjinCard")
	end,
}

jiesi = sgs.CreateTriggerSkill{
	name = "jiesi",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		player:drawCards(1, self:objectName())
		if not player:isKongcheng() and not player:isRemoved() then
			local n = 999
			for _,A in sgs.qlist(room:getAlivePlayers()) do
				if A:getHandcardNum() < n then
					n = A:getHandcardNum()
				end
			end
			local a = player:getHandcardNum() - n
			if a <= 0 or player:isKongcheng() or player:isRemoved() then return false end
			room:askForDiscard(player, self:objectName(), a, a)
			room:setPlayerMark(player, "jiesiCount", a) --给人机用来判断的标记
			local choice = room:askForChoice(player, self:objectName(), "jiesiDraw+jiesiThrow", data)
			if choice == "jiesiDraw" then
				local targetsA = room:askForPlayersChosen(player, room:getAlivePlayers(), "#jiesiDraw", 1, a, "&jiesiDraw:" .. tostring(a), true)
				room:sortByActionOrder(targetsA)
				for _,B in sgs.qlist(targetsA) do
					local m = B:getMaxHp() - B:getHandcardNum()
					if m > 0 then
						B:drawCards(m, self:objectName())
					end
				end
			end
			if choice == "jiesiThrow" then
				local list = sgs.SPlayerList()
				for _,C in sgs.qlist(room:getAlivePlayers()) do
					if not C:isAllNude() then
						list:append(C)
					end
				end
				if list:length() > 0 then
					local targetsB = room:askForPlayersChosen(player, list, "#jiesiThrow", 1, a, "&jiesiThrow:" .. tostring(a), true)
					room:sortByActionOrder(targetsB)
					for _,D in sgs.qlist(targetsB) do
						local id = room:askForCardChosen(player, D, "hej", self:objectName())
						room:throwCard(id, D, player, self:objectName())
					end	
				end
			end	
			room:setPlayerMark(player, "jiesiCount", 0)
		end
	end ,
}

tongzhou = sgs.CreateTriggerSkill{
	name = "tongzhou",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and not room:getCurrent():hasFlag("tongzhouUsed") then
				local reason = move.reason
				if bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 0x03 then
					return self:objectName()
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:getCurrent():setFlags("tongzhouUsed")
		local cards = room:getNCards(3)
		room:askForGuanxing(player, cards)
	end ,
}

heyixCard = sgs.CreateSkillCard{
	name = "heyixCard",
	filter = function(self, targets, to_select, player)
		return #targets < self:getSubcards():length()
	end,
	feasible = function(self, targets, Self)
		return #targets == self:getSubcards():length()
	end ,
    on_use = function(self, room, player, targets)
		for _,p in ipairs(targets) do  
		   room:setPlayerMark(p, "#heyix_draw", p:getMark("#heyix_draw") + 1)
		end	
		local t = sgs.SPlayerList()
		for _,g in ipairs(targets) do
			t:append(g)
		end
		if not t:isEmpty() then
			local targetG = room:askForPlayersChosen(player, t, self:objectName(), 1, 1, "&heyix-slash")
			for _,m in sgs.qlist(targetG) do  
			   room:setPlayerMark(m, "#heyix_slashnum", m:getMark("#heyix_slashnum") + 1)
			end	
		end	
	end,
}

heyix = sgs.CreateViewAsSkill{
	name = "heyix",
	n = 999,
	view_filter = function(self,selected,to_select)
	    if sgs.Self:isJilei(to_select) then return false end
		if to_select:isBlack() or to_select:isEquipped() then return false end
		return true
	end,
	view_as = function(self, cards)
		local vs = heyixCard:clone()
		if #cards == 0 then return nil end
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])                
        end  
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_heyixCard")
	end,
}

heyixglobal = sgs.CreateTriggerSkill{
	name = "heyixglobal",
	global = true,
	events = {sgs.DrawNCards, sgs.AfterDrawNCards, sgs.EventPhaseChanging, sgs.EventPhaseStart},
	priority = 2,
	on_record = function(self, event, room, player, data)
		if event == sgs.DrawNCards then
		    local count = data:toInt()
			if player:isAlive() and player:getMark("#heyix_draw")> 0 then 
				count = count + player:getMark("#heyix_draw")
				data:setValue(count)
			end	
		end
		if event == sgs.AfterDrawNCards then
		   if player:isAlive() and player:getMark("#heyix_draw")> 0 then 
		      room:setPlayerMark(player, "#heyix_draw", 0)
		   end
		end 
		if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("#heyix_slashnum")> 0 then
				room:setPlayerMark(player, "#heyix_slashnum", 0)
			end
		end
	end,	
	can_trigger = function(self, event, room, player, data)
	   return ""
	end,
}

heyixSlash = sgs.CreateTargetModSkill{
	name = "#heyixSlash",
	residue_func = function(self, player, card)
		if player:getMark("#heyix_slashnum") > 0 then
			return player:getMark("#heyix_slashnum")
		end
		return 0
	end,
}

qiesheng = sgs.CreateTriggerSkill{
	name = "qiesheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.PreHpLost, sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damaged then
		    local damage = data:toDamage()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.from and damage.from:isAlive() and not player:isRemoved() and room:getCurrent():objectName() ~= player:objectName() and damage.from:objectName() ~= player:objectName() then 
				return self:objectName()
			end
		else
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:isRemoved() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			local who = sgs.QVariant()
			who:setValue(damage.from)
			if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, who) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		else
			if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		if event == sgs.Damaged then
		    local damage = data:toDamage()
			if player and player:isAlive() and damage.from and damage.from:isAlive()  and not player:isRemoved() then
			    if not damage.from:isNude() then
					local show_ids = room:askForExchange(damage.from, self:objectName(), 1, 0, "&qiesheng_give:" .. player:objectName(), "", ".|.|.")
					if not show_ids:isEmpty() then
						local show = sgs.Sanguosha:getCard(show_ids:first())
						local reason = sgs.CardMoveReason(0x17, player:objectName())
						room:obtainCard(player, show, reason, false)
						return false
					end
				end					
				room:setPlayerCardLimitation(player, "use", ".", false)
				room:setPlayerProperty(player, "removed", sgs.QVariant(true))
			end
		else
			return true
		end
	end ,
}

qingyuan = sgs.CreateTriggerSkill{
	name = "qingyuan",
	limit_mark = "@qingyuan",	
	frequency = sgs.Skill_Limited,	
	events = {sgs.DamageForseen},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.damage >= damage.to:getHp() then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,Kasumi in sgs.qlist(players) do
				if Kasumi:getMark("@qingyuan") > 0 and damage.to:objectName() ~= Kasumi:objectName() and not Kasumi:isKongcheng() then
					return self:objectName(), Kasumi
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
		room:setPlayerMark(ask_who, "qingyuanCount", damage.damage) --给人机用来判断的标记
		local who = sgs.QVariant()
		who:setValue(damage.to)
		if ask_who:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			room:doLightbox("qingyuan$")
			room:setPlayerMark(ask_who, "qingyuanCount", 0)
			return true
		end
		room:setPlayerMark(ask_who, "qingyuanCount", 0)
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)		
		room:setPlayerMark(ask_who, "@qingyuan", 0)
		ask_who:throwAllHandCards()
		local damage = data:toDamage()
		room:setPlayerMark(ask_who, "qingyuanUsed", 1)
		local log = sgs.LogMessage()
		log.type = "#qingyuanEffect"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		return true
	end,
}

qingyuanMark = sgs.CreateTriggerSkill{
	name = "#qingyuanMark",
	limit_mark = "@qingyuan",
	events = {sgs.GameStart},
	can_trigger = function()
	end,
	on_cost = function()
	end,
	on_effect = function()
	end
}

function getKingdomCount(player) --这里是设置自定义函数的方法，括号里面是参数
	local to_count = {} --思路：设置一个角色列表，遍历每个角色，有和已有列表里面势力一样的就不放进列表。这一行也可以用sgs.SPlayerList()，对于要传回日神进行操作的必须这么写，这里只是为了获取数量，就用方便的、lua自己的列表了。翻译曹仁源码
	local players
	if type(player) == "ServerPlayer" then
		players = player:getRoom():getAllPlayers()
	else
		players = player:getAliveSiblings()
		players:append(player)
	end
	for _, p in sgs.qlist(players) do
		if p:hasShownOneGeneral() then
			local no_friend = true
			for _, p2 in ipairs(to_count) do
				if p2:isFriendWith(p) then
					no_friend = false
					break
				end
			end
			if no_friend then
				table.insert(to_count, p)
			end
		end
	end
	local x = #to_count
	return x
end

zilian = sgs.CreateTriggerSkill{
	name = "zilian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.Damage, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.Damage and player:hasFlag("zilianUsed") then
			local damage = data:toDamage()
			room:setPlayerMark(player, "#zilian", player:getMark("#zilian") + damage.damage)
		end
		if event == sgs.EventPhaseChanging and player:getMark("#zilian") > 0 then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				room:setPlayerMark(player, "#zilian", 0)
			end
		end
		if event ==	sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then --这一段是为了防止在某些奇奇怪怪的时机进行记录，例如逆胜
			for _,Kasumi in sgs.qlist(room:getAlivePlayers()) do
				if Kasumi:getMark("#zilian") > 0 then
					room:setPlayerMark(Kasumi, "#zilian", 0)
				end
			end
		end			
	end ,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player and player:isAlive() and player:hasSkill(self:objectName()) and (player:getPhase() == sgs.Player_Play or (player:getPhase() == sgs.Player_Finish and player:hasFlag("zilianUsed") and player:getMark("#zilian") < getKingdomCount(player))) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if (player:getPhase() == sgs.Player_Finish and player:hasShownSkill(self:objectName())) or (player:getPhase() == sgs.Player_Play and (player:hasShownSkill(self:objectName()) and player:getMark("qingyuanUsed") == 0) or player:askForSkillInvoke(self, data)) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		if player:getPhase() == sgs.Player_Play then
			player:drawCards(getKingdomCount(player), self:objectName())
			player:setFlags("zilianUsed")
		end
		if player:getPhase() == sgs.Player_Finish then
			local a = getKingdomCount(player) - player:getMark("#zilian")
			local b = player:getHandcardNum() + player:getEquips():length()
			if a > 0 then
				if b >= a then
					room:askForDiscard(player, self:objectName(), a, a, false, true)
				else
					player:throwAllHandCardsAndEquips()
					room:loseHp(player, a-b)
				end
			end
		end
	end ,
}

zhanmeiVS = sgs.CreateViewAsSkill{
	name = "zhanmei",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local vs = zhanmeiCard:clone()
			for _,card in pairs(cards) do
				vs:addSubcard(card)
			end			
			vs:setShowSkill(self:objectName())
			vs:setSkillName(self:objectName())
			return vs
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@zhanmei"
	end,
}

zhanmeiCard = sgs.CreateSkillCard{
	name = "zhanmeiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			local list = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(source)) do
				if p:getEquips():length() >= source:getEquips():length() then
					list:append(p)
				end
			end
			if list:length() > 0 then
				local targets = room:askForPlayersChosen(source, list, "zhanmei", 1, count, "&zhanmei:" .. tostring(count), true)
				room:sortByActionOrder(targets)
				for _,A in sgs.qlist(targets) do
					local show_ids = room:askForExchange(A, "zhanmei", 1, 0, "&zhanmeiGive:" .. source:objectName(), "", "BasicCard")
					if not show_ids:isEmpty() then					
						room:setPlayerMark(source, "#zhanmei", source:getMark("#zhanmei")+1)
						local show = sgs.Sanguosha:getCard(show_ids:first())
						local reason = sgs.CardMoveReason(0x17, source:objectName())
						room:obtainCard(source, show, reason, false)
					end
				end
				if source:getMark("#zhanmei") < source:getLostHp() then
					local recover = sgs.RecoverStruct()
					recover.who = source
					recover.recover = 1
					room:recover(source, recover, true)
				end
				room:setPlayerMark(source, "#zhanmei", 0)
			end
		end
	end
}

zhanmei = sgs.CreateTriggerSkill{
	name = "zhanmei",
	can_preshow = true,
	view_as_skill = zhanmeiVS,
	events = {sgs.EventPhaseStart, sgs.Dying},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play and not player:isNude() then
				return self:objectName()
			end
		end
		if event == sgs.Dying then
			local dying = data:toDying()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and dying.damage and dying.damage.from and player:objectName() == dying.damage.from:objectName() and player:objectName() ~= dying.damage.to:objectName() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if event == sgs.Dying then
			if player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		if event == sgs.EventPhaseStart then
			if room:askForUseCard(player, "@@zhanmei", "@zhanmei") then
				return true
			end
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)	
		if event == sgs.Dying then
			room:transformDeputyGeneral(player)
		end
	end ,
}

aiwen = sgs.CreateTriggerSkill{
	name = "aiwen",
	events = {sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.to:isAlive() and damage.damage > 0 then
			if not room:getCurrent():hasFlag("aiwen"..damage.to:objectName()) then
				local players = room:findPlayersBySkillName(self:objectName())
				for _,Emma in sgs.qlist(players) do
					if not Emma:isNude() then
						return self:objectName(), Emma
					end
				end
			else
				local players = room:findPlayersBySkillName(self:objectName())
				for _,Emma in sgs.qlist(players) do
					return self:objectName(), Emma
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
		if not room:getCurrent():hasFlag("aiwen"..damage.to:objectName()) then
			local who = sgs.QVariant()
			who:setValue(damage.to)
			if ask_who:askForSkillInvoke(self, who) then
				room:getCurrent():setFlags("aiwen"..damage.to:objectName())
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		else
			if ask_who:hasShownSkill(self:objectName()) then
				room:getCurrent():setFlags("-aiwen"..damage.to:objectName())
				ask_who:setFlags("aiwen_losehp")
				room:broadcastSkillInvoke(self:objectName(), ask_who)
				return true
			end
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
		if not ask_who:hasFlag("aiwen_losehp") then
			local show_ids = room:askForExchange(ask_who, self:objectName(), 1, 1, "&aiwen", "", ".|.|.")
			local show_id = -1
			if show_ids:isEmpty() then
				show_id = ask_who:getCards("he"):first():getEffectiveId()
			else
				show_id = show_ids:first()
			end
			local show = sgs.Sanguosha:getCard(show_id)
			if show then
				room:moveCardTo(show, nil, sgs.Player_DrawPile, room:getCardPlace(show:getId()) ~= sgs.Player_PlaceHand)
				damage.damage = damage.damage - 1
				data:setValue(damage)
				local log = sgs.LogMessage()
				log.type = "#aiwenA"
				log.from = ask_who
				log.arg = self:objectName()
				room:sendLog(log)
				if damage.damage < 1 then
					return true
				end
			end
		else
			ask_who:setFlags("-aiwen_losehp")
			local log = sgs.LogMessage()
			log.type = "#aiwenB"
			log.from = ask_who
			log.arg = self:objectName()
			room:sendLog(log)
			room:loseHp(damage.to)
			return true
		end
	end,
}

lvgui = sgs.CreateTriggerSkill{
	name = "lvgui",
	events = {sgs.Damaged, sgs.EventPhaseStart},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("##oversea") > 0 and player:hasSkill("oversea") then
			room:setPlayerMark(player, "##oversea", 0)
			room:detachSkillFromPlayer(player, "oversea", false, false, player:inHeadSkills(self))
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damaged and player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("##oversea") == 0 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local choice = room:askForChoice(player, self:objectName(), "draw+overseaNEW", data)
		if choice == "draw" then
			local n = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() > n then
					n = p:getHandcardNum()
				end				
			end
			player:drawCards(math.min(5,n-player:getHandcardNum()), self:objectName())
		else
			room:acquireSkill(player, "oversea", true, player:inHeadSkills(self))
			room:setPlayerMark(player, "##oversea", 1)
		end
	end ,
}

xiangyunVS = sgs.CreateZeroCardViewAsSkill{
	name = "xiangyun", --技能名和触发技一样
	view_as = function(self)
		local pattern = sgs.Self:property("xiangyun_card"):toString() --获取记录卡牌名称
		if pattern == "" then return nil end --如果没有记录，返回空
		local vs = sgs.Sanguosha:cloneCard(pattern) --生成一个该名称虚拟卡牌
		vs:setSkillName("xiangyun")
		return vs --返回卡牌
	end,
	enabled_at_play = function(self, player)
		return false --不能在出牌阶段的空闲时间点主动地使用此技能
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xiangyun" --当指定pattern时才能响应
	end,
}

xiangyun = sgs.CreateTriggerSkill{
	name = "xiangyun",
	can_preshow = true,
	events = {sgs.CardFinished, sgs.Damage},
	view_as_skill = xiangyunVS, --合并上面的视为技	
	on_record = function(self, event, room, player, data)
		if event == sgs.Damage then 
			local damage = data:toDamage()
			if damage.card and player:hasSkill(self:objectName()) and (damage.card:isKindOf("BasicCard") or damage.card:isNDTrick()) then
				damage.card:setFlags("xiangyun_damage") --造成伤害时记录卡牌
			end			
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:objectName() == room:getCurrent():objectName() and not player:hasFlag("xiangyunUsed") and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) and not (use.card:hasFlag("xiangyun_damage")) then
				if not use.card:hasFlag("xiangyun_damage") then
				    return self:objectName()
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local use = data:toCardUse()
		if sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, -1):isAvailable(player) and player:askForSkillInvoke(self, data) then
			player:setFlags("xiangyunUsed")
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		room:setPlayerProperty(player, "xiangyun_card", sgs.QVariant(use.card:objectName())) --记录卡牌名称
		room:askForUseCard(player, "@@xiangyun", "@xiangyun:" .. tostring(use.card:getName()))
	end ,
}

oversea = sgs.CreateTriggerSkill{
	name = "oversea",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageForseen},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() and not damage.from:inMyAttackRange(player) then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		damage.damage = damage.damage - 1
		data:setValue(damage)
		local log = sgs.LogMessage()
		log.type = "#oversea-effect"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		if damage.damage < 1 then
			return true
		end
		data:setValue(damage)
		return false
	end,
}

jichan = sgs.CreateTriggerSkill{
	name = "jichan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GeneralShown, sgs.Death},
	can_trigger = function(self, event, room, player, data)
        if event == sgs.GeneralShown then
	        if player and player:isAlive() and player:inHeadSkills(self) == data:toBool() and player:hasSkill(self:objectName()) then
                return self:objectName()
            end
        end
        if event == sgs.Death then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				return self:objectName()
			end
		end
		return ""
    end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:doLightbox("RenJichan$", 999)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
	    local ids = room:getNCards(2, true)
		local hfmb = sgs.SPlayerList()
		hfmb:append(player)
		player:addToPile("heritage", ids, false, hfmb)
	end	   
}


jichanMaxCards = sgs.CreateMaxCardsSkill{
	name = "#jichanMaxCards" ,
	extra_func = function(self, player)
		if player:hasSkill("jichan") then
			return player:getPile("heritage"):length()
		end
		return 0
	end
}

weijiCard = sgs.CreateSkillCard{
	name = "weijiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, player)
	   room:obtainCard(player, self)
	   room:askForUseCard(player, "@@weijiglobal", "@weijiglobal")
	end,
}

weiji = sgs.CreateOneCardViewAsSkill{
	name = "weiji",
	expand_pile = "heritage",
	filter_pattern = ".|.|.|heritage",
	view_as = function(self, card)
		local vs = weijiCard:clone()
		vs:addSubcard(card)
		vs:setSkillName(self:objectName())
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return player:getHandcardNum() < player:getMaxHp() and player:getPile("heritage"):length() > 0 and player:usedTimes("#weijiCard") < math.max(1, player:getLostHp())
	end,
}

weijiglobalS = sgs.CreateViewAsSkill{
	name = "weijiglobal",
	n = 999,
	view_filter = function(self, selected, to_select)
	    if #selected < 1 then return "" end
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs = weijiglobalCard:clone()
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		for i = 1, #cards, 1 do
			vs:addSubcard(cards[i])
		end
		return vs	
	end,	
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@weijiglobal"
	end,
}

weijiglobalCard = sgs.CreateSkillCard{
	name = "weijiglobalCard",
	target_fixed = true,
	will_throw = false, 
	on_use = function(self, room, player, targets)
	    room:moveCardTo(self, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, player:objectName(), self:objectName(), ""))
		room:broadcastSkillInvoke("@recast")
		local log = sgs.LogMessage()
		log.type = "#UseCard_Recast"
		log.from = player
		log.card_str = tostring(cards)
		room:sendLog(log)
		player:drawCards(self:subcardsLength(), "recast")
	end,
}

diwu = sgs.CreateTriggerSkill{
	name = "diwu",
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseChanging and change.to == sgs.Player_NotActive then
			room:setPlayerMark(player, "#diwu_turnused", 0)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		local x = 3 - player:getMark("##ThreeUpBasic") - player:getMark("##ThreeUpTrick") - player:getMark("##ThreeUpEquip")
		if x > 0 then
			if event == sgs.CardUsed and player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("#diwu_turnused") < 3 and player:getPhase() == sgs.Player_Play then
				local use = data:toCardUse()
				if use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard") then
					return self:objectName()
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:setPlayerMark(player, "diwu_used", player:getMark("diwu_used")+1)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local n = player:getMark("diwu_used")
		local x = 3 - player:getMark("##ThreeUpBasic") - player:getMark("##ThreeUpTrick") - player:getMark("##ThreeUpEquip")
		if x <= 0 then return false end
		if room:getDrawPile():length() < x and not room:getDiscardPile():isEmpty() then
			room:swapPile()
		end
		local list = sgs.IntList()
		local dis = sgs.IntList()
		if n%2 == 1 then
			for i = 0, x-1, 1 do
				if room:getDrawPile():length() > i then
					list:append(room:getDrawPile():at(i))
				end
			end
		else
			for i = 1, x, 1 do
				if room:getDrawPile():length() > i then
					list:append(room:getDrawPile():at(room:getDrawPile():length() - i))
				end
			end
		end
		for _,i in sgs.qlist(list) do
			if sgs.Sanguosha:getCard(i):getTypeId() ~= use.card:getTypeId() then dis:append(i) end
		end
		room:fillAG(list, nil, dis)
		local id = -1
		room:setPlayerFlag(player, "diwu"..use.card:getTypeId())
		id = room:askForAG(player, list, true, "diwu")
		room:setPlayerFlag(player, "-diwu"..use.card:getTypeId())
		room:clearAG()
		room:clearAG(player)
		if id > -1 then
			room:setPlayerMark(player, "#diwu_turnused", player:getMark("#diwu_turnused")+1)
			room:obtainCard(player, id)
			local move = sgs.CardsMoveStruct()
			move.to_place = sgs.Player_DiscardPile
			for _,i in sgs.qlist(list) do
				if i ~= id then move.card_ids:append(i) end
			end
			room:moveCardsAtomic(move, true)
		end
	end ,
}

nishengCard = sgs.CreateSkillCard{
	name = "nishengCard",
	filter = function(self, targets, to_select, player)
		return #targets < self:getSubcards():length()
	end,
	feasible = function(self, targets, Self)
		return #targets == self:getSubcards():length()
	end ,
	on_use = function(self,room,player,targets)
		local has = false
		for _,p in ipairs(targets) do
			local damage = sgs.DamageStruct()
			damage.from = player
			damage.to = p
			room:damage(damage)
			if not p:isNude() and player:canDiscard(p, "he") then
				local id = room:askForCardChosen(player, p, "he", "nisheng")
				room:throwCard(id, p, player, self:objectName())
			else
				has = true
			end
		end
		if has then
			local recover = sgs.RecoverStruct()
			recover.who = player
			room:recover(player, recover, true)
		end
	end,
}

nishengVS = sgs.CreateViewAsSkill{
	name = "nisheng",
	view_filter = function(self, selected, to_select)
		local x = sgs.Self:getMark("##ThreeUpBasic") + sgs.Self:getMark("##ThreeUpTrick") + sgs.Self:getMark("##ThreeUpEquip")
		return #selected < x
	end,
	view_as = function(self, cards)		
		if #cards > 0 then
			local new_card = nishengCard:clone()
			new_card:setShowSkill(self:objectName())
			new_card:setSkillName(self:objectName())
			for i = 1, #cards, 1 do
				new_card:addSubcard(cards[i])
			end
			return new_card
		end	
	end,	
	
	enabled_at_play = function(self, player)
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@nisheng"
	end,
}

nisheng = sgs.CreateTriggerSkill{
	name = "nisheng",
	view_as_skill = nishengVS,
	events = {sgs.EventPhaseChanging},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and (player:getMark("##ThreeUpBasic") + player:getMark("##ThreeUpTrick") + player:getMark("##ThreeUpEquip") > 0) and change.to == sgs.Player_NotActive then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if room:askForUseCard(player, "@@nisheng", "@nisheng") then
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
	end ,
}

ThreeUp = sgs.CreateTriggerSkill{
	name = "ThreeUp",
	events = {sgs.AskForPeachesDone},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getMark("##ThreeUpBasic") + player:getMark("##ThreeUpTrick") + player:getMark("##ThreeUpEquip") < 3 and player:getHp() < 1 then
			local dying = data:toDying()
			if player == dying.who then
				return self:objectName()
			else
				return ""
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local choice_list = {}
		if player:getMark("##ThreeUpBasic") <= 0 then table.insert(choice_list, "basic") end
		if player:getMark("##ThreeUpTrick") <= 0 then table.insert(choice_list, "trick") end
		if player:getMark("##ThreeUpEquip") <= 0 then table.insert(choice_list, "equip") end
		if #choice_list == 0 then return false end
		local choice = room:askForChoice(player, self:objectName(), table.concat(choice_list, "+"), data)
		if choice == "basic" then
			room:addPlayerMark(player, "##ThreeUpBasic")
			room:setPlayerCardLimitation(player, "use,response", "BasicCard", false)
		elseif choice == "trick" then
			room:addPlayerMark(player, "##ThreeUpTrick")
			room:setPlayerCardLimitation(player, "use,response", "TrickCard", false)
		elseif choice == "equip" then
			room:addPlayerMark(player, "##ThreeUpEquip")
			room:setPlayerCardLimitation(player, "use,response", "EquipCard", false)
		end
		local recover = sgs.RecoverStruct()
		recover.who = player
		recover.recover = 1-player:getHp()
		room:recover(player, recover, true)
	end ,
}

beide = sgs.CreateTriggerSkill{
	name = "beide",
	events = {sgs.DrawNCards, sgs.CardUsed, sgs.EventPhaseEnd, sgs.EventPhaseChanging},	
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_Discard and player:hasFlag("beideSkip") then
			player:skip(sgs.Player_Discard)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.DrawNCards then
			local count = data:toInt()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and count > 0 then
				return self:objectName()
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasFlag("beideInvoked") and (sgs.Sanguosha:getCurrentCardUseReason() == 0x01 or sgs.Sanguosha:getCurrentCardUseReason() == 0x12) and use.card:getSuit() == sgs.Card_Spade and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) then
				return self:objectName()
			end
		end
		if event == sgs.EventPhaseEnd then
			local OnlyMost = true
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() >= player:getHandcardNum() then
					OnlyMost = false
				end
			end
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:hasFlag("beideInvoked") and player:getPhase() == sgs.Player_Play and OnlyMost then				
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if event == sgs.DrawNCards then
			if player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		if event == sgs.CardUsed then
			if player:hasShownSkill(self:objectName()) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		if event == sgs.EventPhaseEnd then
			if player:hasShownSkill(self:objectName()) and not player:isNude() and room:askForCard(player, ".|heart|.|.", "&beide") then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		if event == sgs.DrawNCards then				
			local count = data:toInt()
			count = count - 1
			player:setFlags("beideInvoked")
			data:setValue(count)
		end
		if event == sgs.CardUsed then
			player:drawCards(1, self:objectName())
		end
		if event == sgs.EventPhaseEnd then
			player:setFlags("beideSkip")
		end
	end ,
}

jinduan = sgs.CreateTriggerSkill{
	name = "jinduan",
	events = {sgs.Damaged, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseChanging and change.to == sgs.Player_NotActive and player:getMark("#jinduan") > 0 then
			room:setPlayerMark(player, "#jinduan", 0)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from:isAlive() and player and player:isAlive() and player:hasSkill(self:objectName()) and damage.damage > 0 then
				local trigger_list = {}
				for i = 1, damage.damage, 1 do
					table.insert(trigger_list, self:objectName())
				end
				return table.concat(trigger_list, ",")
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local damage = data:toDamage()
		local who = sgs.QVariant()
		who:setValue(damage.from)
		if player:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local blacks = {}	
		local to_get = sgs.Sanguosha:cloneCard("slash")
		local damage = data:toDamage()
		damage.from:drawCards(1, self:objectName())
		if damage.from:objectName() ~= player:objectName() and not damage.from:isKongcheng() then
			local blacks = {}
			for _,c in sgs.qlist(damage.from:getHandcards()) do
				if c:isBlack() then
					table.insert(blacks, c)
				end
			end
			if #blacks > 0 then
				local n = math.ceil(#blacks/2)
				while n > 0 and #blacks > 0 do
					local i = math.random(1, #blacks)
					to_get:addSubcard(table.remove(blacks, i))
					n = n-1
				end
			end
			local reason = sgs.CardMoveReason(0x27, player:objectName())
			room:obtainCard(player, to_get, reason, false)
		end
		if room:getCurrent() == damage.from and damage.from:getHandcardNum() < player:getHandcardNum() then
			room:setPlayerMark(damage.from, "#jinduan", damage.from:getMark("#jinduan")+1)
		end
		to_get:deleteLater()
	end ,
}

jinduanMaxCards = sgs.CreateMaxCardsSkill{
	name = "jinduanMaxCards" ,
	global = true,
	extra_func = function(self, player)
		return -player:getMark("#jinduan")
	end
}

qisuVS = sgs.CreateZeroCardViewAsSkill{
	name = "qisu",
	view_as = function(self)
		local pattern = sgs.Self:property("qisu_card"):toInt()
		if pattern == 0 then return nil end
		local vs = sgs.Sanguosha:getCard(pattern)
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@qisu"
	end,
}

qisu = sgs.CreateTriggerSkill{
	name = "qisu",
	can_preshow = true,
	events = {sgs.EventPhaseStart},
	view_as_skill = qisuVS,
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Start then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if sp:getPhase() == sgs.Player_NotActive and sp:getMark("##xingyun-invalid") == 0 then
					return self:objectName(), sp
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local judge = sgs.JudgeStruct()
		judge.pattern = "."
		judge.good = true
		judge.reason = self:objectName()
		judge.who = ask_who
		room:judge(judge)
		if judge.card:isKindOf("Slash") or judge.card:isKindOf("Duel") then
			if not ask_who:isRemoved() then
				room:setPlayerProperty(ask_who, "qisu_card", sgs.QVariant(judge.card:getId()))
				room:askForUseCard(ask_who, "@@qisu", "@qisu")
				room:setPlayerProperty(ask_who, "qisu_card", sgs.QVariant()) --视为卡使用之后，及时清零
			end
		else
			if ask_who:getMark("@qisu"..judge.card:getSuit()) == 0 and ask_who:isAlive() then
				room:setPlayerMark(ask_who, "@qisu"..judge.card:getSuit(), 1)
				if not ask_who:isRemoved() then
					room:setPlayerCardLimitation(ask_who, "use", ".", false)
					room:setPlayerProperty(ask_who, "removed", sgs.QVariant(true))
				end
			end
		end
	end ,
}

xingyun = sgs.CreateTriggerSkill{
	name = "xingyun",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		local change = data:toPhaseChange()
		if event == sgs.EventPhaseChanging and change.to == sgs.Player_NotActive then
			if player:getMark("##xingyun-invalid") > 0 then
				room:setPlayerMark(player, "##xingyun-invalid", 0)
			end
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if sp:getMark("xingyunloseHp") > 0 then --防止星陨的计数标记因为露比挡伤而无法正常归零
					room:setPlayerMark(sp, "xingyunloseHp", 0)
				end
			end
		end
	end ,
	can_trigger = function(self, event, room, player, data)
		if event ==	sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if sp:getMark("@qisu0") > 0 and sp:getMark("@qisu1") > 0 and sp:getMark("@qisu2") > 0 and sp:getMark("@qisu3") > 0 and not sp:isRemoved() then
					return self:objectName(), sp
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:hasShownSkill(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		room:setPlayerMark(ask_who, "@qisu0", 0)
		room:setPlayerMark(ask_who, "@qisu1", 0)
		room:setPlayerMark(ask_who, "@qisu2", 0)
		room:setPlayerMark(ask_who, "@qisu3", 0)
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
		local a = ask_who:getHp()
		room:setPlayerMark(ask_who, "xingyunloseHp", ask_who:getMark("xingyunloseHp")+a)
		room:loseHp(ask_who, a)
	end ,
}

xingyunDying = sgs.CreateTriggerSkill{
	name = "#xingyunDying",
	events = {sgs.Dying},
	can_trigger = function(self, event, room, player, data)
		local dying = data:toDying()
		if player and player:isAlive() and player:getMark("xingyunloseHp") > 0 and player:hasSkill("xingyun") and player == dying.who then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("xingyun") then
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local b = player:getMark("xingyunloseHp")
		player:drawCards(3+b, self:objectName())
		room:setPlayerMark(player, "xingyunloseHp", 0)
		room:setPlayerMark(player, "##xingyun-invalid", 1)
	end ,
}

anyu = sgs.CreateTriggerSkill{
	name = "anyu",
	events = {sgs.CardUsed, sgs.CardResponded},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and not room:getCurrent():hasFlag("anyuUsed") then
			if event == sgs.CardUsed then
				local use = data:toCardUse()
				if use.card:isBlack() and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) then
					return self:objectName()
				end
			end
			if event == sgs.CardResponded then
				local Card = data:toCardResponse().m_card
				if Card:isBlack() and Card:isKindOf("BasicCard") or Card:isKindOf("TrickCard") or Card:isKindOf("EquipCard") then
					return self:objectName()
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local who = sgs.QVariant()
		who:setValue(room:getCurrent())
		if player:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)		
		room:getCurrent():setFlags("anyuUsed")
		local a = 5 - room:getCurrent():getEquips():length()
		local choice
		local b = player:getHandcardNum() + player:getEquips():length()
		if b < a then
			choice = "anyuDraw"
		else
			choice = room:askForChoice(player, self:objectName(), "anyuDamage+anyuDraw", data)
		end
		if choice == "anyuDamage" then
			room:askForDiscard(player, self:objectName(), a, a, false, true)
			local damage = sgs.DamageStruct()
			damage.damage = 1
			damage.from = player
			damage.to = room:getCurrent()
			damage.nature = sgs.DamageStruct_Thunder
			room:damage(damage)
		else
			local ids = room:getNCards(a)
			local dummy = sgs.DummyCard()
			local list = sgs.IntList()
			for _,id in sgs.qlist(ids) do
				local c = sgs.Sanguosha:getCard(id)
				dummy:addSubcard(c)
			end
			for _,id in sgs.qlist(ids) do
				local c = sgs.Sanguosha:getCard(id)
				if c:isRed() then
					list:append(id)
				end
			end
			if dummy:getSubcards():length() > 0 then
				local reason = sgs.CardMoveReason(0x06, player:objectName())
				room:obtainCard(player, dummy, reason, false)
			end
			dummy:deleteLater()
			if list:length() > 0 then
			   local move = sgs.CardsMoveStruct()
			   move.card_ids = list
			   move.to_place = sgs.Player_DiscardPile
			   move.reason.m_reason = 0x33
			   move.reason.m_playerId = player:objectName()
			   move.reason.m_skillName = self:objectName()
			   room:moveCardsAtomic(move, true)
			end
		end
	end ,
}

jinfaVS = sgs.CreateViewAsSkill{
	name = "jinfa",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local pattern = sgs.Self:property("jinfa_card"):toString()
			if pattern == "" then return nil end
			local vs = sgs.Sanguosha:cloneCard(pattern, cards[1]:getSuit(), cards[1]:getNumber())
			vs:setSkillName("jinfa")
			vs:setShowSkill("jinfa")
			vs:addSubcard(cards[1])
			return vs
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jinfa"
	end,
}

jinfa = sgs.CreateTriggerSkill{
	name = "jinfa",
	can_preshow = true,
	events = {sgs.TargetConfirmed, sgs.CardFinished},
	view_as_skill = jinfaVS,
	on_record = function(self, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == self:objectName() and use.card:isRed() then
				for _, Liko in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
					if not Liko:isNude() then
						room:askForDiscard(Liko, self:objectName(), 1, 1, false, true)
					end
				end
			end
		end
	end ,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and use.from:objectName() == player:objectName() and use.card:isNDTrick() then
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, -1):isAvailable(p) and not (p:isKongcheng() or use.to:contains(p) or p:isRemoved()) then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local use = data:toCardUse()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, -1):isAvailable(p) and not (p:isKongcheng() or use.to:contains(p) or p:isRemoved()) then
				targets:append(p)
			end
		end
		local to = room:askForPlayerChosen(player, targets, self:objectName(), "&jinfa", true, true)
		if to then
			local _to = sgs.QVariant()
			_to:setValue(to)
			player:setTag("jinfaTarget", _to)
			room:broadcastSkillInvoke(self:objectName(), player)
			room:doLightbox("jinfa$", 800)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local to = player:getTag("jinfaTarget"):toPlayer()
		room:setPlayerProperty(to, "jinfa_card", sgs.QVariant(use.card:objectName()))
		room:askForUseCard(to, "@@jinfa", "@jinfa:" .. tostring(use.card:getName()))
	end ,
}

xunfei = sgs.CreateTriggerSkill{
	name = "xunfei",
	events = {sgs.TurnStart, sgs.EventPhaseStart},
	on_record = function(self, event, room, player, data)---sgs.TurnStart, 
	    if event == sgs.TurnStart then 
			if not player:hasFlag("Point_ExtraTurn") then
			    if event == sgs.TurnStart then 
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						if p:getMark("xunfeiUsed")> 0 then
						   room:setPlayerMark(p, "xunfeiUsed", 0)
						end  
					end 
				end	 
			end
		end
	end ,	
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Start then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if player:getMark("xunfeiUsed") == 0 and player:isFriendWith(sp) then
					local handcard_has_trick = false
					for _, c in sgs.qlist(sp:getCards("h")) do
						if c:isKindOf("TrickCard") then handcard_has_trick = true end
					end
					local xunfei_result = 0
					if handcard_has_trick then xunfei_result = xunfei_result + 1 end
					if xunfei_result == 0 then
					   return self:objectName(), sp				
					end 
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		room:setPlayerMark(player, "xunfeiUsed", 1)
		local list = sgs.IntList()
		for _,id in sgs.qlist(room:getDrawPile()) do
			local card = sgs.Sanguosha:getCard(id)
			if not card:isKindOf("TrickCard") then continue end
			list:append(id)
		end
		if list:length() > 0 then
			local id = list:at(math.random(0, list:length()-1))
			local card = sgs.Sanguosha:getCard(id)
			room:obtainCard(ask_who, card, false)
			if card and card:isKindOf("DelayedTrick") then
				ask_who:drawCards(1, self:objectName())
			else
			    if ask_who ~= player then
					local card = room:askForCard(ask_who, ".|.|.|.", "@xunfei_give", sgs.QVariant(), sgs.Card_MethodNone)
					if card then
						room:moveCardTo(card, player, sgs.Player_PlaceHand, sgs.CardMoveReason(0x17, ask_who:objectName(), player:objectName(), self:objectName(), ""))
					end	
				end	
			end
			
		end
	end ,		
}

lianhui = sgs.CreateTriggerSkill{
	name = "lianhui",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and not player:isKongcheng() then
				return self:objectName()
			end
		else
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
				local move = data:toMoveOneTime()
				local club = false
				for _, card_id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Club then
						club = true
						break
					end
				end
				if club then
					local reason = move.reason
					local basic = bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
					if move.from and move.from:objectName() == player:objectName() and basic ~= 0x01 and basic ~= 0x02 and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and not (move.to and move.to:objectName() == player:objectName() and (move.to_place == sgs.Player_PlaceHand or move.to_place == sgs.Player_PlaceEquip)) then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			player:drawCards(1, self:objectName())
		else
			room:showAllCards(player)
			local m = 0
			for _, p in sgs.qlist(player:getHandcards()) do
				if p:getSuit() == sgs.Card_Club then
					m = m+1
				end
			end
			if m > 0 then
				room:setPlayerMark(player, "lianhuiCount", m) --给人机用来判断的标记
				local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 1, m, "&lianhui:" .. tostring(m), true)
				room:sortByActionOrder(targets)
				for _,B in sgs.qlist(targets) do
					B:drawCards(1, self:objectName())
				end
				room:setPlayerMark(player, "lianhuiCount", 0)
			end
		end
	end,
}

shixin = sgs.CreateTriggerSkill{
	name = "shixin",
	events = {sgs.CardFinished, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then			
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("#shixin") > 0 then
					room:setPlayerMark(p, "#shixin", 0)
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and not player:isNude() and use.card:getSuit() and use.card:getSuit() ~= sgs.Card_Club and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) and player:getMark("#shixin") < 2 then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:setPlayerMark(player, "#shixin", player:getMark("#shixin")+1)
		room:askForDiscard(player, self:objectName(), 1, 1, false, true)
		local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "&shixinDraw")
		target:drawCards(1, self:objectName())
		if player:getMark("#shixin") == 1 then
			if target:isFriendWith(player) and not target:isKongcheng() then
				local players = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(target)) do
					if p:isFriendWith(player) then players:append(p) end
				end
				local t = room:askForPlayerChosen(target, players, self:objectName(), "&shixinChoose:" .. player:objectName(), true)
				if t then
					players = sgs.SPlayerList()
					players:append(t)
					local reason = sgs.CardMoveReason(0x17, player:objectName())
				    room:askForYiji(target, target:handCards(), self:objectName(), false, false, true, 2, players, reason, "&shixin:" .. t:objectName())
                end
			end
		end
	end ,
}

function hasFlush(list)
	local heart = {} 
	local club = {} 
	local spade = {} 
	local diamond = {}
	for _,id in ipairs(list) do
		local c = sgs.Sanguosha:getCard(id)
		if c:getSuitString() == "heart" then table.insert(heart, c) end
		if c:getSuitString() == "club" then table.insert(club, c) end
		if c:getSuitString() == "spade" then table.insert(spade, c) end
		if c:getSuitString() == "diamond" then table.insert(diamond, c) end
	end
	return #heart >= 3 or #club >= 3 or #spade >= 3 or #diamond >= 3
end

function hasStraight(list)
	local newlist = {}
	while #list > 0 do
		local min = 998
		for _,id in ipairs(list) do
			local c = sgs.Sanguosha:getCard(id)
			if c:getNumber() < min then min = c:getNumber() end
		end
		for _,id in ipairs(list) do
			local c = sgs.Sanguosha:getCard(id)
			if c:getNumber() == min then
				table.removeOne(list, id)
				table.insert(newlist, c:getNumber())
			end
		end
	end
	if #newlist < 3 then return false end
	for i = 1, #newlist-2, 1 do
		if newlist[i]+1 == newlist[i+1] and newlist[i]+2 == newlist[i+2] then return true end
	end
	return false
end

function hasStraightFlush(list)
	local heart = {} 
	local club = {} 
	local spade = {} 
	local diamond = {}
	for _,id in ipairs(list) do
		local c = sgs.Sanguosha:getCard(id)
		if c:getSuitString() == "heart" then table.insert(heart, id) end
		if c:getSuitString() == "club" then table.insert(club, id) end
		if c:getSuitString() == "spade" then table.insert(spade, id) end
		if c:getSuitString() == "diamond" then table.insert(diamond, id) end
	end
	return hasStraight(heart) or hasStraight(club) or hasStraight(spade) or hasStraight(diamond)
end

yaojiancard = sgs.CreateSkillCard{
	name = "yaojiancard",
	will_throw = false,
	filter = function(self, targets, to_select) --必须
		local s = sgs.Sanguosha:cloneCard("slash")
		local ex = 0
		ex = ex+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, sgs.Self, s)
		return #targets <= ex and not sgs.Self:isProhibited(to_select, s) and sgs.Self:objectName() ~= to_select:objectName() and (sgs.Self:inMyAttackRange(to_select) or sgs.Self:hasFlag("yaojian_nolimit"))
	end ,
	on_use = function(self, room, player, targets)
		local card = sgs.Sanguosha:cloneCard("slash")
		card:setShowSkill("yaojian")
		card:setSkillName("yaojian")
		for _,i in sgs.qlist(self:getSubcards()) do
			card:addSubcard(i)
		end
		local use = sgs.CardUseStruct()
		use.card = card
		use.from = player
		for _,p in ipairs(targets) do
			use.to:append(p)
		end
		room:useCard(use, false)
	end ,
}

yaojianVS = sgs.CreateViewAsSkill{
	name = "yaojian",
	mute = true,
	view_filter=function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local vs
		if #cards == 0 then return nil end
		local ask = sgs.Sanguosha:getCurrentCardUsePattern()
		if ask == "slash" then
           vs = sgs.Sanguosha:cloneCard("slash")
		else
           vs = yaojiancard:clone()
		end
		for var = 1, #cards, 1 do   
            vs:addSubcard(cards[var])           
        end		
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_yaojianCard")
	end,
	enabled_at_response = function(self, player, pattern)
        return pattern == "@@yaojian" or (pattern == "slash" and player:getMark("yaojian_used") == 0 and sgs.Sanguosha:getCurrentCardUseReason() == 0x12)
    end,
}

yaojian = sgs.CreateTriggerSkill{
	name = "yaojian",
	view_as_skill = yaojianVS,
	events = {sgs.SlashHit, sgs.CardUsed, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "yaojian_used", 0)
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == self:objectName() then
				room:setPlayerMark(player, "yaojian_used", 1)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		local effect = data:toSlashEffect()
		if event == sgs.SlashHit and player:isAlive() and player:hasSkill(self:objectName()) and effect.slash:getSkillName() == self:objectName() and effect.to:getJudgingArea():length()+effect.to:getEquips():length() > 0 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local effect = data:toSlashEffect()
		local n = effect.slash:getSubcards():length()
		for i = 1, n, 1  do
			if effect.to:getJudgingArea():length() + effect.to:getEquips():length() > 0 then
				local id = room:askForCardChosen(effect.to, effect.to, "ej", self:objectName())
				room:throwCard(id, effect.to, effect.to, self:objectName())
			end
		end
	end
}

tonghua = sgs.CreateTriggerSkill{
	name = "tonghua",
	events = {sgs.EventPhaseStart, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerProperty(p, "tonghua_list"..room:getCurrent():objectName(), sgs.QVariant())
				end
			end
		end
		if event ~= sgs.CardsMoveOneTime then return end
		local move = data:toMoveOneTime()
		if (move.reason.m_reason ~= 0x01 and move.reason.m_reason ~= 0x11) then return end
		if (move.card_ids:length() == 0 or move.to_place ~= sgs.Player_DiscardPile) then return end
		local list = player:property("tonghua_list"..room:getCurrent():objectName()):toString():split("+")
		for _,id in sgs.qlist(move.card_ids) do
			table.insert(list, tostring(id))
		end
		room:setPlayerProperty(player, "tonghua_list"..room:getCurrent():objectName(), sgs.QVariant(table.concat(list,"+")))
	end ,
	can_trigger = function(self, event, room, player, data)
		local players = room:findPlayersBySkillName(self:objectName())
		for _,sp in sgs.qlist(players) do
			local list = sp:property("tonghua_list"..room:getCurrent():objectName()):toString():split("+")
			local intlist = {}
			for _,i in ipairs(list) do
				table.insert(intlist, tonumber(i))
			end
			if event == sgs.EventPhaseStart and sp:isFriendWith(player) and player:getPhase() == sgs.Player_Finish and hasFlush(intlist) then
				return self:objectName(), sp
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
		if sp:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)
		local list = player:property("tonghua_list"..room:getCurrent():objectName()):toString():split("+")
		local intlist = {}
		for _,i in ipairs(list) do
            table.insert(intlist, tonumber(i))
		end
		if hasFlush(intlist) then
            sp:drawCards(2, self:objectName())
		end
		if hasStraightFlush(intlist) then
            room:setPlayerFlag(sp, "yaojian_nolimit")
            room:askForUseCard(sp, "@@yaojian", "@yaojian")
			room:setPlayerFlag(sp, "-yaojian_nolimit")
			local target = room:askForPlayerChosen(sp, room:getAlivePlayers(), self:objectName(), "&tonghua")
			local damage = sgs.DamageStruct()
			damage.from = sp
			damage.to = target
			room:damage(damage)
		end
	end ,
}

shouwuCard = sgs.CreateSkillCard{
	name = "shouwuCard",
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if to_select:hasSkill("xueyun") then return false end
		return #targets < self:getSubcards():length()
	end,
	feasible = function(self, targets, Self)
		return #targets == self:getSubcards():length()
	end ,
	on_use = function(self, room, player, targets)
		for _,id in sgs.qlist(self:getSubcards()) do
			room:showCard(player, id)
		end
		for _,p in ipairs(targets) do
			room:acquireSkill(p, "xueyun", true, p:inHeadSkills("shouwu"))
			room:setPlayerMark(p, "##xueyun", 1)
		end
	end,
}

shouwu = sgs.CreateViewAsSkill{
	name = "shouwu",
	n = 999,
	view_filter = function(self, selected, to_select)
		if not to_select:isBlack() or to_select:isEquipped() then return false end
		for _,d in ipairs(selected) do
			if to_select:objectName() == d:objectName() then return false end
		end
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs = shouwuCard:clone()
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		for i = 1, #cards, 1 do
			vs:addSubcard(cards[i])
		end
		return vs	
	end,	
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_shouwuCard")
	end,
}

xueyuncard = sgs.CreateSkillCard{
	name = "xueyuncard",
	will_throw = false,
	filter = function(self, targets, to_select)
		local s = sgs.Sanguosha:cloneCard("ice_slash")
		local ex = 0
		ex = ex+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,sgs.Self,s)
		return #targets <= ex and not sgs.Self:isProhibited(to_select, s) and sgs.Self:objectName() ~= to_select:objectName() and sgs.Self:inMyAttackRange(to_select)
	end,
    on_use = function(self, room, player, targets)
		local card = sgs.Sanguosha:cloneCard("ice_slash")
		card:setSkillName("xueyun")
		for _,i in sgs.qlist(self:getSubcards()) do
			card:addSubcard(i)
		end
		local use = sgs.CardUseStruct()
		use.card = card
		use.from = player
		for _,p in ipairs(targets) do
			use.to:append(p)
		end
		room:useCard(use, false)
	end,
}

xueyun = sgs.CreateOneCardViewAsSkill{
	name = "xueyun",
	view_filter = function(self, card)
		if not card:isBlack() then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == 0x01 then
    		local ice_slash = sgs.Sanguosha:cloneCard("ice_slash", sgs.Card_SuitToBeDecided, -1)
        	ice_slash:addSubcard(card:getEffectiveId())
        	ice_slash:deleteLater()
        	return true
    	end
    	return true
	end,
	view_as = function(self, originalCard, player)
		local vs
		local ask = sgs.Sanguosha:getCurrentCardUsePattern()
		if ask == "slash" then
			vs = sgs.Sanguosha:cloneCard("ice_slash")
		else
			vs = xueyuncard:clone()
		end
		vs:addSubcard(originalCard:getId())
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return true
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == 0x12
	end,
}

xueyunglobal = sgs.CreateTriggerSkill{
	name = "xueyunglobal",
	global = true,
	events = {sgs.EventPhaseChanging, sgs.CardUsed},
	priority = 2,
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
		    if player:hasSkill("xueyun") and change.to == sgs.Player_NotActive then
			    room:setPlayerMark(player, "##xueyun", 0)
				room:detachSkillFromPlayer(player, "xueyun", false, false, player:inHeadSkills("shouwu"))
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == "xueyun" then
				room:setPlayerMark(player, "##xueyun", 0)
				room:detachSkillFromPlayer(player, "xueyun", false, false, player:inHeadSkills("shouwu"))
			end
		end	
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false 
	end,
}

xianju = sgs.CreateTriggerSkill{
	name = "xianju",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnStart, sgs.Damage},
	on_record = function(self, event, room, player, data)
		if event == sgs.TurnStart and not player:hasFlag("Point_ExtraTurn") then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getMark("xianju") > 0 then
					room:setPlayerMark(p, "xianju", 0)
				end
			end
		end
	end ,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.Damage then
			local damage = data:toDamage()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if damage and damage.from and damage.from:isAlive() and damage.nature == sgs.DamageStruct_Ice and damage.from:getMark("xianju") == 0 then
					return self:objectName(), sp
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()
		if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			room:setPlayerMark(damage.from, "xianju", 1)
			return true
		end
		room:setPlayerMark(damage.from, "xianju", 1)
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
		ask_who:drawCards(1, self:objectName())
	end,
}

lamei = sgs.CreateTriggerSkill{
	name = "lamei",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
	    local use = data:toCardUse()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and use.card:objectName() == "indulgence" then
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHp() <= player:getHp() then
					return self:objectName()
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		local use = data:toCardUse()
		sgs.Room_cancelTarget(use, player)
		data:setValue(use)
	end ,
}

youai = sgs.CreateZeroCardViewAsSkill{
	name = "youai",
	view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@youai" then
			local id = sgs.Self:property("youai_use"):toInt()
			if id == 0 then
				return nil
			end
			local vs = sgs.Sanguosha:getCard(id)
			return vs
		else
			local vs = youaiCard:clone() 
			vs:setShowSkill(self:objectName())
			return vs
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_youaiCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@youai"
	end,
}

youaiCard = sgs.CreateSkillCard{
	name = "youaiCard",
	filter = function(self, targets, to_select, Self)
		if #targets ~= 0 then return false end
		return to_select:objectName() ~= Self:objectName()
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local a = target:getLostHp()
		target:drawCards(1+a, "youai")
		local n = target:getHandcardNum() + target:getEquips():length() + target:getJudgingArea():length()
		n = math.min(n, 1+a)
		if n > 0 then
			local handle_list = {}
			for i = 1, n, 1 do
				table.insert(handle_list, "hej")
			end
			local to
			local choice = room:askForChoice(player, "youai", "youaiSelf+youaiTarget")
			if choice == "youaiSelf" then
				to = player
			else
				to = target
			end
			local ids = room:askForCardsChosen(to, target, table.concat(handle_list, "|"), "youai")
			local listA = sgs.IntList()
			for _,id in sgs.qlist(ids) do
				listA:append(id:getId())
			end
			if listA:length() > 0 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = listA
				move.to_place = sgs.Player_DiscardPile
				move.reason.m_reason = 0x33
				move.reason.m_playerId = player:objectName()
				move.reason.m_skillName = "youai"
				room:moveCardsAtomic(move, true)
			end
			local list = sgs.IntList()
			for _,i in sgs.qlist(ids) do
				if i:isRed() and i:isAvailable(player) then
					list:append(i:getId())
				end
			end
			if list:length() > 0 then
				room:fillAG(list, nil)
				local id = -1
				id = room:askForAG(player, list, true, "youai")
				room:clearAG()
				room:clearAG(player)
				if id > -1 then
					room:setPlayerProperty(player, "youai_use", sgs.QVariant(id))
					room:askForUseCard(player, "@@youai", "@youai:" .. tostring(sgs.Sanguosha:getCard(id):getName()))
					room:setPlayerProperty(player, "youai_use", sgs.QVariant())
				end
			end
		end
		if player:isAlive() and target:isAlive() and not target:hasSkill("youaizongheng") then
			local choice = room:askForChoice(player, "youai", "youaiManoeuvre+cancel")
			if choice == "youaiManoeuvre" then
				room:acquireSkill(target, "youaizongheng", true, false)
				room:setPlayerMark(target, "##youai", 1)
			end
		end
	end ,
}

youaizongheng = sgs.CreateZeroCardViewAsSkill{
	name = "youaizongheng",
	view_as = function(self)
		local vs = youaizonghengCard:clone() 
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_youaizonghengCard")
	end,
}

youaizonghengCard = sgs.CreateSkillCard{
	name = "youaizonghengCard",
	filter = function(self, targets, to_select, Self)
		if #targets ~= 0 then return false end
		return to_select:objectName() ~= Self:objectName()
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		target:drawCards(1, "youaizongheng")
		if not target:isAllNude() then
			local to
			local choice = room:askForChoice(player, "youaizongheng", "youaiSelf+youaiTarget")
			if choice == "youaiSelf" then
				to = player
			else
				to = target
			end
			local id = room:askForCardChosen(to, target, "hej", "youaizongheng")
			room:throwCard(id, target, player, "youaizongheng")
		end
	end ,			
}

youaiglobal = sgs.CreateTriggerSkill{
	name = "youaiglobal",
	global = true,
	events = {sgs.EventPhaseChanging},
		priority = 2,
	can_trigger = function(self, event, room, player, data)  
		local change = data:toPhaseChange()
		if change.to == sgs.Player_NotActive and player:getMark("##youai") > 0 and player:hasSkill("youaizongheng") then
			room:setPlayerMark(player, "##youai", 0)
			room:detachSkillFromPlayer(player, "youaizongheng", false, false, false)
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false 
	end,
}

gejiVS = sgs.CreateViewAsSkill{
	name = "geji",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped() and not sgs.Self:hasFlag("geji_pro"..to_select:getSuitString()) and #selected == 0
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local music = sgs.Sanguosha:cloneCard("music", cards[1]:getSuit(), cards[1]:getNumber())
			music:setShowSkill(self:objectName())
			music:setSkillName(self:objectName())
			music:addSubcard(cards[1])
			return music
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

geji = sgs.CreateTriggerSkill{
	name = "geji",
	view_as_skill = gejiVS,
	events = {sgs.CardFinished},
	can_preshow = true,
	on_record = function(self, event, room, player, data)
		local use = data:toCardUse()
		if event == sgs.CardFinished and player:getPhase() ~= sgs.Player_NotActive then
			if not (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) then return end
			if use.card:getSuitString() ~= "heart" and use.card:getSuitString() ~= "diamond" and use.card:getSuitString() ~= "spade" and use.card:getSuitString() ~= "club" then return end
			room:setPlayerFlag(player, "geji_pro"..use.card:getSuitString())
            if use.card:getSkillName() == self:objectName() then
				room:setPlayerCardLimitation(player, "use", ".|"..use.card:getSuitString().."|.|.", true)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		if player and use.card:isKindOf("Music") and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
	    return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:isFriendWith(player) then targets:append(p) end
			end
			local target = room:askForPlayerChosen(player, targets, self:objectName(), "&geji", true)
			if target then
				room:broadcastSkillInvoke(self:objectName(), player)
                player:setProperty("geji_target", sgs.QVariant(target:objectName()))
				return true
			end			
		end
	end,
	on_effect = function(self, event, room, player, data)
	    local target = findPlayerByObjectName(player:property("geji_target"):toString())
		if not target then return false end
		target:drawCards(1, self:objectName())
	end,
}

gongzhuMaxCards = sgs.CreateMaxCardsSkill{
	name = "#gongzhuMaxCards",
	extra_func = function(self, player)
		if player:hasShownSkill("gongzhu") then
			local a = 1
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:isFriendWith(player) then
					a = a+1
				end
			end
			return a
		end
		return 0
	end
}

gongzhu = sgs.CreateTriggerSkill{
	name = "gongzhu",
	events = {sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		    local has = false
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:willBeFriendWith(p) and not use.to:contains(p) then has = true end
			end
			if player and player:isAlive() and player:hasSkill(self:objectName()) and use.to:contains(player) and use.card:isKindOf("Slash") and has then
				return self:objectName()
			end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local targets = room:getOtherPlayers(player)
		room:sortByActionOrder(targets)
		for _,p in sgs.qlist(targets) do
			if player:isFriendWith(p) and not use.to:contains(p) and not p:isRemoved() then 
				local da = sgs.QVariant()
				da:setValue(player)
				if p:askForSkillInvoke("gongzhu_defend", da) then
				    use.to:removeOne(player)
                    player:slashSettlementFinished(use.card)
                    use.to:append(p)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                    room:getThread():trigger(sgs.TargetConfirming, room, p, data)
					break
				end
			end
		end
	end ,
}

caiquan = sgs.CreateTriggerSkill{
	name = "caiquan",
	events = {sgs.EventPhaseStart, sgs.AskForRetrial},
	on_record = function(self, event, room, player, data)
		if event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if judge.reason == "zhaolei" and not player:isNude() and player:hasFlag("caiquan_win") then
				local prompt = "@guidao-card:"..judge.who:objectName()..":caiquan"..":"..judge.reason..":"..tostring(judge.card:getEffectiveId())
				local card = room:askForCard(player, ".|.|.|.", prompt, data, sgs.Card_MethodResponse, judge.who, true)
				if card then
					room:retrial(card, player, judge, self:objectName(), true)
					judge:updateResult()
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Play and not player:isKongcheng() then
            return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		local list = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if not p:isKongcheng() then
				list:append(p)		   
			end
		end
		local target 
		if player:askForSkillInvoke(self, data) then
			target = room:askForPlayerChosen(player, list, self:objectName(), "&caiquan", true)
		end
		if target then
			room:broadcastSkillInvoke(self:objectName(), player)
			player:setProperty("caiquan_target", sgs.QVariant(target:objectName()))
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
        local target = findPlayerByObjectName(player:property("caiquan_target"):toString())
		if not target then return false end
        if target:isKongcheng() or player:isKongcheng() then return false end
		local pd = player:pindianSelect(target, "caiquan")
		local success = player:pindian(pd)
		local a, b = pd.from_card:getEffectiveId(), pd.to_card:getEffectiveId()
		if success then
			local choices = "caiquan_pdcards+cancel"
			if not target:isNude() then choices = "caiquan_pdcards+caiquan_tcard+cancel" end
			local choice = room:askForChoice(player, self:objectName(), choices, data)
            if choice == "caiquan_pdcards" then
				local dummy = sgs.DummyCard()
				dummy:addSubcard(sgs.Sanguosha:getCard(a))
				dummy:addSubcard(sgs.Sanguosha:getCard(b))
				if dummy:getSubcards():length() > 0 then
					room:obtainCard(player, dummy)
				end
				dummy:deleteLater()
			elseif choice == "caiquan_tcard" then
				local id = room:askForCardChosen(player, target, "he", self:objectName())
				room:obtainCard(player, id, false)
			end
			room:setPlayerFlag(player, "caiquan_win")
		else
			room:setPlayerFlag(player, "caiquan_lose")
		end
	end,
}

caiquanMaxCards = sgs.CreateMaxCardsSkill{
	name = "#caiquanMaxCards",
	extra_func = function(self, player)
		if player:hasFlag( "caiquan_lose") then
			return -1
		end
		return 0
	end
}

zhaolei = sgs.CreateTriggerSkill{
	name = "zhaolei",
    events = {sgs.EventPhaseStart, sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
            return self:objectName()
		end
		if event == sgs.DamageInflicted and player:hasSkill(self:objectName()) and data:toDamage().nature == sgs.DamageStruct_Thunder then
            return self:objectName()
		end
	end,
	on_cost = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:doLightbox("zhaolei$", 999)
            return true
		end
		if event == sgs.DamageInflicted and (player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data)) then
			room:broadcastSkillInvoke(self:objectName(), player)
            return true
		end
	end,
	on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
			local judge = sgs.JudgeStruct()
			judge.pattern = "."
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			local x = judge.card:getNumber()
			local tname = player:objectName()
			for i = 1, x, 1 do
				if i == 1 then 
					tname = player:objectName()
				else
					tname = findPlayerByObjectName(tname):getLastAlive():objectName()
				end
			end  
			local t = findPlayerByObjectName(tname)
			if not t then return false end
			local damage = sgs.DamageStruct()
			damage.from = player
			damage.to = t
			damage.nature = sgs.DamageStruct_Thunder
			room:damage(damage)
	    end
		if event == sgs.DamageInflicted then
			room:sendCompulsoryTriggerLog(player, self:objectName(), true)
			return true
		end
	end,
}

chixin = sgs.CreateViewAsSkill{
	name = "chixin",
	n = 1,
	guhuo_type = "bt",
	view_filter = function(self, selected, to_select)
		return #selected == 0 and to_select:isRed()
	end ,
	view_as = function(self, cards)
		local pattern = sgs.Self:getTag(self:objectName()):toString()
		if #cards ~= 1 or pattern == "" then return end
		local vs = sgs.Sanguosha:cloneCard(pattern)
		for var = 1, #cards, 1 do
			vs:addSubcard(cards[var])
		end
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		return vs
	end ,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_chixinCard")
	end ,
	button_enabled = function(self, name)
		if name ~= "fire_slash" and name ~= "fire_attack" and name ~= "burning_camps" then return false end
		return true
	end ,
}

chixinEffect = sgs.CreateTriggerSkill{
	name = "#chixinEffect",
	events = {sgs.TargetConfirmed, sgs.TrickCardCanceling},
	can_trigger = function(self, event, room, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()		
			local most = true
			if not use.from then return "" end
			for _,p in sgs.qlist(room:getOtherPlayers(use.from)) do
				if p:getHandcardNum() > use.from:getHandcardNum() then
					most = false
				end
			end
			if most and player and player:isAlive() and use.card:isKindOf("Slash") and use.card:getSkillName() == "chixin" and use.from == player then
				local targets = {}
				for _,k in sgs.qlist(use.to) do
					table.insert(targets, k:objectName())
				end
				if #targets > 0 then
					return self:objectName().."->"..table.concat(targets, "+")
				end
			end
		end
		if event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()	
			local most = true
			if not effect.from then return "" end 
			for _,p in sgs.qlist(room:getOtherPlayers(effect.from)) do
				if effect.from and p:getHandcardNum() > effect.from:getHandcardNum() then
					most = false
				end
			end
			if most then
				for _, q in sgs.qlist(room:findPlayersBySkillName("chixin")) do
					if effect.from and effect.from:isAlive() and effect.card:getSkillName() == "chixin" then
						return self:objectName()
					end
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		return true
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			local jink_list = ask_who:getTag("Jink_" .. use.card:toString()):toList()
			local index = use.to:indexOf(player)
			jink_list:replace(index,sgs.QVariant(0))
			ask_who:setTag("Jink_" .. use.card:toString(), sgs.QVariant(jink_list))
		end
		if event == sgs.TrickCardCanceling then
			local effect = data:toCardEffect()
			return true
		end
	end ,
}

chixinVS = sgs.CreateTargetModSkill{
	name = "#chixinVS",
	pattern = ".",	
	extra_target_func = function(self, from, card)
		if from:hasShownSkill("chixin") and (card:isKindOf("FireSlash") or card:objectName() == "fire_attack") then
			return 1
		end
		return 0
	end ,
}

jinhun = sgs.CreateTriggerSkill{
	name = "jinhun",
	limit_mark = "@jinhun",	
	frequency = sgs.Skill_Limited,	
	events = {sgs.AskForPeachesDone},
	can_trigger = function(self, event, room, player, data)
		local dying = data:toDying()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player == dying.who and player:getHp() < 1 and player:getMark("@jinhun") > 0 and (player:inHeadSkills(self) or player:inDeputySkills(self)) then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:doLightbox("jinhun$")
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)		
		room:setPlayerMark(player, "@jinhun", 0)
		player:removeGeneral(player:inHeadSkills(self))	
		room:setPlayerProperty(player, "hp", sgs.QVariant(1))
        room:setPlayerProperty(player, "maxhp", sgs.QVariant(1))
		local t = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "&jinhun", true)
		if t then
			local list = sgs.IntList()
			for _,id in sgs.qlist(room:getDrawPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:objectName() == "fire_slash" or card:objectName() == "fire_attack" or card:objectName() == "burning_camps" then
					list:append(id)
				else
					continue
				end
			end
			for _,id in sgs.qlist(room:getDiscardPile()) do
				local card = sgs.Sanguosha:getCard(id)
				if card:objectName() == "fire_slash" or card:objectName() == "fire_attack" or card:objectName() == "burning_camps" then
					list:append(id)
				else
					continue
				end
			end
			if list:length() > 0 then
				local Chase = sgs.Sanguosha:getCard(list:at(math.random(0, list:length() - 1)))
				room:obtainCard(t, Chase, false)
			end
		end
	end,
}

jinhunMark = sgs.CreateTriggerSkill{
	name = "#jinhunMark",
	limit_mark = "@jinhun",
	events = {sgs.GameStart},
	can_trigger = function()
	end,
	on_cost = function()
	end,
	on_effect = function()
	end
}

yibing = sgs.CreateTriggerSkill{
	name = "yibing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.DrawNCards},	
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart and player:getMark("#yibing") > 0 then
			room:setPlayerMark(player, "#yibing", 0)
			room:setPlayerMark(player, "yibing-slash", 0)
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
				return self:objectName()
			end
			if event == sgs.DrawNCards and player:hasFlag("yibing-draw") then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		if event == sgs.EventPhaseStart then
			local choiceA = room:askForChoice(player, "#yibingX", "yes+no", data)
			if choiceA == "yes" then
				room:setPlayerMark(player, "#yibing", player:getMark("#yibing")+1)
				player:setFlags("yibing-draw")
				local log = sgs.LogMessage()
				log.type = "#yibingA"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			end
			local choiceB = room:askForChoice(player, "#yibingY", "yes+no", data)
			if choiceB == "yes" then
				room:setPlayerMark(player, "#yibing", player:getMark("#yibing")+1)
				room:setPlayerMark(player, "yibing-slash", 1)
				local log = sgs.LogMessage()
				log.type = "#yibingB"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			end
			local choiceC
			if player:getMark("#yibing") == 0 then
				choiceC = "yes"
			else
				choiceC = room:askForChoice(player, "#yibingZ", "yes+no", data)
			end
			if choiceC == "yes" then
				room:setPlayerMark(player, "#yibing", player:getMark("#yibing")+1)
				player:setFlags("yibing-maxcard")
				local log = sgs.LogMessage()
				log.type = "#yibingC"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			end
		end
		if event == sgs.DrawNCards then
			local count = data:toInt()
			count = count + 1
			data:setValue(count)
		end
	end,
}			

yibingVS = sgs.CreateTargetModSkill{
	name = "yibingVS",
	residue_func = function(self, player)
		if player:getMark("yibing-slash") > 0 then
			return 1
		end
		return 0
	end,
}

yibingMaxCards = sgs.CreateMaxCardsSkill{
	name = "yibingMaxCards" ,
	extra_func = function(self, player)
		if player:hasFlag("yibing-maxcard") then
			return 1
		end
		return 0
	end
}

neifan = sgs.CreateTriggerSkill{
	name = "neifan",
	events = {sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		if player:isAlive() and player:getPhase() == sgs.Player_Play then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,Haru in sgs.qlist(players) do
				if Haru:getPhase() == sgs.Player_NotActive and Haru:hasSkill("neifan") and (player:getHandcardNum() - Haru:getHandcardNum()) <= Haru:getMark("#yibing") and ((player:getHandcardNum() - Haru:getHandcardNum()) > 0) then
					return self:objectName(), Haru
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:hasShownSkill(self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
		local list = {}
		if not player:isNude() then 
			table.insert(list, "neifanExchange")
		end
		if not (string.find(player:getActualGeneral2Name(), "sujiang")) then
			table.insert(list, "neifanRemove")
		end
		if #list > 0 then
			local choice = room:askForChoice(player, self:objectName(), table.concat(list, "+"), data)
			if choice == "neifanExchange" then
				local show_ids = room:askForExchange(player, self:objectName(), 1, 1, "@neifan_give:" .. ask_who:objectName(), "", ".|.|.")
				local show_id = -1
				if show_ids:isEmpty() then
					show_id = player:getCards("he"):first():getEffectiveId()
				else
					show_id = show_ids:first()
				end
				local show = sgs.Sanguosha:getCard(show_id)
				local reason = sgs.CardMoveReason(0x17, ask_who:objectName())
				room:obtainCard(ask_who, show, reason, false)
			end
			if choice == "neifanRemove" then
				player:removeGeneral(false)
				ask_who:removeGeneral(ask_who:inHeadSkills(self))
			end
		end
	end ,
}

wangzu = sgs.CreateTriggerSkill{
	name = "wangzu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},	
	on_record = function(self, event, room, player, data)  
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Discard and player:getMark("wangzuCount") > 0 then
			room:setPlayerMark(player, "wangzuCount", 0)
			room:removePlayerCardLimitation(player, "discard", ".|diamond|.|.")
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Discard then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,Dia in sgs.qlist(players) do
				if Dia:objectName() == player:objectName() or (Dia:hasShownOneGeneral() and player:isFriendWith(Dia)) then
					return self:objectName(), Dia
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local who = sgs.QVariant()
		who:setValue(player)
		if ask_who:hasShownSkill(self) or ask_who:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
		if not player:isKongcheng() then
			local d = 0
			for _,k in sgs.qlist(player:getHandcards()) do
				if k:getSuit() == sgs.Card_Diamond and not (k:isKindOf("EquipCard") and player:hasShownSkill("wuzhuang")) then
					d = d+1
				end
			end
			if d > 0 then
				room:setPlayerCardLimitation(player, "discard", ".|diamond|.|.", false)
				room:setPlayerMark(player, "wangzuCount", d)
			end
		end
	end ,
}

wangzuMaxCards = sgs.CreateMaxCardsSkill{
	name = "wangzuMaxCards",
	global = true,
	extra_func = function(self, player)
		return player:getMark("wangzuCount")
	end
}

yayi = sgs.CreateZeroCardViewAsSkill{
	name = "yayi",
	view_as = function(self)
		local vs = yayiCard:clone() 
		vs:setShowSkill(self:objectName())
		return vs
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_yayiCard")
	end,
}

yayiCard = sgs.CreateSkillCard{
	name = "yayiCard",
	filter = function(self, targets, to_select, Self)
		if #targets ~= 0 then return false end
		return to_select:objectName() ~= Self:objectName()
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]
		local index = player:startCommand(self:objectName())
		local dest
		if index == 0 then
			dest = room:askForPlayerChosen(player, room:getAlivePlayers(), "command_yayi", "@command-damage")
			room:doAnimate(1, player:objectName(), dest:objectName())
		end
		local desuwa = target:doCommand(self:objectName(), index, player, dest)
		if desuwa then
			if target:isAlive() then
				local A = room:askForPlayerChosen(target, room:getOtherPlayers(target), self:objectName(), "&yayi_slash")
            	local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
		    	local use = sgs.CardUseStruct()
		    	use.from = target
				use.to:append(A)
		    	use.card = c
		    	room:useCard(use, false)
			end
		else
			if not target:isNude() then
				local id = room:askForCardChosen(player, target, "he", self:objectName())
				room:obtainCard(player, id, false)
			end
		end
	end ,
}

aoji = sgs.CreateTriggerSkill{
	name = "aoji",
	events = {sgs.Damage, sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if damage.from and damage.to then
			if damage.from:objectName() == damage.to:objectName() or damage.from:isKongcheng() or damage.to:isKongcheng() then return "" end
			local to
			if player:objectName() == damage.from:objectName() then
				to = damage.to
			end
			if player:objectName() == damage.to:objectName() then
				to = damage.from
			end
			if player and player:isAlive() and player:hasSkill(self:objectName()) and not room:getCurrent():hasFlag("aojiUsed") and to and to:isAlive() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local damage = data:toDamage()
		local who = sgs.QVariant()
		local to
		if player:objectName() == damage.from:objectName() then
			to = damage.to
		end
		if player:objectName() == damage.to:objectName() then
			to = damage.from
		end
		who:setValue(to)
		if player:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:getCurrent():setFlags("aojiUsed")
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()	
		local to
		if player:objectName() == damage.from:objectName() then
			to = damage.to
		end
		if player:objectName() == damage.to:objectName() then
			to = damage.from
		end
		if not (player:isKongcheng() or to:isKongcheng()) then				
			local pd = player:pindianSelect(to, self:objectName())
			local success = player:pindian(pd)
			if success then
				local list = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() ~= player:objectName() and p:objectName() ~= to:objectName() then
						list:append(p)
					end
				end
				local choice
				if list:length() == 0 then
					choice = "aojiLoseHp"
				else
					choice = room:askForChoice(player, self:objectName(), "aojiLoseHp+aojiPD", data)
				end
				if choice == "aojiLoseHp" then
					room:loseHp(to)
				else
					local target = room:askForPlayerChosen(player, list, self:objectName(), "&aoji3:" .. to:objectName())
					target:drawCards(1, self:objectName())
					to:drawCards(1, self:objectName())
					if not (target:isKongcheng() or to:isKongcheng()) then
						local pdX = target:pindianSelect(to, self:objectName())
						local successX = target:pindian(pdX)
						if pdX.from_number ~= pdX.to_number then
							if successX then
								local damageX = sgs.DamageStruct()
								damageX.from = target
								damageX.to = to
								room:damage(damageX)
							else
								local damageY = sgs.DamageStruct()
								damageY.from = to
								damageY.to = target
								room:damage(damageY)
							end
						end
					end
				end
			end
		end
	end ,
}

tuyou = sgs.CreateTriggerSkill{
	name = "tuyou",
	events = {sgs.PindianVerifying},
	can_trigger = function(self, event, room, player, data)
		local pd = data:toPindian()
		local players = room:findPlayersBySkillName(self:objectName())
		for _,p in sgs.qlist(players) do
			if (p:isFriendWith(pd.from) and pd.from_card:isRed()) or (p:isFriendWith(pd.to) and pd.to_card:isRed()) then
				return self:objectName(), p
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local pd = data:toPindian()	
		local targets = sgs.SPlayerList()
		if ask_who:isFriendWith(pd.from) then
			targets:append(pd.from)
		end
		if ask_who:isFriendWith(pd.to) then
			targets:append(pd.to)
		end
		local to = room:askForPlayerChosen(ask_who, targets, self:objectName(), "&tuyou", true, true)
		if to then
			local _to = sgs.QVariant()
			_to:setValue(to)
			ask_who:setTag("tuyouTarget", _to)
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local pd = data:toPindian()
		local to = ask_who:getTag("tuyouTarget"):toPlayer()
		if room:getDrawPile():isEmpty() and not room:getDiscardPile():isEmpty() then
            room:swapPile()
		end
		local X = room:getDrawPile():at(0) --来自间宫明里
		local d = sgs.Sanguosha:getCard(X):getNumber()
		room:setPlayerMark(ask_who, "tuyouCount", d) --给人机用来判断的标记
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, sgs.CardMoveReason(0x18, player:objectName(), self:objectName(), ""))
		room:moveCardsAtomic(move, true)
		room:getThread():delay()
		local choice
		if sgs.Sanguosha:getCard(X):isRed() then
			choice = room:askForChoice(ask_who, self:objectName(), "tuyouObtain+tuyouAddNum+sc_drboth", data) --闪耀演唱立大功（确信）
		else
			choice = room:askForChoice(ask_who, self:objectName(), "tuyouObtain+tuyouAddNum", data)
		end
		if choice == "tuyouObtain" or choice == "sc_drboth" then
			room:obtainCard(room:askForPlayerChosen(ask_who, room:getAlivePlayers(), self:objectName(), "&tuyou_obtain:" .. tostring(sgs.Sanguosha:getCard(X):getName())), X)
		end
		if choice == "tuyouAddNum" or choice == "sc_drboth" then
			local a
			local log = sgs.LogMessage()
			log.type = "$tuyouEffect"
			log.from = to
			if pd.from:objectName() == to:objectName() then
				a = d + pd.from_number
				pd.from_number = math.min(13, a)
				log.arg = pd.from_number
			end
			if pd.to:objectName() == to:objectName() then
				a = d + pd.to_number
				pd.to_number = math.min(13, a)
				log.arg = pd.to_number
			end
			room:sendLog(log)
		end
		room:setPlayerMark(ask_who, "tuyouCount", 0)
	end
}

yinfa = sgs.CreateTriggerSkill{
	name = "yinfa",
	events = {sgs.CardFinished},
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.CardFinished then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if use.card:isKindOf("TrickCard") then
					if sp:getMark("@jijian") > 0 and use.to:contains(sp) and not room:getCurrent():hasFlag("yinfa_used") then
						return self:objectName(), sp
					elseif sp:getMark("@jijian") == 0 and player:objectName() == sp:objectName() then
					    return self:objectName(), sp
					end	
				end
			end
        end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
	    local use = data:toCardUse()
		local dat = sgs.QVariant()
		dat:setValue(use.from)
		if sp:isAlive() then
		   targets = room:askForPlayerChosen(sp, room:getAlivePlayers(), self:objectName(), "&yinfa", true, true)
		end
		if targets then
			targets:setFlags("yinfa_use")
			sp:setProperty("yinfa_target", sgs.QVariant(targets:objectName()))
			return true
	   end
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.CardFinished then
		    local use = data:toCardUse()
			local targets = findPlayerByObjectName(sp:property("yinfa_target"):toString())
		    if not targets then return false end
			local probabilityB = math.random(1,4)
			if probabilityB == 1 then
			   room:doLightbox("yinfa1$", 800)
			elseif probabilityB == 2 then
			   room:doLightbox("yinfa2$", 800)
			elseif probabilityB == 3 then
			   room:doLightbox("yinfa3$", 800) 
			elseif probabilityB == 4 then
			   room:doLightbox("yinfa4$", 800)   
			end   	 
			if targets:hasFlag("yinfa_use") then
			    room:getCurrent():setFlags("yinfa_used")
			    targets:setFlags("-yinfa_use")
				if not room:askForUseCard(targets, "BasicCard+^Jink,EquipCard|"..use.card:getSuitString().."|.|hand", "@yinfa_use", -1, sgs.Card_MethodUse, false) then 
					local x = sp:getMaxHp()-1
					if x - targets:getHandcardNum() > 0 then
						targets:drawCards(x - targets:getHandcardNum(), self:objectName())
					elseif x - targets:getHandcardNum() < 0 then
						room:askForDiscard(targets, self:objectName(), targets:getHandcardNum() - x, targets:getHandcardNum() - x, false, false)
					end
				end
			end	
		end   
		
	end
}	

jijianglobal = sgs.CreateTriggerSkill{
	name = "jijianglobal",
    events = {sgs.EventPhaseStart},
	global = true,
	priority = 2,
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill("jijian") and player:getPhase() == sgs.Player_Start and player:getMark("jijianTurn") < 4  then
            room:setPlayerMark(player, "jijianTurn", player:getMark("jijianTurn")+1)
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false
	end,
}

jijian = sgs.CreateTriggerSkill{
	name = "jijian",
	limit_mark = "@jijian",
	frequency = sgs.Skill_Limited,
    events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and player:getMark("jijianTurn") > 2 and player:getMark("@jijian") > 0 then
            return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self, data) then
		   player:loseMark("@jijian")
           room:broadcastSkillInvoke(self:objectName(), player)
		   room:doLightbox("jijian$", 2000)
		   return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
        room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp()+1))
	end	
}

jijianMark = sgs.CreateTriggerSkill{
	name = "#jijianMark",
	limit_mark = "@jijian",
	events = {sgs.GameStart},
	can_trigger = function()
	end,
	on_cost = function()
	end,
	on_effect = function()
	end
}

xinxing = sgs.CreateTriggerSkill{
	name = "xinxing",
	events = {sgs.EventPhaseStart, sgs.Damaged, sgs.HpLost},
	on_record = function(self, event, room, player, data)
		if (event == sgs.Damaged or event == sgs.HpLost) and player and player:isAlive() and not room:getCurrent():hasFlag(player:objectName().."xinxing") then
			room:setPlayerFlag(room:getCurrent(), player:objectName().."xinxing")
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(players) do
				if p:isWounded() and room:getCurrent():hasFlag(p:objectName().."xinxing") then
					return self:objectName(), p
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local a = ask_who:getLostHp()
		if a <= 0 then return end
		local list = sgs.SPlayerList()
		for _,C in sgs.qlist(room:getAlivePlayers()) do
			if C:isFriendWith(ask_who) then
				list:append(C)
			end
		end
		room:setPlayerMark(ask_who, "xinxingCount", a) --给人机用来判断的标记
		local targets = room:askForPlayersChosen(ask_who, list, self:objectName(), 1, a, "&xinxing:" .. tostring(a), true)
		room:sortByActionOrder(targets)
		for _,A in sgs.qlist(targets) do
			local choice
			if A:getJudgingArea():length() <= 0 then
				choice = "draw"
			else
				local who = sgs.QVariant()
				who:setValue(A)
				choice = room:askForChoice(ask_who, self:objectName(), "draw+xinxingThrow", who)
			end
			if choice == "draw" then
				A:drawCards(1, self:objectName())
			else
				local id = -1
				id = room:askForCardChosen(ask_who, A, "j", self:objectName())
				if id ~= -1 then
					room:throwCard(id, A, ask_who, self:objectName())
				end				
			end
		end
		room:setPlayerMark(ask_who, "xinxingCount", 0) --给人机用来判断的标记
	end ,
}

yanlvCard = sgs.CreateSkillCard{
	name = "yanlvCard",
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if to_select:getLostHp() ~= self:getSubcards():length() or not sgs.Self:inMyAttackRange(to_select) then return false end
		return #targets == 0
	end,
	feasible = function(self, targets, Self)
		return #targets == 1 and sgs.Self:inMyAttackRange(targets[1])
	end ,
	on_use = function(self, room, player, targets)
		local target = targets[1]		
		local damage = sgs.DamageStruct()
		damage.from = player
		damage.to = target
		room:damage(damage)
		if player:isAlive() then
			local choice 
			if self:getSubcards():length() > 0 then
				choice = room:askForChoice(player, "yanlv", "yanlvA+yanlvB+yanlvC")
			else
				choice = room:askForChoice(player, "yanlv", "yanlvB+yanlvC")
			end
			if choice == "yanlvA" then
				local card = sgs.Sanguosha:cloneCard("god_salvation")
				card:setSkillName("yanlv")
				for _,i in sgs.qlist(self:getSubcards()) do
					card:addSubcard(i)
				end
				local use = sgs.CardUseStruct()
				use.card = card
				use.from = player
				room:useCard(use, false)
			end
			if choice == "yanlvB" then
				if player:isAlive() and player:isWounded() then
					player:drawCards(player:getLostHp(), "yanlv")
				end
				if target:isAlive() and target:isWounded() then
					target:drawCards(target:getLostHp(), "yanlv")
				end				
			end
			if choice == "yanlvC" then
				room:loseHp(player)				
			end
		end
	end,
}

yanlv = sgs.CreateViewAsSkill{
	name = "yanlv",
	n = 999,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		local vs = yanlvCard:clone()
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		if #cards > 0 then		
			for i = 1, #cards, 1 do
				vs:addSubcard(cards[i])
			end
		end
		return vs	
	end,	
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_yanlvCard")
	end,
}

jiaoxin = sgs.CreateTriggerSkill{
	name = "jiaoxin",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local damage = data:toDamage()
		local who = sgs.QVariant()
		who:setValue(damage.from)
		if player:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local choice = room:askForChoice(damage.from, self:objectName(), "jiaoxinDiscard+jiaoxinExchange", data)
		if choice == "jiaoxinDiscard" then
			if not damage.from:isKongcheng() then
				local list = sgs.IntList()
				for _,c in sgs.qlist(damage.from:getHandcards()) do
					if c:isBlack() and not c:isKindOf("EquipCard") then
						list:append(c:getId())
					end
				end
				if list:length() > 0 then
					local move = sgs.CardsMoveStruct()
					move.card_ids = list
					move.to_place = sgs.Player_DiscardPile
					move.reason.m_reason = 0x33
					move.reason.m_playerId = player:objectName()
					move.reason.m_skillName = self:objectName()
					room:moveCardsAtomic(move, true)
				end
			end
		else
			local exchangeMove = sgs.CardsMoveList()
			local move1 = sgs.CardsMoveStruct(player:handCards(), damage.from, sgs.Player_PlaceHand, sgs.CardMoveReason(0x19, player:objectName(), damage.from:objectName(), self:objectName(), ""))
			local move2 = sgs.CardsMoveStruct(damage.from:handCards(), player, sgs.Player_PlaceHand, sgs.CardMoveReason(0x19, damage.from:objectName(), player:objectName(), self:objectName(), ""))
			exchangeMove:append(move1)
			exchangeMove:append(move2)
        	room:moveCardsAtomic(exchangeMove, false)
			local a, b = player:getHandcardNum(), damage.from:getHandcardNum()
			if a < b then
				player:drawCards(2, self:objectName())
			end
			if a > b then
				damage.from:drawCards(2, self:objectName())
			end
		end
	end ,
}

xiuxing = sgs.CreateZeroCardViewAsSkill{
	name = "xiuxing",
	view_as = function(self)
		local new_card = xiuxingCard:clone()   
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play = function(self, player)
		return not player:hasUsed("ViewAsSkill_xiuxingCard")
	end,
}

xiuxingCard = sgs.CreateSkillCard{
	name = "xiuxingCard",
	filter = function(self, targets, to_select)
		return #targets == 0
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
		if target then
           if target:isKongcheng() then
				room:setPlayerMark(target, "##xiuxingZero", 1)
			else
				room:setPlayerMark(target, "#xiuxing", target:getHandcardNum())
			end
		end
	end,
}

xiuxingglobal = sgs.CreateTriggerSkill{
	name = "xiuxingglobal",
	events = {sgs.EventPhaseEnd},
	global = true,
	priority = 2,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:getMark("##xiuxingZero") + p:getMark("#xiuxing") > 0 then
						local x = p:getMark("#xiuxing")
						room:setPlayerMark(p, "##xiuxingZero", 0)
						room:setPlayerMark(p, "#xiuxing", 0)
						local y = p:getHandcardNum()
						if x > y and y < 5 then
							local a = math.min(x, 5)
							p:drawCards(a-y, self:objectName())
						end
						if x < y then
							local b = math.min(y-x, 5)
							room:askForDiscard(p, self:objectName(), b, b)
						end
					end
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		return false
	end,
}

shangyuan = sgs.CreateTriggerSkill{
	name = "shangyuan",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
		if player:getPhase() == sgs.Player_Play then
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if sp:inMyAttackRange(player) and player:objectName() ~= sp:objectName() then
					return self:objectName(), sp
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		local who = sgs.QVariant()
		who:setValue(player)
		if sp:askForSkillInvoke(self, who) and room:askForUseSlashTo(sp, player, "@shangyuan-slash", false) then
			room:broadcastSkillInvoke(self:objectName(), sp)
			local probabilityS = math.random(1,2)
			if probabilityS == 1 then
			   room:doLightbox("shangyuan1$", 800)
			elseif probabilityS == 2 then
			   room:doLightbox("shangyuan2$", 800)
			end
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)
		if player:isAlive() then
			player:drawCards(1, self:objectName())
			room:setPlayerFlag(player, "shangyuan_extra")
		end
	end,
}

shangyuantr = sgs.CreateTargetModSkill{
	name = "#shangyuantr",
	residue_func = function(self, player, card)
		if player:hasFlag("shangyuan_extra") then
			return 1
		end
		return 0
	end,
}

shangyuants = sgs.CreateAttackRangeSkill{
	name = "#shangyuants" ,
	extra_func = function(self, player, include_weapon)
		if player:hasFlag("shangyuan_extra") then
			return 1
		end
		return 0
	end,
}

chaoshi = sgs.CreateTriggerSkill{
	name = "chaoshi",	
	events = {sgs.EventPhaseEnd, sgs.CardFinished},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(p, "&chaoshi_js", 0)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished then
		   local use = data:toCardUse()
		   if player and player:isAlive() and player:hasSkill(self:objectName()) and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) and player:getMark("&chaoshi_js") < 2 then
				for _,c in sgs.qlist(player:getCards("h")) do
					if c:getSuit() == use.card:getSuit() then
						return self:objectName()     
					end
				end       
			end
		end   
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		player:drawCards(1, self:objectName())
		room:setPlayerMark(player, "&chaoshi_js", player:getMark("&chaoshi_js")+1)
	end,
}

chaoshist = sgs.CreateTriggerSkill{
	name = "#chaoshist",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,p in sgs.qlist(players) do
				if (move.to and move.to:objectName() == player:objectName() and player:objectName() == p:objectName() and (move.to_place == sgs.Player_PlaceHand)) and room:getCurrent():objectName() ~= p:objectName() and not room:getCurrent():hasFlag("chaoshist_used") then
					local handcard_has_spade = false  local handcard_has_club = false  local handcard_has_heart = false	local handcard_has_diamond = false
					for _, c in sgs.qlist(p:getCards("hej")) do
						if c:getSuit() == sgs.Card_Spade then
							handcard_has_spade = true
						end
						if c:getSuit() == sgs.Card_Club then
							handcard_has_club = true
						end
						if c:getSuit() == sgs.Card_Heart then
							handcard_has_heart = true
						end
						if c:getSuit() == sgs.Card_Diamond then
							handcard_has_diamond = true
						end
					end
					local Tchaoshi_result = 0
					if handcard_has_spade then
						Tchaoshi_result = Tchaoshi_result + 1
					end
					if handcard_has_club then
						Tchaoshi_result = Tchaoshi_result + 1
					end
					if handcard_has_heart then
						Tchaoshi_result = Tchaoshi_result + 1
					end
					if handcard_has_diamond then
						Tchaoshi_result = Tchaoshi_result + 1
					end
					if p:getHandcardNum() > Tchaoshi_result then
						return self:objectName(), p 
					end  
				end
			end
	    end
		return ""
	end,
	on_cost = function(self, event, room, player, data, p)
		---if  p:getMark("#chaoshist_an") == 0 then
		if p:hasShownSkill("chaoshi") or p:askForSkillInvoke(self, data) then
			if not p:hasShownSkill("chaoshi") then
			   p:showGeneral(p:inHeadSkills("chaoshi"))
			end
			getCurrent():setFlags("chaoshist_used")
			room:broadcastSkillInvoke("chaoshi")
			return true	
		---else	
			---room:setPlayerMark(p, "#chaoshist_an", 1)
		end
		---end	
		return false
	end ,
	on_effect = function(self, event, room, player, data, p)
		if not p:isRemoved() then			
			room:sendCompulsoryTriggerLog(p, self:objectName(), true)
		    if not room:askForDiscard(p, self:objectName(), 1, 1, true, true, "@chaoshi") then
			  room:setPlayerCardLimitation(p, "use", ".", false)
			  room:setPlayerProperty(p, "removed", sgs.QVariant(true))
			end  
		end
	end,
}

moliang = sgs.CreateTriggerSkill{
	name = "moliang",
	events = {sgs.CardFinished, sgs.Damaged},
	on_record = function(self, event, room, player, data)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.damage and damage.card and (damage.card:isKindOf("BasicCard") or damage.card:isKindOf("TrickCard") or damage.card:isKindOf("EquipCard")) then
				room:setPlayerFlag(damage.to, "moliangA"..damage.card:toString()) --直接记录之
			end
		end
	end ,	
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				for _,p in sgs.qlist(room:getAlivePlayers()) do --直接在所有玩家中判断
					if p:hasFlag("moliangA"..use.card:toString()) and sp:isFriendWith(p) and p:getMark("@halfmaxhp") <= 0 then
						return self:objectName(), sp
					end
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
		local use = data:toCardUse()
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:hasFlag("moliangA"..use.card:toString()) and sp:isFriendWith(p) and p:getMark("@halfmaxhp") <= 0 then
				targets:append(p)
				if p ~= sp then
					room:setPlayerFlag(p, "-moliangA"..use.card:toString()) --在这里清除其他角色flag
				end
			end
		end		
		if sp:askForSkillInvoke(self, data)  then
			local target = room:askForPlayerChosen(sp, targets, self:objectName(), "&moliangFish", true)
			if target then
				sp:setProperty("moliang_target", sgs.QVariant(target:objectName())) --记录目标
				room:broadcastSkillInvoke(self:objectName(), sp)
				room:doLightbox("FuukaMoliang$", 999)
				return true
			end
		end
		if sp:hasFlag("moliangA"..use.card:toString()) then
            room:setPlayerFlag(sp, "-moliangA"..use.card:toString()) --在这里清除自己的flag
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)
		local use = data:toCardUse()
		local target = findPlayerByObjectName(sp:property("moliang_target"):toString()) --获取目标
		if not target then return false end
		target:gainMark("@halfmaxhp", 1)
		if sp:hasFlag("moliangA"..use.card:toString()) then
			room:setPlayerFlag(sp, "-moliangA"..use.card:toString()) --在这里清除自己的flag
			if not sp:isKongcheng() then
				local show_ids = room:askForExchange(sp, self:objectName(), 1, 0, "&moliang", "", ".|.|.|hand")
				if not show_ids:isEmpty() then
					local card = sgs.Sanguosha:getCard(show_ids:first())
					room:moveCardTo(card, sp, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, sp:objectName(), self:objectName(), ""))
					room:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = sp
					log.card_str = tostring(card)
					room:sendLog(log)
					sp:drawCards(1, "recast")
				end
			end
		end
	end,
}

yuanshu = sgs.CreateTriggerSkill{
	name = "yuanshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged, sgs.DamageInflicted},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		----if damage.damage > 0 then
		if event == sgs.Damaged then
			if player and player:isAlive() and player:hasSkill(self:objectName()) then
			   return self:objectName()
				--[[local trigger_list = {}
				for i = 1, damage.damage, 1 do
					table.insert(trigger_list, self:objectName())
				end
				return table.concat(trigger_list, ",")]]
			end
		else
			local players = room:findPlayersBySkillName(self:objectName())
			for _,Fuuka in sgs.qlist(players) do
				if damage.damage > 1 and room:getCurrent():hasFlag("yuanshu"..player:objectName()) then
					return self:objectName(), Fuuka
				end
			end
		end
		--end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		if ask_who:hasShownSkill(self:objectName()) or ask_who:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local damage = data:toDamage()	
		room:sendCompulsoryTriggerLog(ask_who, self:objectName(), true)
		room:doLightbox("FuukaYuanshu$", 999)
		if event == sgs.Damaged then
			local p1 = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName(), "&yuanshu")
			ask_who:drawCards(1, self:objectName())
			p1:drawCards(1, self:objectName())
			room:setPlayerFlag(room:getCurrent(), "yuanshu"..ask_who:objectName())
			room:setPlayerFlag(room:getCurrent(), "yuanshu"..p1:objectName())
		else
			local log = sgs.LogMessage()
			log.type = "#yuanshu"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = tostring(damage.damage)
			room:sendLog(log)
			return true
		end
	end,
}

lvge = sgs.CreateViewAsSkill{
	name = "lvge",
	n = 999,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards) 
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@lvge" then
			if #cards > 0 then
			local zhiheng = lvgeZhihengCard:clone()
			for _,card in pairs(cards) do
				zhiheng:addSubcard(card)
			end
			zhiheng:setSkillName("lvge")
			return zhiheng
		end
		else
			local lvge = lvgeCard:clone() 
			lvge:setShowSkill(self:objectName())
			return lvge
		end
	end,
	enabled_at_play = function(self, player)
		return player:getGeneral2() and not string.find(player:getActualGeneral2Name(),"sujiang") and not player:hasUsed("#lvgeCard")
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@lvge"
	end,
}

lvgeZhihengCard = sgs.CreateSkillCard{
	name = "lvgeZhihengCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:throwCard(self, source)
		if source:isAlive() then
			local count = self:subcardsLength()
			room:drawCards(source, count, "lvge")
		end
	end
}

lvgeCard = sgs.CreateSkillCard{
	name = "lvgeCard",
	target_fixed = true,
	on_use = function(self, room, player, targets)
		if player:isAlive() then
		    room:doLightbox("lvge$", 800)
			local k = math.min(3,player:getHp())
			for x = 1, k, 1 do
				local list = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:hasEquip() or p:getJudgingArea():length() > 0 then
						list:append(p)
					end
				end
				if list:length() == 0 then break end
				local from = room:askForPlayerChosen(player, list, "lvge", "&lvgeA", true)
				if not from then
					break
				else
					local card_id = room:askForCardChosen(player, from, "ej", "lvge")
					local card = sgs.Sanguosha:getCard(card_id)
					local place = room:getCardPlace(card_id)
					local equip_index = -1
					if place == sgs.Player_PlaceEquip then
						local equip = card:getRealCard():toEquipCard()
						equip_index = equip:location()
					end
					local tos = sgs.SPlayerList()
					local list = room:getAlivePlayers()
					for _,p in sgs.qlist(list) do
						if equip_index ~= -1 then
							if not p:getEquip(equip_index) then
								tos:append(p)
							end
						else
							if not player:isProhibited(p, card) and not p:containsTrick(card:objectName()) then
								tos:append(p)
							end
						end
					end
					local tag = sgs.QVariant()
					tag:setValue(from)
					room:setTag("lvgeTarget", tag)
					local to = room:askForPlayerChosen(player, tos, "lvge", "&lvgeB")
					if to then
						local reason = sgs.CardMoveReason(0x09, player:objectName(), "lvge", "")
						room:moveCardTo(card, from, to, place, reason)
					end
					room:removeTag("lvgeTarget")
				end
			end
			player:removeGeneral(false)
			local most = true
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if p:getHandcardNum() > player:getHandcardNum() then
					most = false
				end
			end
			if not player:isNude() and room:askForUseCard(player, "@@lvge", "@lvge") then
				local mostNow = true
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:getHandcardNum() > player:getHandcardNum() then
						mostNow = false
					end
				end
				if not most and mostNow then
					room:loseHp(player)
				end
			end
		end
	end ,
}

quming = sgs.CreateTriggerSkill{
	name = "quming",
	relate_to_place = "head",
	events = {sgs.Dying},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getGeneral2() and string.find(player:getActualGeneral2Name(), "sujiang") then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local dying = data:toDying()
		local who = sgs.QVariant()
		who:setValue(dying.who)
		if dying.who:getMark("qumingUsed") <= 0 and player:askForSkillInvoke(self, who) then
			room:setPlayerMark(dying.who, "qumingUsed", 1)
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		room:transformDeputyGeneral(player)
		local dying = data:toDying()
		local recover = sgs.RecoverStruct()
		recover.who = dying.who
		recover.recover = 1-dying.who:getHp()
		room:recover(dying.who, recover, true)
	end ,
}

yangming = sgs.CreateTriggerSkill{
	name = "yangming",
	relate_to_place = "deputy",
	events = {sgs.GeneralRemoved},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and data:toString() == "Arisa" and player:hasEquip() then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local a = player:getEquips():length()
		local targets = room:askForPlayersChosen(player, room:getAlivePlayers(), self:objectName(), 1, a, "&yangming:" .. tostring(a), true)
		room:sortByActionOrder(targets)
		for _,A in sgs.qlist(targets) do
			A:drawCards(1, self:objectName())
		end
		for _,B in sgs.qlist(targets) do
			if player:objectName() ~= B:objectName() and not B:isNude() then
				local show_ids = room:askForExchange(B, self:objectName(), 1, 1, "&yangming_give:" .. player:objectName(), "", ".|.|.")
				local show_id = -1
				if show_ids:isEmpty() then
					show_id = B:getCards("he"):first():getEffectiveId()
				else
					show_id = show_ids:first()
				end
				local show = sgs.Sanguosha:getCard(show_id)
				local reason = sgs.CardMoveReason(0x17, player:objectName())
				room:obtainCard(player, show, reason, false)
			end
		end
	end ,
}

yueyincard = sgs.CreateSkillCard{
	name = "yueyincard",
	target_fixed = true,
	will_throw = false,
	filter = function(self, targets, to_select)
		return not sgs.Self:isProhibited(to_select, sgs.Sanguosha:cloneCard("music")) and sgs.Self:objectName() == to_select:objectName()
	end ,
	on_use = function(self, room, player, targets)
		local card = sgs.Sanguosha:cloneCard("music")
		card:setSkillName("yueyin")
		for _,i in sgs.qlist(self:getSubcards()) do
			card:addSubcard(i)
		end
		local use = sgs.CardUseStruct()
		use.card = card
		use.from = player
		use.to:append(player)
		room:useCard(use, false)
	end ,
}

yueyinVS = sgs.CreateViewAsSkill{
	name = "yueyin",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and not to_select:isKindOf("BasicCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local vs = yueyincard:clone()
			vs:setShowSkill(self:objectName())
			vs:setSkillName(self:objectName())
			vs:addSubcard(cards[1])
			return vs
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@yueyin"
	end,
}

yueyin = sgs.CreateTriggerSkill{
	name = "yueyin",
	can_preshow = true,
	view_as_skill = yueyinVS,	
	events = {sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()		
		local players = room:findPlayersBySkillName(self:objectName())
		for _,p in sgs.qlist(players) do
			if p:getPhase() == sgs.Player_NotActive and use.from and use.from:objectName() ~= p:objectName() and use.card:isKindOf("Slash") and not room:getCurrent():hasFlag("yueyinUsed"..p:objectName()) then
				return self:objectName(), p
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, ask_who)
		local use = data:toCardUse()
		local who = sgs.QVariant()
		who:setValue(player)
		if ask_who:askForSkillInvoke(self, who) then
			room:getCurrent():setFlags("yueyinUsed"..ask_who:objectName())
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, ask_who)
		local use = data:toCardUse()
		local card = room:askForUseCard(ask_who, "@@yueyin", "@yueyin")
		if card then
			if sgs.Sanguosha:getCard(card:getSubcards():at(0)):isKindOf("EquipCard") then
				if not use.to:contains(ask_who) then				
                    use.to:append(ask_who)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                    room:getThread():trigger(sgs.TargetConfirming, room, ask_who, data)
				end
				for _,p in sgs.qlist(use.to) do
					if p:objectName() ~= ask_who:objectName() then					
						use.to:removeOne(p)
						p:slashSettlementFinished(use.card)
						data:setValue(use)
					end
				end
			end
		else
			local a, b = ask_who:getHandcardNum(), ask_who:getHp()
			if a < b then
				ask_who:drawCards(b-a, self:objectName())
			end
			if player:objectName() ~= ask_who:objectName() then
				local show_ids = room:askForExchange(ask_who, self:objectName(), 1, 1, "@yueyin_give:" .. player:objectName(), "", ".|.|.|hand")
				local show_id = -1
				if show_ids:isEmpty() then
					show_id = ask_who:getCards("h"):first():getEffectiveId()
				else
					show_id = show_ids:first()
				end
				local show = sgs.Sanguosha:getCard(show_id)
				local reason = sgs.CardMoveReason(0x17, player:objectName())
				room:obtainCard(player, show, reason, false)
			end
		end
	end ,
}

juexiang = sgs.CreateTriggerSkill{
	name = "juexiang",
	events = {sgs.EventPhaseEnd},
    can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
		   return self:objectName()
        end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
        if player:askForSkillInvoke(self:objectName()) then
            room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data)
		local ids = room:getNCards(player:getLostHp()+1, false)
		local move = sgs.CardsMoveStruct(ids, player, sgs.Player_PlaceTable, sgs.CardMoveReason(0x18, player:objectName(), self:objectName(), ""))
		room:moveCardsAtomic(move, true)
		room:getThread():delay()
		local card_to_throw = sgs.IntList()
		local card_to_gotback = sgs.IntList()
		if player:isAlive() then
			local choice = room:askForChoice(player, self:objectName(), "@juexiang1+cancel", data)
			if choice == "@juexiang1" then
				for _, id in sgs.qlist(ids) do
					local card = sgs.Sanguosha:getCard(id)
					if card:getTypeId() == sgs.Card_TypeBasic then
						card_to_gotback:append(id)
					else
						card_to_throw:append(id)
					end			
				end
				if not card_to_gotback:isEmpty() then
					local dummy = sgs.DummyCard(card_to_gotback)
					room:obtainCard(player, dummy)
					dummy:deleteLater()
				end
				if not card_to_throw:isEmpty() then
					local dummyX = sgs.DummyCard(card_to_throw)
					room:throwCard(dummyX, sgs.CardMoveReason(0x1A, player:objectName(), self:objectName(), ""), nil)
					dummyX:deleteLater()
		        end
				room:loseHp(player)
				if player:isAlive() then
					local msg = sgs.LogMessage()
					msg.type = "#newphase"
					msg.from = player
					room:sendLog(msg)
					player:setPhase(sgs.Player_Play)
					room:broadcastProperty(player, "phase")
					local thread = room:getThread()
					if not thread:trigger(sgs.EventPhaseStart, room, player) then
						thread:trigger(sgs.EventPhaseProceeding, room, player)
					end
					thread:trigger(sgs.EventPhaseEnd, room, player)
					player:setPhase(sgs.Player_RoundStart)
					room:broadcastProperty(player, "phase")
				end
			end
		end
    end,
}

huyi = sgs.CreateTargetModSkill{
	name = "huyi",
	residue_func = function(self, player, card)
		if player:hasShownSkill("huyi") and player:getLostHp() > 0 then
			return 1
		end
		return 0
	end,
}

huyis = sgs.CreateDistanceSkill{
	name = "#huyis",
	correct_func = function(self, from, to)
		if from:hasShownSkill("huyi") then
			return -from:getLostHp()
		end
		return 0
	end,
}

lixunCard = sgs.CreateSkillCard{
	name = "lixunCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select)
	    if to_select:isRemoved() then return false end
	    return #targets < (sgs.Self:getEquips():length() + sgs.Self:getJudgingArea():length()) and sgs.Self:inMyAttackRange(to_select) and sgs.Self:objectName() ~= to_select:objectName()
	end,
	feasible = function(self, targets, to_select)
		return #targets > 0
	end,
	on_use = function(self, room, player, targets)
		local card = sgs.Sanguosha:cloneCard("ice_slash")
		card:setSkillName("lixun")
		local id = room:askForCardChosen(player, player, "ej", "lixun")
		card:addSubcard(id)
		local use = sgs.CardUseStruct()
		use.card = card
		use.from = player
		for _,p in ipairs(targets) do
			use.to:append(p)
		end
		room:useCard(use, false)
		player:drawCards(1, self:objectName())
		if player:getMark("#lixun_weapon") < 4 then
		   room:setPlayerMark(player, "#lixun_weapon", player:getMark("#lixun_weapon")+1)
		end 
	end
}

lixunvs = sgs.CreateZeroCardViewAsSkill{
	name = "lixun",
	view_as = function(self, cards)
			local new_card = lixunCard:clone()
			new_card:setSkillName("lixun")
			return new_card	
	end,	
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@lixun"
	end,
}

lixun = sgs.CreateTriggerSkill{
    name = "lixun",
	view_as_skill = lixunvs,
	events = {sgs.EventPhaseStart},
	can_preshow = true,
	can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Start and player:getEquips():length() + player:getJudgingArea():length() > 0 then
		    return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
	    room:askForUseCard(player, "@@lixun", "@lixun")
	end ,
}

lixuntr = sgs.CreateAttackRangeSkill{
	name = "#lixuntr" ,
	extra_func = function(self, player, include_weapon)
		if player:getMark("#lixun_weapon") > 0 then
			return player:getMark("#lixun_weapon")
		end
		return 0
	end ,
}

gongdaoSummonCard = sgs.CreateArraySummonCard{
	name = "gongdao",
	mute = true,
}

gongdaoVS = sgs.CreateArraySummonSkill{
	name = "gongdao",
	array_summon_card = gongdaoSummonCard,
}

gongdao = sgs.CreateTriggerSkill{
	name = "gongdao",
	is_battle_array = true,
	battle_array_type = sgs.Formation,
	view_as_skill = gongdaoVS,
	events = {sgs.GeneralShown, sgs.EventPhaseStart, sgs.EventPhaseChanging},
	can_preshow = false,
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local phase = data:toPhaseChange().to
			if phase == sgs.Player_NotActive and player:getMark("#gongdaoAttackRange") > 0 then
				room:setPlayerMark(player, "#gongdaoAttackRange", 0)
			end
		end
	end,
	can_trigger = function(self,event,room,player,data)
		if event == sgs.GeneralShown then
			if player and player:isAlive() and player:hasShownSkill("gongdao") and data:toBool() == player:inHeadSkills("gongdao") then
                return self:objectName(), player
			end
		elseif event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart then
				local Umi = room:findPlayerBySkillName("gongdao")
				if Umi and Umi:isAlive() and Umi:hasShownSkill("gongdao") and player:inFormationRalation(Umi) then
					return self:objectName(), Umi
				end
			end
		end
	end,
    on_cost = function(self,event,room,player,data,ask_who)
		if ask_who:hasShownSkill("gongdao") then
			room:doBattleArrayAnimate(ask_who)
		    if event == sgs.EventPhaseStart then return true end
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
	    local max = 0
		local players = room:getAlivePlayers()
		local formation = player:getFormation()
		if formation:length()<=1 or players:length()< 4 then return false end
		players:append(player)
		for _,p in sgs.qlist(players) do
            if p:isFriendWith(player) and p:getAttackRange()>max and formation:contains(p) then
				max = p:getAttackRange()
			end
        end
		if max > player:getAttackRange() then
			room:broadcastSkillInvoke(self:objectName(), ask_who)
			room:setPlayerMark(player, "#gongdaoAttackRange", max)
		end
	end ,
}

gongdaotr = sgs.CreateAttackRangeSkill{
	name = "#gongdaotr" ,
	fixed_func = function(self, player, include_weapon)
	    if player:getMark("#gongdaoAttackRange") > 0 then
			return player:getMark("#gongdaoAttackRange")
		end
		return -1
	end ,
}

baoshix = sgs.CreateViewAsSkill{
	name = "baoshix",
	n = 999 ,
	guhuo_type = "b",
    view_filter = function(self, selected, to_select)
	   local n = 1 + sgs.Self:getMark("#baoshix_jishu")
	   if sgs.Self:getMark("baoshix_analeptic_used") > 0 and sgs.Self:getMark("baoshix_peach_used") > 0 and sgs.Self:getMark("baoshix_tacos_used") > 0 and sgs.Self:getMark("baoshix_mapo_tofu_used") > 0then
	   return false end
	   if #selected >= n then return false end
	   if #selected < 1 then return not to_select:isEquipped() end
	   return not to_select:isEquipped()
    end,
    view_as = function(self, cards, room)
	    local n = 1 + sgs.Self:getMark("#baoshix_jishu")
		if #cards < n then return nil end 
		local pattern = sgs.Self:getTag(self:objectName()):toString()
		if sgs.Self:getMark("baoshix_Current") > 0 then
			if #cards ~= n or pattern == "" then return end
			local vs = sgs.Sanguosha:cloneCard(pattern)
			for var = 1, #cards, 1 do
				vs:addSubcard(cards[var])
			end
			vs:setShowSkill(self:objectName())
			vs:setSkillName(self:objectName())
			return vs
		elseif sgs.Self:getMark("baoshix_Current") == 0 and (sgs.Self:getMark("baoshix_peach") > 0 or sgs.Self:getMark("baoshix_analeptic_used")>0) and sgs.Self:getMark("baoshix_peach_used") == 0 then
		    if #cards < n then return nil end
			local card = cards[1]
			local new_card = nil
			new_card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, 0)
			if new_card then
				if #cards == n then
					new_card:setSkillName(self:objectName())
				end
				for _, c in ipairs(cards) do
					new_card:addSubcard(c)
				end
			end
			return new_card
		elseif sgs.Self:getMark("baoshix_Current") == 0 and (sgs.Self:getMark("baoshix_analeptic") > 0 or sgs.Self:getMark("baoshix_peach_used") > 0) and sgs.Self:getMark("baoshix_analeptic_used") == 0 then
            if #cards < n then return nil end
			local card = cards[1]
			local new_card = nil
			new_card = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_SuitToBeDecided, 0)
			if new_card then
				if #cards == n then
					new_card:setSkillName(self:objectName())
				end
				for _, c in ipairs(cards) do
					new_card:addSubcard(c)
				end
			end
			return new_card
        end
    end,
    enabled_at_play = function(self, player)
	    return true
	end,
	enabled_at_response = function(self, player, pattern)
		return (string.find(pattern, "peach") and (not player:hasFlag("Global_PreventPeach"))) or string.find(pattern, "analeptic") or string.find(pattern, "tacos") or string.find(pattern, "mapo_tofu")
	end,
	button_enabled = function(self, name)
	    local n = 1 + sgs.Self:getMark("#baoshix_jishu")
		if n > 0 then
           if name ~= "peach" and name ~= "analeptic" and name ~= "tacos" and name ~= "mapo_tofu" then return false end
           if sgs.Self:getMark("baoshix_"..name.."_used") > 0 then return false end
		end	
		return true
	end ,
}

baoshixglobal = sgs.CreateTriggerSkill{
	name = "baoshixglobal",
	global = true,
	events = {sgs.TurnStart, sgs.EventPhaseChanging, sgs.CardUsed, sgs.Dying, sgs.QuitDying, sgs.Death},
		priority = 2,
	on_record = function(self, event, room, player, data)
		if event == sgs.TurnStart then 
			if not player:hasFlag("Point_ExtraTurn") then
				room:setPlayerMark(player, "baoshix_analeptic_used", 0)
				room:setPlayerMark(player, "baoshix_peach_used", 0)
				room:setPlayerMark(player, "baoshix_tacos_used", 0)
				room:setPlayerMark(player, "baoshix_mapo_tofu_used", 0)	
			end
	    end
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_Play then
		    if player and player:isAlive() and player:hasSkill("baoshix") then
		       room:setPlayerMark(player, "baoshix_Current", 1)			
		    end
		end
		if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_Finish then
            if player and player:isAlive() and player:hasSkill("baoshix") then
		       room:setPlayerMark(player, "baoshix_Current", 0)			
		    end
		end
		if event == sgs.Dying then
		   local dying = data:toDying()
		    if player and player:isAlive() and player:hasSkill("baoshix") and player == dying.who then
		       room:setPlayerMark(player, "baoshix_Current", 0)
			        local choice_list = {}
					if player:getMark("baoshix_analeptic_used")== 0 then table.insert(choice_list, "analeptic_use") end
					if player:getMark("baoshix_peach_used")== 0 then table.insert(choice_list, "peach_use") end
					if #choice_list == 0 then return false end
					local choice = room:askForChoice(player, "baoshix", table.concat(choice_list, "+"), data)
					if choice == "analeptic_use" then
					   room:setPlayerMark(player, "baoshix_analeptic", 1)
					elseif choice == "peach_use" then
					   room:setPlayerMark(player, "baoshix_peach", 1)
					end
			else
               room:setPlayerMark(player, "baoshix_Current", 0) 			
		    end
		end
		if event == sgs.QuitDying or event ==sgs.Death then
			if player and player:isAlive() and player:hasSkill("baoshix") then
		       room:setPlayerMark(player, "baoshix_Current", 1)
			end
		end
		if event == sgs.CardUsed then	
			local use = data:toCardUse()
			if use.card:getSkillName() == "baoshix" then  
				room:setPlayerMark(player, "#baoshix_jishu", player:getMark("#baoshix_jishu")+1)
				room:setPlayerMark(player, "baoshix_used", 1)
				if player:getMark("baoshix_Current") == 0 then
                   room:setPlayerMark(player, "baoshix_analeptic", 0)
			       room:setPlayerMark(player, "baoshix_peach", 0)
				end
			end
		end
	end,	
	can_trigger = function(self, event, room, player, data)
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false 
	end,
}

baoshixst = sgs.CreateTriggerSkill{
	name = "#baoshixst",
	events = {sgs.CardsMoveOneTime, sgs.CardUsed},
	on_record = function(self, event, room, player, data)
		if event == sgs.CardUsed then
		    local use = data:toCardUse()
			if player and player:isAlive() and use.card:getSkillName() == "baoshix" then
			   if use.card:isKindOf("Analeptic") then
			      room:setPlayerMark(player, "baoshix_used", 0)
				  room:setPlayerMark(player, "baoshix_analeptic_used", 1)
			   elseif use.card:isKindOf("Peach") then
			      room:setPlayerMark(player, "baoshix_used", 0)
				  room:setPlayerMark(player, "baoshix_peach_used", 1)
			   elseif use.card:isKindOf("Tacos") then
			      room:setPlayerMark(player, "baoshix_used", 0)
				  room:setPlayerMark(player, "baoshix_tacos_used", 1)
			   elseif use.card:isKindOf("Mapo_tofu") then
			      room:setPlayerMark(player, "baoshix_used", 0)
				  room:setPlayerMark(player, "baoshix_mapo_tofu_used", 1)
			   end
			end
		end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player and player:isAlive() and move.from and move.from:objectName() == player:objectName() and (player:getHandcardNum()+ player:getEquips():length()) == 0 then
				if player:getMark("#baoshix_jishu")> 0 then
				  room:setPlayerMark(player, "#baoshix_jishu", 0)
				end  
			end		  
		end			   

	end,	
	can_trigger = function(self, event, room, player, data)
	end,
	on_cost = function(self, event, room, player, data)
	end,
	on_effect = function(self, event, room, player, data)
	end,
}

changyue = sgs.CreateTriggerSkill{
	name = "changyue",
	events = {sgs.CardFinished},
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		local players = room:findPlayersBySkillName(self:objectName())
		for _,sp in sgs.qlist(players) do
			if use.card:isNDTrick()then
				if player:objectName() ~= sp:objectName() and not room:getCurrent():hasFlag(sp:objectName().."changyue_used") then   
					for _,c in sgs.qlist(sp:getCards("he")) do
						if c:getSuit() == use.card:getSuit() then
							return self:objectName(), sp
						end
					end
				end
			end
		end	
		return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
	    local use = data:toCardUse()
		local who = sgs.QVariant()
		who:setValue(use.from)
		if sp:askForSkillInvoke(self, who) then
			local card = room:askForCard(sp, ".|"..use.card:getSuitString().."|.|.", "@changyue", data, sgs.Card_MethodNone)
			if card then
				room:setPlayerProperty(sp, "changyue_card", sgs.QVariant(card:getEffectiveId()))
				room:getCurrent():setFlags(sp:objectName().."changyue_used")
				room:broadcastSkillInvoke("changyue")
				return true	
			end
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)
		local use = data:toCardUse()
		local id = sp:property("changyue_card"):toInt()
		room:obtainCard(player, id, false)
		if sp:isAlive() then
			room:obtainCard(sp, use.card)
		end 
	end,
}

changyues = sgs.CreateTriggerSkill{
	name = "#changyues",
	events = {sgs.CardFinished}, 
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		if player:isAlive() and player:hasSkill("changyue") and use.card:isNDTrick() and player:objectName() == use.from:objectName() then
			if not room:getCurrent():hasFlag(player:objectName().."changyue_used") then   
				local players = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					for _,c in sgs.qlist(p:getCards("ej")) do
						if c:getSuit() == use.card:getSuit() then
							return self:objectName()
						end
					end  
				end
			end
		end	
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
	    local use = data:toCardUse()
		if player:askForSkillInvoke(self, data) then
		    local use = data:toCardUse()
			local players = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				for _,c in sgs.qlist(p:getCards("ej")) do
					if c:getSuit() == use.card:getSuit() then
						players:append(p)
						break
					end
				end
			end
			if not players:isEmpty() then
				local target = room:askForPlayerChosen(player, players, self:objectName(), "changyue-invoke")
				if target then
					local list = sgs.IntList()
					for _,c in sgs.qlist(target:getCards("ej")) do
						if c:getSuit() == use.card:getSuit() then
							list:append(c:getEffectiveId())
						end
					end
					room:fillAG(list, player)
					local id = room:askForAG(player, list, false, self:objectName())
					room:clearAG(player)
					room:setPlayerProperty(player, "changyue_id", sgs.QVariant(id+1))
					local dat = sgs.QVariant()
					dat:setValue(target)
					room:setPlayerProperty(player, "changyue_target", dat)
					room:getCurrent():setFlags(player:objectName().."changyue_used")
					if not player:hasShownSkill("changyue") then
						player:showGeneral(player:inHeadSkills("changyue"))
					end
			        room:broadcastSkillInvoke("changyue", player)
			        return true	
				end
			end	          
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		local use = data:toCardUse()
		local id = player:property("changyue_id"):toInt()-1
		local target = player:property("changyue_target"):toPlayer()
		room:setPlayerProperty(player, "changyue_id", sgs.QVariant())
		room:setPlayerProperty(player, "changyue_target", sgs.QVariant())
		if id > -1 and target then
			room:obtainCard(player, id, false)
			room:obtainCard(target, use.card)
		end
	end,
}

lieju = sgs.CreateTriggerSkill{
	name = "lieju",
	events = {sgs.TargetConfirmed, sgs.CardFinished},
	on_record = function(self, event, room, player, data)
	   if event == sgs.CardFinished then
			local use=data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if player:objectName() == sp:objectName() and use.card:isKindOf("Slash") then
					for _,p in sgs.qlist(room:getAlivePlayers()) do
						room:setPlayerMark(p, "lieju_target", 0)
					end 
				end
			end	
		end
	end,
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.TargetConfirmed then
		   local use = data:toCardUse()
		   local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if use.from and sp:objectName() == use.from:objectName() and player:objectName() ~= sp:objectName() and use.card and use.card:isKindOf("Slash") then
				    local list = sgs.SPlayerList()
					for _,l in sgs.qlist(use.to) do
						if l:getMark("lieju_target") == 0 then 
							list:append(l) 
						end
					end
					if not list:isEmpty() then
					   return self:objectName(), sp
					end   
				end  
			end
		end	
		return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
		local use = data:toCardUse()
		local dat = sgs.QVariant()
		dat:setValue(use.from)
		if sp:askForSkillInvoke(self, dat) then
		    room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		else
           	room:setPlayerMark(player, "lieju_target", 1)	
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)		
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			room:loseHp(sp)
			if sp:isAlive() then
			    local list = sgs.SPlayerList()
			    for _,l in sgs.qlist(use.to) do
					if l:getMark("lieju_target") == 0 then 
						list:append(l) 
					end
				end
				local targets = room:askForPlayersChosen(sp, list, self:objectName(), 1, 1, "@liejus")
				if targets then        
				   for _,po in sgs.qlist(targets) do
                        room:setPlayerMark(po, "lieju_target", 1)			   
						local x, y = po:getHandcardNum(), sp:getLostHp()+po:getLostHp()
						if x <= y then
							room:showAllCards(po)
							if use.card:isRed() or use.card:isBlack() then
								local listBlack = sgs.IntList()
								local listRed = sgs.IntList()
								for _,c in sgs.qlist(po:getHandcards()) do
									if c:isBlack() then
										listBlack:append(c:getId())
									end
									if c:isRed() then
										listRed:append(c:getId())
									end
								end
								if listBlack:length() > 0 and use.card:isBlack() then
									local move = sgs.CardsMoveStruct()
									move.card_ids = listBlack
									move.to_place = sgs.Player_DiscardPile
									move.reason.m_reason = 0x33
									move.reason.m_playerId = sp:objectName()
									move.reason.m_skillName = self:objectName()
									room:moveCardsAtomic(move, true)
								end
								if listRed:length() > 0 and use.card:isRed() then
									local move = sgs.CardsMoveStruct()
									move.card_ids = listRed
									move.to_place = sgs.Player_DiscardPile
									move.reason.m_reason = 0x33
									move.reason.m_playerId = sp:objectName()
									move.reason.m_skillName = self:objectName()
									room:moveCardsAtomic(move, true)
								end
							end
						else
							local handle_list = {}
							for i = 1, y, 1 do
								table.insert(handle_list, "h")
							end
							local ids = room:askForCardsChosen(sp, po, table.concat(handle_list, "|"), self:objectName())
							local listA = sgs.IntList()
							for _,id in sgs.qlist(ids) do
								listA:append(id:getId())
							end
							if listA:length() > 0 then
								while listA:length() > 0 do
									local id = listA:at(0)
									room:showCard(po, id)
									listA:removeOne(id)
								end
							end
							if use.card:isRed() or use.card:isBlack() then
								local listBlack = sgs.IntList()
								local listRed = sgs.IntList()
								for _,c in sgs.qlist(ids) do
									if c:isBlack() then
										listBlack:append(c:getId())
									end
									if c:isRed() then
										listRed:append(c:getId())
									end
								end
								if listBlack:length() > 0 and use.card:isBlack() then
									local move = sgs.CardsMoveStruct()
									move.card_ids = listBlack
									move.to_place = sgs.Player_DiscardPile
									move.reason.m_reason = 0x33
									move.reason.m_playerId = sp:objectName()
									move.reason.m_skillName = self:objectName()
									room:moveCardsAtomic(move, true)
								end
								if listRed:length() > 0 and use.card:isRed() then
									local move = sgs.CardsMoveStruct()
									move.card_ids = listRed
									move.to_place = sgs.Player_DiscardPile
									move.reason.m_reason = 0x33
									move.reason.m_playerId = sp:objectName()
									move.reason.m_skillName = self:objectName()
									room:moveCardsAtomic(move, true)
								end
							end
						end	
					end	
				end
			end	
		end	
	end ,
}

jiazhen = sgs.CreateViewAsSkill{
	name = "jiazhen",
	n = 1,
	view_filter = function(self, selected, to_select)
		if #selected > 0 then return false end
		return to_select:isBlack() and not to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
			analeptic:setShowSkill(self:objectName())
			analeptic:setSkillName(self:objectName())
			analeptic:addSubcard(cards[1])
			return analeptic
		end
	end,
	enabled_at_play = function(self, player)
		if player:getMark("jiazhen_used") > 0 then
			return false
		end
		local newanal = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		if player:isCardLimited(newanal, sgs.Card_MethodUse) or player:isProhibited(player, newanal) then
			return false
		end
		return player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, newanal)
	end,
	enabled_at_response = function(self, player, pattern)
		if player:getMark("jiazhen_used") > 0 then
			return false
		end
		return string.find(pattern, "analeptic")
	end
}

jiazhenGlobal = sgs.CreateTriggerSkill{
	name = "jiazhenGlobal",
	global = true,
	events = {sgs.CardUsed, sgs.EventPhaseChanging},
	priority = 2,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == "jiazhen" then
				room:setPlayerMark(use.from, "jiazhen_used", 1)
				use.from:drawCards(1, "jiazhen")
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "jiazhen_used", 0)
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false 
	end,
}

xiexing = sgs.CreateTriggerSkill{
	name = "xiexing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed, sgs.EventPhaseChanging, sgs.Damage, sgs.CardFinished},
	on_record = function(self, event, room, player, data)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:objectName() == room:getCurrent():objectName() and p:getMark("xiexing-invoke") > 0 then
						room:setPlayerMark(p, "xiexing-invoke", 0)
					end
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player:objectName() == room:getCurrent():objectName() and (sgs.Sanguosha:getCurrentCardUseReason() == 0x01 or sgs.Sanguosha:getCurrentCardUseReason() == 0x12) and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) then
				room:setPlayerMark(player, "xiexing-invoke", player:getMark("xiexing-invoke")+1)
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if player:hasFlag("xiexing"..use.card:toString()) and player:objectName() == room:getCurrent():objectName() then				
				local log = sgs.LogMessage()
				log.type = "#xiexingC"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:objectName() == room:getCurrent():objectName() and player:getPhase() == sgs.Player_Play and (sgs.Sanguosha:getCurrentCardUseReason() == 0x01 or sgs.Sanguosha:getCurrentCardUseReason() == 0x12) and (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) and ((player:getMark("xiexing-invoke") == player:getHp() and not player:hasFlag("xiexing-distance")) or (player:getMark("xiexing-invoke") == getKingdomCount(player)) and not player:hasFlag("xiexingVS")) then
				return self:objectName()
			end
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:objectName() == room:getCurrent():objectName() and player:getPhase() == sgs.Player_Play and player:objectName() ~= damage.to:objectName() and damage.card then
				local n = 999
				for _,A in sgs.qlist(room:getAlivePlayers()) do
					if A:getHandcardNum() < n then
						n = A:getHandcardNum()
					end	
				end
				if (player:getHandcardNum() == n and not (player:hasFlag("xiexing-distance") and player:hasFlag("xiexingVS"))) or (player:hasFlag("xiexing-distance") and player:hasFlag("xiexingVS")) then
					return self:objectName()
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self) or room:askForSkillInvoke(player, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
		room:sendCompulsoryTriggerLog(player, self:objectName(), true)
		if event == sgs.CardUsed then
			if player:getMark("xiexing-invoke") == player:getHp() and not player:hasFlag("xiexing-distance") then
				room:setPlayerFlag(player, "xiexing-distance")
				local log = sgs.LogMessage()
				log.type = "#xiexingA"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			else
				room:setPlayerFlag(player, "xiexingVS")
				local log = sgs.LogMessage()
				log.type = "#xiexingB"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
			end			
		end
		if event == sgs.Damage then
			local damage = data:toDamage()
			if not (player:hasFlag("xiexing-distance") and player:hasFlag("xiexingVS")) then
				player:drawCards(1, self:objectName())
			else
				room:setPlayerFlag(player, "xiexing"..damage.card:toString())
			end
		end
	end,
}

xiexingDistance = sgs.CreateTargetModSkill{
	name = "#xiexingDistance",
	pattern = ".",
	distance_limit_func = function(self, from, card)
		if from:hasFlag("xiexing-distance") then
			return 1000
		end
		return 0
	end
}

xiexingVS = sgs.CreateTargetModSkill{
	name = "#xiexingVS",
	pattern = ".",
	residue_func = function(self, player)
		if player:hasFlag("xiexingVS") then
			return 1000
		end
		return 0
	end,
}

huaqian = sgs.CreateTriggerSkill{
	name = "huaqian",
	events = {sgs.CardFinished, sgs.EventPhaseEnd, sgs.CardUsed},
	on_record = function(self, event, room, player, data)
	    if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
			    for _,p in sgs.qlist(room:getAlivePlayers()) do
				   room:setPlayerMark(p, "huaqian_suit", 0)
			    end 
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if player:objectName() == use.from:objectName() and player:objectName() == room:getCurrent():objectName() and player:isFriendWith(sp) then
					if not (use.card:isKindOf("BasicCard") or use.card:isKindOf("TrickCard") or use.card:isKindOf("EquipCard")) or player:getPhase() == sgs.Player_NotActive then return end
					if use.card:getSuit() == sgs.Card_Spade and not player:hasFlag("huaqian-Spade") then
						room:setPlayerFlag(player, "huaqian-Spade")
						room:setPlayerMark(player, "huaqian_suit", player:getMark("huaqian_suit") + 1)
					elseif use.card:getSuit() == sgs.Card_Heart and not player:hasFlag("huaqian-Heart") then
						room:setPlayerFlag(player, "huaqian-Heart")
						room:setPlayerMark(player, "huaqian_suit", player:getMark("huaqian_suit") + 1)
					elseif use.card:getSuit() == sgs.Card_Club and not player:hasFlag("huaqian-Club") then
						room:setPlayerFlag(player, "huaqian-Club")
						room:setPlayerMark(player, "huaqian_suit", player:getMark("huaqian_suit") + 1)
					elseif use.card:getSuit() == sgs.Card_Diamond and not player:hasFlag("huaqian-Diamond") then
						room:setPlayerFlag(player, "huaqian-Diamond")
						room:setPlayerMark(player, "huaqian_suit", player:getMark("huaqian_suit") + 1)
					end
				end	
			end	
		end
	end,
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.CardFinished then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if player:objectName() == use.from:objectName() and player:objectName() == room:getCurrent():objectName() and not room:getCurrent():hasFlag("huaqian_no") and player:isFriendWith(sp) then
					if player:getMark("huaqian_suit") == 3 then
						return self:objectName(), sp
					end	
				end
			end
        end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
	    local use = data:toCardUse()
		local dat = sgs.QVariant()
		dat:setValue(use.from)
		room:getCurrent():setFlags("huaqian_no")
		if sp:askForSkillInvoke(self, dat) then
			room:broadcastSkillInvoke(self:objectName(), sp)
		    room:doLightbox("KozueHuaqian$", 999)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.CardFinished then
		   local use = data:toCardUse()
		   player:drawCards(1, self:objectName())
		    if player:objectName() ~= sp:objectName() and not player:isNude() then
		       local card = room:askForCard(player, "..", "&huaqian:" .. sp:objectName(), data, sgs.Card_MethodNone)
			    if not card then
					card = player:getCards("he"):at(math.random(1,player:getCards("he"):length())-1)
			    end
				if card then					
					local reason = sgs.CardMoveReason(0x17, player:objectName())
					room:obtainCard(sp, card, reason, false)
				end	
		    end
			if player:isAlive() then
				local n = room:getAlivePlayers():first():getHandcardNum()
				for _, p in sgs.qlist(room:getAlivePlayers()) do
					n = math.max(n, p:getHandcardNum())
				end
				if sp:getHandcardNum() == n then
		    	    room:setPlayerFlag(player, "huaqian-distance")
					local log = sgs.LogMessage()
					log.type = "#huaqianA"
					log.from = player
					log.arg = self:objectName()
					room:sendLog(log)
				end
			end			 
		end	
	end
}

huaqianDistance = sgs.CreateTargetModSkill{
	name = "#huaqianDistance",
	pattern = ".",
	distance_limit_func = function(self, from, card)
		if from:hasFlag("huaqian-distance") then
			return 1000
		end
		return 0
	end
}

qiuyu = sgs.CreateTriggerSkill{
	name = "qiuyu",
	events = {sgs.Damaged},	
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			return self:objectName()
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self, data) then 
			room:broadcastSkillInvoke(self:objectName(), player)
		    room:doLightbox("KozueQiuyu$", 999)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		player:drawCards(1, self:objectName())
		if not player:isKongcheng() and damage.from:isAlive() then
			local id = room:askForCardChosen(damage.from, player, "h", self:objectName())
			room:showCard(player, id)
			local cardid = sgs.Sanguosha:getCard(id)
			if cardid:getSuit() == sgs.Card_Heart then
				room:throwCard(cardid, player, player, self:objectName())
				local recoverlist = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					if p:isWounded() then
						recoverlist:append(p)
					end
				end
				if recoverlist:length() > 0 then
					local target =  room:askForPlayerChosen(player, recoverlist, self:objectName(), "&qiuyu-recover", true, true)
					if target then
						local recover = sgs.RecoverStruct()
						recover.who = player
						recover.recover = 1
						room:recover(target, recover, true)
					end		  		   
				end 
			else
				room:moveCardTo(cardid, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, player:objectName(), self:objectName(), ""))
				room:broadcastSkillInvoke("@recast")
				local log = sgs.LogMessage()
				log.type = "#UseCard_Recast"
				log.from = player
				log.card_str = tostring(cardid)
				room:sendLog(log)
				player:drawCards(1, "recast")
			end     		
		end		  	
	end,
}

jianxingCard = sgs.CreateSkillCard{
	name = "jianxingCard",
	target_fixed = true,
	will_throw = false, 
	on_use = function(self, room, player, targets)
		room:moveCardTo(self, player, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, player:objectName(), self:objectName(), ""))
		room:broadcastSkillInvoke("@recast")
		local log = sgs.LogMessage()
		log.type = "#UseCard_Recast"
		log.from = player
		log.card_str = tostring(cards)
		room:sendLog(log)
		player:drawCards(self:subcardsLength(), "recast")
		room:setPlayerMark(player, "#jianxing_recastnum", self:subcardsLength())
	end,
}

jianxingS = sgs.CreateViewAsSkill{
	name = "jianxing",
	n = 999,
	view_filter = function(self, selected, to_select)
	    if #selected >= 99 then return false end
	    if #selected < 1 then return "" end
		return to_select:objectName() == selected[1]:objectName()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local vs = jianxingCard:clone()
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		for i = 1, #cards, 1 do
			vs:addSubcard(cards[i])
		end
		return vs	
	end,	
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jianxing!"
	end,
}

jianxing = sgs.CreateTriggerSkill{
	name = "jianxing",
	can_preshow = true,
	view_as_skill = jianxingS,
	events = {sgs.TargetConfirming, sgs.CardFinished, sgs.Dying},
	on_record = function(self, event, room, player, data)
		if event==sgs.CardFinished then
			local effect=data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if player:hasFlag("jianxing_bz") and effect.from and effect.from:objectName() == player:objectName() and effect.card:isKindOf("BasicCard") then
					for _,m in sgs.qlist(room:getOtherPlayers(player)) do
					   room:removePlayerCardLimitation(m, "use", ".|.|.|.")
					end
					player:setFlags("-jianxing_bz")
				end
			end	
		end
		if event == sgs.Dying then
		    local dying = data:toDying()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,pl in sgs.qlist(players) do
				for _,g in sgs.qlist(room:getAlivePlayers()) do
					room:removePlayerCardLimitation(g, "use", ".|.|.|.")
				end	
			end
		end
	end,	
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if sp:hasSkill("jianxing") and use.from and player:objectName() ~= use.from:objectName() and use.card:isKindOf("BasicCard") and not room:getCurrent():hasFlag("jianxing_used") and not sp:isNude() and not sp:isRemoved() then
					return self:objectName(), sp
				end
			end
        end
		return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
	    local use = data:toCardUse()
		local dat = sgs.QVariant()
		dat:setValue(use.from)
		if sp:askForSkillInvoke(self, dat) then
		    local probabilityS = math.random(1,2)
			if probabilityS == 1 then
			   room:doLightbox("jianxing1$", 800)
			elseif probabilityS == 2 then
			   room:doLightbox("jianxing2$", 800)
			end 
			room:getCurrent():setFlags("jianxing_used")
			use.from:setFlags("jianxing_bz")
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.TargetConfirming then
		    local use = data:toCardUse()
			room:askForUseCard(sp, "@@jianxing!", "@jianxing")
			if sp:getMark("#jianxing_recastnum") == 1 then
			    for _,pm in sgs.qlist(use.to) do
					if pm:hasEquip() or pm:getJudgingArea():length() > 0 then 
						local card_id = room:askForCardChosen(use.from, pm, "ej", self:objectName())
						local card = sgs.Sanguosha:getCard(card_id)
						local reason = sgs.CardMoveReason(0x09, use.from:objectName(), self:objectName(), "")
						room:moveCardTo(card, pm, pm, sgs.Player_PlaceHand, reason)
					end
				end
			elseif sp:getMark("#jianxing_recastnum") == 2 then 
				for _,m in sgs.qlist(room:getOtherPlayers(use.from)) do
				   room:setPlayerCardLimitation(m, "use", ".|.|.|.", false)
				end
			elseif sp:getMark("#jianxing_recastnum") == 3 then
				local log = sgs.LogMessage()
				log.type = "$jianxing_NOTarget"
				log.arg = use.card:objectName()
				room:sendLog(log)
				use.to = sgs.SPlayerList()
				data:setValue(use)
			end
			room:setPlayerMark(sp, "#jianxing_recastnum", 0)
			return false
		end 		
	end,
}

yinni = sgs.CreateViewAsSkill{
	name = "yinni",
	n = 1,
	view_filter = function(self, selected, to_select)
		return #selected == 0 and not to_select:isEquipped() 
	end,
	view_as = function(self, cards)
		local card = yinniCard:clone() 
		if #cards == 0 then return nil end
		for var = 1, #cards, 1 do   
			card:addSubcard(cards[var])                
		end  
		card:setShowSkill(self:objectName())	
		card:setSkillName(self:objectName())		
		return card	
	end,	
	enabled_at_play = function(self, player)
		return player:getMark("##yinni_used") == 0---not player:hasFlag("yinni_used")
	end,
}

yinniCard = sgs.CreateSkillCard{
	name = "yinniCard",
	target_fixed = false,
	will_throw = false,
	--mute = true,
	filter = function(self, targets, to_select) 
		return #targets < 2 and not to_select:isKongcheng() and to_select:objectName() ~= sgs.Self:objectName()
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
		local cd = sgs.Sanguosha:getCard(self:getSubcards():first())
		source:setFlags("yinni_target")
		if #targets > 1 then
		    targets[1]:setFlags("yinni_target")
			targets[2]:setFlags("yinni_target")
			local id = room:askForCardChosen(targets[1], targets[1], "h", self:objectName())
			local id2 = room:askForCardChosen(targets[2], targets[2], "h", self:objectName()) 
			room:showCard(source, self:getSubcards():first())
			room:showCard(targets[1], id)
			room:showCard(targets[2], id2)
			local cardid = sgs.Sanguosha:getCard(id)
			local cardid2 = sgs.Sanguosha:getCard(id2)
			local num = sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber()
			local HD2 = sgs.Sanguosha:getCard(id2):getNumber() 
			local HD = sgs.Sanguosha:getCard(id):getNumber()
			if num ~= HD and num ~= HD2 and HD ~= HD2 then
				if num > HD and num > HD2 then
				    local targetst = sgs.SPlayerList()
				    for _,m in ipairs(targets) do
						targetst:append(m)
					end
				    local tar = room:askForPlayersChosen(source, targetst, "yinni", 0, 1, "@yinni_duel")
					for _,p in sgs.qlist(tar) do
						local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
						local use = sgs.CardUseStruct(duel,source,p)
						room:useCard(use,false)
						p:setFlags("-yinni_target")
						source:setFlags("-yinni_target")
					end
					if targets[1]:hasFlag("yinni_target") then
					   room:throwCard(id, targets[1], targets[1], "yinni")
					end
					if targets[2]:hasFlag("yinni_target") then
					   room:throwCard(id2, targets[2], targets[2], "yinni")
					end
				elseif HD > num and HD > HD2 then
                    local targetst = sgs.SPlayerList()
				    for _,m in sgs.qlist(room:getOtherPlayers(targets[1])) do
						if m:hasFlag("yinni_target") then
						  targetst:append(m)
						end  
					end
				    local tar = room:askForPlayersChosen(targets[1], targetst, "yinni", 0, 1, "@yinni_duel")
					for _,p in sgs.qlist(tar) do                           
						local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
						local use = sgs.CardUseStruct(duel,targets[1],p)
						room:useCard(use,false)
						p:setFlags("-yinni_target")
						targets[1]:setFlags("-yinni_target")
					end
					if source:hasFlag("yinni_target") then
					   room:throwCard(cd, source, source, "yinni")
					end
					if targets[2]:hasFlag("yinni_target") then
					   room:throwCard(id2, targets[2], targets[2], "yinni")
					end
				elseif HD2 > num and HD2 > HD then
                    local targetst = sgs.SPlayerList()
				    for _,m in sgs.qlist(room:getOtherPlayers(targets[2])) do
						if m:hasFlag("yinni_target") then
						  targetst:append(m)
						end  
					end
				    local tar = room:askForPlayersChosen(targets[2], targetst, "yinni", 0, 1, "@yinni_duel")
					for _,p in sgs.qlist(tar) do                           
						local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
						local use = sgs.CardUseStruct(duel,targets[2],p)
						room:useCard(use,false)
						p:setFlags("-yinni_target")
						targets[2]:setFlags("-yinni_target")
					end
					if source:hasFlag("yinni_target") then
					   room:throwCard(cd, source, source, "yinni")
					end
					if targets[1]:hasFlag("yinni_target") then
					   room:throwCard(id, targets[1], targets[1], "yinni")
					end
				end
			else
					room:moveCardTo(cd, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, source:objectName(), self:objectName(), ""))
					room:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = source
					log.card_str = tostring(cd)
					room:sendLog(log)
					source:drawCards(1, "recast")                  
					room:moveCardTo(cardid, targets[1], nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, targets[1]:objectName(), self:objectName(), ""))
					room:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = targets[1]
					log.card_str = tostring(cardid)
					room:sendLog(log)
					targets[1]:drawCards(1, "recast")	
					
					room:moveCardTo(cardid2, targets[2], nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, targets[2]:objectName(), self:objectName(), ""))
					room:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = targets[2]
					log.card_str = tostring(cardid2)
					room:sendLog(log)
					targets[2]:drawCards(1, "recast")	
					
					source:setFlags("-yinni_target")
					targets[1]:setFlags("-yinni_target")
					targets[2]:setFlags("-yinni_target")
					room:setPlayerMark(source, "##yinni_used", 0)
			end
		elseif #targets == 1 then
		    targets[1]:setFlags("yinni_target")
		    local id = room:askForCardChosen(targets[1], targets[1], "h", self:objectName())
			room:showCard(source, self:getSubcards():first())
			room:showCard(targets[1], id)
			local num = sgs.Sanguosha:getCard(self:getSubcards():first()):getNumber()
			local HD = sgs.Sanguosha:getCard(id):getNumber()
			if num ~= HD  then
				if num > HD  then
				    local targetst = sgs.SPlayerList()
				    for _,m in ipairs(targets) do
						targetst:append(m)
					end
				    local tar = room:askForPlayersChosen(source, targetst, "yinni", 0, 1, "@yinni_duel")
					for _,p in sgs.qlist(tar) do                           
						local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
						local use = sgs.CardUseStruct(duel,source,p)
						room:useCard(use,false)
						p:setFlags("-yinni_target")
						source:setFlags("-yinni_target")
					end
					if targets[1]:hasFlag("yinni_target") then
					   room:throwCard(id, targets[1], targets[1], "yinni")
					end
				elseif HD > num  then
				    local targetst = sgs.SPlayerList()
				    for _,m in sgs.qlist(room:getOtherPlayers(targets[1])) do
						if m:hasFlag("yinni_target") then
						  targetst:append(m)
						end  
					end
				    local tar = room:askForPlayersChosen(targets[1], targetst, "yinni", 0, 1, "@yinni_duel")
					for _,p in sgs.qlist(tar) do                           
						local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
						local use = sgs.CardUseStruct(duel,targets[1],p)
						room:useCard(use,false)
						p:setFlags("-yinni_target")
						targets[1]:setFlags("-yinni_target")
					end
					if source:hasFlag("yinni_target") then
					   room:throwCard(cd, source, source, "yinni")
					end  
				end
			else
					room:moveCardTo(cd, source, nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, source:objectName(), self:objectName(), ""))
					room:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = source
					log.card_str = tostring(cd)
					room:sendLog(log)
					source:drawCards(1, "recast")
                    
					room:moveCardTo(cardid, targets[1], nil, sgs.Player_DiscardPile, sgs.CardMoveReason(0x04, targets[1]:objectName(), self:objectName(), ""))
					room:broadcastSkillInvoke("@recast")
					local log = sgs.LogMessage()
					log.type = "#UseCard_Recast"
					log.from = targets[1]
					log.card_str = tostring(cardid)
					room:sendLog(log)
					targets[1]:drawCards(1, "recast")
					
					source:setFlags("-yinni_target")
					targets[1]:setFlags("-yinni_target")
				    room:setPlayerMark(source, "##yinni_used", 0)
			end
        end
		for _,K in sgs.qlist(room:getAlivePlayers()) do
			if K:hasFlag("yinni_target") then
			   K:setFlags("-yinni_target")
			end  
		end
	end,
}

yinniGlobal = sgs.CreateTriggerSkill{
	name = "yinniGlobal",
	global = true,
	events = {sgs.CardUsed, sgs.EventPhaseEnd},
	     priority = 2,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == "yinni" then
				room:setPlayerMark(player, "##yinni_used", 1)
			end
		end
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			    if p:getMark("##yinni_used") > 0 then
				   room:setPlayerMark(p, "##yinni_used", 0)
				end
			end
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false 
	end,
}

yongwang = sgs.CreateTriggerSkill{
	name = "yongwang",
	events = {sgs.CardsMoveOneTime},	
	can_trigger = function(self, event, room, player, data)
	   if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 0x03 and move.to_place == sgs.Player_DiscardPile and player:hasSkill("yongwang") and not room:getCurrent():hasFlag("yongwang_times") and not player:isKongcheng() then
				local n = 0
				local ids = sgs.IntList()
				for _,card in sgs.qlist(player:getHandcards()) do 
					if card:getNumber() > n then
						n = card:getNumber()	
					end
				end	
				for _,card in sgs.qlist(player:getHandcards()) do 
					if card:getNumber() == n then
						room:setPlayerMark(player, "yongwang_num", n)
					end
				end
				local Nums = false
				for _, card_id in sgs.qlist(move.card_ids) do
					if sgs.Sanguosha:getCard(card_id):getNumber() > player:getMark("yongwang_num") then
						Nums = true
						break
					end
				end
				if Nums then 
					return self:objectName()									
				end
			end
		end	
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:getCurrent():setFlags("yongwang_times")
			return true	
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
		    local move = data:toMoveOneTime()
			room:showAllCards(player)
			local ts = sgs.IntList()
			for _, c in sgs.qlist(move.card_ids) do
			    local card = sgs.Sanguosha:getCard(c)
				if sgs.Sanguosha:getCard(c):getNumber() > player:getMark("yongwang_num") then
					ts:append(c)
				end
			end
			if not ts:isEmpty() then
				room:fillAG(ts, player)
				local ide = room:askForAG(player, ts, false, self:objectName())
				room:clearAG(player)
				room:obtainCard(player, ide)
			end   
		end
	end,
}

chaoyan = sgs.CreateTriggerSkill{
	name = "chaoyan",
	events = {sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
		local damage = data:toDamage()
		if player and player:isAlive() and player:hasSkill(self:objectName()) and damage.damage > 0 then
			return self:objectName()
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local damage = data:toDamage()
		local x = damage.damage
		local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
		local choice = room:askForChoice(player, self:objectName(), "chaoyanA+chaoyanB", data)
		if choice == "chaoyanA" then
			local list = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() < target:getHandcardNum() then
					list:append(p)
				end
			end
			if list:length() <= 0 then return end
			room:sortByActionOrder(list)
			for _,a in sgs.qlist(list) do
				a:drawCards(x, self:objectName())
			end
		else
			local listB = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getHandcardNum() > target:getHandcardNum() then
					listB:append(p)
				end
			end
			if listB:length() <= 0 then return end
			room:sortByActionOrder(listB)
			for _,a in sgs.qlist(listB) do
				room:askForDiscard(a, self:objectName(), x, x)
			end
		end	
	end ,
}

youli = sgs.CreateTriggerSkill{
	name = "youli",
	events = {sgs.CardsMoveOneTime},
	can_trigger = function(self, event, room, player, data)
		if player and player:isAlive() and player:hasSkill(self:objectName()) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() ~= player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and player:getHandcardNum() <= move.from:getHandcardNum() and not (player:isKongcheng() and move.from:isKongcheng()) and not room:getCurrent():hasFlag("youli"..move.from:objectName()) then
				local reason = move.reason
				if bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == 0x03 then
					return self:objectName()
				end
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		local move = data:toMoveOneTime()
		local dest = findPlayerByObjectName(move.from:objectName())
		local who = sgs.QVariant()
		who:setValue(dest)
		if player:askForSkillInvoke(self, who) then
			room:broadcastSkillInvoke(self:objectName(), player)
			room:getCurrent():setFlags("youli"..move.from:objectName())
			return true
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data)
		local move = data:toMoveOneTime()
		local dest = findPlayerByObjectName(move.from:objectName())
		local choice_list = {}
		if not player:isKongcheng() then table.insert(choice_list, "youli_give") end
		if not dest:isKongcheng() then table.insert(choice_list, "youli_obtain") end
		if #choice_list == 0 then return false end
		local choice = room:askForChoice(player, self:objectName(), table.concat(choice_list, "+"), data)
		if choice == "youli_give" then
			local card = room:askForCard(player, ".|.|.|hand", "&youli:" .. dest:objectName(), data, sgs.Card_MethodNone)
			if not card then
			   card = player:getCards("h"):at(math.random(1, player:getCards("h"):length())-1)
			end
			if card then			
				local reason = sgs.CardMoveReason(0x17, player:objectName())
				room:obtainCard(dest, card, reason, false)
				local a, b = dest:getHandcardNum(), dest:getMaxHp()
				if a < b then
					dest:drawCards(b-a, self:objectName())
				elseif a > b then
					room:askForDiscard(dest, self:objectName(), a-b, a-b)
				end				
			end
		else
			local id = room:askForCardChosen(player, dest, "h", self:objectName())
			room:obtainCard(player, id, false)
			if dest:isWounded() then
				local recover = sgs.RecoverStruct()
				recover.who = player
				recover.recover = 1
				room:recover(dest, recover, true)
			end
		end
	end ,
}

SRiko:addSkill(qinban)
SRiko:addSkill(zhiyuan)
Honoka:addSkill(guwu)
Honoka:addSkill(huqing)
Rin:setHeadMaxHpAdjustedValue(-1)
Rin:addSkill(xunjiRin)
Rin:addSkill(tuibian)
Rin:addSkill(qiaoyuan)
Maki:addSkill(ciqiang)
Maki:addSkill(qianjin)
Chika:addSkill(jiesi)
Chika:addSkill(tongzhou)
Ruby:addSkill(heyix)
Ruby:addSkill(qiesheng)
Kasumi:addSkill(qingyuan)
Kasumi:addSkill(qingyuanMark)
Kasumi:addSkill(zilian)
Karin:addSkill(zhanmei)
EmmaVerde:addSkill(aiwen)
EmmaVerde:addCompanion("Karin")
TangKK:addSkill(lvgui)
TangKK:addRelateSkill("oversea")
TangKK:addSkill(xiangyun)
Ren:addSkill(jichan)
Ren:addSkill(jichanMaxCards)
sgs.insertRelatedSkills(extension, "jichan", "#jichanMaxCards")
Ren:addSkill(weiji)
TokaiTeio:addSkill(diwu)
TokaiTeio:addSkill(nisheng)
TokaiTeio:addSkill(ThreeUp)
Ailian:addSkill(beide)
Ailian:addSkill(jinduan)
SilenceSuzuka:addSkill(qisu)
SilenceSuzuka:addSkill(xingyun)
SilenceSuzuka:addSkill(xingyunDying)
sgs.insertRelatedSkills(extension, "xingyun", "#xingyunDying")
Aien:addSkill(anyu)
Aien:addCompanion("Ailian")
Liko:addSkill(jinfa)
Liko:addSkill(xunfei)
Tsubomi:addSkill(lianhui)
Tsubomi:addSkill(shixin)
Makoto:addSkill(yaojian)
Makoto:addSkill(tonghua)
Eli:addSkill(shouwu)
Eli:addRelateSkill("xueyun")
Eli:addSkill(xianju)
Ai:addSkill(lamei)
Ai:addSkill(youai)
Ai:addCompanion("Karin")
Miku:addSkill(geji)
Miku:addSkill(gongzhu)
Yayoi:addSkill(caiquan)
Yayoi:addSkill(zhaolei)
YSetsuna:addSkill(chixin)
YSetsuna:addSkill(chixinEffect)
YSetsuna:addSkill(chixinVS)
sgs.insertRelatedSkills(extension, "chixin", "#chixinEffect", "#chixinVS")
YSetsuna:addSkill(jinhun)
YSetsuna:addSkill(jinhunMark)
Haru:addSkill(yibing)
Haru:addSkill(neifan)
Dia:addSkill(wangzu)
Dia:addSkill(yayi)
Dia:addCompanion("Ruby")
DaiwaScarlet:addSkill(aoji)
DaiwaScarlet:addSkill(tuyou)
Asahina:addSkill(yinfa)
Asahina:addSkill(jijian)
Asahina:addCompanion("Liko")
Shioriko:addSkill(xinxing)
Shioriko:addSkill(yanlv)
Tooru:addSkill(jiaoxin)
Tooru:addSkill(xiuxing)
Prism:addSkill(chaoshi)
Prism:addSkill(chaoshist)
sgs.insertRelatedSkills(extension, "chaoshi", "#chaoshist")
Prism:addSkill(shangyuan)
Fuuka:addSkill(moliang)
Fuuka:addSkill(yuanshu)
Arisa:setHeadMaxHpAdjustedValue(-1)
Arisa:addSkill(lvge)
Arisa:addSkill(quming)
Arisa:addSkill(yangming)
Nozomi:addSkill(yueyin)
AmouKanade:addSkill(juexiang)
AmouKanade:addSkill(huyi)
AmouKanade:addCompanion("kntsubasa")
Umi:addSkill(lixun)
Umi:addSkill(gongdao)
sgs.insertRelatedSkills(extension, "gongdao", "#gongdaotr")
Umi:addCompanion("Honoka")
Hanamaru:addSkill(baoshix)
Hanamaru:addSkill(baoshixst)
sgs.insertRelatedSkills(extension, "baoshix", "#baoshixst")
Hanamaru:addSkill(changyue)
Hanamaru:addSkill(changyues)
sgs.insertRelatedSkills(extension, "changyue", "#changyues")
Hanamaru:addCompanion("Ruby")
Vodka:addSkill(jiazhen)
Vodka:addSkill(lieju)
Vodka:addCompanion("DaiwaScarlet")
MihonoBourbon:addSkill(xiexing)
MihonoBourbon:addSkill(xiexingDistance)
MihonoBourbon:addSkill(xiexingVS)
sgs.insertRelatedSkills(extension, "xiexing", "#xiexingDistance", "#xiexingVS")
Kozue:addSkill(huaqian)
Kozue:addSkill(huaqianDistance)
sgs.insertRelatedSkills(extension, "huaqian", "#huaqianDistance")
Kozue:addSkill(qiuyu)
Harewataru:addSkill(jianxing)
Harewataru:addCompanion("Prism")
NiceNature:addSkill(yinni)
NiceNature:addSkill(yongwang)
PalmerHelios:addSkill(chaoyan)
PalmerHelios:addSkill(youli)

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("tuibianVS") then skills:append(tuibianVS) end
if not sgs.Sanguosha:getSkill("heyixglobal") then skills:append(heyixglobal) end
if not sgs.Sanguosha:getSkill("#heyixSlash") then skills:append(heyixSlash) end
if not sgs.Sanguosha:getSkill("oversea") then skills:append(oversea) end
if not sgs.Sanguosha:getSkill("weijiglobal") then skills:append(weijiglobalS) end
if not sgs.Sanguosha:getSkill("jinduanMaxCards") then skills:append(jinduanMaxCards) end
if not sgs.Sanguosha:getSkill("youaiglobal") then skills:append(youaiglobal) end
if not sgs.Sanguosha:getSkill("youaizongheng") then skills:append(youaizongheng) end
if not sgs.Sanguosha:getSkill("xueyun") then skills:append(xueyun) end
if not sgs.Sanguosha:getSkill("xueyunglobal") then skills:append(xueyunglobal) end
if not sgs.Sanguosha:getSkill("#gongzhuMaxCards") then skills:append(gongzhuMaxCards) end
if not sgs.Sanguosha:getSkill("#caiquanMaxCards") then skills:append(caiquanMaxCards) end
if not sgs.Sanguosha:getSkill("yibingVS") then skills:append(yibingVS) end
if not sgs.Sanguosha:getSkill("yibingMaxCards") then skills:append(yibingMaxCards) end
if not sgs.Sanguosha:getSkill("wangzuMaxCards") then skills:append(wangzuMaxCards) end
if not sgs.Sanguosha:getSkill("jijianglobal") then skills:append(jijianglobal) end
if not sgs.Sanguosha:getSkill("xiuxingglobal") then skills:append(xiuxingglobal) end
if not sgs.Sanguosha:getSkill("#shangyuantr") then skills:append(shangyuantr) end
if not sgs.Sanguosha:getSkill("#shangyuants") then skills:append(shangyuants) end
if not sgs.Sanguosha:getSkill("#huyis") then skills:append(huyis) end
if not sgs.Sanguosha:getSkill("#lixuntr") then skills:append(lixuntr) end
if not sgs.Sanguosha:getSkill("baoshixglobal") then skills:append(baoshixglobal) end
if not sgs.Sanguosha:getSkill("jiazhenGlobal") then skills:append(jiazhenGlobal) end
if not sgs.Sanguosha:getSkill("#gongdaotr") then skills:append(gongdaotr) end
if not sgs.Sanguosha:getSkill("yinniGlobal") then skills:append(yinniGlobal) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
  ["Shiny"] = "闪耀之章",
	
  ["SRiko"] = "樱内梨子",
  ["@SRiko"] = "Love Live系列",
  ["#SRiko"] = "纯洁乐句",
  ["~SRiko"] = "呜呜，可能是我很土的原因——",
  ["designer:SRiko"] = "花宫瑞业",
  ["cv:SRiko"] = "逢田梨香子",
  ["illustrator:SRiko"] = "在下是子龙",
  ["%SRiko"] = "“直至如今才明白 我不是孤身一人”",
 
  ["qinban"] = "琴绊",
  [":qinban"] = "与你势力相同的角色的准备阶段开始时，你可以弃置你或其装备区内的一张牌，选择一项：1.令你与其各摸一张牌；2.令其回复1点体力。",
  ["$qinban1"] = "大概这就是我和你的羁绊——？",
  ["$qinban2"] = "喜欢我弹琴？听你这么说，感觉真高兴，有信心了呢。",
  ["$qinban3"] = "偶尔来听听我弹琴吗？",
  ["$qinban4"] = "难道这就是约……不、不对，我到底在乱想什么啊……",
  ["$qinban5"] = "啊、那个……能陪我一会儿吗？！呃，一个人穿着这个制服上台的话……呜呜呜……？",
  ["$qinban6"] = "让纯净而可爱的天使将迷途的羔羊引导至天堂吧……呜呜，可以不说吗？这种台词……",
  ["&qinban"] = "你可以发动“琴绊”，选择一名角色弃置其装备区内的一张牌", 
  ["recoverRiko"] = "其回复1点体力",
  ["RikoQinban$"] = "image=image/animate/RikoQinban.png",
  ["zhiyuan"] = "知缘",
  [":zhiyuan"] = "锁定技，①当你受到伤害时，若伤害来源与你势力相同且不为你，则此伤害-1。②当你受到伤害后，你选择一项：1.摸一张牌；2.移动场上的一张牌。",
  ["$zhiyuan1"] = "想要共度一生的人……不知我能不能和这样的人相遇。",
  ["$zhiyuan2"] = "那么在意我吗？——其实我也对你很在意呢——",
  ["$zhiyuan3"] = "你啊……已经是我世界中不可或缺的人咯♪",
  ["$zhiyuan4"] = "其实我很喜欢雨天。为了不被淋湿，需要放慢脚步，这样和你在一起的时间也就更长了……", 
  ["$zhiyuan5"] = "能和你一起度过风平浪静的日子，真要感谢神明呢。",
  ["$zhiyuan6"] = "在你的身边赏花，似乎樱花也变得分外的美丽。",
  ["&zhiyuanA"] = "选择一名装备区或判定区内有牌的角色",
  ["&zhiyuanB"] = "选择另一名角色，将选择的牌移动给其",
  ["AskForZhiyuan"] = "移动场上的一张牌",
  ["#zhiyuan"] = "%from 的“%arg”被触发，此伤害-1",
  ["RikoZhiyuan$"] = "image=image/animate/RikoZhiyuan.png",
  
  ["Honoka"] = "高坂穗乃果",
  ["@Honoka"] = "Love Live系列",
  ["#Honoka"] = "奇迹的起始",
  ["~Honoka"] = "啊呀，搞砸了……",
  ["designer:Honoka"] = "Sword Elucidator&时雨",
  ["cv:Honoka"] = "新田惠海",
  ["illustrator:Honoka"] = "彩虹之翼",
  ["%Honoka"] = "“Fight哒哟！”",
  
  ["guwu"] = "鼓舞",
  [":guwu"] = "社团技，「μ's」。\n加入条件：每名角色于其回合外回复体力后，你可以令其选择是否加入「μ's」。\n社团效果：「μ's」成员于濒死状态被救回后，其判定。若为：红色，则其回复1点体力；黑色，则所有「μ's」成员各摸一张牌。",
  ["mus"] = "「μ's」",
  ["guwu_accept"] = "接受邀请加入「μ's」",
  ["$refuse_club"] = "%from 拒绝了社团 %arg 的邀请",
  ["guwu$"] = "image=image/animate/se_guwu.png",
  ["$guwu1"] = "好的，就和穗乃果一起来唱歌吧！",
  ["$guwu2"] = "嘿，打起精神来挑战一下吧！",
  ["$guwu3"] = "哦？好像还可以继续进行练习！那只好继续加油了！",
  ["$guwu4"] = "穂乃果来支援你了~",
  ["huqing"] = "呼晴",
  [":huqing"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以弃置其中没有的花色的牌各一张（花色均有则只能取消），对其造成1点火焰伤害。",
  ["huqingfire"] = "呼晴",
  ["@huqing"] = "你可以弃置符合要求的牌，对其造成1点火焰伤害",
  ["~huqing"] = "选择符合要求的牌→点击“确定”",
  ["$huqing1"] = "耀眼的阳光与一望无际的碧海青天！看着就让人活力充沛～",
  ["$huqing2"] = "如果做“好～多好多的”晴天娃娃，会不会每天都变好天气呢？",
  
  ["Rin"] = "星空凛",
  ["@Rin"] = "Love Live系列",
  ["#Rin"] = "脱兔",
  ["~Rin"] = "失败了喵……",
  ["designer:Rin"] = "花宫瑞业",
  ["cv:Rin"] = "饭田里穗",
  ["illustrator:Rin"] = "彩虹之翼",
  ["%Rin"] = "“喵~喵~喵~”",

  ["xunjiRin"] = "迅急",
  [":xunjiRin"] = "准备阶段开始时，你可以无距离限制地使用一张【杀】，然后你本回合不能使用锦囊牌。",
  ["$xunjiRin1"] = "那么！只有前进了喵~",
  ["$xunjiRin2"] = "一起上喵！",
  ["&xunjiRin"] = "你可以无距离限制地使用一张【杀】，然后你本回合不能使用锦囊牌",
  ["tuibian"] = "蜕变",
  [":tuibian"] = "主将技，你计算体力上限减少1个单独的阴阳鱼。<font color=\"green\"><b>回合内限四次，</b></font>当你使用基本牌结算后，你可以重铸一张牌，本回合使用【杀】的次数+1。",
  ["$tuibian1"] = "都是你的功劳喵♪",
  ["$tuibian2"] = "让你看看，凛全力以赴的表演！",
  ["qiaoyuan"] = "巧援",
  [":qiaoyuan"] = "副将技，出牌阶段限一次，你可以将最多X张不能使用的手牌交给一名其他角色（X为你的体力值）。",
  --[":qiaoyuan"] = "副将技，当你受到伤害后，你可以观看3张未加入游戏的偶像势力人物牌，将副将替换为其中一张。",
  ["$qiaoyuan1"] = "喂～！住手喵～！",
  ["$qiaoyuan2"] = "再得寸进尺的话，我要生气了喵！",

  ["Maki"] = "西木野真姬",
  ["@Maki"] = "Love Live系列",
  ["#Maki"] = "深红蔷薇",
  ["~Maki"] = "……能力不够吧。",
  ["designer:Maki"] = "花宫瑞业",
  ["cv:Maki"] = "Pile（堀绘梨子）",
  ["illustrator:Maki"] = "ハヤオキ",
  ["%Maki"] = "“什么呀，意味不明啦！”",
 
  ["ciqiang"] = "刺蔷",
  [":ciqiang"] = "<font color=\"green\"><b>每回合限X次（X为你的体力值），</b></font>当你于回合外成为其他角色使用基本牌或锦囊牌的唯一目标时，若所有角色体力值均＞0，则你可以弃置其区域内的一张牌。",
  ["$ciqiang1"] = "你这个笨蛋，脑袋里到底在想什么啊……嗯哼~",
  ["$ciqiang2"] = "有没有不好的地方啊让我仔细地找找♪不行！不准逃哦！",
  ["qianjin"] = "千金",
  [":qianjin"] = "出牌阶段限一次，你可以选择一种花色。你弃置该花色的所有牌（没有则不弃），摸X张牌（X为场上该花色的牌数，最多为5）。",
  ["$qianjin1"] = "虽然感觉有点怪……当然是很合适吧♪",
  ["$qianjin2"] = "华丽……？礼服都是这样的吧？",

  ["Chika"] = "高海千歌",
  ["@Chika"] = "Love Live系列",
  ["#Chika"] = "哐哐蜜柑",
  ["~Chika"] = "哇——失败了！",
  ["designer:Chika"] = "花宫瑞业",
  ["cv:Chika"] = "伊波杏树",
  ["illustrator:Chika"] = "KOUGI",
  ["%Chika"] = "“生活就像海洋，只有意志坚强的人才能到达彼岸。”",

  ["jiesi"] = "解思",
  [":jiesi"] = "当你受到伤害后，你可以摸一张牌，然后将手牌弃至全场最少，选择一项：1.令最多X名角色将手牌摸至体力上限（X为你以此法弃置的牌数）；2.弃置最多X名角色区域内各一张牌。",
  ["$jiesi1"] = "感到困扰的时候，我会帮忙的！",
  ["$jiesi2"] = "可以哦，觉得不安的时候，我会陪你的。",
  ["jiesiDraw"] = "令一些角色摸一些牌",
  ["jiesiThrow"] = "你弃置一些角色的牌",
  ["&jiesiDraw"] = "请选择最多 %src 名要摸牌的角色",
  ["#jiesiDraw"] = "解思：摸牌",
  ["&jiesiThrow"] = "请选择最多 %src 名要弃牌的角色",
  ["#jiesiThrow"] = "解思：弃牌",
  ["tongzhou"] = "同舟",
  [":tongzhou"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你的牌因弃置而进入弃牌堆后，你可以观星3。",
  ["$tongzhou1"] = "我们好像心意相通了。",
  ["$tongzhou2"] = "没关系，我绝对不会放弃。",
  
  ["Ruby"] = "黑泽露比",
  ["@Ruby"] = "Love Live系列",
  ["#Ruby"] = "红宝石",
  ["~Ruby"] = "不行吗——",
  ["designer:Ruby"] = "花宫瑞业",
  ["cv:Ruby"] = "降幡爱",
  ["illustrator:Ruby"] = "黑濑结季",
  ["%Ruby"] = "“加油露比！”", 
  
  ["heyix"] = "和谊",
  [":heyix"] = "出牌阶段限一次，你可以弃置任意张红色手牌并令等量角色下个摸牌阶段多摸一张牌，然后令其中一名角色使用【杀】的次数+1直到其回合结束。",
  ["&heyix-slash"] = "选择一名角色使用【杀】的次数+1",
  ["heyix_draw"] = "和谊摸牌",
  ["heyix_slashnum"] = "和谊出杀",
  ["$heyix1"] = "今天的是以古代中国为主题的服装。好看吗？你能喜欢真是太好了♪",
  ["$heyix2"] = "要和露比一起穿越到古代中国去旅行吗？哎嘿嘿，我想起了中国的传说故事~",
  ["qiesheng"] = "怯生",
  [":qiesheng"] = "锁定技，①当你于回合外受到其他角色的伤害后，你令伤害来源选择一项：1.交给你一张牌；2.你进入【存在缺失】状态。②当你失去体力或受到伤害时，若你处于【存在缺失】状态，则防止之。 ",
  ["&qiesheng_give"] = "你可以交给 %src 一张牌，或者点击“取消”令其进入【存在缺失】状态",
  ["$qiesheng1"] = "哇啊，怎么啦！",
  ["$qiesheng2"] = "呀——别挠痒嘛——",
  
  ["Kasumi"] = "中须霞",
  ["@Kasumi"] = "Love Live系列",
  ["#Kasumi"] = "玲珑彻璨",
  ["~Kasumi"] = "……我没有灰心丧气啊……",
  ["designer:Kasumi"] = "花宫瑞业",
  ["cv:Kasumi"] = "相良茉优",
  ["illustrator:Kasumi"] = "M子",
  ["%Kasumi"] = "“我是最可爱的校园偶像，小霞霞喔！”",
 
  ["qingyuan"] = "情援",
  [":qingyuan"] = "限定技，其他角色受到致命伤害时，若你有手牌，则你可以弃置所有手牌防止之，然后你将“自恋”改为非强制发动。",
  ["$qingyuan1"] = "你和小霞之间，连着红线~像毛线那么粗！",
  ["$qingyuan2"] = "我能走到今天，虽说是因为我本来就很可爱，但也是……托了大家的福吧……",
  ["@qingyuan"] = "情援",
  ["#qingyuanEffect"] = "“%arg”效果触发，此伤害被防止",  
  ["qingyuan$"] = "image=image/animate/qingyuan.png",
  ["zilian"] = "自恋",
  [":zilian"] = "锁定技，出牌阶段开始时，你摸X张牌（X为势力数），然后结束阶段开始时，若你在此期间造成的伤害数＜此时的势力数，则你弃置等同于二者之差的牌（若牌数不足则多余数值改为失去体力）。",
  ["$zilian1"] = "我果然很可爱！",
  ["$zilian2"] = "小霞可爱吗？啊，经常被人这么说~♪",
  
  ["Karin"] = "朝香果林",
  ["@Karin"] = "Love Live系列",
  ["#Karin"] = "蓝色诱惑",
  ["~Karin"] = "我还差得远呢……",
  ["designer:Karin"] = "花宫瑞业",
  ["cv:Karin"] = "久保田未梦",
  ["illustrator:Karin"] = "ckst",
  ["%Karin"] = "“今夜的目标就决定是·你·了！”",
  
  ["zhanmei"] = "展魅",
  [":zhanmei"] = "①出牌阶段开始时，你可以弃置任意张牌。然后你选择最多等量名装备区内牌数≥你的其他角色，这些角色选择是否交给你一张基本牌。若你本次获得的牌数＜你已损失的体力值，则你回复1点体力。②当其他角色因你的伤害而进入濒死状态时，你可以变更副将。",
  ["@zhanmei"] = "你可以发动“展魅”",
  ["~zhanmei"] = "选择任意张牌→点击“确定”",
  ["&zhanmei"] = "请选择最多 %src 名角色作为“展魅”的目标",
  ["&zhanmeiGive"] = "你可以交给 %src 一张基本牌",
  ["$zhanmei1"] = "美丽也是一种才能哦。如果不加以运用，岂不是太浪费了？",
  ["$zhanmei2"] = "我一直都在关注别人看向我的视线……虽然紧张，但那也会让我更出色！",

  ["EmmaVerde"] = "艾玛·维尔德",
  ["@EmmaVerde"] = "Love Live系列",
  ["&EmmaVerde"] = "艾玛",
  ["#EmmaVerde"] = "空蝉千岁",
  ["~EmmaVerde"] = "呜呜……",
  ["designer:EmmaVerde"] = "花宫瑞业",
  ["cv:EmmaVerde"] = "指出毬亚",
  ["illustrator:EmmaVerde"] = "ゴミョン",
  ["%EmmaVerde"] = "“今天也一起快乐地享受吧！”",
  
  ["aiwen"] = "哀温",
  [":aiwen"] = "当一名角色受到伤害时，你可以将一张牌背面朝上置于牌堆顶，令此伤害-1，然后其本回合下次受到伤害时，你防止此伤害，改为失去1点体力。",
  ["$aiwen1"] = "瑞士有句俗语，“我为人人，人人为我”。说的就是我们呢！",
  ["$aiwen2"] = "不行~不行不行~",
  ["&aiwen"] = "选择一张牌背面朝上置于牌堆顶",
  ["#aiwenA"] = "“%arg”效果触发，此伤害-1",
  ["#aiwenB"] = "“%arg”效果触发，此伤害改为失去1点体力",
  
  ["TangKK"] = "唐可可",
  ["@TangKK"] = "Love Live系列",
  ["#TangKK"] = "星振春申",
  ["~TangKK"] = "搞砸了……！",
  ["designer:TangKK"] = "bd波导&花宫瑞业",
  ["cv:TangKK"] = "Liyuu（李嘉）",
  ["illustrator:TangKK"] = "在下是子龙",
  ["%TangKK"] = "“太好听了吧~”",
  
  ["xiangyun"] = "乡韵",
  [":xiangyun"] = "<font color=\"green\"><b>回合内限一次，</b></font>当你使用基本牌或普通锦囊牌结算后，若你未因此牌造成伤害，则你可以视为使用一张相同牌名的牌。",
  ["xiangyunX"] = "视为使用相同牌名的牌",
  ["@xiangyun"] = "你可以视为使用<font color=\"#A0FFF9\"><b>【%src】</b></font>",
  ["~xiangyun"] = "请选择此牌的合法目标，若目标已确定则直接点击“确定”",
  ["$xiangyun1"] = "好厉害！",
  ["$xiangyun2"] = "太好了！",
  ["lvgui"] = "虑归",
  [":lvgui"] = "当你受到伤害后，你可以选择一项：1.将手牌摸至与手牌最多的角色相同（最多摸五张）；2.获得技能“远域”且本技能失效直到你下回合开始。",
  ["overseaNEW"] = "获得技能“远域”且此技能失效直到你下回合开始",
  ["$lvgui1"] = "情谊满满！就是这样！",
  ["$lvgui2"] = "请你永远和可可在一起！我们说好了哦！",
  ["oversea"] = "远域",
  [":oversea"] = "锁定技，当你受到其他角色的伤害时，若你不在其攻击范围内，则此伤害-1。" ,
  ["$oversea1"] = "日本有许多可爱的事物，真是太有趣了！",
  ["$oversea2"] = "接下来会结识怎样的朋友呢……真让人紧张呢。",
  ["#oversea-effect"] = "%from 的“%arg”被触发，此伤害-1",
  
  ["Ren"] = "叶月恋",
  ["@Ren"] = "Love Live系列",
  ["#Ren"] = "孑然的芝兰",
  ["~Ren"] = "对、对不起！",
  ["designer:Ren"] = "花宫瑞业",
  ["cv:Ren"] = "青山渚",
  ["illustrator:Ren"] = "青空葵",
  ["%Ren"] = "“秋叶红，歌踌躇，叶月恋。”",
  
  ["jichan"] = "继产",
  [":jichan"] = "锁定技，当你明置此人物牌时，或其他角色死亡时，你将牌堆顶两张牌背面朝上置于人物牌上，称为“遗产”。你的手牌上限+X（X为“遗产”数）。",
  ["heritage"] = "遗产",
  ["$jichan1"] = "受到妈妈的影响，我从小就与音乐结缘。",
  ["$jichan2"] = "结丘是我妈妈创立的学校。",
  ["RenJichan$"] = "image=image/animate/RenJichan.png",
  ["weiji"] = "危计",
  [":weiji"] = "<font color=\"green\"><b>出牌阶段限X次（X为你已损失的体力值且至少为1），</b></font>若你的手牌数＜体力上限，则你可以将一张“遗产”收入手牌，然后重铸任意张手牌。",
  ["$weiji1"] = "我想继续唱歌！希望你能帮忙恢复……",
  ["$weiji2"] = "那个……冒昧打扰下，我还想参加live！",
  ["weijiglobal"] = "危计",
  ["@weijiglobal"] = "你可以重铸任意张手牌",
  ["~weijiglobal"] = "选择任意张手牌→点击“确定”",
  
  ["TokaiTeio"] = "东海帝王",
  ["@TokaiTeio"] = "赛马娘",
  ["#TokaiTeio"] = "奇迹之王",
  ["designer:TokaiTeio"] = "网瘾少年",
  ["cv:TokaiTeio"] = "Machico",
  ["%TokaiTeio"] = "“无敌的帝王传说，终于要拉开序幕了哟！”",
 
  ["diwu"] = "帝舞",
  [":diwu"] = "当你于出牌阶段使用牌时，若本回合你以此法获得的牌数＜3，且本技能发动次数为奇数/偶数，则你可以从牌堆顶/底亮出3-X张牌（X为你因“三起”而不能使用的类别数）。你可以获得其中一张与使用牌类别相同的牌，并将其余的牌置入弃牌堆。",
  ["diwu_turnused"] = "帝舞已获得",  
  ["ThreeUp"] = "三起",
  [":ThreeUp"] = "当你于濒死状态未救活时，你可以选择一种未以此法选择的类别，将体力回复至1点，然后本局游戏你不能使用或打出该类别的牌。",
  ["ThreeUpBasic"] = "三起基本牌",
  ["ThreeUpEquip"] = "三起装备牌",
  ["ThreeUpTrick"] = "三起锦囊牌",
  ["nisheng"] = "逆胜",
  [":nisheng"] = "回合结束时，你可以弃置最多X张牌（X为你因“三起”而不能使用的类别数）并选择等量角色，你对这些角色依次造成1点伤害并弃置其一张牌（若其中存在无法弃牌的角色，则你在结算结束后回复1点体力）。",
  ["@nisheng"] = "你可以发动“逆胜”",
  ["~nisheng"] = "选择任意张牌→选择等量角色→点击“确定”",

  ["Ailian"] = "爱莲",
  ["@Ailian"] = "摇滚都市",
  ["#Ailian"] = "天空谎言",
  ["~Ailian"] = "比起我，你觉得还是音乐比较重要吗？",
  ["designer:Ailian"] = "奇洛",
  ["cv:Ailian"] = "野口瑠璃子",
  ["%Ailian"] = "“我要将你们一起送入地狱！”",
 
  ["beide"] = "背德",
  [":beide"] = "摸牌阶段，你可以少摸一张牌，令你本回合使用♠牌时摸一张牌，然后出牌阶段结束时，若你的手牌唯一最多，则你可以弃置一张♥牌，跳过弃牌阶段。",
  ["&beide"] = "你可以弃置一张红桃牌，跳过弃牌阶段",
  ["$beide1"] = "什么梦想什么希望，都无聊至极，所有人都给我下地狱去吧。",
  ["$beide2"] = "对手是谁都没关系，midicity的光辉马上就要消失了。",
  ["$beide3"] = "今晚正是实现我野心的日子！",
  ["jinduan"] = "禁断",
  [":jinduan"] = "每当你受到1点伤害后，你可以令伤害来源摸一张牌，随机获得其半数黑色手牌（向上取整）。然后若伤害来源为当前回合角色且其手牌数＜你，则其本回合手牌上限-1。",
  ["$jinduan1"] = "还在鬼鬼祟祟地到处打探吗？",
  ["$jinduan2"] = "软弱无力的人只要闭上嘴看看就好。",
  ["$jinduan3"] = "我还要将音乐，将乐队继续下去。",
  
  ["SilenceSuzuka"] = "无声铃鹿",
  ["@SilenceSuzuka"] = "赛马娘",
  ["#SilenceSuzuka"] = "沉默的流星",
  ["~SilenceSuzuka"] = "姆、使不上力气……明明还想接着跑的……",
  ["designer:SilenceSuzuka"] = "网瘾少年",
  ["cv:SilenceSuzuka"] = "高野麻里佳",
  ["%SilenceSuzuka"] = "“我能做到的事，只有奔跑而已。”",
  
  ["qisu"] = "奇速",
  [":qisu"] = "其他角色的准备阶段开始时，你可以判定。若判定牌为【杀】或【相爱相杀】，则你可以使用之；否则，若此牌花色未记录，则你记录此花色并进入【存在缺失】状态。",
  ["@qisu"] = "你可以对合法目标使用此判定牌，或者点击“取消”",
  ["@qisu0"] = "奇速：黑桃",
  ["@qisu1"] = "奇速：梅花",  
  ["@qisu2"] = "奇速：红桃",
  ["@qisu3"] = "奇速：方块",
  ["~qisu"] = "选择使用目标→点击“确定”",
  ["xingyun-invalid"] = "奇速失效",
  ["$qisu1"] = "即使身处最前方也要继续奔跑……直到目睹那谁也未曾见过的景色！",
  ["$qisu2"] = "最前方的景色绝不拱手相让！",
  ["xingyun"] = "星陨",
  [":xingyun"] = "锁定技，每名角色的回合开始时，若你不处于【存在缺失】状态且“奇速”记录中每种花色均有，则你清零记录，失去X点体力（X为你的体力值）。你以此法进入濒死状态时，摸3+X张牌，“奇速”失效。你的回合结束时，复原“奇速”。",
  
  ["Aien"] = "艾恩",
  ["@Aien"] = "摇滚都市",
  ["#Aien"] = "黑色怪物",
  ["~Aien"] = "曾经立下的要一同登上顶点的誓言，原来只是一场谎言吗？",
  ["designer:Aien"] = "奇洛",
  ["cv:Aien"] = "内山昂辉",
  ["%Aien"] = "“触犯言灵禁忌的罪孽，比地狱的深渊还要深重！”",
  
  ["anyu"] = "暗喻",
  [":anyu"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你使用或打出黑色牌时，你可以选择一项：1.弃置X张牌，对当前回合角色造成1点雷电伤害（X为其空置的装备栏的个数）；2.摸X张牌，弃置其中的红色牌。",
  ["$anyu1"] = "触犯言灵禁忌的罪孽，比地狱的深渊还要深重！",
  ["$anyu2"] = "升华至炼狱的恐怖，现在就让你体会一下！",
  ["anyuDamage"] = "弃置X张牌，对当前回合角色造成1点雷电伤害",
  ["anyuDraw"] = "摸X张牌，弃置其中的红色牌",
  
  ["Liko"] = "十六夜理子",
  ["illustrator:Liko"] = "XING",
  ["@Liko"] = "魔法使光之美少女",
  ["#Liko"] = "魔法天使",
  ["~Liko"] = "因为、我已经施下魔法了——",
  ["designer:Liko"] = "FlameHaze",
  ["cv:Liko"] = "堀江由衣",
  ["%Liko"] = "“两个人的魔法！Cure Magical！”",

  ["jinfa"] = "金法",
  ["jinfa$"] = "image=image/animate/jinfa.png",
  [":jinfa"] = "当你使用普通锦囊牌指定目标后，你可以令一名不是此牌目标的其他角色选择是否将一张手牌当此牌使用，若其选择是且转化牌为红色，则你于此转化牌结算后弃置一张牌。",
  ["$jinfa"] = "无穷无尽的波纹~",
  ["&jinfa"] = "你可以对一名符合要求的其他角色发动“金法”，或者点击“取消”",  
  ["@jinfa"] = "你可以将一张手牌当<font color=\"#BA8EC1\"><b>【%src】</b></font>使用，或者点击“取消”",
  ["~jinfa"] = "金法",
  ["xunfei"] = "寻翡",
  [":xunfei"] = "<font color=\"green\"><b>每轮每名与你势力相同的角色限一次，</b></font>其准备阶段开始时，若你手牌中没有锦囊牌，则你可以随机获得牌堆中的一张锦囊牌。若此牌为延时锦囊牌，则你摸一张牌，否则你可以交给其一张牌。",
  ["$xunfei"] = "嗯！你知道波纹石？",
  ["@xunfei_give"] = "请交给其一张牌",
  
  ["Tsubomi"] = "花咲蕾",
  ["illustrator:Tsubomi"] = "堆糖同人",
  ["@Tsubomi"] = "HeartCatch光之美少女",
  ["#Tsubomi"] = "花蕾天使",
  ["~Tsubomi"] = "咿——（哭）已经撑不住了——（哭）",
  ["designer:Tsubomi"] = "FlameHaze",
  ["cv:Tsubomi"] = "水树奈奈",
  ["%Tsubomi"] = "“大地上盛开的一朵花，Cure Blossom！”",
  
  ["lianhui"] = "恋卉",
  [":lianhui"] = "①当你不因使用或打出而失去♣牌时，你可以摸一张牌。②结束阶段开始时，你可以展示手牌，然后令最多X名角色各摸一张牌（X为其中♣牌数）。",
  ["&lianhui"] = "你可以选择最多 %src 名角色各摸一张牌",
  ["$lianhui"] = "有了！是四叶草，花语是幸福。",
  ["shixin"] = "拾心",
  [":shixin"] = "<font color=\"green\"><b>每回合限两次，</b></font>当你使用或打出非♣牌结算后，你可以弃置一张牌，令一名其他角色摸一张牌。若本次为你本回合首次发动本技能且其与你势力相同，则其可以将最多两张手牌交给一名与你势力相同的角色。",
  ["&shixinDraw"] = "选择一名其他角色摸一张牌",
  ["&shixin"] = "你可以交给 %src 1~2张手牌，或者点击“取消”",
  ["&shixinChoose"] = "选择一名与 %src 势力相同的角色",
  ["$shixin"] = "果断拒绝掉了~我可能也有所改变了呢~",

  ["Makoto"] = "剑崎真琴",
  ["@Makoto"] = "心跳！光之美少女",
  ["#Makoto"] = "剑天使",
  ["~Makoto"] = "咦耶~~~脚~脚麻了（哭）",
  ["designer:Makoto"] = "FlameHaze",
  ["cv:Makoto"] = "宫本佳那子",
  ["illustrator:Makoto"] = "稚代★レインボー生足ウェーブ",
  ["%Makoto"] = "“勇气之刃！Cure Sword！”",

  ["yaojian"] = "耀剑",
  [":yaojian"] = "<font color=\"green\"><b>每回合限一次，</b></font>你可以将任意张手牌当无视次数的【杀】使用。此【杀】击中目标时，你可以令目标角色依次弃置等量张装备区和判定区的牌。",
  ["$yaojian"] = "闪耀吧！Holy Sword！",
  ["tonghua"] = "同花",
  [":tonghua"] = "与你势力相同的角色的结束阶段开始时，若本回合因使用而进入弃牌堆的牌中至少有3张组成同花，则你可以摸两张牌，若至少有3张组成同花顺，则你可以额外发动一次无距离限制的“耀剑”，并对一名角色造成1点伤害。",
  ["$tonghua"] = "把我们的力量集中到Cure Heart的身上！",
  ["@yaojian"] = "你可以发动一次无距离限制的“耀剑”",
  ["~yaojian"] = "选择任意张手牌→选择【杀】的目标→点击“确定”",
  ["~tonghua"] = "选择一名角色对其造成伤害",

  ["Eli"] = "绚濑绘里",
  ["@Eli"] = "Love Live系列",
  ["#Eli"] = "聪明可爱小绘里",
  ["~Eli"] = "……好遗憾哦。",
  ["designer:Eli"] = "花宫瑞业",
  ["cv:Eli"] = "南条爱乃",
  ["illustrator:Eli"] = "彩虹之翼",
  ["%Eli"] = "“哈啦咻！”",
  
  ["shouwu"] = "授舞",
  [":shouwu"] = "出牌阶段限一次，你可以展示任意张不同牌名的黑色手牌并选择等量名没有技能“雪晕”的角色，这些角色获得技能“雪晕”直到其回合结束。",
  ["$shouwu1"] = "能获邀在校庆上演出，真是荣幸之至。我们一定要加紧练习才行。",
  ["$shouwu2"] = "为了不输给这些竞争对手，我们一定要继续勇攀高峰。",
  ["xianju"] = "先举",
  [":xianju"] = "锁定技，每名角色于每轮第一次造成冰冻伤害后，你摸一张牌。",
  ["$xianju1"] = "今后，我会努力争取更大的成长。这样才能获得你更多的支持嘛。",
  ["$xianju2"] = "作为校园偶像，认真的态度可是绝对有保证的哦♪",
  ["xueyun"] = "雪晕",
  [":xueyun"] = "你可以将黑色牌当无视次数的冰【杀】使用。你以此法使用牌时，失去本技能。",
  ["xueyunglobal"] = "雪晕",
  ["$xueyun1"] = "我设计了冰雪女王主题的芭蕾舞。这应该也能成为生日的回忆吧。",
  ["$xueyun2"] = "好美的snow stage……啊哈，透过这片景色，也能感受到冬日气息呢。",  
  
  ["Ai"] = "宫下爱",
  ["@Ai"] = "Love Live系列",
  ["#Ai"] = "天才级快乐",
  ["~Ai"] = "呜呜……真是太沮丧了～",
  ["designer:Ai"] = "花宫瑞业",
  ["cv:Ai"] = "村上奈津实",
  ["illustrator:Ai"] = "ootato",
  ["%Ai"] = "“爱你们哟，因为我是爱！什么的~”",
  
  ["lamei"] = "辣妹",
  [":lamei"] = "锁定技，当你成为【节能主义】的目标时，若存在体力值≤你的其他角色，则取消之。",
  ["$lamei1"] = "自从开始当校园偶像后，爱姐我的世界就变得越来越开阔了，超开心的！",
  ["$lamei2"] = "耶~！夏天来啦~！爱姐最喜欢的季节就是夏天了！太兴奋啦~！",
  ["youai"] = "友爱",
  [":youai"] = "出牌阶段限一次，你可以令一名其他角色摸1+X张牌（X为其已损失的体力值），然后令你或其弃置其区域内等量张牌，你可以使用其中一张红色牌。你可以令其拥有技能“友爱（纵横）”直到其下回合结束<font color=\"#FF5800\"><b>（出牌阶段限一次，你可以令一名其他角色摸一张牌，然后令你或其弃置其区域内一张牌）</b></font>。",
  ["youaiCard"] = "友爱",
  ["youaiSelf"] = "你选择弃置的牌",
  ["youaiTarget"] = "其选择弃置的牌",
  ["$youai1"] = "你看到不曾看过的景色了吗？我会让你看到更多、更多不同的景色！",
  ["$youai2"] = "下次我陪你一起去买泳装吧。不能只让我们穿得这么可爱，你也要注意打扮才行啊！",
  ["@youai"] = "你可以使用此<font color=\"#FF5800\"><b>【%src】</b></font>",
  ["~youai"] = "请选择此牌的合法目标，若目标已确定则直接点击“确定”",
  ["youaiManoeuvre"] = "令其拥有技能“友爱（纵横）”直到其下回合结束", 
  ["youaizongheng"] = "友爱",
  [":youaizongheng"] = "出牌阶段限一次，你可以令一名其他角色摸一张牌，然后令你或其弃置其区域内一张牌。",
  ["youaizonghengCard"] = "友爱",

  ["Miku"] = "初音未来",
  ["@Miku"] = "Vocaloid",
  ["#Miku"] = "公主殿下",
  ["designer:Miku"] = "clannad最爱",
  ["cv:Miku"] = "藤田咲",
  ["%Miku"] = "“把你mikumiku掉~”",
  ["illustrator:Miku"] = "フカヒレ",

  ["geji"] = "歌姬",
  [":geji"] = "①你可以将一张手牌当【音】使用，此牌花色须与你本回合使用过的牌花色均不同。此牌结算后，本回合你不能使用此花色的牌。②你使用的【音】结算后，你可以令一名与你势力相同的角色摸一张牌。",
  ["gongzhu"] = "公主",
  [":gongzhu"] = "①当你成为【杀】的目标时，与你势力相同的其他角色可以将此【杀】转移给其。②锁定技，你的手牌上限+X（X为与你势力相同的角色数）。",
  ["&geji"] = "选择一名与你势力相同的角色摸一张牌",
  ["gongzhu_defend"] = "公主：代替成为目标",
  
  ["Yayoi"] = "黄濑弥生",
  ["@Yayoi"] = "Smile光之美少女",
  ["#Yayoi"] = "和平天使",
  ["~Yayoi"] = "已经分出胜负了吧...求你了，把我的漫画还给我。",
  ["designer:Yayoi"] = "FlameHaze",
  ["cv:Yayoi"] = "金元寿子",
  ["illustrator:Yayoi"] = "XING/シン",
  ["%Yayoi"] = "“闪闪发光，剪刀石头布♪ Cure Peace！”",

  ["caiquan"] = "猜拳",
  [":caiquan"] = "出牌阶段开始时，你可以与一名角色拼点。若你赢，则你可以选择一项：1.获得两张拼点牌；2.获得其一张牌。选择完成后，本回合“召雷”判定牌生效时，你可以打出一张牌替换之；若你没赢，则你本回合手牌上限-1。",
  ["$caiquan1"] = "闪闪发光，剪刀石头布！",
  ["$caiquan2"] = "今天的闪闪猜拳出的布呢。", 
  ["&caiquan"] = "选择一名拼点目标", 
  ["caiquan_pdcards"] = "获得两张拼点牌",
  ["caiquan_tcard"] = "获得目标的一张牌",
  ["zhaolei"] = "召雷",
  ["zhaolei$"] = "image=image/animate/zhaolei.png",
  [":zhaolei"] = "①结束阶段开始时，你可以判定，从你开始顺时针计数至该牌点数，终止角色受到你的1点雷电伤害。②锁定技，防止你受到的雷电伤害。",
  ["$zhaolei1"] = "Peace Thunder",
  ["$zhaolei2"] = "Peace Thunder Hurricane。",

  ["YSetsuna"] = "优木雪菜",
  ["@YSetsuna"] = "Love Live系列",
  ["#YSetsuna"] = "炽热野望",
  ["~YSetsuna"] = "为什么这样……",
  ["designer:YSetsuna"] = "花宫瑞业",
  ["cv:YSetsuna"] = "楠木灯→林鼓子",
  ["illustrator:YSetsuna"] = "ckst",
  ["%YSetsuna"] = "“和我一起创造一个充满喜欢的世界吧！”",

  ["chixin"] = "炽心",
  [":chixin"] = "①出牌阶段限一次，你可以将一张红色牌当火【杀】、【异端审判】或【天破壤碎】使用，若你的手牌最多，则此牌不能被响应。②若此人物牌已明置，则你的火【杀】和【异端审判】目标上限+1。",
  ["$chixin1"] = "呜～我心里“喜欢”的情绪快满出来了啦～！好想开live！",
  ["$chixin2"] = "被喜欢的心意环绕，真的好幸福……身体会变得暖呼呼的！",
  ["#chixinEffect"] = "炽心",
  ["jinhun"] = "烬魂",
  [":jinhun"] = "限定技，当你于濒死状态未救活时，你可以移除此人物牌，将体力上限和体力值调整为1，然后你可以令一名其他角色从牌堆或弃牌堆中获得一张火【杀】、【异端审判】或【天破壤碎】。",
  ["&jinhun"] = "你可以选择一名其他角色获得随机牌",
  ["@jinhun"] = "烬魂",
  ["$jinhun1"] = "我不是孤单一人，你为我带来了莫大的勇气……",
  ["$jinhun2"] = "独自努力的时候，我根本无法想象……自己竟会如此依赖他人。", 
  ["jinhun$"] = "image=image/animate/jinhun.png",

  ["Haru"] = "青天国春",
  ["@Haru"] = "SHINE POST",
  ["#Haru"] = "怀璧其罪",
  ["~Haru"] = "各位……对不起……但是……谢谢……",
  ["designer:Haru"] = "花宫瑞业",
  ["cv:Haru"] = "铃代纱弓",
  ["illustrator:Haru"] = "栉月",
  ["%Haru"] = "“就交给小春吧！”",

  ["yibing"] = "异禀",
  [":yibing"] = "锁定技，准备阶段开始时，你令以下选项中至少一项本回合+1：1.摸牌阶段摸牌数；2.使用【杀】的次数；3.手牌上限。",
  ["$yibing1"] = "没关系，有雪音酱在，我完美的计划就能执行了~",
  ["$yibing2"] = "我好像是有当偶像的天赋，比谁都能先记住动作，比谁都能跳得更完美，仅此而已。", 
  ["#yibingX"] = "摸牌阶段摸牌数",
  ["#yibingA"] = "%from 的“%arg”被触发，本回合摸牌阶段摸牌数+1",
  ["#yibingY"] = "使用【杀】的次数",
  ["#yibingB"] = "%from 的“%arg”被触发，本回合使用【杀】的次数+1",
  ["#yibingZ"] = "手牌上限",
  ["#yibingC"] = "%from 的“%arg”被触发，本回合手牌上限+1",
  ["neifan"] = "内反",
  [":neifan"] = "锁定技，其他角色的出牌阶段结束时，若此人物牌已明置，且你上一次“异禀”选择的选项数≥其多于你的手牌数，则其选择一项：1.交给你一张牌；2.其移除副将，你移除此人物牌。",
  ["neifanExchange"] = "交出一张牌",
  ["@neifan_give"] = "“内反”发动，请交给 %src 一张牌",
  ["neifanRemove"] = "移除双方副将",
  ---["&neifan"] = "请选择一名角色，其移除副将", 
  ["$neifan1"] = "（杏夏）TiNgS的C位是春，没有我的歌也不要紧。",
  ["$neifan2"] = "（雪音）春不认真也不尽全力，一直在骗我们吗！",

  ["Dia"] = "黑泽黛雅",
  ["@Dia"] = "Love Live系列",
  ["#Dia"] = "雍容华贵",
  ["~Dia"] = "怎么会——肯定有什么地方搞错了！",
  ["designer:Dia"] = "花宫瑞业",
  ["cv:Dia"] = "小宫有纱",
  ["illustrator:Dia"] = "黑濑结季",
  ["%Dia"] = "“噗噗——desuwa！”",

  ["wangzu"] = "望族",
  [":wangzu"] = "锁定技，与你势力相同的角色的弃牌阶段开始时，你令其♦牌不计入本回合的手牌上限。",
  ["$wangzu1"] = "之所以和露比一起推出沼津问答题，也是为了让大家进一步了解沼津。",
  ["$wangzu2"] = "通过查询沼津的历史与风土人情，加深了我们对故乡的理解。",
  ["yayi"] = "雅仪",
  [":yayi"] = "出牌阶段限一次，你可以对一名其他角色发起“指令”。若其执行，则其视为使用无距离限制的【杀】；若其不执行，则你获得其一张牌。",
  ["yayiCard"] = "雅仪",
  ["docommand_yayiCard"] = "雅仪",
  ["&yayi_slash"] = "选择一名其他角色，你视为对其使用无距离限制的【杀】",
  ["$yayi1"] = "黑泽家的家训是“永远的赢家”，请大家记住。",
  ["$yayi2"] = "婆娑的衣服我能够完美诠释呢，哼哼，天生丽质嘛！",

  ["DaiwaScarlet"] = "大和赤骥",
  ["@DaiwaScarlet"] = "赛马娘",
  ["#DaiwaScarlet"] = "Miss.Perfect",
  ["designer:DaiwaScarlet"] = "网瘾少年",
  ["cv:DaiwaScarlet"] = "木村千咲",
  ["%DaiwaScarlet"] = "“目标，无论何时都是第一名！除此之外我都不能接受。”",
 
  ["aoji"] = "傲骥",
  [":aoji"] = "<font color=\"green\"><b>每回合限一次，</b></font>当你对其他角色造成伤害后，或当你受到其他角色的伤害后，你可以与其拼点，若你赢，则你选择一项：1.其失去1点体力；2.选择另一名其他角色，双方各摸一张牌并拼点，若存在赢者，则赢者对没赢者造成1点伤害。",
  ["aojiLoseHp"] = "令其失去1点体力",
  ["aojiPD"] = "令第三者与其拼点",
  ["&aoji3"] = "选择另一名其他角色与 %src 拼点",
  ["tuyou"] = "图优",
  [":tuyou"] = "与你势力相同的角色的红色拼点牌亮出后，你可以展示牌堆顶的一张牌，选择一项：1.令一名角色获得展示的牌；2.令此拼点牌点数+X（X为展示的牌的点数）。若展示的牌为红色，则你可以依次执行两项。",
  ["&tuyou"] = "你可以对一名角色发动“图优”，其拼点牌点数可能增加",
  ["&tuyou_obtain"] = "选择一名角色获得<font color=\"#E73472\"><b>【%src】</b></font>",
  ["tuyouObtain"] = "令一名角色获得展示的牌",
  ["tuyouAddNum"] = "增加拼点牌的点数",
  ["$tuyouEffect"] = "%from 的拼点牌点数视为 %arg",

  ["Asahina"] = "朝日奈未来",
  ["@Asahina"] = "魔法使光之美少女",
  ["#Asahina"] = "奇迹天使",
  ["designer:Asahina"] = "FlameHaze",
  ["cv:Asahina"] = "高桥李依",
  ["illustrator:Asahina"] = "振川ゆきの",
  ["%Asahina"] = "“你刚才是不是说（人或事）？！”",
  ["~Asahina"] = "嗯，再见啦！",

  ["yinfa"] = "银法",
  [":yinfa"] = " <font color=\"green\"><b>每回合限一次，</b></font>当目标包含你的锦囊牌结算后，你可以令一名角色选择一项执行：1、使用一张与此牌花色相同的基本牌或装备牌（不计入次数）。2、将手牌调整至X，X为你的体力上限-1。 ",---------（“迹见”已发动则改为‘当你使用锦囊牌后'）
 --- ["@yinfa1"] = "其视为使用以其为唯一目标的【魔法变身】",
  ["&yinfa"] = "选择执行“银法”效果的角色",
  ["@yinfa_use"] = "银法：使用一张该花色基本牌或装备牌（不计次数），否则将手牌调整至其体力上限-1",
  ["$yinfa1"] = "Diamond！Miracle Magical Jewelry！",
  ["yinfa1$"] = "image=image/animate/yinfa1.png",
  ---["@yinfa2"] = "其弃置三张牌，然后将手牌摸至X（X为你的体力上限-1）",
  ["$yinfa2"] = "Ruby！Miracle Magical Jewelry！",
  ["yinfa2$"] = "image=image/animate/yinfa2.png",
  ["$yinfa3"] = "Sapphire！Miracle Magical Jewelry！",
  ["yinfa3$"] = "image=image/animate/yinfa3.png",
  ["$yinfa4"] = "Topaz！Miracle Magical Jewelry！",
  ["yinfa4$"] = "image=image/animate/yinfa4.png",
  ["$yinfa5"] = "Cure Up Rapapa！",
  ["jijian"] = "迹见",
  ["@jijian"] = "迹见",
  ["jijian$"] = "image=image/animate/jijian.png",
  ["jijianglobal"] = "迹见：回合数记录",
  [":jijian"] = "限定技，此人物存在于场的第四个准备阶段开始，你可以加1点体力上限并修改“银法”:‘<font color=\"#FF5800\"><b>每回合限一次，当目标包含你的锦囊牌结算后</b></font>’改为‘<font color=\"#FF5800\"><b>当你使用锦囊牌后</b></font>’。",
  ["$jijian"] = "理子语：“未来~”；未来语：“理子*3我可想死你了！*2”",
 --- ["&jijian"] = "选择1~3名角色各摸一张牌",

  ["Shioriko"] = "三船栞子",
  ["@Shioriko"] = "Love Live系列",
  ["#Shioriko"] = "翠色金丝雀",
  ["~Shioriko"] = "下次一定会吸取这一次的教训。",
  ["designer:Shioriko"] = "花宫瑞业",
  ["cv:Shioriko"] = "小泉萌香",
  ["illustrator:Shioriko"] = "オク",
  ["%Shioriko"] = "“再度将发饰紧紧系起，绽放出光芒苍翠如翡。”",

  ["xinxing"] = "心省",
  [":xinxing"] = "每名角色的结束阶段开始时，若你本回合受到过伤害或失去过体力，则你可以选择最多X名与你势力相同的角色（X为你已损失的体力值），依次对这些角色选择一项：1.其摸一张牌；2.弃置其判定区内的一张牌。",
  ["&xinxing"] = "请选择最多 %src 名角色作为“心省”的目标",
  ["xinxingThrow"] = "弃置其判定区内的一张牌",
  ["$xinxing1"] = "天气这么冷，就很想找个人互相依偎，这种心情我也稍微明白了。……咦？不是的！我不是那个意思……！",
  ["$xinxing2"] = "我很想看看，跨越犹豫迷茫后的未来里……究竟有什么？",
  ["yanlv"] = "严律",
  [":yanlv"] = "出牌阶段限一次，你可以弃置X张手牌并对攻击范围内的一名角色造成1点伤害（X为其已损失的体力值，为0则不弃），然后选择一项：\n1.若以此法弃置了牌，则将弃置的牌当【闪耀祭典】使用；\n2.你与其各摸等同于自己已损失体力值的牌；\n3.失去1点体力。",
  ["yanlvA"] = "转化【闪耀祭典】",
  ["yanlvB"] = "你与其分别摸牌",
  ["yanlvC"] = "失去1点体力",
  ["$yanlv1"] = "阳光的确相当毒辣，但是心静自然凉哦。",
  ["$yanlv2"] = "最近天气一直都很炎热，你有没有好好吃饭呢？你要是倒下的话我会很伤脑筋的……所以我有点担心你。",

  ["Tooru"] = "浅仓透",
  ["@Tooru"] = "偶像大师系列",
  ["#Tooru"] = "不惊的明镜",
  ["~Tooru"] = "嘿嘿，还很长哦，人生。",
  ["designer:Tooru"] = "花宫瑞业",
  ["cv:Tooru"] = "和久井优",
  ["illustrator:Tooru"] = "なまま三兄弟",
  ["%Tooru"] = "“能像这样相遇……我，很开心。”",

  ["jiaoxin"] = "交心",
  [":jiaoxin"] = "当你受到其他角色的伤害后，你可以令其选择一项：1.弃置所有黑色基本牌或锦囊牌（没有则不弃）；2.令你与其交换手牌，然后其中手牌唯一较少的角色摸两张牌。 ",
  ["jiaoxinDiscard"] = "弃置所有黑色基本牌或锦囊牌",
  ["jiaoxinExchange"] = "交换手牌，然后其中手牌唯一较少的角色摸两张牌",
  ["$jiaoxin1"] = "诶，有没有信赖……是说信赖制作人吗？嗯……",
  ["$jiaoxin2"] = "今天，相互夸奖对方努力的地方吧。制作人先开始。",
  ["xiuxing"] = "修性",
  [":xiuxing"] = "出牌阶段限一次，你可以令一名角色记录其此时手牌数，然后出牌阶段结束时，其将手牌摸或弃置至记录值（最多摸至5张、弃5张牌）。",
  ["$xiuxing1"] = "各种事情都辛苦了——诶？是还要我再说点什么吗？",
  ["$xiuxing2"] = "命运，会相信吗？我……我或许不明白呢。",
  ---["&xiuxing"] = "你可以发动“修性”，选择一名角色记录其手牌数",
  ["xiuxingZero"] = "修性[0]",

  ["Prism"] = "虹之丘真白",
  ["@Prism"] = "Hanging sky! 光之美少女",
  ["#Prism"] = "棱镜天使",
  ["designer:Prism"] = "FlameHaze",
  ["cv:Prism"] = "加隈亚衣",
  ["illustrator:Prism"] = "XING/シン",
  ["%Prism"] = "“ターイム！”",
  ["~Prism"] = "但是，我没法像大家一样有“我就要做这个”的心情。",

  ["shangyuan"] = "伤援",
  [":shangyuan"] = "其他角色的出牌阶段开始时，若其在你攻击范围内，则你可以对其使用一张【杀】，然后其摸一张牌且其本回合攻击范围和使用【杀】的次数+1。",
  ["shangyuan1$"] = "image=image/animate/shangyuan1.png",
  ["shangyuan2$"] = "image=image/animate/shangyuan2.png",
  ["@shangyuan-slash"] = "使用一张【杀】",
  ["$shangyuan1"] = "等我一下，索拉酱。",
  ["$shangyuan2"] = "Sky!",
  ["$shangyuan3"] = "呲嘤~，哒",
  ["chaoshi"] = "超识",
  [":chaoshi"] = "①<font color=\"green\"><b>每回合限两次，</b></font>当你使用牌后，若手牌中存在与此牌花色相同的牌，则你可以摸一张牌。②<font color=\"green\"><b>每回合限一次，</b></font>当你于回合外获得牌后，若手牌数＞区域内花色数，则你弃置一张牌或进入【存在缺失】状态。",
  ["#chaoshist"] = "超识②", 
  ["chaoshi_js"] = "超识",
  ["@chaoshi"] = "弃置1张牌否则进入【存在缺失】状态",
  ["$chaoshi1"] = "唉？怎么可能……",
  ["$chaoshi2"] = "大……大概你不会相信刚才发生的事，但是先听我！",
  ["$chaoshi3"] = "你也太赖皮了吧!?", 

  ["real|idol"] = "现世/偶像",
  ["science|idol"] = "科学/偶像",
  ["game|idol"] = "游戏/偶像",
  ["magic|idol"] = "魔法/偶像",

  ["Fuuka"] = "宫泽风花",
  ["@Fuuka"] = "白沙的水族馆",
  ["#Fuuka"] = "温玉润心",
  ["~Fuuka"] = "真美，这里能看到很多在东京看不到的星星。",
  ["designer:Fuuka"] = "花宫瑞业",
  ["cv:Fuuka"] = "逢田梨香子",
  ["illustrator:Fuuka"] = "在下是子龙",
  ["%Fuuka"] = "“下沉的梦，漂浮的梦，动起来的梦……”",
  
  ["moliang"] = "默良",
  [":moliang"] = "当一张牌结算后，你可以选择一名没有阴阳鱼标记、在此结算中受到过此牌的伤害且与你势力相同的角色，其获得1枚阴阳鱼标记。然后若你在此结算中受到过此牌的伤害，则你可以重铸一张手牌。",
  ["@moliang"] = "你可以弃置1张手牌并摸1张牌，或者点击“取消”",
  ["&moliangFish"] = "选择一名可选角色，其获得一枚阴阳鱼标记",
  ["&moliang"] = "你可以重铸一张手牌",
  ["$moliang1"] = "我想来和你聊聊，想多了解了解你。",
  ["$moliang2"] = "你愿意告诉我这些，我很开心。",
  ["$moliang3"] = "现在她应该正为了理解你的辛苦，在体验带小孩。",
  ["$moliang4"] = "能行的，我们要相信它，相信它能独自克服。",
  ["$moliang5"] = "各位~大家好——好痛！",
  ["FuukaMoliang$"] = "image=image/animate/FuukaMoliang.png",
  ["yuanshu"] = "缘抒",
  [":yuanshu"] = "锁定技，当你受到伤害后，你与一名角色各摸一张牌，然后本回合你与其受到＞1点的伤害时，防止此伤害。",
  ["$yuanshu1"] = "你藏在这种角落里，别人都看不到你了。和我一样呢。",
  ["$yuanshu2"] = "我的梦想虽然结束了，但我还能为别人的梦想出一份力。",
  ["$yuanshu3"] = "触摸能够促进了解~",
  ["$yuanshu4"] = "奶奶给你的，你饿了吧？",
  ["$yuanshu5"] = "等我有了新的梦想，你能再来帮我吗？",
  ["&yuanshu"] = "选择一名角色，你与其各摸一张牌",
  ["#yuanshu"] = "“%arg”效果触发，%from 造成的 %arg2 点伤害被防止",
  ["FuukaYuanshu$"] = "image=image/animate/FuukaYuanshu.png",

  ["Arisa"] = "鸣护艾丽莎",
  ["@Arisa"] = "魔法禁书目录",
  ["#Arisa"] = "圣人判定",
  ["designer:Arisa"] = "FlameHaze",
  ["cv:Arisa"] = "三泽纱千香",
  ["%Arisa"] = "“无论你在打什么主意，我的奇迹之歌都将超越它！”",
  ["~Arisa"] = "（纯音乐）",

  ["$lvge1"] = "命运的交响曲~",
  ["$lvge2"] = "我要唱歌~现在收集希望~",
  ["$quming"] = "我以前好像也遇过什么大事故。",
  ["$yangming"] = "我的歌声是为了那些单纯想来享受的人们唱的。",
  ["lvge"] = "律歌",
  ["lvge$"] = "image=image/animate/lvge.png",
  [":lvge"] = "出牌阶段限一次，若你有副将，则你可以移动场上0~X张牌（X为你的体力值且最多为3），移除副将，然后你可以弃置任意张牌，摸等量的牌，若你以此法手牌变为最多，则失去1点体力。",
  ["&lvgeA"] = "你可以选择一名装备区或判定区内有牌的角色，或点击“取消”结束",
  ["lvgeCard"] = "律歌",
  ["&lvgeB"] = "选择另一名角色，将选择的牌移动给其",
  ["@lvge"] = "你可以弃置任意张牌，摸等量的牌，若你以此法手牌变为最多，则失去1点体力",
  ["lvgezhiheng"] = "律歌：制衡",
  ["~lvge"] = "选择任意张牌→点击“确定”",
  ["quming"] = "曲命",
  [":quming"] = "主将技，你计算体力上限减少1个单独的阴阳鱼。<font color=\"green\"><b>每名角色限一次，</b></font>当一名角色进入濒死状态时，若你没有副将，则你可以变更副将，令其回复体力至1点。",
  ["yangming"] = "扬名",
  [":yangming"] = "副将技，当你移除此人物牌时，你可以令最多X名角色各摸一张牌（X为你装备区内的牌数），然后这些角色各交给你一张牌。",
  ["yangming:Arisa"] = "你可以点击“确定”，发动技能“扬名”。或者点击“取消”",
  ["&yangming"] = "请选择最多 %src 名角色作为“扬名”的目标",
  ["&yangming_give"] = "“扬名”发动，请交给 %src 一张牌",

  ["Nozomi"] = "樱井望",
  ["@Nozomi"] = "公主连结！Re:Dive",
  ["#Nozomi"] = "偶像应援",
  ["designer:Nozomi"] = "网瘾少年",
  ["cv:Nozomi"] = "日笠阳子",
  ["%Nozomi"] = "“来吧，演唱会要开始了！”",

  ["yueyin"] = "悦音",
  [":yueyin"] = "<font color=\"green\"><b>每回合限一次，</b></font>一名角色成为【杀】的目标时，若使用者和当前回合角色均不为你，则你可以选择一项：1.将一张锦囊牌或装备牌当【音】对自己使用，若为装备牌，则你成为此【杀】的目标并取消其他所有目标；2.将手牌摸至体力值，然后交给其一张手牌。",
  ["@yueyin"] = "你可以转化【音】，或者点击“取消”将手牌摸至体力值",
  ["~yueyin"] = "选择一张锦囊牌或装备牌→点击“确定”",
  ["@yueyin_give"] = "请交给 %src 一张手牌",
   
  ["AmouKanade"] = "天羽奏",
  ["@AmouKanade"] = "战姬绝唱",
  ["#AmouKanade"] = "双翼",
  ["designer:AmouKanade"] = "FlameHaze",
  ["cv:AmouKanade"] = "高山南",
  ["illustrator:AmouKanade"] = "3s",
  ["%AmouKanade"] = "“请不要放弃活下去！”",
  ["~AmouKanade"] = "（纯音乐）",

  ["$juexiang1"] = "给你们最棒的……（武器碎裂声）……绝唱。",
  ["$juexiang2"] = "Gatrandis babel ziggurat endenal...",
  ["juexiang"] = "绝响",
  [":juexiang"] = "结束阶段结束时，你可以展示牌堆顶1+X张牌（X为你已损失的体力值），选择是否获得其中所有基本牌并弃置其余牌。若你选择是，则你失去1点体力，执行一个额外的出牌阶段。",
  ["@juexiang1"] = "获得其中所有基本牌并弃置其余牌，失去1点体力，执行一个额外的出牌阶段",
  ["#newphase"] = "%from 因为技能“绝响”，而获得一个额外的出牌阶段",
  ["huyi"] = "护翼",
  [":huyi"] = "锁定技，若你已受伤，则你使用【杀】的次数+1，计算与其他角色的距离-X（X为你已损失的体力值）。",

  ["Umi"] = "园田海未",
  ["@Umi"] = "Love Live系列",
  ["#Umi"] = "爱神之箭",
  ["~Umi"] = "应该是练习不够吧……",
  ["designer:Umi"] = "花宫瑞业",
  ["cv:Umi"] = "三森铃子",
  ["illustrator:Umi"] = "彩虹之翼",
  ["%Umi"] = "“Love Arrow Shoot!”",

  ["lixun"] = "厉训",
  [":lixun"] = "准备阶段开始时，你可以将你场上的一张牌当目标上限为X的冰【杀】使用（X为你场上的牌数），然后你摸一张牌且攻击范围永久+1（最多+4）。",
  ["@lixun"] = "你可以发动“厉训”，转化一张冰【杀】",
  ["~lixun"] = "选择若干名其他角色作为目标→点击“确定”",
  ["lixun_weapon"] = "攻击范围+",
  ["$lixun1"] = "你有没有看到穗乃果和小鸟？真不知她们跑去哪里了……",
  ["$lixun2"] = "你说正月想要好好休息下？不可以，正因为是年初，所以才不能疏于训练呢。好了，我们走吧。",
  ["gongdao"] = "弓道",
  [":gongdao"] = "阵法技，与你处于同一队列的角色的回合开始时，其攻击范围改为其中队列的最大值至回合结束。",
  ["gongdaoAttackRange"] = "弓道修改范围",
  ["$gongdao1"] = "在握紧弓的那瞬间，就感觉心如止水。",
  ["$gongdao2"] = "只要射出这根箭……你的眼里就会变得只有我了吧？",

  ["Hanamaru"] = "国木田花丸",
  ["@Hanamaru"] = "Love Live系列",
  ["#Hanamaru"] = "卷识晦思",
  ["~Hanamaru"] = "失败了——对不起——！",
  ["designer:Hanamaru"] = "花宫瑞业",
  ["cv:Hanamaru"] = "高槻加奈子",
  ["illustrator:Hanamaru"] = "KOUGI",
  ["%Hanamaru"] = "“未来zura~”",

  ["baoshix"] = "饱食",
  [":baoshix"] = "你可以将一张手牌当做你本轮未以此法使用过的【桃】、【酒】或食物牌使用，然后本技能转化所需牌数+1直到你失去最后的牌。",
  ["baoshix_jishu"] = "饱食计数+",
  ["peach_use"] = "使用桃",
  ["analeptic_use"] = "使用酒",
  ["$baoshix1"] = "肚子饿了zura……要不要一起去吃点什么？",
  ["$baoshix2"] = "既然来到了函馆，当然要享尽当地美食zura～♪",
  ["changyue"] = "常阅",
  ["#changyues"] = "常阅",
  [":changyue"] = "<font color=\"green\"><b>每回合限一次，</b></font>其他角色使用普通锦囊牌结算后，你可以交给其一张相同花色的牌获得之；你使用普通锦囊牌结算后，你可以获得一名其他角色场上一张相同花色的牌，令其获得之。",
  ["@changyue"] = "选择一张与此牌花色相同的牌",
  ["changyue-invoke"] = "选择一名其他角色，获得其区域内与此牌花色相同的牌",
  ["$changyue1"] = "咱非常喜爱图书委员的工作。能待在书本环绕的空间里，真是一种幸福zura。",
  ["$changyue2"] = "千歌、鞠莉，这本书的知识应该有用。啊……全都睡着了zura。",

  ["Vodka"] = "伏特加",
  ["@Vodka"] = "赛马娘",
  ["#Vodka"] = "打破常识的女帝",
  ["designer:Vodka"] = "网瘾少年",
  ["cv:Vodka"] = "大桥彩香",
  ["%Vodka"] = "“目标，只有成为帅气的赛马娘！”",

  ["jiazhen"] = "假斟",
  [":jiazhen"] = "<font color=\"green\"><b>每回合限一次，</b></font>你可以将一张黑色基本牌或锦囊牌当【酒】使用并摸一张牌。", 
  ["lieju"] = "烈驹",
  [":lieju"] = "当你使用【杀】指定目标后，你可以失去1点体力，展示目标之一X张手牌（X为你与其已损失体力值之和），弃置其中所有与此【杀】颜色相同的牌。（触发次数等于此杀目标数） ",
  ["@liejus"] = "选择其中一个目标",
  ["jiazhenGlobal"] = "假斟",

  ["MihonoBourbon"] = "美浦波旁",
  ["@MihonoBourbon"] = "赛马娘",
  ["#MihonoBourbon"] = "坡道奇才",
  ["designer:MihonoBourbon"] = "网瘾少年",
  ["cv:MihonoBourbon"] = "长谷川育美",
  ["%MihonoBourbon"] = "“目标确认。开始执行操作‘获得三冠’。”",

  ["xiexing"] = "械行",
  [":xiexing"] = "锁定技，出牌阶段，\n①当你使用牌时，若你本回合使用牌的数量达到你的体力值/势力数，则你本回合后续使用牌无距离/次数限制。\n②当你使用牌对其他角色造成伤害后，若你手牌最少且上述效果至少有一项未触发，则你摸一张牌；若你上述效果均触发，则此牌结算后你结束出牌阶段。", 
  ["#xiexingA"] = "%from 的“%arg”被触发，本回合使用牌无距离限制",
  ["#xiexingB"] = "%from 的“%arg”被触发，本回合使用牌无次数限制",
  ["#xiexingC"] = "%from 的“%arg”被触发，即将结束出牌阶段",
  
  ["Kozue"] = "乙宗梢",
  ["@Kozue"] = "Love Live系列",
  ["#Kozue"] = "加贺青女",
  ["designer:Kozue"] = "花宫瑞业",
  ["cv:Kozue"] = "花宫初奈",
  ["illustrator:Kozue"] = "在下是子龙",
  ["%Kozue"] = "“立如芍药，坐若牡丹，行犹百合。”",
  ["~Kozue"] = "（弹唱《水彩世界》）",
  
  ["huaqian"] = "花牵",
  ["KozueHuaqian$"] = "image=image/animate/KozueHuaqian.png",
  [":huaqian"] = "与你势力相同的角色于其回合内使用第三种花色的牌后，你可以令其摸一张牌并交给你一张牌，然后若你的手牌最多，则其本回合使用牌无距离限制。",
  ["&huaqian"] = "“花牵”发动，请交给 %src 一张牌（点取消则随机选一张牌）",
  ["#huaqianA"] = "“%arg”效果触发，%from 本回合使用牌无距离限制",
  ["$huaqian1"] = "好，那就让我来为你展示一个未知的世界~",
  ["$huaqian2"] = "你想成为怎样的星星呢？",
  ["qiuyu"] = "秋语",
  ["KozueQiuyu$"] = "image=image/animate/KozueQiuyu.png",
  [":qiuyu"] = "锁定技，当你受到伤害后，你摸一张牌并令伤害来源展示你的一张手牌，若为♥，则弃置之，然后你可以令一名角色回复1点体力，否则你重铸此牌。",
  ["&qiuyu-recover"] = "你可以选择一名角色回复1点体力",
  ["$qiuyu1"] = "明年再去吧，呐？明天开始的练习，要努力哦？",
  ["$qiuyu2"] = "不仅是我，沙知前辈也是，再之前的前辈也是，大家每个人……都是反复如此。",
  
  ["Harewataru"] = "索拉·哈雷瓦塔尔",
  ["@Harewataru"] = "Hanging sky! 光之美少女",
  ["&Harewataru"] = "索拉",
  ["#Harewataru"] = "晴空天使",
  ["designer:Harewataru"] = "FlameHaze",
  ["cv:Harewataru"] = "关根明良",
  ["illustrator:Harewataru"] = "伊藤星一",
  ["%Harewataru"] = "“「英雄」这不是现在的我够资格说出的话，但是，如果你这么称呼我的话...”",
  ["~Harewataru"] = "你的对手是我....呃啊~",
  
  ["jianxing"] = "践行",
  ["jianxing1$"] = "image=image/animate/jianxing1.png",
  ["jianxing2$"] = "image=image/animate/jianxing2.png",
  [":jianxing"] = "<font color=\"green\"><b>每回合限一次，</b></font>当一名角色使用基本牌指定其他角色为目标时，你可以重铸任意张牌名互相相同的牌并根据数量令其执行：1，将目标场上一张牌移至对应目标手牌区；2，其他角色不能使用牌直到此牌生效；3，取消所有目标。",
  ["@jianxing"] = "践行：重铸",
  ["~jianxing"] = "选择任意张同名牌",
  ["jianxing_recastnum"] = "践行",
  -----["$jianxing_slash_effect"] = "%from 受到“践行”的影响，无法响应 %arg 的效果。",
  ["$jianxing_NOTarget"] = "受到“践行”的影响， %arg 的目标取消。",
  ["$jianxing1"] = "放马过来！",
  ["$jianxing2"] = "不管对手有多强，都要贯彻正义到最后。",
  ["$jianxing3"] = "要阻止他！",
  ["$jianxing4"] = "轮到英雄登场了！",
  ["$jianxing5"] = "Hero Girl Sky Punch英雄少女天空拳！", 
  
  ["NiceNature"] = "优秀素质",
  ["@NiceNature"] = "赛马娘",
  ["#NiceNature"] = "理想女主",---铜牌收藏家
  ["designer:NiceNature"] = "网瘾少年",
  ["cv:NiceNature"] = "前田佳织里",
  ["illustrator:NiceNature"] = "mmk",
  ["%NiceNature"] = "“好啦好啦，因为是普通人，即使第三也很幸福啦～”",
  
  ["yinni"] = "寅睨",
  ["yinniCard"] = "寅睨技能卡",
  [":yinni"] = "出牌阶段限一次，你可以与至多两名其他角色各展示一张手牌，若点数均不同，则点数最大的角色可以视为对另外两名角色（A）之一使用一张决斗，然后角色A中未被此决斗指定为目标的角色弃置展示牌；否则你与其重铸展示牌且此技能视为未发动。",
  ["@yinni"] = "寅睨：展示一张手牌",
  ["@yinni_duel"] = "视为使用决斗",
  ["~yinni"] = "选择拼点目标",
  ["yinni$"] = "image=image/animate/yinni.png",
  ["yinni_used"] = "寅睨已发动",
  ["yongwang"] = "庸望",
  [":yongwang"] = "<font color=\"green\"><b>每回合限一次，</b></font>当牌因弃置而进入弃牌堆时，若其中存在点数比你的每一张手牌都大的牌，则你可以展示手牌，获得其中一张符合条件的牌。",
  ["yongwang$"] = "image=image/animate/yongwang.png",
  ["yongwang_num"] = "点数",

  ["PalmerHelios"] = "目白善信＆大拓太阳神",
  ["@PalmerHelios"] = "赛马娘",
  ["&PalmerHelios"] = "善信太阳神",
  ["#PalmerHelios"] = "爆逃姐妹",
  ["designer:PalmerHelios"] = "网瘾少年",
  ["cv:PalmerHelios"] = "野口百合&山根绮",
  ["%PalmerHelios"] = "太阳神：“呀好嗨呦☆场子炒起来全都嗨起来，好好享受吧♪”善信：“要当一辈子的爆逃姐妹哦！不是笨蛋组合！”",

  ["chaoyan"] = "潮宴",
  [":chaoyan"] = "当你受到伤害后，你可以选择一名角色并选择一项：1.手牌数＜其的角色各摸X张牌（X为伤害数）；2.手牌数＞其的角色各弃置X张手牌。",
  ["chaoyanA"] = "小于其者摸牌",
  ["chaoyanB"] = "大于其者弃牌",
  ["youli"] = "友励",
  [":youli"] = "<font color=\"green\"><b>每回合每名角色限一次，</b></font>其他角色因弃置而失去手牌时，若你的手牌数≤其，则你可以选择一项：1.交给其一张手牌，令其将手牌数调整至体力上限；2.获得其一张手牌，其回复1点体力。",
  ["youli_give"] = "交出手牌，其将手牌数调整至体力上限",
  ["youli_obtain"] = "获得手牌，其回复1点体力",
  ["&youli"] = "请交给 %src 一张手牌（点取消则随机选一张手牌）",
}

return {extension}