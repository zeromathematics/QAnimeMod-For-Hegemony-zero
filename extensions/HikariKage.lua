extension = sgs.Package("hikarikage", sgs.Package_GeneralPack)
Ruri = sgs.General(extension , "Ruri", "real", 3, false)
Ayanokoji = sgs.General(extension , "Ayanokoji", "real", 4)
ManakaMiuna = sgs.General(extension , "ManakaMiuna", "real", 3, false)
Elaina = sgs.General(extension , "Elaina", "magic", 3, false)
Aiz = sgs.General(extension, "Aiz", "magic", 4, false)
Origami = sgs.General(extension , "Origami", "magic", 3, false)
Enju = sgs.General(extension , "Enju", "science", 3, false)
Enju:addCompanion("Rentaro")
Inori = sgs.General(extension , "Inori", "science", 3, false)
Inori:addCompanion("Oumashu")
Chisato = sgs.General(extension, "Chisato", "science", 3, false)
AliceM = sgs.General(extension , "AliceM", "game", 3, false)
Meirin = sgs.General(extension , "Meirin", "game", 4, false)
Ellen = sgs.General(extension , "Ellen", "game", 3, false)
--HoshinoAi = sgs.General(extension , "HoshinoAi", "idol", 3, false)
--TsukimiEiko = sgs.General(extension , "TsukimiEiko", "idol", 3, false)

Shengli = sgs.CreateTriggerSkill{
    name = "shengli",
	events = {sgs.CardFinished, sgs.CardUsed},
    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            use.card:setFlags("IsUsed")
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:getTypeId() == sgs.Card_TypeSkill then return "" end
            if not use.card:hasFlag("IsUsed") then return "" end
            local players = room:findPlayersBySkillName(self:objectName())
            for _,sp in sgs.qlist(players) do
                if sp:hasSkill(self:objectName()) and sp:isAlive() and use.from and use.to:contains(sp) and sp ~= use.from and use.card:isBlack() and not room:getCurrent():hasFlag(sp:objectName().."shengli_black") then
                    return self:objectName(), sp
                end
                if sp:hasSkill(self:objectName()) and sp:isAlive() and use.from and use.to:contains(sp) and not use.card:isBlack() and not room:getCurrent():hasFlag(sp:objectName().."shengli_notblack") then
                    return self:objectName(), sp
                end
            end 
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if event == sgs.CardFinished and sp:askForSkillInvoke(self,data) then
            local use = data:toCardUse()
            room:setCardFlag(use.card, "-IsUsed");
            if use.card:isBlack() then
                room:setPlayerFlag(room:getCurrent(), sp:objectName().."shengli_black")
                room:broadcastSkillInvoke(self:objectName(), math.random(1,3), sp)
            else
                room:setPlayerFlag(room:getCurrent(), sp:objectName().."shengli_notblack")
                room:broadcastSkillInvoke(self:objectName(), math.random(4,7), sp)
            end
            return true
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            room:setCardFlag(use.card, "-IsUsed");
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:isBlack() then
                if not sp:isKongcheng() and not use.from:isKongcheng() then
                    local pd = sp:pindianSelect(use.from, "shengli")
                    if sp:pindian(pd) then
                       sp:drawCards(1)
                       room:askForUseSlashTo(sp, use.from, "#shengli", false)
                    end
                end
            else
                sp:drawCards(1)
                if use.from ~= sp then use.from:drawCards(1) end
            end
        end
    end
}

Yishi= sgs.CreateTriggerSkill{
	name = "yishi",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(player, "##yishi_max", 0)
            end
        end
    end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase()==sgs.Player_Start then
            return self:objectName()
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:askForSkillInvoke(self, data) then
            local list = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                if p:isMale() and p ~= player and p:isFriendWith(player) then list:append(p) end
            end
            if list:length() == 0 then return true end
            local dest = room:askForPlayerChosen(player, list, self:objectName(), "", true, true)
            if dest then
               player:setProperty("yishi_dest", sgs.QVariant(dest:objectName()))
               room:broadcastSkillInvoke(self:objectName(), player)
               return true
            end
        end
        return false
    end,
    on_effect = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            local name = player:property("yishi_dest"):toString()
            local dest = findPlayerByObjectName(name)
            if not dest then
                room:setPlayerMark(player, "##yishi_max", 1)
                return false
            end
            player:setProperty("yishi_dest", sgs.QVariant())
            if dest:isDead() then return end
            local recover_dest
            local draw_dest 
            if dest:getHp() < player:getHp() then
                recover_dest = dest
            elseif player:getHp() < dest:getHp() then
                recover_dest = player
            end
            if dest:getHandcardNum() < player:getHandcardNum() then
                draw_dest = dest
            elseif player:getHandcardNum() < dest:getHandcardNum() then
                draw_dest = player
            end
            if recover_dest then
                local recover = sgs.RecoverStruct()
		        recover.who = player
		        room:recover(recover_dest, recover, true)
            end
            if draw_dest then
                draw_dest:drawCards(1)
            end
		end
    end	
}

YishiMax = sgs.CreateMaxCardsSkill{
	name = "#yishimax",
	extra_func = function(self, player)
		if player:getMark("##yishi_max")>0 then
           return 1
		end
		return 0
	end,
}
	
AnceCard = sgs.CreateSkillCard{
	name = "AnceCard",
    will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:objectName() ~= to_select:objectName() then
			return true
		end
	end,
    feasible = function(self, targets)
        if #targets ~= 1 then return false end
		local target = targets[1]
        if sgs.Self:getMark(target:objectName().."wuhen_effect")>0 then
            return self:getSubcards():length()<=2
        else
            return self:getSubcards():length()==1
        end
	end,
	on_use = function(self, room, source, targets)
		for _,target in ipairs(targets) do
            room:setPlayerFlag(target, source:objectName().."ance")
            room:obtainCard(target, self, false)
            room:askForUseCard(target, "Slash, Duel|.|.|hand", "@ance_use", -1, sgs.Card_MethodUse, false)
        end
	end,
}

Ancevs=sgs.CreateViewAsSkill{
	name="ance",
	n=2,
	view_filter=function(self,selected,to_select)
		return #selected < 2  and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards > 2  then return end
		local new_card = AnceCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_anceCard")
	end,
}

Ance = sgs.CreateTriggerSkill{
    name = "ance",
    view_as_skill = Ancevs,
	events = {sgs.EventPhaseEnd, sgs.Damage, sgs.Damaged},
	on_record = function(self, event, room, player, data)
       if (event == sgs.Damage or event == sgs.Damaged) and room:getCurrent():getPhase() == sgs.Player_Play and player:hasFlag(room:getCurrent():objectName().."ance") then
          room:setPlayerMark(player, "ance_damage", 1)
       end
	   if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
           for _,p in sgs.qlist(room:getAlivePlayers()) do
              if p:hasFlag(player:objectName().."ance") and p:getMark("ance_damage") == 0 then
                 room:setPlayerFlag(p, "-"..player:objectName().."ance") 
                 room:loseHp(p)
                 player:drawCards(1)
              end
              room:setPlayerMark(p, "ance_damage", 0)
           end
	   end
	end,
	can_trigger = function(self, event, room, player, data)
        return ""
    end
}

