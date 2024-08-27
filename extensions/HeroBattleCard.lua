--[[extension = sgs.Package("herobattlecard", sgs.Package_CardPack)

Music = sgs.CreateBasicCard{
	name = "music",
	class_name = "Music",
	subtype = "assist_card",
    filter = function(self, targets, to_select)
        return #targets < 1
    end,
	available = function(self, player)
		return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
	end,
	on_use = function(self, room, source, targets)
		room:cardEffect(self, source, source)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
	end,
}

Shinai=sgs.CreateWeapon{
    name="shinai",
    class_name="Shinai",
    suit=sgs.Card_Diamond,
    number=1,
    range =2,
    target_fixed = false,
    filter = function(self, targets, to_select, player)
        return player:distanceTo(to_select)<=1 and (player:objectName()==to_select:objectName() or not to_select:getWeapon()) and #targets<1
    end,
    on_install=function(self,player)

    end,
    on_uninstall = function(self, player)

    end,
}

local cards = sgs.CardList()

cards:append(Music:clone(0, 9))
cards:append(Music:clone(2, 8))
cards:append(Music:clone(3, 10))
cards:append(Music:clone(1, 11))
cards:append(Shinai)

for _,c in sgs.qlist(cards) do
   c:setParent(extension)
end]]

sgs.LoadTranslationTable{
    ["herobattlecard"] = "诸神之章",

    ["music"] = "音",
	[":music"] = "基本牌<br />出牌时机：出牌阶段<br />使用目标：一名角色<br />作用效果：目标从以下选项里选一个数值+1直到其下次进入其回合结束时：1.手牌上限。2.攻击范围。3.其他角色与自己的距离。4.一回合使用杀次数。<br />",
    ["#MusicTimes"] = "本回合使用“音”的累计次数为 %arg",
    ["music_maxh"] = "手牌上限+1",
    ["music_range"] = "攻击范围+1",
    ["music_distance"] = "其他角色与自己的距离+1",
    ["music_moreslash"] = "一回合使用杀的次数+1",
    ["#MusicTimesmusicmaxh"] = "%from 令其手牌上限+1",
    ["#MusicTimesmusicrange"] = "%from 攻击范围+1",
    ["#MusicTimesmusicdistance"] = "%from 令其他角色与自己计算距离+1",
    ["#MusicTimesmusicmoreslash"] = "%from 令其一回合使用杀次数+1",
    ["musicmaxh"] = "音（手牌）",
    ["musicrange"] = "音（范围）",
    ["musicdistance"] = "音（距离）",
    ["musicmoreslash"] = "音（出杀）",

    ["multi_card"] = "多功能牌",
    ["clowcard"] = "变",
	[":clowcard"] = "基本牌<br />作用效果：在合适的时机，此牌可以当作【杀】或【闪】使用或打出。此牌以其他特殊方法使用时，以使用杀的方式指定目标，但不对目标产生效果。<br />",
   
    ["Shinai"] = "竹刀",
    [":Shinai"] = "装备牌·武器\n\n攻击范围：2\n技能：出牌阶段，手牌/装备区的此牌可以指定距离1以内的角色为目标（不能替换其他角色装备，装备区每回合以此法使用限一次）。锁定技，你使用杀时，其视为普通杀；你的杀造成的伤害-1；你使用杀指定多个目标后，此杀无效；你使用杀结算后，此杀目标依次摸1张牌。",

    ["Josou"] = "女装",
    [":Josou"] = "装备牌·防具\n技能：出牌阶段，手牌/装备区的此牌可以指定距离1以内的角色为目标（不能替换其他角色装备，装备区每回合以此法使用限一次）。锁定技，此牌进入或离开一名男性角色装备区时，其弃置一张手牌；装备此牌的男性角色手牌上限-1。当你受到异性角色造成的伤害时，你可以弃置装备区的此牌，防止此伤害。",
    ["#Josou"] = "%from 防止了 %to 对其造成的 %arg 点伤害[%arg2]",
    
    ["MagicBroom"] = "魔法扫把",
    [":MagicBroom"] = "装备牌·坐骑\n\n技能：其他角色与你的距离+1。",

    ["Idolyousei"] = "偶像养成",
	[":Idolyousei"] = "装备牌·宝物\n\n技能：锁定技，此牌进入装备区时，你视为使用一张【音】。当你装备区装备此牌时，你的【音】获得的效果不会消失。",
	["@Idolyousei"] = "你可以发动【偶像养成】，视为你使用一张【音】",
	["~Idolyousei"] = "选择【音】的目标→点击确定",
    ["#IdolyouseiEffect"] = "由于【偶像养成】的效果，%from的【音】效果不消失",

    ["igiari"] = "异议",
	[":igiari"] = "锦囊牌\n\n使用时机：一张 基本牌/金色宣言/论破/异议 对一个目标生效前。\n使用目标：一张对一个目标生效前的 基本牌/金色宣言/论破/异议。\n作用效果：抵消此 基本牌/金色宣言/论破/异议。",
    ["#IgiariDetails"] = "【<font color=\"yellow\"><b>异议</b></font>】的目标是 %from 对 %to 的基本牌 【%arg】", 
    ["#IgiariDetails1"] = "【<font color=\"yellow\"><b>异议</b></font>】的目标是 %from 对 %to 的錦囊 【%arg】", 

    ["Negi"] = "大葱",
    [":Negi"] = "装备牌·武器\n\n攻击范围：2\n技能：<font color=\"green\"><b>每回合限两次，</b></font>当你的【杀】造成伤害后，你可以将一张手牌当作【音】使用。",
    ["@Negi"] = "大葱",
    ["~Negi"] = "将一张手牌当作【音】使用",

    ["Idolclothes"] = "打歌服",
    [":Idolclothes"] = "装备牌·防具\n技能：当你成为一张牌的非唯一目标时，你可以选择一项：1，此牌对你取消之。2，此牌对你以外的目标取消之。",
    ["ic_self"] = "此牌对你取消之",
    ["ic_others"] = "此牌对你以外的目标取消之",

    ["shining_concert"] = "闪耀演唱",
    [":shining_concert"] = "锦囊牌\n\n使用时机：出牌阶段 \n使用目标：其他角色。\n作用效果：目标选择一项或选择不执行：1，摸一张牌。2，(你令)回复一点体力。若目标为偶像势力，可选择依次执行两项效果。若目标没有选择不执行，你获得其一张牌。",
    ["sc_draw"] = "摸一张牌",
    ["sc_recover"] = "回复一点体力",
    ["sc_drboth"] = "依次执行两项效果",

    ["idol_road"] = "偶像之路",
	[":idol_road"] = "锦囊牌\n\n使用时机：出牌阶段。\n使用目标：你。\n作用效果：你选择一项：1，明置一张人物牌，摸2张牌。 2，摸X张牌（X为你本局发动【偶像之路】次数且最多为存活人数）。",
    ["ir_draw"] = "摸X张牌",

    ["himitsu_koudou"] = "秘密行动",
    [":himitsu_koudou"] = "锦囊牌\n\n使用时机：一名其他角色在出牌阶段内摸牌后，若其手牌大于体力上限。\n使用目标：无。\n作用效果：你将此牌交给当前回合角色，终止此次询问流程，然后若此牌有颜色，该角色此回合不能使用或打出与此牌颜色相同的牌。此牌不能被金色宣言/论破响应。",
    ["#HimitsuRedDetails"] = "%from 获得了 %arg 的【<font color=\"yellow\"><b>秘密行动</b></font>】，此回合不能使用或打出红色牌。",
    ["#HimitsuBlackDetails"] = "%from 获得了 %arg 的【<font color=\"yellow\"><b>秘密行动</b></font>】，此回合不能使用或打出黑色牌。",

    ["member_recruitment"] = "部员募集",
    [":member_recruitment"] = "锦囊牌\n\n使用时机：出牌阶段，若你有明置人物牌。\n使用目标：自己。\n作用效果：你发起一次单体势力召唤，若有人响应，你和该角色各摸1张牌，然后若你有明置社团技，该角色可选择加入其中一个社团；若无人响应/执行效果时你无明置人物牌，你摸一张牌。",

}
   
   --return extension
