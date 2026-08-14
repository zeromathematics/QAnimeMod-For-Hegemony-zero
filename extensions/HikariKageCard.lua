extension = sgs.Package("hikarikagecard", sgs.Package_CardPack)

Zenith = sgs.CreateTrickCard{
	name = "zenith",
	class_name = "Zenith",
    subtype = "zenith",
    filter = function(self, targets, to_select)
        return to_select:objectName() ~= sgs.Self:objectName() and add_different_kingdoms(to_select, targets) and to_select:hasShownOneGeneral()
    end,
	available = function(self, player)
		return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
	end,
	about_to_use = function(self, room, card_use) --用这个函数在特殊条件下修改目标
        local use = card_use
	    if use.from:hasShownOneGeneral() and use.from:getKingdom() == "idol" and not use.to:contains(use.from) then
            use.to:append(use.from)
        end
		self:cardOnUse(room, use)
	end,
    on_use = function(self, room, source, targets) --每名目标之间的弃牌有关系所以不用on_effect
        local suits = {"spade", "heart", "diamond", "club"}
	    for _,target in ipairs(targets) do

            --对论破无懈势力的前置判断
            local nullified_list = room:getTag("CardUseNullifiedList"):toList()
            local effect = sgs.CardEffectStruct()
            effect.card = self
            effect.from = source
            effect.to = target
            --effect.multiple = false
            effect.nullified = nullified_list:contains(sgs.QVariant("_ALL_TARGETS")) or nullified_list:contains(sgs.QVariant(target:objectName())) --关键点

            local players = sgs.VariantList()

            for i = 1, #targets, 1 do  --关键点
                if not nullified_list:contains(sgs.QVariant("_ALL_TARGETS")) and not nullified_list:contains(sgs.QVariant(targets[i]:objectName())) then
                    local da = sgs.QVariant()
                    da:setValue(targets[i])
                    players:append(da)
                end
            end

            room:setTag("targets"..self:toString(), sgs.QVariant(players))  --关键点

            if not room:cardEffect(effect) then --因为没有写on_effect所以这里加上卡牌效果响应流程，否则不会触发相关事件比如询问金色宣言
                continue --被取消则跳过
            end
            local choices = "zenithchoice1+zenithchoice2"
            if not source:isWounded() then
                choices = "zenithchoice1"
            end
            local choice = room:askForChoice(target, self:objectName(), choices)
            if choice == "zenithchoice1" then
               if not target:isNude() then
                   if #suits == 0 then
                    if not target:isKongcheng() then
                       room:showAllCards(target)
                    end
                   else
                     local card = room:askForCard(target, ".|"..table.concat(suits, ",").."|.|.", "@zenith_discard")
                     if not card then
                        for _,c in sgs.qlist(target:getCards("he")) do
                            if table.contains(suits, c:getSuitString()) then
                                card = c
                                room:throwCard(c, target, target)
                                break
                            end
                        end
                     end
                     if card then
                        table.removeOne(suits, card:getSuitString())
                     else
                        if not target:isKongcheng() then
                            room:showAllCards(target)
                        end
                     end
                   end
               end
               source:drawCards(1)
            else
               local recover = sgs.RecoverStruct()
			   room:recover(source, recover, true)
            end
        end
        room:removeTag("targets"..self:toString()) --清除tag
    end,
}

Penlight = sgs.CreateTreasure{
    name = "penlight",
    class_name = "Penlight",
    suit = sgs.Card_Heart,
    number = 9,
    on_install=function(self,player)

    end,
    on_uninstall = function(self, player)

    end,
}

PenlightEffect = sgs.CreateTriggerSkill{
	name = "penlight",
    priority = 2,
	events = {sgs.Damage, sgs.Damaged},
	can_trigger = function(self, event, room, player, data)
        if event == sgs.Damage or event == sgs.Damaged then
            for _,sp in sgs.qlist(room:getAlivePlayers()) do
                if room:getCurrent():hasFlag(sp:objectName().."penlight_used") then continue end
                if sp and sp:getTreasure() and sp:getTreasure():objectName() == "penlight" and (sp:objectName() == player:getLastAlive():objectName() or sp:objectName() == player:getNextAlive():objectName()) then
                    return self:objectName(), sp
                end
            end
        end
        return ""
	end ,
	on_cost = function(self, event, room, player, data, sp)
        if event == sgs.Damage or event == sgs.Damaged then       
			local who = sgs.QVariant()
			who:setValue(player)
			if sp:askForSkillInvoke(self, who) then
                room:getCurrent():setFlags(sp:objectName().."penlight_used")
				return true
			end
        end
		return false
	end,
	on_effect = function(self, event, room, player, data, sp)
        if event == sgs.Damage or event == sgs.Damaged then       
			sp:drawCards(1)
            player:drawCards(1)
        end     
	end,
}

local cards = sgs.CardList()

cards:append(Zenith:clone(3, 12))
cards:append(Penlight:clone(2, 9))

for _,c in sgs.qlist(cards) do
   c:setParent(extension)
end

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("penlight") then skills:append(PenlightEffect) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
    ["hikarikagecard"] = "光影之章",

    ["zenith"] = "如日中天",
	[":zenith"] = "锦囊牌<br />出牌时机：出牌阶段<br />使用目标：对任意名势力已确定且各不相同的其他角色使用。<br />作用效果：目标角色选择一项：1.弃置一张此次未弃置过的花色的牌（无法弃置则展示手牌），你摸一张牌；2.你回复1点体力。<br />歌：偶像势力使用者额外指定自己为目标。<br />",
    ["zenithchoice1"] = "弃置一张此次未弃置过的花色的牌（无法弃置则展示手牌），来源摸一张牌",
    ["zenithchoice2"] = "来源回复1点体力",
    ["@zenith_discard"] = "弃置一张此次未弃置过的花色的牌（无法弃置则展示手牌），点取消则随机弃置一张符合条件的牌",

    ["penlight"] = "应援棒",
	[":penlight"] = "装备牌·宝物\n\n技能：每回合限一次，一名与你相邻的角色受到或造成伤害后，你可以与其各摸一张牌。",
}
   
return extension