Wuhen = sgs.CreateTriggerSkill{
    name = "wuhen",
	events = {sgs.DamageInflicted, sgs.CardsMoveOneTime, sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.from == sgs.Player_Play then
                for _,p in sgs.qlist(room:getAlivePlayers()) do
                    if player:getMark(p:objectName().."wuhen_effect") > 0 then
                        room:setPlayerMark(player, p:objectName().."wuhen_effect", 0)
                        room:setPlayerMark(p, "#wuhen", p:getMark("#wuhen")-1)
                    end
                end
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player:hasSkill(self:objectName()) and player:isAlive() and player == room:getCurrent() then
                return self:objectName()
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            if player:hasSkill(self:objectName()) and player:isAlive() and move.from and move.from:isAlive() and move.from:objectName() ~= player:objectName() and move.from_places:contains(sgs.Player_PlaceHand) and move.from:isKongcheng() and player:getMark(move.from:objectName().."wuhen_effect") == 0 then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if event == sgs.DamageInflicted and (player:hasShownSkill(self:objectName()) or player:askForSkillInvoke(self,data)) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
        if event == sgs.CardsMoveOneTime and player:askForSkillInvoke(self,data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        if event == sgs.DamageInflicted then
            room:sendCompulsoryTriggerLog(player, self:objectName(), true)
            local damage = data:toDamage()
            if damage.damage > 1 then
                damage.damage = damage.damage - 1
                data:setValue(damage)
            else
                return true
            end
        end
        if event == sgs.CardsMoveOneTime then
            local move = data:toMoveOneTime()
            local from = findPlayerByObjectName(move.from:objectName())
            room:setPlayerMark(player, move.from:objectName().."wuhen_effect", 1)
            room:setPlayerMark(from, "#wuhen", from:getMark("#wuhen")+1)
        end
    end
}

HailianCard = sgs.CreateSkillCard{
	name = "HailianCard",
    will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:objectName() ~= to_select:objectName() and not to_select:isKongcheng() then
			return true
		end
	end,
	on_use = function(self, room, source, targets)
		for _,target in ipairs(targets) do
            if target:isKongcheng() then continue end
            local ids = room:askForExchange(target, "hailian", 1, 1, "@hailian", "", ".|.|.|hand")
            if ids:isEmpty() then ids:append(target:handCards():at(0)) end
            room:obtainCard(target, self)
            room:obtainCard(source, ids:at(0))
            if sgs.Sanguosha:getCard(self:getSubcards():at(0)):isKindOf("EquipCard") then
                target:drawCards(1)
            end
            if sgs.Sanguosha:getCard(ids:at(0)):isKindOf("EquipCard") then
                source:drawCards(1)
            end
        end
	end,
}

Hailian=sgs.CreateViewAsSkill{
	name="hailian",
	n=1,
	view_filter=function(self,selected,to_select)
		return #selected == 0  and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0  then return end
		local new_card = HailianCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_hailianCard")
	end,
}

Langjing = sgs.CreateTriggerSkill{
	name = "langjing",
	events = {sgs.Damage, sgs.EventPhaseEnd, sgs.EventPhaseChanging},
    on_record = function(self, event, room, player, data)
        if event == sgs.Damage then
            if player:getPhase() ~= sgs.Player_NotActive then
                local damage = data:toDamage()
                room:setPlayerMark(player, "langjing_record", player:getMark("langjing_record")+damage.damage)
            end
        end
        if event == sgs.EventPhaseChanging then
            local change = data:toPhaseChange()
            if change.to == sgs.Player_NotActive then
                room:setPlayerMark(player, "langjing_record", 0)
            end
        end
    end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseEnd then
            if player and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish then
                return self:objectName()
            end
        end
        return ""
	end,
    on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self,data) then
            local x = player:getMark("langjing_record")
            local list = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getHandcardNum() <= 2*x then
                    list:append(p)
                end
            end
            if list:length() > 0 then
                local players = room:askForPlayersChosen(player, list, self:objectName(), 0, x+1, "@langjing", true)
                if players:length()> 0 then
                    local s = {}
                    for _,p in sgs.qlist(players) do
                        table.insert(s, p:objectName())
                    end
                    player:setProperty("langjing_targets", sgs.QVariant(table.concat(s, "+")))
                    room:broadcastSkillInvoke(self:objectName(), player)
                    return true
                end
            end
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        local players = player:property("langjing_targets"):toString():split("+")
        local m = 0
        local f = 0
		for _,q in ipairs(players) do
			local p = findPlayerByObjectName(q)
            p:drawCards(1)
        end
        for _,q in ipairs(players) do
            local p = findPlayerByObjectName(q)
			if p:isMale() then m = m+1 end
            if p:isFemale() then f = f+1 end
        end
        if m == f and player:isWounded() then
            local recover = sgs.RecoverStruct()
		    recover.who = player
		    room:recover(player, recover, true)
        end
    end
}

Lvji = sgs.CreateTriggerSkill{
    name = "lvji",
	events = {sgs.EventPhaseStart, sgs.GeneralShown, sgs.GeneralTransformed, sgs.EventAcquireSkill},
	on_record = function(self, event, room, player, data)
        if ((event == sgs.GeneralShown or event == sgs.GeneralTransformed) and player:hasSkill(self:objectName()) and player:isAlive() and player:inHeadSkills(self) == data:toBool()) then
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                room:attachSkillToPlayer(p, "lvjigive")
            end
        elseif (event==sgs.EventAcquireSkill) then
            if (data:toString():split(":")[1] == self:objectName()) then
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    room:attachSkillToPlayer(p, "lvjigive")
                end
            end
        end
	end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if player:hasSkill(self:objectName()) and player:isAlive() and player:getPile("jixu_id"):length()<5 then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self,data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        while room:getDrawPile():length()<5 do
            room:swapPile()
        end
        local list = sgs.IntList()
        for i=1 ,5 ,1 do
            list:append(room:getDrawPile():at(i-1))
        end
        room:fillAG(list, player)
		local id = room:askForAG(player, list, false, "lvji")
        local card = sgs.Sanguosha:getCard(id)
		room:clearAG(player)
        local has
            for _,i in sgs.qlist(player:getPile("jixu_id")) do
                local c = sgs.Sanguosha:getCard(i)
                if card:objectName() == c:objectName() then
                    has = true
                end
            end
        player:addToPile("jixu_id", id)
        if not has and card:isKindOf("TrickCard") then player:drawCards(1) end
	end
}

LvjigiveCard = sgs.CreateSkillCard{
	name = "LvjigiveCard",
    will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:objectName() ~= to_select:objectName() and to_select:hasShownSkill("lvji") and to_select:getPile("jixu_id"):length()<5 then
			return true
		end
	end,
	on_use = function(self, room, source, targets)
		for _,target in ipairs(targets) do
            local card = sgs.Sanguosha:getCard(self:getSubcards():at(0))
            local has
            for _,i in sgs.qlist(target:getPile("jixu_id")) do
                local c = sgs.Sanguosha:getCard(i)
                if card:objectName() == c:objectName() then
                    has = true
                end
            end
            room:broadcastSkillInvoke("lvji", target)
            target:addToPile("jixu_id", self:getEffectiveId())
            if not has and card:isKindOf("TrickCard") then source:drawCards(1) end
        end
	end,
}

Lvjigive = sgs.CreateViewAsSkill{
	name="lvjigive",
	n=1,
    attached_lord_skill = true,
	view_filter=function(self,selected,to_select)
		return #selected == 0 and not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 0 then return end
        local new_card = LvjigiveCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card	
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_lvjigiveCard")
	end,
}

Fahuivs = sgs.CreateViewAsSkill{
	name="fahui",
	n=2,
    expand_pile = "jixu_id",
	view_filter=function(self,selected,to_select)
		if #selected == 0 then
            return not sgs.Self:getHandcards():contains(to_select) and not sgs.Self:getEquips():contains(to_select) and (to_select:isKindOf("BasicCard") or to_select:isNDTrick()) and to_select:isAvailable(sgs.Self)
        end
        if #selected == 1 then
            return sgs.Self:getHandcards():contains(to_select)
        end
	end,
	view_as = function(self, cards)
		if #cards ~= 2 then return end
		local vs = sgs.Sanguosha:cloneCard(cards[1]:objectName())
		vs:addSubcard(cards[2])
		vs:setShowSkill(self:objectName())
		vs:setSkillName(self:objectName())
		return vs	
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_fahuiCard")
	end,
}

Fahui = sgs.CreateTriggerSkill{
    name = "fahui",
    view_as_skill = Fahuivs,
    can_preshow = true,
	events = {sgs.CardUsed},
	can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            local has
            for _,id in sgs.qlist(player:getPile("jixu_id")) do
                local card = sgs.Sanguosha:getCard(id)
                if card:getColor() == use.card:getColor() then
                    has = true
                end
            end
            if player:hasSkill(self:objectName()) and player:isAlive() and use.card:isNDTrick() and has and use.to:length()>0 then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self,data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        local use = data:toCardUse()
        local list = sgs.IntList()
        for _,id in sgs.qlist(player:getPile("jixu_id")) do
            local card = sgs.Sanguosha:getCard(id)
            if card:getColor() == use.card:getColor() then
                list:append(id)
            end
        end
        if list:length()> 0 then
            room:fillAG(list, player)
            local id = room:askForAG(player, list, false, "lvji")
            room:clearAG(player)
            room:throwCard(id, player, player)
            local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
            if use.to:contains(target) then
                sgs.Room_cancelTarget(use, target)
            else
                use.to:append(target)
            end
            data:setValue(use)
        end
	end
}

Jizou = sgs.CreateTriggerSkill{
	name = "jizou",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, event, room, player, data)
        local players = room:findPlayersBySkillName(self:objectName())
        for _,Aiz in sgs.qlist(players) do
            if player:getPhase() == sgs.Player_Finish and not Aiz:isNude() then
                return self:objectName(), Aiz
            end
        end
        return ""
	end,
	on_cost = function(self, event, room, player, data, ask_who)
		if room:askForDiscard(ask_who, self:objectName(), 1, 1, true, true, "&jizouDiscard", true) then
            room:broadcastSkillInvoke(self:objectName(), player)
			return true
		end
        return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
        if ask_who:isAlive() then
            local list = sgs.IntList()
            local choice
		    if ask_who:getHandcardNum() < 2 then
                choice = "jizouDrawPile"
            else
                choice = room:askForChoice(ask_who, self:objectName(), "jizouHand+jizouDrawPile")
            end
            if choice == "jizouDrawPile" then
                if room:getDrawPile():length() < 2 then
                    room:swapPile()
                end
                for i = 0, 1, 1 do
                    list:append(room:getDrawPile():at(i))
                end
            else
                --local show_ids = room:askForExchange(ask_who, self:objectName(), 2, 2, "&jizouShow", "", ".|.|.|hand")
                for _,p in sgs.qlist(ask_who:handCards()) do
                    list:append(p)
                end
            end
            local hasSlash, hasJink, noBasic = false, false, true
            for _,i in sgs.qlist(list) do
                local card = sgs.Sanguosha:getCard(i)
                if card:isKindOf("Slash") then
                    hasSlash = true
                end
                if card:isKindOf("Jink") then
                    hasJink = true
                end
                if card:isKindOf("BasicCard") then
                    noBasic = false
                end      
            end
            if hasSlash then
                local dis = sgs.IntList()
                for _,i in sgs.qlist(list) do
                    local card = sgs.Sanguosha:getCard(i)
                    if not card:isKindOf("Slash") then
                        dis:append(i)
                    end
                end
                room:fillAG(list, nil, dis)
                local id = -1
                id = room:askForAG(ask_who, list, true, self:objectName())
                room:clearAG()
                room:clearAG(ask_who)
                if id > -1 then
                    local to = room:askForPlayerChosen(ask_who, room:getOtherPlayers(ask_who), self:objectName())                           
				    local use = sgs.CardUseStruct()
				    use.from = ask_who
				    use.to:append(to)
				    use.card = sgs.Sanguosha:getCard(id)
				    room:useCard(use, false)
                end
            else --由于AG的使用在这里有两种可能，所以只能在分开的选项里单独讨论了     
		        room:fillAG(list)
		        room:getThread():delay()
                room:clearAG()
		        room:clearAG(ask_who)
            end
            if noBasic then
                if room:getDrawPile():length() < 2 then
                    room:swapPile()
                end
                local dummy = sgs.DummyCard()
                for i = 1, 2, 1 do
                    local a = room:getDrawPile():at(room:getDrawPile():length()-i)
                    dummy:addSubcard(sgs.Sanguosha:getCard(a))
                end
				if dummy:getSubcards():length() > 0 then
					room:obtainCard(ask_who, dummy)
				end
                dummy:deleteLater()
            end
            if hasJink then
                ask_who:gainMark("@halfmaxhp", 1)
		        --room:attachSkillToPlayer(ask_who, "halfmaxhp")
            end
        end
	end,
}

GuangjianCard = sgs.CreateSkillCard{
	name = "GuangjianCard",
    will_throw = false,
	filter = function(self, targets, to_select) 
		if #targets <1 and sgs.Self:objectName() ~= to_select:objectName() and to_select:getPile("guangjian"):length() == 0 then
			return true
		end
	end,
	on_use = function(self, room, source, targets)
		for _,target in ipairs(targets) do
            for _,id in sgs.qlist(self:getSubcards()) do
                target:addToPile("guangjian", id)
            end
        end
	end,
}

Guangjianvs=sgs.CreateViewAsSkill{
	name="guangjian",
	n=2,
	view_filter=function(self,selected,to_select)
		if #selected == 0  and to_select:isKindOf("BasicCard") then
            return true
        elseif #selected == 1 and to_select:isKindOf("BasicCard") then
            return to_select:getColor() ~= selected[1]:getColor()
        end
        return false
	end,
	view_as = function(self, cards)
		if #cards == 0  then return end
		local new_card = GuangjianCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_guangjianCard")
	end,
}

