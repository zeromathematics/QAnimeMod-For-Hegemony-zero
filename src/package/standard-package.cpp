/********************************************************************
    Copyright (c) 2013-2015 - Mogara

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
    *********************************************************************/

#include "standard-package.h"
#include "exppattern.h"
#include "card.h"
#include "skill.h"

//Xusine: we can put some global skills in here,for example,the Global FakeMove.
//just for convenience.

class GlobalFakeMoveSkill : public TriggerSkill { 
public:
    GlobalFakeMoveSkill() : TriggerSkill("global-fake-move") {
        events << BeforeCardsMove << CardsMoveOneTime;
        global = true;
    }

    virtual int getPriority() const{
        return 10;
    }

    virtual QStringList triggerable(TriggerEvent, Room *, ServerPlayer *target, QVariant &, ServerPlayer * &) const{
        return (target != NULL) ? QStringList(objectName()) : QStringList();
    }

    virtual bool effect(TriggerEvent , Room *room, ServerPlayer *, QVariant &, ServerPlayer *) const{
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->hasFlag("Global_InTempMoving"))
                return true;
        }

        return false;
    }

};

AnimeShanaCard::AnimeShanaCard()
{
    target_fixed = true;
    m_skillName = "animeshana";
}

void AnimeShanaCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    room->removePlayerMark(player, "animeshana");
    player->drawCards(1, "animeshana");
}

class AnimeShana : public ZeroCardViewAsSkill
{
public:
    AnimeShana() : ZeroCardViewAsSkill("animeshana")
    {
        frequency = Limited;
        limit_mark = "animeshana";
        guhuo_type = "e";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("animeshana") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new AnimeShanaCard;
    }
};

HalfMaxHpCard::HalfMaxHpCard()
{
    target_fixed = true;
    m_skillName = "halfmaxhp";
}

void HalfMaxHpCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    room->removePlayerMark(player, "@halfmaxhp");
    player->drawCards(1, "halfmaxhp");
}

class HalfMaxHp : public ZeroCardViewAsSkill
{
public:
    HalfMaxHp() : ZeroCardViewAsSkill("halfmaxhp")
    {
        frequency = Limited;
        limit_mark = "@halfmaxhp";
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@halfmaxhp") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new HalfMaxHpCard;
    }
};

class HalfMaxHpMaxCards : public MaxCardsSkill
{
public:
    HalfMaxHpMaxCards() : MaxCardsSkill("halfmaxhp-maxcards")
    {
    }

    virtual int getExtra(const ServerPlayer *target, MaxCardsType::MaxCardsCount) const
    {
        if (target->hasFlag("HalfMaxHpEffect"))
            return 2;
        return 0;
    }
};

StandardPackage::StandardPackage()
    : Package("standard")
{
    addWeiGenerals();
    addShuGenerals();
    addWuGenerals();
    addQunGenerals();

    addMetaObject<AnimeShanaCard>();
    addMetaObject<HalfMaxHpCard>();

    skills << new GlobalFakeMoveSkill << new AnimeShana << new HalfMaxHp << new HalfMaxHpMaxCards;

    patterns["."] = new ExpPattern(".|.|.|hand");
    patterns[".S"] = new ExpPattern(".|spade|.|hand");
    patterns[".C"] = new ExpPattern(".|club|.|hand");
    patterns[".H"] = new ExpPattern(".|heart|.|hand");
    patterns[".D"] = new ExpPattern(".|diamond|.|hand");

    patterns[".black"] = new ExpPattern(".|black|.|hand");
    patterns[".red"] = new ExpPattern(".|red|.|hand");

    patterns[".."] = new ExpPattern(".");
    patterns["..S"] = new ExpPattern(".|spade");
    patterns["..C"] = new ExpPattern(".|club");
    patterns["..H"] = new ExpPattern(".|heart");
    patterns["..D"] = new ExpPattern(".|diamond");

    patterns[".Basic"] = new ExpPattern("BasicCard");
    patterns[".Trick"] = new ExpPattern("TrickCard");
    patterns[".Equip"] = new ExpPattern("EquipCard");

    patterns[".Weapon"] = new ExpPattern("Weapon");
    patterns["slash"] = new ExpPattern("Slash");
    patterns["jink"] = new ExpPattern("Jink");
    patterns["peach"] = new  ExpPattern("Peach");
    patterns["nullification"] = new ExpPattern("Nullification");
    patterns["peach+analeptic+guangyucard"] = new ExpPattern("Peach,Analeptic,GuangyuCard");
    patterns["peach+guangyucard"] = new ExpPattern("Peach,GuangyuCard");
}

ADD_PACKAGE(Standard)


TestPackage::TestPackage()
: Package("test")
{
    new General(this, "sujiang", "god", 5, true, true);
    new General(this, "sujiangf", "god", 5, false, true);

    new General(this, "anjiang", "god", 5, true, true, true);
    new General(this, "anjiang_head", "god", 5, true, true, true);
    new General(this, "anjiang_deputy", "god", 5, true, true, true);

    // developers
    new General(this, "slob", "programmer", 9, true, true, true);
}

ADD_PACKAGE(Test)


StandardCardPackage::StandardCardPackage()
: Package("standard_cards", Package::CardPack)
{
    QList<Card *> cards;

    cards << basicCards() << equipCards() << trickCards();

    foreach (Card *card, cards)
        card->setParent(this);

    addEquipSkills();
}

ADD_PACKAGE(StandardCard)