Guangjian = sgs.CreateTriggerSkill{
    name = "guangjian",
    view_as_skill = Guangjianvs,
	events = {sgs.CardFinished, sgs.CardUsed},
    on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
            local use = data:toCardUse()
            use.card:setFlags("IsUsed")
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardFinished then
            local use = data:toCardUse()
            if use.card:getTypeId() == sgs.Card_TypeSkill then return "" end
            if not use.card:hasFlag("IsUsed") then return "" end
            local players = room:findPlayersBySkillName(self:objectName())
            for _,sp in sgs.qlist(players) do
                if sp:hasSkill(self:objectName()) and sp:isAlive() and player:getPile("guangjian"):length()>0 then
                    return self:objectName(), sp
                end
            end 
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if event == sgs.CardFinished and sp:askForSkillInvoke(self,data) then
            --room:broadcastSkillInvoke(self:objectName(), sp)
            return true
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        if event == sgs.CardFinished then
            local list = player:getPile("guangjian")
            if list:length() == 0 then return false end
            room:fillAG(list, sp)
            local id = room:askForAG(sp, list, false, self:objectName())
            room:clearAG(sp)
            local slash = sgs.Sanguosha:cloneCard("slash")
            slash:addSubcard(id)
            slash:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
		    use.from = sp
		    use.to:append(player)
		    use.card = slash
		    room:useCard(use, false)
            if player:getPile("guangjian"):length() == 0 then sp:drawCards(1) end
        end
    end
}

Rilun = sgs.CreateTriggerSkill{
    name = "rilun",
	events = {sgs.EventPhaseStart, sgs.Damage},
    on_record = function(self, event, room, player, data)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.card and damage.card:getSkillName() == self:objectName() then
                room:setPlayerFlag(player, "rilun_damage")
            end 
        end
    end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local list = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasShownOneGeneral() then list:append(p) end
            end
            if list:length() == 0 then return "" end
            if player:hasSkill(self:objectName()) and player:isAlive() and player:getHandcardNum()>player:getHp() then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self,data) then
            local list = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasShownOneGeneral() then list:append(p) end
            end
            if list:length() == 0 then return false end
            local target = room:askForPlayerChosen(player, list, self:objectName(), "@rilun", true, true)
            if target then
               local n = 0
               for _,p in sgs.qlist(room:getAlivePlayers()) do
                  if p:isFriendWith(target) then n = n+1 end
               end
               local x = math.ceil(n/2)
               local discard = room:askForDiscard(player, self:objectName(), x, x, true, true, "@rilun_discard") 
               if discard then 
                  player:setProperty("rilun_target", sgs.QVariant(target:objectName()))
                  return true 
               end
            end
            return false
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        local name = player:property("rilun_target"):toString()
        local target = findPlayerByObjectName(name)
        if not target then return false end
        local targets = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:isFriendWith(target) then targets:append(p) end
            end
        if targets:length() == 0 then return false end
        local card = sgs.Sanguosha:cloneCard("archery_attack")
            card:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
		    use.from = player
		    use.to = targets
		    use.card = card
		    room:useCard(use, false)
            if player:hasFlag("rilun_damage") then
                room:setPlayerFlag(player, "-rilun_damage")
            else
                local h
                for _,id in sgs.qlist(room:getDrawPile()) do
                    local card = sgs.Sanguosha:getCard(id)
                    if card:getSuitString() == "heart" then
                        h = card
                    end
                end
                if h then room:obtainCard(player, h) end
            end
	end
}

YuejiCard = sgs.CreateSkillCard{
	name = "YuejiCard",
    mute = true,
	filter = function(self, targets, to_select) 
                if #targets <1 and sgs.Self:objectName() ~= to_select:objectName() and sgs.Self:distanceTo(to_select) <= 2 and sgs.Self:distanceTo(to_select)>-1 then
			return true
		end
	end,
	on_use = function(self, room, source, targets)
	   local slash = sgs.Sanguosha:cloneCard("slash")
	   slash:setSkillName("yueji")
       local tos = sgs.SPlayerList()
	   for _,p in ipairs(targets) do
		   tos:append(p)
	   end
       if self:getSubcards():length()>0 then
           slash:addSubcards(self:getSubcards())
           if self:isBlack() then
               room:setPlayerFlag(source, "yueji_addtimes")
           end
       else
           room:loseHp(source)
       end
	   room:useCard(sgs.CardUseStruct(slash, source, tos), false)
	end,
}

Yuejivs=sgs.CreateViewAsSkill{
	name="yueji",
	n=1,
	view_filter=function(self,selected,to_select)
		return #selected == 0 and not to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		local new_card = YuejiCard:clone()
		for var = 1, #cards, 1 do   
            new_card:addSubcard(cards[var])                
        end      
		new_card:setShowSkill(self:objectName())	
		new_card:setSkillName(self:objectName())		
		return new_card		
	end,	
	enabled_at_play=function(self,player,pattern)
		return not player:hasUsed("ViewAsSkill_yuejiCard") --or (player:usedTimes("#YuejiCard") < 2 and player:hasFlag("yueji_addtimes"))
	end,
}

Yuejimod = sgs.CreateTargetModSkill{
	name = "#yuejimod",
	pattern = "Slash",
	residue_func = function(self,player,card)
	  if player:hasFlag("yueji_addtimes") then return 1 end
	end,
}

Yueji = sgs.CreateTriggerSkill{
    name = "yueji",
    view_as_skill = Yuejivs,
	events = {sgs.DamageCaused, sgs.TargetConfirmed},
	can_trigger = function(self, event, room, player, data)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            if damage.card and damage.card:getSubcards():length() == 0 and damage.card:getSkillName() == "yueji" and damage.card:isKindOf("Slash") then
                return self:objectName()
            end
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            if use.from and use.from == player and use.card:isRed() and use.card:getSkillName() == "yueji" and use.card:isKindOf("Slash") then
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
        return true
    end,
    on_effect = function(self, event, room, player, data, sp)
        if event == sgs.DamageCaused then
            local damage = data:toDamage()
            damage.damage = damage.damage+1
            data:setValue(damage)
        end
        if event == sgs.TargetConfirmed then
            local use = data:toCardUse()
            local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toList())
			for i = 0, use.to:length() - 1, 1 do
				if jink_list[i + 1]:toInt() == 1 then
					jink_list[i + 1]:setValue(2)
				end
			end
            local result = sgs.VariantList()
            for i = 1, #jink_list, 1 do
                 result:append(jink_list[i])
            end
			player:setTag("Jink_" .. use.card:toString(), sgs.QVariant(result))
        end
	end
}

Qishi = sgs.CreateTriggerSkill{
	name = "qishi",
	events = {sgs.DamageInflicted, sgs.EventPhaseStart},
    on_record = function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Start and player:getMark("#qinshi") > 0 then
                room:setPlayerMark(player, "#qinshi", 0)
                room:loseHp(player)
            end
        end
    end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            if player and player:hasSkill(self:objectName()) and damage.damage >= player:getHp() and not player:isKongcheng() and player:getMark("#qinshi") == 0 then
                return self:objectName()
            end
        end
        return ""
	end,
    on_cost = function(self, event, room, player, data, sp)
        if player:askForSkillInvoke(self,data) then
            room:broadcastSkillInvoke(self:objectName(), player)
            return true
        end
    end,
    on_effect = function(self, event, room, player, data, sp)
        if event == sgs.DamageInflicted then
            local damage = data:toDamage()
            local x = 0
            for _,c in sgs.qlist(player:getHandcards()) do
                if c:isRed() then
                    room:showCard(player, c:getEffectiveId())
                    x = x+1
                end
            end
            if x < damage.damage then
                damage.damage = damage.damage - x
                data:setValue(damage)
            else
                room:setPlayerMark(player, "#qinshi", 1)
                return true
            end
        end
    end
}

Jieji = sgs.CreateTriggerSkill{
	name = "jieji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage, sgs.CardFinished, sgs.CardUsed},
	on_record = function(self, event, room, player, data)
        if event == sgs.CardUsed then
		    local use = data:toCardUse()
		    if player and player:isAlive() and player:hasSkill("jieji") and not use.card:isKindOf("SkillCard") and not use.to:contains(player) and use.to:length() > 0 then
				use.card:setFlags("isuse_jieji")
            end
		end
		if event == sgs.Damage then 
			local damage = data:toDamage()
			if player and player:isAlive() and player:hasSkill("jieji") and damage.card and not damage.card:isKindOf("SkillCard") then
				damage.card:setFlags("damage_jieji")
			end			
		end
	end, 
	can_trigger = function(self, event, room, player, data)
       if event == sgs.CardFinished then
			local use = data:toCardUse()
            if player and player:isAlive() and player:hasSkill("jieji") and not use.card:isKindOf("SkillCard") and not use.to:contains(player) and use.to:length() > 0 and use.card:hasFlag("isuse_jieji") then
				return self:objectName()
			end
        end
        return ""
	end,
	on_cost = function(self, event, room, player, data)
		if player:hasShownSkill("jieji") or player:askForSkillInvoke(self, data) then
			room:broadcastSkillInvoke(self:objectName())
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data)
	    if event == sgs.CardFinished then
		    local use = data:toCardUse()
			if use.card:hasFlag("damage_jieji") then
			    room:askForDiscard(player, "jieji", 1, 1, false, true)
			elseif not use.card:hasFlag("damage_jieji") then
				local list = room:getDrawPile()
				if list:length()>0 then
					local lists = sgs.IntList()
					for _,g in sgs.qlist(room:getDrawPile()) do  
					    if use.card:getSuit() ~= sgs.Sanguosha:getCard(g):getSuit() then  
						   lists:append(g)  
						end	
					end
					if lists:length() > 0 then	
					   local ids = lists:at(math.random(0, lists:length()-1))  
					   local card = sgs.Sanguosha:getCard(ids)  
					   room:obtainCard(player, card)	
					end
				end
			end
		end	
	end,
}

Qianggan = sgs.CreateTriggerSkill{
	name = "qianggan",
	events = {sgs.EventPhaseEnd, sgs.SlashMissed},---sgs.SlashHit
	on_record = function(self, event, room, player, data)
	   if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Finish then
				for _,m in sgs.qlist(room:getAlivePlayers()) do room:setPlayerMark(m, "qianggan_times", 0) end
			end
		end
	end,	
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.SlashMissed then
			local effect = data:toSlashEffect()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
                                if sp:isAlive()and sp:hasSkill("qianggan") and room:getCurrent():objectName() == player:objectName() and sp:distanceTo(player) <= sp:getAttackRange() and sp:distanceTo(player)>-1 and sp:getMark("qianggan_times") < 1 then----effect.from ~= player and player == effect.to and and effect.from:objectName() ~= player:objectName() and effect.to:objectName() == player:objectName()
				   return self:objectName(), sp
				end
			end	
		end	
        return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
	    local effect = data:toSlashEffect()
	    local dat = sgs.QVariant()
		dat:setValue(player)
		if sp:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), sp)
			room:doLightbox("qianggan$", 999)
			room:setPlayerMark(sp, "qianggan_times", 1)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
	    local effect = data:toSlashEffect()
		local choice_list = {}
		if sp:isAlive() then table.insert(choice_list, "choice-qianggan-obtain") end
		if not sp:isKongcheng() then table.insert(choice_list, "choice-qianggan-use") end
		if #choice_list == 0 then return false end
		local choice = room:askForChoice(sp, self:objectName(), table.concat(choice_list, "+"))
		if choice == "choice-qianggan-obtain" then
			local handcard_has_spade = false
			local handcard_has_club = false
			local handcard_has_heart = false
			local handcard_has_diamond = false
			for _, c in sgs.qlist(sp:getCards("h")) do
				if c:getSuit() == sgs.Card_Spade then handcard_has_spade = true end
				if c:getSuit() == sgs.Card_Club then handcard_has_club = true end
				if c:getSuit() == sgs.Card_Heart then handcard_has_heart = true end
				if c:getSuit() == sgs.Card_Diamond then handcard_has_diamond = true end
			end
			local qianggan_result = 0
			if handcard_has_spade then qianggan_result = qianggan_result + 1 end
			if handcard_has_club then qianggan_result = qianggan_result + 1 end
			if handcard_has_heart then qianggan_result = qianggan_result + 1 end
			if handcard_has_diamond then qianggan_result = qianggan_result + 1 end
			if qianggan_result == 1 then
				local list = room:getDrawPile()
				if list:length()>0 then
					local id = list:at(math.random(0,list:length()-1))
					local cards = sgs.Sanguosha:getCard(id)
					room:obtainCard(sp, cards)
				end
			elseif qianggan_result == 0 then
				local list = room:getDrawPile()
				if list:length()>0 then
					local id = list:at(math.random(0,list:length()-1))
					local cards = sgs.Sanguosha:getCard(id)
					room:obtainCard(sp, cards)
					local lists = sgs.IntList()
					for _,g in sgs.qlist(room:getDrawPile()) do  if cards:getSuit() ~= sgs.Sanguosha:getCard(g):getSuit() then  lists:append(g)  end	end
					if lists:length() > 0 then	local ids = lists:at(math.random(0, lists:length()-1))  local card = sgs.Sanguosha:getCard(ids)  room:obtainCard(sp, card)	end
				end
			end	
		elseif choice == "choice-qianggan-use" then		
				local cards = sp:getCards("h")
				local pattern = {}
				for _,c in sgs.qlist(cards) do
				   if c:isAvailable(sp) then
					   table.insert(pattern, c:getClassName())
				   end
				end
				if not sp:isKongcheng() then room:askForUseCard(sp, table.concat(pattern, ",").."|.|.|hand", "@qianggan_use", -1, sgs.Card_MethodUse, false) end
	    end
	end,
}

Wange = sgs.CreateTriggerSkill{
	name = "wange",
	events = {sgs.CardsMoveOneTime, sgs.CardFinished, sgs.Death, sgs.PreCardUsed},
	on_record = function(self, event, room, player, data)
        if event == sgs.PreCardUsed then
            local use = data:toCardUse()
            local list = room:getTag("wangeCard"):toList()
			if list:contains(sgs.QVariant(use.card:getEffectiveId())) and use.card:getTypeId() ~= sgs.Card_TypeSkill then
				room:setPlayerFlag(use.from, "wangeCard_useprevent")
			end
        end
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local reason = move.reason
			if move.from_places:contains(sgs.Player_PlaceHand) then --and bit32.band(reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= 0x01 then --不因使用而失去的时候在这里清零，因使用而失去的时候就要在对应的技能那里清零了，免得技能触发不了
				for _,id in sgs.qlist(move.card_ids) do
                    local list = room:getTag("wangeCard"):toList()
					--[[if sgs.Sanguosha:getCard(id):hasFlag("wangeCard") then
						sgs.Sanguosha:getCard(id):setFlags("-wangeCard")
					end]]
                    if list:contains(sgs.QVariant(id)) and move.from and move.from:objectName() == player:objectName() then
                        local from = findPlayerByObjectName(move.from:objectName())
                        if from:hasFlag("wangecard_fisrtflag") then
                            room:setPlayerFlag(from, "-wangecard_fisrtflag")
                            return
                        end
                        if from:hasFlag("wangeCard_useprevent") then
                            room:setPlayerFlag(from, "-wangeCard_useprevent")
                            --room:setPlayerFlag(from, "wangeCard_useprevent2")
                            return
                        --[[elseif from:hasFlag("wangeCard_useprevent2") then
                            room:setPlayerFlag(from, "-wangeCard_useprevent2")
                            return]]
                        end
                        list:removeOne(sgs.QVariant(id))
                        room:setTag("wangeCard", sgs.QVariant(list))
                    end
				end
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and move.from and move.from:objectName() == player:objectName() and move.to and move.to:objectName() ~= player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip) or move.from_places:contains(sgs.Player_PlaceDelayedTrick)) and move.to_place == sgs.Player_PlaceHand and not room:getCurrent():hasFlag("wangeUsed") and move.card_ids:length() == 1 then
				return self:objectName()
			end		
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
                local list = room:getTag("wangeCard"):toList()
				if use.from:objectName() ~= sp:objectName() and list:contains(sgs.QVariant(use.card:getEffectiveId())) and use.card:getTypeId() ~= sgs.Card_TypeSkill then
					return self:objectName(), sp
				end
			end
		end
		if event == sgs.Death then
			local death = data:toDeath()
			if player and player:hasSkill(self:objectName()) and death.who:objectName() == player:objectName() then
				return self:objectName()
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local who = sgs.QVariant()
			who:setValue(findPlayerByObjectName(move.to:objectName()))
			if player:askForSkillInvoke("wangeA", who) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			local who = sgs.QVariant()
			who:setValue(use.from)
			if sp:askForSkillInvoke("wangeB", who) then
				room:broadcastSkillInvoke(self:objectName(), sp)
				return true
			end
            local list = room:getTag("wangeCard"):toList()
            if list:contains(sgs.QVariant(use.card:getEffectiveId())) then
                list:removeOne(sgs.QVariant(use.card:getEffectiveId()))
                room:setTag("wangeCard", sgs.QVariant(list))
            end
		end
		if event == sgs.Death then
			if player:askForSkillInvoke("wangeC", data) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		return false
	end ,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			room:getCurrent():setFlags("wangeUsed")
			--sgs.Sanguosha:getCard(move.card_ids:first()):setFlags("wangeCard")
            local list = room:getTag("wangeCard"):toList()
            list:append(sgs.QVariant(move.card_ids:first()))
            room:setTag("wangeCard", sgs.QVariant(list))
            room:setPlayerFlag(player, "wangecard_fisrtflag")
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			--use.card:setFlags("-wangeCard")
            local list = room:getTag("wangeCard"):toList()
            if list:contains(sgs.QVariant(use.card:getEffectiveId())) then
                list:removeOne(sgs.QVariant(use.card:getEffectiveId()))
                room:setTag("wangeCard", sgs.QVariant(list))
            end
			local choice = room:askForChoice(sp, self:objectName(), "draw+wangeMusic", data)
			if choice == "draw" then
				sp:drawCards(1, self:objectName())
			else
		    	local NEWuse = sgs.CardUseStruct()
		    	NEWuse.from = sp
				NEWuse.to:append(use.from)
		    	NEWuse.card = sgs.Sanguosha:cloneCard("music", sgs.Card_NoSuit, -1)
		    	room:useCard(NEWuse, false)
			end
		end
		if event == sgs.Death then
			local targets = room:askForPlayersChosen(player, room:getOtherPlayers(player), self:objectName(), 1, 999, "&wange", true)
			room:sortByActionOrder(targets)
			local use = sgs.CardUseStruct()
			use.card = sgs.Sanguosha:cloneCard("music", sgs.Card_NoSuit, -1)
			use.from = player
			use.to = targets
			room:useCard(use, false)
		end
	end ,
}

Xujian = sgs.CreateTriggerSkill{
	name = "xujian",
	events = {sgs.CardsMoveOneTime, sgs.TargetConfirmed, sgs.CardFinished, sgs.EventPhaseChanging, sgs.EventPhaseStart},
	on_record = function(self, event, room, player, data)
		if event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card and use.card:isKindOf("Slash") and player:objectName() == use.from:objectName() and player:getMark("##xujian") > 0 then
				for _,p in sgs.qlist(use.to) do
					room:setPlayerMark(p, "Armor_Nullified", p:getMark("Armor_Nullified")+1)
					room:setPlayerMark(p, "xujian_null", 1)
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			for _,p in sgs.qlist(use.to) do
				if p:getMark("xujian_null") > 0 then
					room:setPlayerMark(p, "Armor_Nullified", p:getMark("Armor_Nullified")-1)
					room:setPlayerMark(p, "xujian_null", 0)
				end
			end
		end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive and player:getMark("##xujian") > 0 then
				room:setPlayerMark(player, "##xujian", 0)
			end
		end
	end,
	can_trigger = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then		
			local move = data:toMoveOneTime()
			if player and player:isAlive() and player:hasSkill(self:objectName()) and move.from and move.from:objectName() == player:objectName() and move.to and move.to:objectName() ~= player:objectName() and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.to_place == sgs.Player_PlaceHand then
				return self:objectName()
			end
		end
		if event == sgs.EventPhaseStart then
			if player and player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Play then
				if player:inHeadSkills(self) and player:hasShownGeneral2() and (string.find(player:getActualGeneral2Name(), "Oumashu") or not player:isNude()) then
					return self:objectName()
				end
				if player:inDeputySkills(self) and player:hasShownGeneral1() and (string.find(player:getActualGeneral1Name(), "Oumashu") or not player:isNude()) then
					return self:objectName()
				end				
			end
		end
		return ""
	end ,
	on_cost = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			local who = sgs.QVariant()
			who:setValue(findPlayerByObjectName(move.to:objectName()))
			if player:askForSkillInvoke(self, who) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
		if event == sgs.EventPhaseStart then
			if player:askForSkillInvoke(self, data) then
				room:broadcastSkillInvoke(self:objectName(), player)
				return true
			end
		end
	end ,
	on_effect = function(self, event, room, player, data)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			room:setPlayerMark(findPlayerByObjectName(move.to:objectName()), "##xujian", 1)
		end
		if event == sgs.EventPhaseStart then
			if (player:inHeadSkills(self) and player:hasShownGeneral2() and string.find(player:getActualGeneral2Name(), "Oumashu")) or (player:inDeputySkills(self) and player:hasShownGeneral1() and string.find(player:getActualGeneral1Name(), "Oumashu")) then
				room:setPlayerMark(player, "##xujian", 1)
			elseif not player:isNude() then
				local A = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "&xujian")
				local show_ids = room:askForExchange(player, self:objectName(), 1, 1, "&xujian_give", "", ".|.|.")
				local show_id = -1
				if show_ids:isEmpty() then
					show_id = player:getCards("he"):first():getEffectiveId()
				else
					show_id = show_ids:first()
				end
				local show = sgs.Sanguosha:getCard(show_id)
				local reason = sgs.CardMoveReason(0x17, player:objectName())
				room:obtainCard(A, show, reason, false)
			end
		end
	end,
}

XujianVS = sgs.CreateTargetModSkill{
	name = "xujianvs",
	residue_func = function(self, player)
		if player:getMark("##xujian") > 0 then
			return 1
		end
		return 0
	end,
}

Suou = sgs.CreateTriggerSkill{
	name = "suou",
	events = {sgs.EventPhaseEnd},
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.EventPhaseEnd then
			if  player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Draw then
                return self:objectName()
            end
		end	
        return ""
	end,
	on_cost = function(self, event, room, player, data, sp)
		if player:askForSkillInvoke(self, data) then
		    room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
        local choices = {}
        local e = 0
        for _,c in sgs.qlist(player:getCards("e")) do
            if c:isKindOf("Horse") and not c:isKindOf("OffensiveHorse") and not c:isKindOf("DefensiveHorse") then  --for special horses that take 2 places
                e = e+2
            else
                e = e+1
            end
        end
        local n = 5 - e
        if n > 0 then
            table.insert(choices, "suou_draw")
        end
        if player:getCards("e"):length() > 0 then
            table.insert(choices, "suou_move")
        end
        local choice = room:askForChoice(player, self:objectName(), table.concat(choices, "+"))
        if choice == "suou_draw" then
            while room:getDrawPile():length()<n do
                room:swapPile()
            end
            local list = sgs.IntList()
            local dis = sgs.IntList()
            local ids = sgs.IntList()
            for i=1 ,n ,1 do
                local id = room:getDrawPile():at(i-1)
                local c = sgs.Sanguosha:getCard(id)
                local same
                for _,e in sgs.qlist(player:getCards("e")) do
                    if e:getSuit() == c:getSuit() then same = true end
                end
                list:append(id)
                if not c:isKindOf("EquipCard") and (player:getEquips():length() == 0 or same) then dis:append(id) end
            end
            room:fillAG(list, player, dis)
            local id = room:askForAG(player, list, true, "suou")
            if id > -1 then
                ids:append(id)
                if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
                    dis:append(id)
                    for _,i in sgs.qlist(list) do
                        local c = sgs.Sanguosha:getCard(i)
                        if not c:isKindOf("EquipCard") and not dis:contains(i) then dis:append(i) end
                    end
                    room:clearAG(player)
                    room:fillAG(list, player, dis)
                    local id2 = room:askForAG(player, list, true, "suou")
                    if id2 > -1 then ids:append(id2) end
                end                
            end
            room:clearAG(player)
            for _,i in sgs.qlist(ids) do
               room:obtainCard(player, i)
            end
        end
        if choice == "suou_move" then
            local dest = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
            local id = room:askForCardChosen(player, player, "e", self:objectName())
            local reason = sgs.CardMoveReason(0x09, player:objectName(), self:objectName(), "")
			room:moveCardTo(sgs.Sanguosha:getCard(id), player, dest, sgs.Player_PlaceEquip, reason)
        end
	end,
}

WeizhenCard = sgs.CreateSkillCard{
    name = "WeizhenCard",
	filter = function(self, targets, to_select, Self)
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        local reason = sgs.Sanguosha:getCurrentCardUseReason()
        if pattern == "jink" then
            return false
        end
        if pattern == "slash" and (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
            return false
        end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local tos = sgs.PlayerList()
	    for _,p in ipairs(targets) do
		   tos:append(p)
	    end
        return slash:targetFilter(tos, to_select, Self)	 and slash:isAvailable(Self)
	end,
    feasible = function(self, targets)
        if pattern == "jink" then
            return #targets == 0
        end
        if pattern == "slash" and (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
            return #targets == 0
        end
		return #targets > 0
	end,
	on_use = function(self, room, source, targets)
        local players = sgs.SPlayerList()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getEquips():length() >= room:getCurrent():getEquips():length() and p:isFriendWith(source) and p:getEquips():length()>0 then
                players:append(p)
            end
        end
        if players:length() == 0 then return end
        local dest = room:askForPlayerChosen(source, players, "weizhen")
        local id = room:askForCardChosen(source, dest, "e", "weizhen")
        room:setPlayerFlag(source, "weizhen_used")

        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        if pattern == "jink" or (pattern == "slash" and (reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)) then
            local card = sgs.Sanguosha:cloneCard(pattern)
            card:setShowSkill("weizhen")
		    card:setSkillName("weizhen")
		    card:addSubcard(id)
            room:provide(card)
            dest:drawCards(1)
            return
        end

		local card = sgs.Sanguosha:cloneCard("slash")
		card:setShowSkill("weizhen")
		card:setSkillName("weizhen")
		card:addSubcard(id)
		local use = sgs.CardUseStruct()
		use.card = card
		use.from = source
		for _,p in ipairs(targets) do
			use.to:append(p)
		end
		room:useCard(use, true)
        dest:drawCards(1)
	end,
}

Weizhenvs = sgs.CreateZeroCardViewAsSkill{
	name = "weizhen",
	view_as = function(self)
		local new_card = WeizhenCard:clone()	
		return new_card		
	end,
    enabled_at_play = function(self, player)
		return not player:hasFlag("weizhen_used")
	end,
    enabled_at_response=function(self, player, pattern)
		return pattern == "@@weizhen"
	end,
}

Weizhen = sgs.CreateTriggerSkill{
    name = "weizhen",
    view_as_skill = Weizhenvs,
    can_preshow = true,
	events = {sgs.EventPhaseChanging, sgs.CardAsked},
	on_record = function(self, event, room, player, data)
	   if event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then
           for _,p in sgs.qlist(room:getAlivePlayers()) do
             room:setPlayerFlag(p, "-weizhen_used")
           end
	   end
	end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.CardAsked then
            local pattern = data:toList():first():toString()
            if (pattern == "jink" or pattern == "slash") and player:isAlive() and player:hasSkill(self:objectName()) and not player:hasFlag("weizhen_used") then 
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
		if player:askForSkillInvoke(self, data) then
            local players = sgs.SPlayerList()
            for _,p in sgs.qlist(room:getAlivePlayers()) do
                if p:getEquips():length() >= room:getCurrent():getEquips():length() and p:isFriendWith(player) and p:getEquips():length()>0 then
                   players:append(p)
                end
            end
            if players:length() == 0 then return false end
            local pattern = data:toList():first():toString()
            local dest = room:askForPlayerChosen(player, players, "weizhen")
            local id = room:askForCardChosen(player, dest, "e", "weizhen")
            room:setPlayerFlag(player, "weizhen_used")
            local card = sgs.Sanguosha:cloneCard(pattern)
            card:setShowSkill("weizhen")
		    card:setSkillName("weizhen")
		    card:addSubcard(id)
            room:provide(card)
            dest:drawCards(1)
			return true
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, sp)

    end
}

Taiji = sgs.CreateTriggerSkill{
	name = "taiji",
	events = {sgs.TargetConfirming},
	can_trigger = function(self, event, room, player, data)
	    if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			local players = room:findPlayersBySkillName(self:objectName())
			for _,sp in sgs.qlist(players) do
				if sp:isAlive() and sp:hasSkill("taiji") and use.card:isKindOf("Slash") and not sp:isNude() then 
					if sp:objectName() ~= player:objectName() and sp:objectName() == use.from:objectName() and use.to:length() == 1 then
						return self:objectName(), sp
					elseif sp:objectName() == player:objectName() and sp:objectName() ~= use.from:objectName() then
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
		if sp:askForSkillInvoke(self, dat) and room:askForCard(sp, ".|.|.|.", "@taiji-discard", data, self:objectName()) then
			room:broadcastSkillInvoke(self:objectName(), sp)
			return true
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
		if event == sgs.TargetConfirming then
		    local use = data:toCardUse()
			 local judge=sgs.JudgeStruct()
			 judge.who=sp
			 judge.pattern = "."
			 judge.good = true
			 judge.reason=self:objectName()
			 room:judge(judge)
			 local card1 = judge.card
			 local list = sgs.IntList()
			 list:append(card1:getEffectiveId())
		    if sp:objectName() ~= player:objectName() and sp:objectName() == use.from:objectName() then
			     room:askForDiscard(player, "taiji", 1, 1, false, true)
				 local judge=sgs.JudgeStruct()
				 judge.who=player
				 judge.pattern = "."
				 judge.good = true
				 judge.reason=self:objectName()
				 room:judge(judge)
				 local card2 = judge.card
				 list:append(card2:getEffectiveId())
				 if card1:getColor() == card2:getColor() then
				    room:fillAG(list, sp)
					idl = room:askForAG(sp, list, false, self:objectName())
					room:clearAG(sp)
					room:obtainCard(sp, idl)
					sp:setFlags("taiji_success")
				 else
                   	room:fillAG(list, player)
					idl = room:askForAG(player, list, false, self:objectName())
					room:clearAG(player)
					room:obtainCard(player, idl)			 
				 end
		    elseif sp:objectName() == player:objectName() and sp:objectName() ~= use.from:objectName() then	
                 room:askForDiscard(use.from, "taiji", 1, 1, false, true)
				 local judge=sgs.JudgeStruct()
				 judge.who=use.from
				 judge.pattern = "."
				 judge.good = true
				 judge.reason=self:objectName()
				 room:judge(judge)
				 local card2 = judge.card
				 list:append(card2:getEffectiveId())
				 if card1:getColor() == card2:getColor() then
				    room:fillAG(list, sp)
					idl = room:askForAG(sp, list, false, self:objectName())
					room:clearAG(sp)
					room:obtainCard(sp, idl)
					use.to:removeOne(sp)
			        data:setValue(use)
				 else  
				    room:fillAG(list, use.from)
					idl = room:askForAG(use.from, list, false, self:objectName())
					room:clearAG(use.from)
					room:obtainCard(use.from, idl) 
				 end	
            end
		end	
	end
}

Taijiglobal = sgs.CreateTriggerSkill{
	name = "taijiglobal",
	global = true,
	events = {sgs.CardFinished},
		priority = 2,	
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
		    if player:hasFlag("taiji_success") then
		       room:addPlayerHistory(player, use.card:getClassName(),-1)		  			
			end	
			player:setFlags("-taiji_success")
		end
		return ""
	end,
	on_cost = function(self, event, room, player, data)
		return false 
	end,
}

Hongquan = sgs.CreateTriggerSkill{
    name = "hongquan",
	events = {sgs.EventPhaseChanging, sgs.CardsMoveOneTime, sgs.EventPhaseEnd},
	on_record = function(self, event, room, player, data)
	   if event == sgs.CardsMoveOneTime then
           local move = data:toMoveOneTime()
           if bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD and (move.to_place == sgs.Player_DiscardPile or move.to_place == sgs.Player_PlaceTable) then
               if player == room:getCurrent() then
                    local list = room:getTag(player:objectName().."hongquan_record"):toList()
                    for _,id in sgs.qlist(move.card_ids) do
                        if not list:contains(sgs.QVariant(id)) then
                            list:append(sgs.QVariant(id))
                        end
                    end
                    room:setTag(player:objectName().."hongquan_record", sgs.QVariant(list))
               end
            end
	   end
       if event == sgs.EventPhaseChanging then
         local change = data:toPhaseChange()
         if change.to == sgs.Player_NotActive then
             room:setTag(player:objectName().."hongquan_record", sgs.QVariant())
         end
       end
	end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.EventPhaseEnd then
            local players = room:getOtherPlayers(player)
            for _,p in sgs.qlist(players) do
               if p:isKongcheng() then
                 players:removeOne(p)
               end
            end
            if player:isAlive() and player:hasSkill(self:objectName()) and player:getPhase() == sgs.Player_Finish and not players:isEmpty() then 
                return self:objectName()
            end
        end
        return ""
    end,
    on_cost = function(self, event, room, player, data, sp)
		if player:askForSkillInvoke(self, data) then
            local players = room:getOtherPlayers(player)
            for _,p in sgs.qlist(players) do
               if p:isKongcheng() then
                 players:removeOne(p)
               end
            end
            if players:isEmpty() then return false end
            local target = room:askForPlayerChosen(player, players, self:objectName())
            if target then
                room:setPlayerProperty(player, "hongquan_target", sgs.QVariant(target:objectName()))
                room:broadcastSkillInvoke(self:objectName(), player)
                return true
            end
		end
		return false
	end,
    on_effect = function(self, event, room, player, data, sp)
        local target = findPlayerByObjectName(player:property("hongquan_target"):toString())
        if not target or target:isKongcheng() then return false end
        local list = room:getTag(player:objectName().."hongquan_record"):toList()
        local h,d,s,c = 0, 0, 0, 0
        for _,m in sgs.qlist(list) do
            local id = m:toInt()
            local card = sgs.Sanguosha:getCard(id)
            if room:getDiscardPile():contains(id) then
               if card:getSuitString() == "heart" then h = 1 end
               if card:getSuitString() == "dismond" then d = 1 end
               if card:getSuitString() == "spade" then s = 1 end
               if card:getSuitString() == "club" then c = 1 end            
            end
        end
        room:showAllCards(target, player)
        local h1, d1, s1, c1 = 0, 0, 0, 0
        for _,card in sgs.qlist(target:getHandcards()) do
          if card:getSuitString() == "heart" then h1 = 1 end
          if card:getSuitString() == "dismond" then d1 = 1 end
          if card:getSuitString() == "spade" then s1 = 1 end
          if card:getSuitString() == "club" then c1 = 1 end    
        end
        if h1+d1+s1+c1 < h+d+s+c then
            local slash = sgs.Sanguosha:cloneCard("slash")
			local u = sgs.CardUseStruct()
			u.from = player
			u.to:append(target)
			u.card = slash
			room:useCard(u, false)
        end
    end
}

EhuanshenCard = sgs.CreateSkillCard{
	name = "EhuanshenCard",
	filter = function(self,targets, to_select, player) 
                return #targets < 1 and to_select:objectName() ~= player:objectName() and player:distanceTo(to_select) == 1
	end,
	on_use = function(self,room,source,targets)
		local dest = targets[1]
		dest:showGeneral(false)
		room:transformDeputyGeneralTo(dest,"Ellen")	
		room:detachSkillFromPlayer(dest,"ehuanshen",false, false, false)
		source:removeGeneral(source:inHeadSkills("ehuanshen"))
		local ahp = dest:getHp()
		local bhp = source:getHp()	
		room:setPlayerProperty(source, "hp", sgs.QVariant(math.min(ahp, source:getMaxHp())))
		room:setPlayerProperty(dest, "hp", sgs.QVariant(math.min(bhp, dest:getMaxHp())))	
	end
}

Ehuanshen = sgs.CreateViewAsSkill{
	name = "ehuanshen",
	n = 0,
	view_filter = function(self, selected, to_selected)
	end,
	view_as = function(self,cards)
		local vs_card = EhuanshenCard:clone()
        vs_card:setSkillName(self:objectName())
        vs_card:setShowSkill(self:objectName())
		return vs_card
	end
}

MowuCard = sgs.CreateSkillCard{
	name = "MowuCard",
	will_throw = false,
	filter = function(self, targets, to_select, Self)
        for _,p in sgs.qlist(sgs.Self:getAliveSiblings()) do
            if p:hasFlag("mowuflag") then
                return to_select == p
            end
        end
                return #targets < 1 and sgs.Self:distanceTo(to_select) == 1 and to_select:objectName() ~= Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		local target = targets[1]
	
		local subcards = self:getSubcards()
		local id = subcards:first()
		local card = sgs.Sanguosha:getCard(id)
	
		local suit = card:getSuit()
		local point = card:getNumber()
        local choice = room:askForChoice(source, "mowu", "slash+fire_slash+thunder_slash+ice_slash")
		local slash = sgs.Sanguosha:cloneCard(choice, suit ,point)
		slash:addSubcard(card)
		slash:setSkillName("mowu")
	    slash:setShowSkill("mowu")
		local use = sgs.CardUseStruct()
		use.from = source
		use.to:append(target)
		use.card = slash
		room:useCard(use, true)
	end,
}

Mowuvs = sgs.CreateViewAsSkill{
	name = "mowu",
	n = 1,
	view_filter = function(self, selected, to_selected)
        return not to_selected:isEquipped() and #selected < 1
	end,
	view_as = function(self,cards)
        if #cards == 0 then return nil end
		local vs_card = MowuCard:clone()
        vs_card:addSubcard(cards[1])
		return vs_card
	end,
    enabled_at_play=function(self, player)
        local slash = sgs.Sanguosha:cloneCard("slash")
		return not player:hasUsed("ViewAsSkill_mowuCard") and slash:isAvailable(player)
	end,
    enabled_at_response=function(self,player,pattern) 
		return pattern=="@@mowu"
	end,
}

Mowu = sgs.CreateTriggerSkill{
	name = "mowu",
	events = {sgs.TargetConfirmed},
	view_as_skill = Mowuvs,
    can_preshow = true,
	can_trigger = function(self, event, room, player, data)
		local use = data:toCardUse()
			if player:isAlive() and player:hasSkill(self:objectName()) and use.card:isKindOf("Slash") and use.to:contains(player) and use.from and use.from ~= player then
				return self:objectName()
			end
			return ""
		end,
	on_cost = function(self, event, room, player, data, ask_who)
		if player:askForSkillInvoke(self,data)  then
			local use = data:toCardUse()
			local dest = use.from
            room:setPlayerFlag(dest,"mowuflag")
		    if room:askForUseCard(player, "@@mowu", "@mowu")  then
                room:setPlayerFlag(dest,"-mowuflag")
                return true
		    end	
            room:setPlayerFlag(dest,"-mowuflag")
		end
		return false
	end,
	on_effect = function(self, event, room, player, data, ask_who)
			
	end
}

Youpiandis = sgs.CreateDistanceSkill{
	name = "#youpiandis",
	correct_func = function(self, from, to)
		if from:hasFlag(to:objectName().."youpian_target") or to:hasFlag(from:objectName().."youpian_target") then
			return -999
		end
	end
}

YoupianCard = sgs.CreateSkillCard{
	name = "YoupianCard",
	filter = function(self, targets, to_select, Self)
		return #targets < 1 and to_select:objectName() ~= Self:objectName()
	end,
	on_use = function(self, room, source, targets)
		for _,p in ipairs(targets) do
            room:setPlayerFlag(source, p:objectName().."youpian_target")
            if not room:askForUseSlashTo(p, source, "#youpian", true) then
               p:drawCards(1)
               room:setPlayerMark(source, p:objectName().."youpian_pro", 1)
               room:setPlayerMark(p, "##youpian", p:getMark("##youpian")+1)
            end
        end
	end,
}

Youpianvs = sgs.CreateZeroCardViewAsSkill{
	name = "youpian",
	view_as = function(self,cards)
		local vs_card = YoupianCard:clone()
        vs_card:setSkillName(self:objectName())
        vs_card:setShowSkill(self:objectName())
		return vs_card
	end,
    enabled_at_play=function(self,player)
		return not player:hasUsed("ViewAsSkill_youpianCard")
	end,
}

Youpian = sgs.CreateTriggerSkill{
	name = "youpian",
	events = {sgs.Damage, sgs.TrickCardCanceling, sgs.SlashProceed},
	view_as_skill = Youpianvs,
    on_record = function(self, event, room, player, data)
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark(damage.to:objectName().."youpian_pro")>0 then
                room:setPlayerMark(damage.from, damage.to:objectName().."youpian_pro", 0)
                room:setPlayerMark(damage.to, "##youpian", damage.to:getMark("##youpian")-1)
            end
        end
    end,
	can_trigger = function(self, event, room, player, data)
        if event == sgs.TrickCardCanceling then
            local effect = data:toCardEffect()
            if effect.from and effect.from:getMark(player:objectName().."youpian_pro")>0 then return self:objectName() end
        end
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            if effect.from and effect.to and effect.from:getMark(effect.to:objectName().."youpian_pro")>0 then return self:objectName() end
        end
		return ""
    end,
	on_cost = function(self, event, room, player, data, ask_who)
		if event == sgs.TrickCardCanceling or event == sgs.SlashProceed then
            return true
        end
	end,
	on_effect = function(self, event, room, player, data, ask_who)
		if event == sgs.TrickCardCanceling then
            --[[local effect = data:toCardEffect()
            local log = sgs.LogMessage()
            log.type = "$youpian_effect"
            log.from = effect.to
            log.arg = effect.card:objectName()
            room:sendLog(log);]]
            return true
        end
        if event == sgs.SlashProceed then
            local effect = data:toSlashEffect()
            local log = sgs.LogMessage()
            log.type = "$youpian_effect"
            log.from = effect.to
            log.arg = effect.slash:objectName()
            room:sendLog(log);
            room:slashResult(effect, nil)
            return true
        end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("lvjigive") then skills:append(Lvjigive) end
if not sgs.Sanguosha:getSkill("#yuejimod") then skills:append(Yuejimod) end
if not sgs.Sanguosha:getSkill("#yishimax") then skills:append(YishiMax) end
if not sgs.Sanguosha:getSkill("xujianvs") then skills:append(XujianVS) end
if not sgs.Sanguosha:getSkill("taijiglobal") then skills:append(Taijiglobal) end
sgs.Sanguosha:addSkills(skills)

Ruri:addSkill(Shengli)
Ruri:addSkill(Yishi)
extension:insertRelatedSkills("yishi", "#yishimax")
Ayanokoji:addSkill(Ance)
Ayanokoji:addSkill(Wuhen)
ManakaMiuna:addSkill(Hailian)
ManakaMiuna:addSkill(Langjing)
Elaina:addSkill(Lvji)
Elaina:addSkill(Fahui)
extension:insertRelatedAttachSkill("lvji", "lvjigive")
Aiz:addSkill(Jizou)
Origami:addSkill(Guangjian)
Origami:addSkill(Rilun)
Enju:addSkill(Yueji)
Enju:addSkill(Qishi)
sgs.insertRelatedSkills(extension, "yueji", "#yuejimod")
Inori:addSkill(Wange)
Inori:addSkill(Xujian)
Chisato:addSkill(Jieji)
Chisato:addSkill(Qianggan)
AliceM:addSkill(Suou)
AliceM:addSkill(Weizhen)
Meirin:addSkill(Taiji)
Meirin:addSkill(Hongquan)
Ellen:addSkill(Ehuanshen)
Ellen:addSkill(Mowu)
Ellen:addSkill(Youpian)
Ellen:addSkill(Youpiandis)
sgs.insertRelatedSkills(extension, "youpian", "#youpiandis")

sgs.LoadTranslationTable{
    ["hikarikage"] = "光影之章",

    ["Ruri"] = "五更琉璃",
    ["@Ruri"] = "我的妹妹不可能这么可爱！",
    ["#Ruri"] = "堕天圣黑猫",
    ["~Ruri"] = "很，很难受啊，不要这样。",
    ["designer:Ruri"] = "FlameHaze, 光临长夜",
    ["cv:Ruri"] = "花泽香菜",
    ["%Ruri"] = "“记载着在不久的将来，等待着恋人们的命运之预言书”",
    ["shengli"] = "圣狸「圣黑猫&圣白猫」",
    [":shengli"] = "<font color=\"green\"><b>每回合各限一次，</b></font>其他角色使用以你为目标的黑色牌结算后，你可以与其拼点，若你赢，你摸一张牌并可以对其使用一张【杀】；一名角色使用以你为目标的非黑色牌结算后，你可以与使用者各摸一张牌（使用者为你则累计摸一张牌）。",
    ["yishi"] = "仪式「命运记录」",
    [":yishi"] = "准备阶段开始时，你可以选择一名你势力的其他男性角色，你令你与其当中体力值较小的角色回复1点体力，手牌数较小的角色摸一张牌；若没有与你势力相同的其他男性角色，你可以令你本回合手牌上限+1。",
    ["yishi$"] = "image=image/animate/SE_Yishi.png",
    ["$yishi1"] = "请和我交往吧。",
    ["$yishi2"] = "我喜欢你，对君之爱，胜于世间万千，思君之情，亘古至斯，唯有此心，不逊他人，纵使魂消魄散，湮没于这尘世间，若有来生，爱你依旧。",
    ["$yishi3"] = "记载着在不久的将来，等待着恋人们的命运之预言书，大概是这种东西。而且还是为了实现我崇高愿望而进行的仪式阶段记录。",
    ["$yishi4"] = "和你交往之后，应该做些什么，我通宵在进行着思考与模拟。",
    ["$yishi5"] = "那个，前辈说要做的话，也是可以做的哦。",
    ["$shengli1"] = "梅露露，难道就是那个星尘☆小魔女梅露露么？那个小屁孩和脑残和狂热分子和尼特族家里蹲才会看的粪作？",
    ["$shengli2"] = "话说我最讨厌的字应该是从内容上来说异常值得批判的无知的猪吧，貌似你也是它们的伙伴呢，那就快来“噗”一声啊。",
    ["$shengli3"] = "你不会懂的，放弃吧。",
    ["$shengli4"] = "竟然能够到的这个地方，值得嘉奖呢。",
    ["$shengli5"] = "长点自知之明吧笨蛋！为什么我要和你这个...区区人类干那种不知羞耻的事。",
    ["$shengli6"] = "一个人的自我满足？自慰作品？谁管你啊，我只想把我自己想做的，自己真正在做的呈现出来而已。",
    ["$shengli7"] = "明明能和妹妹一起玩色情游戏，却不能和我玩文字游戏么？",
    ["#shengli"]  = "圣狸：你可以对来源使用一张【杀】",
    ["yishi_max"] = "仪式",

    ["Ayanokoji"] = "绫小路清隆",
    ["@Ayanokoji"] = "欢迎来到实力至上主义的教室",
    ["#Ayanokoji"] = "实力至上",
    ["~Ayanokoji"] = "一切都结束了。",
    ["designer:Ayanokoji"] = "樱内瑞业，光临长夜",
    ["cv:Ayanokoji"] = "千叶翔也",
    ["%Ayanokoji"] = "“要付出多少牺牲都无所谓，只要最后我胜出那就行了”",
    ["ance"] = "暗策",
    [":ance"] = "出牌阶段限一次，你可以将一张手牌交给一名其他角色，然后其可以使用一张【杀】或【相爱相杀】；然后本出牌阶段结束时，若该角色存活且其此阶段未造成或受到过伤害，其失去1点体力，你摸1张牌。",
    ["wuhen"] = "无痕",
    [":wuhen"] = "锁定技，你令你回合内受到的伤害-1；当其他角色失去最后的手牌时，若其存活，你可以令你对其发动“暗策”时交出的牌数改为“0~2张”至你出牌阶段结束（不能对已有此效果的角色发动）。",
    ["@ance_use"] = "暗策：使用一张【杀】或【相爱相杀】",
    ["$ance1"] = "没有人可以对不存在的事件进行判决",
    ["$ance2"] = "只要我们统一口径，学校也就不能再追究了",
    ["$ance3"] = "零分作战吗？真是有趣",
    ["$wuhen1"] = "想出这个计划的是堀北，我只是按命令行动而已",
    ["$wuhen2"] = "要是传出各种谣言你也会很困扰的吧",

    ["ManakaMiuna"] = "爱花&美海",
    ["&ManakaMiuna"] = "爱花美海",
    ["@ManakaMiuna"] = "来自风平浪静的明天",
    ["#ManakaMiuna"] = "海之祭女",
    ["~ManakaMiuna"] = "",
    ["%ManakaMiuna"] = "“为那场初恋所流下的泪水 融进了温暖的大海中”",
    ["designer:ManakaMiuna"] = "奇洛",
    ["cv:ManakaMiuna"] = "花泽香菜&小松未可子",
    ["hailian"] = "海恋",
    [":hailian"] = "出牌阶段限一次，你可以与一名有手牌的其他角色交换一张手牌，然后以此法获得装备牌的角色摸一张牌。",
    ["langjing"] = "浪静",
    [":langjing"] = "结束阶段结束时，你可以选择至多X+1名手牌数不大于2X角色的角色摸一张牌，然后若以此法选择的角色中此时男女性别数量相等，你回复一点体力。（X为你此回合造成伤害值总数）",
    ["@hailian"] = "海恋：选择一张交换的手牌",
    ["@langjing"] = "浪静：选择至多X+1名手牌数不大于2X的角色",

    ["Elaina"] = "依蕾娜",
    ["@Elaina"] = "魔女之旅",
    ["#Elaina"] = "灰之魔女",
    ["~Elaina"] = "晚安。",
    ["designer:Elaina"] = "光临长夜",
    ["cv:Elaina"] = "本渡枫",
    ["%Elaina"] = "“这位不输给色彩斑斓的鲜花美得如花般绽放的人是谁呢？没错，就是我”",
    ["lvji"] = "旅迹",
    [":lvji"] = "准备阶段开始时，你可以观看牌堆顶5张牌，选择一张置于人物牌上成为“记叙”，若为锦囊牌且与已有牌名皆不同，你摸一张牌；其他角色出牌阶段限一次，其可以将一张手牌当作“记叙”置于你人物牌上，若为锦囊牌且与已有牌名皆不同，其摸一张牌。（“记叙”上限为5）",
    ["fahui"] = "法慧",
    [":fahui"] = "当你使用一张指定目标的普通锦囊牌时，你可以弃置一张与其颜色相同的“记叙”，无视合法性增加或减少一名目标。出牌阶段限一次，你可以将一张手牌当作“记叙”中的一张基本牌或普通锦囊牌使用。",
    ["jixu_id"] = "记叙",
    ["lvjigive"] = "旅迹",
    ["$lvji1"] = "来说说我的故事吧。我是一个魔女，也是一个旅行者。",
    ["$lvji2"] = "旅途中充满了相遇与分别，同时也充满了选择。",
    ["$lvji3"] = "我自身可能也存在着别的选择-除我以外的可能性",
    ["$lvji4"] = "这位不输给色彩斑斓的鲜花，美得如花般绽放的人是谁呢？没错，就是我。",
    ["$fahui1"] = "呼~",
    ["$fahui2"] = "然后呢？你在那之后就被杀人魔剪掉了头发吗？你经历过的旅行与我相差甚远呢。",
    ["$fahui3"] = "一次又一次做出无法反悔的选择，才有了现在的我。",

    ["Aiz"] = "艾丝·华伦斯坦",
    ["@Aiz"] = "在地下城寻求邂逅是否搞错了什么",
    ["&Aiz"] = "艾丝",
    ["#Aiz"] = "剑姬",
    ["designer:Aiz"] = "FlameHaze",
    ["cv:Aiz"] = "大西沙织",
    ["%Aiz"] = "“袭卷吧”",
    ["~Aiz"] = "呃啊",
    ["jizou"] = "疾走",
    [":jizou"] = "每名角色的结束阶段开始时，你可以弃置一张牌，展示所有手牌（至少2张）或牌堆顶的两张牌。若展示的牌中：\n没有基本牌，则你从牌堆底摸两张牌；\n有【闪】，则你获得1枚阴阳鱼标记；\n有【杀】，则你可以无距离限制地使用其中一张。",
    ["&jizouDiscard"] = "你可以弃置一张牌，发动“疾走”",
    ["jizouHand"] = "展示所有手牌",
    ["jizouDrawPile"] = "展示牌堆顶的两张牌",
    ["&jizouShow"] = "请选择两张要展示的手牌",
    ["$jizou1"] = "Tempest",
    ["$jizou2"] = "风啊",
    ["$jizou3"] = "微型劲风",
    ["$jizou4"] = "我不会输的",
    ["$jizou5"] = "我要变得更强..更强..更强..",
    ["$jizou6"] = "嗞~呛~",

    ["Origami"] = "鸢一折纸",
    ["@Origami"] = "Date A Live",
    ["#Origami"] = "歼灭天使",
    ["designer:Origami"] = "Yuuki，FlameHaze",
    ["cv:Origami"] = "富㭴美铃",
    ["%Origami"] = "“我要、杀死它。杀死那个――天使”",
    ["~Origami"] = "什么？！",
    ["guangjian"] = "光剑",
    [":guangjian"] = "出牌阶段限一次，你可以将至多两张颜色不同的基本牌置于一名没有“光剑”的其他角色上记为“光剑”。当其他角色使用牌结算后，你可以将一张“光剑”当作【杀】视为对其使用之，然后若其没有“光剑”，你摸1张牌。",
    ["rilun"] = "日轮",
    [":rilun"] = "准备阶段开始时，若你手牌数大于体力值，你可以指定一个势力，弃置该势力数一半的牌（向上取整），视为对该势力角色使用一张【无限剑制】，然后若其未造成伤害，你从摸牌堆检索一张红桃牌。",
    ["$guangjian1"] = "光剑",
    ["$guangjian2"] = "我会为了打败精灵而施展这股力量。",
    ["$guangjian3"] = "嗞~嗞~（剑光声）",
    ["$rilun1"] = "灭绝天使！",
    ["$rilun2"] = "灭绝天使·日轮",
    ["$rilun3"] = "开什么玩笑？！我的意志不会改变，我的使命不会改变，我否定一切的精灵！",
    ["@rilun"] = "日轮：选择一名有明置人物牌的角色",
    ["@rilun_discard"] = "日轮：弃置等同该角色势力数一半的牌（向上取整）",

    ["Enju"] = "蓝原延珠",
    ["@Enju"] = "漆黑的子弹",
    ["#Enju"] = "Initiator",
    ["~Enju"] = "为什么？！",
    ["designer:Enju"] = "光临长夜",
    ["cv:Enju"] = "日高里菜",
    ["%Enju"] = "“人家是蓝原延珠，兔型起始者”",
    ["yueji"] = "跃击",
    [":yueji"] = "出牌阶段限一次，你可以{失去一点体力/弃置一张非装备牌}，视为对一名距离2以内的其他角色使用一张不计次数的{虚拟/对应实体牌为弃置牌}的【杀】。然后若你此次失去体力，此杀造成伤害+1；若你弃置红色牌，目标需要额外使用一张【闪】响应此杀；若你弃置黑色牌，此回合你使用【杀】的额定次数+1。",
    ["qishi"] = "起始",
    [":qishi"] = "当你受到濒死伤害时，若你没有“侵蚀”标记，你可以展示手牌中所有的红色牌。每展示一张红色牌，此伤害-1。然后若此伤害被防止，你获得一个“侵蚀”标记。<font color=\"#C0C0C0\"><b>永久技，</b></font>准备阶段开始时，若你有“侵蚀”标记，你失去“侵蚀”标记并失去一点体力。",
    ["qinshi"] = "侵蚀",
    ["$yueji1"] = "哈~啊~！！砰！",
    ["$yueji2"] = "没能踢飞",
    ["$yueji3"] = "你才是小豆丁呢！真无礼。",
    ["$qishi1"] = "人家是蓝原延珠，兔型起始者。",
    ["$qishi2"] = "莲太郎是正义的伙伴，世界上没有什么事是莲太郎做不到的！",

    ["Inori"] = "楪祈",
    ["@Inori"] = "罪恶王冠",
    ["#Inori"] = "葬仪的歌姬",
    ["~Inori"] = "集，一直留在我身边吧，因为我是集的伙伴，呐",
    ["designer:Inori"] = "FlameHaze",
    ["cv:Inori"] = "茅野愛衣",
    ["%Inori"] = "“集，拜托你了，使用我的力量”",
    ["xujian"] = "虚剑",
    [":xujian"] = "①其他角色获得你的牌后，可以令其获得效果V直到其回合结束：使用杀次数+1且无视防具。②出牌阶段开始，若你的另一张人物牌为“樱满集”则获得效果V直到回合结束，否则若另一张人物牌明置可以交给一名其他角色一张牌。",
    ["wange"] = "挽歌",
    [":wange"] = "每回合限一次，当其他角色获得你区域的仅一张牌时，此牌记为“挽歌”牌直到其失去此牌。其他角色使用“挽歌”牌后，你可以摸一张牌或视为对其使用一张音。当你阵亡时，视为对任意名其他角色使用一张音。",
    ["wangeA"] = "挽歌-标记此牌",
    ["wangeB"] = "挽歌-选择效果",
    ["wangeC"] = "挽歌-死亡用音",
    ["wangeMusic"] = "视为对其使用【音】",
    ["&wange"] = "你可以视为对任意名其他角色使用【音】",
    ["&xujian"] = "选择一名其他角色",
    ["&xujian_give"] = "选择一张牌交给其",
    ["$wange1"]="盛开的原野之花唷...",
    ["$wange2"]="人们为什么要互相伤害...",
    ["$xujian1"]="拜托了，大家，请使用我。",
    ["$xujian2"]="集，拜托你了，使用我的力量。",

    ["Chisato"] = "锦木千束",
    ["@Chisato"] = "Lycoris Recoil",
    ["#Chisato"] = "LC2808",
    ["designer:Chisato"] = "FlameHaze",
    ["cv:Chisato"] = "安济知佳",
    ["illustrator:Chisato"] = "絵葉ましろ",
    ["~Chisato"] = "竟然在这种时候.....再撑一下.....",
    ["%Chisato"] = "“想做的事最·优·先!”",
    ["jieji"] = "戒己",
    ---["jieji$"] = "image=image/animate/jieji.png",
    [":jieji"] = "锁定技，当你使用牌结算后，若此牌目标和初始目标均为不包含你的其他角色，则：若此牌未在此次结算中造成伤害，则你获得牌堆一张与其不同花色牌；否则你弃置一张牌。",-----且手牌花色数小于4，
    ["$jieji1"] = "这次又是什么？",
    ["$jieji2"] = "喔是喔，那你已经满足了吧。",
    ["qianggan"] = "强感",
    ["qianggan$"] = "image=image/animate/qianggan.png",
    [":qianggan"] = "<font color=\"green\"><b>每回合限一次，</b></font>①当前回合角色使用的杀被闪抵消时，若其在你攻击范围内，则你可以选择：\n1、获得牌堆x张不同花色牌（x为2与你手牌花色数之差）；\n2、使用一张手牌（不计次数）。",
    ["choice-qianggan-obtain"] = "获得牌堆x张不同花色牌（x为2与你手牌花色数之差）",
    ["choice-qianggan-use"] = "使用一张手牌（不计次数）",
    ["@qianggan_use"] = "选择将要使用的手牌",
    ["$qianggan1"] = "砰砰砰~砰！",
    ["$qianggan2"] = "啊~本店目前不接受工作委托，要说为什么的话~因为我们现在在夏威夷~",

    ["AliceM"] = "爱丽丝·玛格特罗伊德",
    ["&AliceM"] = "爱丽丝",
    ["@AliceM"] = "東方project",
    ["#AliceM"] = "七色的人偶使",
    ["~AliceM"] = "",
    ["%AliceM"] = "“只有锐气还是不减呢”",
    ["designer:AliceM"] = "网瘾少年",
    ["cv:AliceM"] = "",
    ["suou"] = "塑偶",
    [":suou"] = "摸牌阶段结束时，你可以选择一项:1.观看牌堆顶等同于你空置装备区数量的牌，选择其中至多两张装备牌获得之或者选择一张与你装备区牌（至少一张）花色皆不同的牌获得之。2. 将自己装备区一张牌置于其他角色装备区。",
    ["weizhen"] = "威阵",
    [":weizhen"] = "<font color=\"green\"><b>每回合限一次，</b></font>:你可以将一名装备区牌数量不小于当前回合角色且与你势力相同的角色的一张装备区牌当杀或闪使用或打出，然后该角色摸一张牌。",
    ["suou_draw"] = "观看牌堆顶并获得对应牌",
    ["suou_move"] = "移动自己一张装备区的牌",

    ["Meirin"] = "红美铃",
    ["@Meirin"] = "東方project",
    ["#Meirin"] = "华人小姑娘",
    ["~Meirin"] = "",
    ["%Meirin"] = "“先手必胜！”",
    ["designer:Meirin"] = "网瘾少年",
    ["cv:Meirin"] = "",
    ["taiji"] = "太极",
	[":taiji"] = "当你使用杀指定唯一目标/成为杀的目标时，你可以弃置一张牌进行一次判定，然后目标/来源须弃置一张牌（无牌不弃）进行一次判定。若判定牌颜色相同则此杀不计入本回合使用次数/此杀无效，你选择获得一张判定牌；否则目标/来源选择获得一张判定牌。",
	["@taiji-discard"] = "太极：弃置一张牌",
    ["hongquan"] = "虹拳",
    [":hongquan"] = "结束阶段结束时，你可以选择一名有手牌的其他角色观看其所有手牌，若其手牌花色数小于本回合进入弃牌堆的牌的花色数，你视为对其使用一张无距离限制的杀。",

    ["Ellen"] = "艾琳",
	["@Ellen"] = "魔女之家",
	["#Ellen"] = "渴望被爱的魔女",
    ["designer:Ellen"] = "clannad最爱",
    ["cv:Ellen"] = "",
    ["%Ellen"] = "“我依然没有彻底绝望，因为我一心一意想要获得值得被爱的身体”",
	["ehuanshen"] = "换身",
	[":ehuanshen"] ="出牌阶段，你可以指定一名与你距离为1的其他角色，你移除此人物牌，该角色将副将替换为“艾琳”且移除此技能，然后你与该角色交换体力值。",
	["mowu"] = "魔屋",
	[":mowu"] = "出牌阶段限一次，你可以将一张手牌当做任意属性【杀】对距离1以内的一名角色使用；当你成为其他角色【杀】的目标后，你可以将一张手牌当做任意属性【杀】对其使用",
	["@mowu"] = "魔屋",
	["~mowu"] = "将一张手牌当做杀对来源使用。",
	["youpian"] = "诱骗",
	[":youpian"] = "出牌阶段限一次，你可以指定其他一名角色，该角色与你距离互相为1至此回合结束，该角色选择：对你使用一张杀；摸一张牌，不能响应你的牌直到你对其造成伤害",
    ["#youpiandis"] = "诱骗",
    ["#youpian"] = "诱骗：对来源使用一张杀",
    ["$youpian_effect"] = "%from 受到“诱骗”的影响，无法响应 %arg 的效果。",

    ["HoshinoAi"] = "星野爱",
    ["@HoshinoAi"] = "我推的孩子",
    ["#HoshinoAi"] = "天才偶像大人",
    ["~HoshinoAi"] = "",
    ["designer:HoshinoAi"] = "Yuuki",
    ["cv:HoshinoAi"] = "高桥李依",

    ["TsukimiEiko"] = "月见英子",
    ["@TsukimiEiko"] = "派对浪客诸葛孔明",
    ["#TsukimiEiko"] = "地狱歌姬",
    ["~TsukimiEiko"] = "",
    ["designer:TsukimiEiko"] = "clannad最爱",
    ["cv:TsukimiEiko"] = "鬼头明里",
    ["fengliang"] = "逢亮",
    [":fengliang"] = "你的回合内或你成为普通锦囊目标时，与你势力相同的其他角色可以将一张手牌当做【金色宣言】使用。",
    ["zhuimeng"] = "追梦",
    [":zhuimeng"] = "出牌阶段限一次，如果你的手牌为全场最少，你可以把一张手牌当做【偶像之路】使用，如果你的手牌为全场最多，你可以把一张手牌当做【闪耀演唱】使用。",

}

return {extension}
