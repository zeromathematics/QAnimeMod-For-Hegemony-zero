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
#include "engine.h"
#include "structs.h"
#include "gamerule.h"
#include "settings.h"
#include "exppattern.h"
#include "card.h"
#include "skill.h"
#include "standard-basics.h"
#include "json.h"

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

class GlobalClear : public TriggerSkill
{
public:
    GlobalClear() : TriggerSkill("#global-clear")
    {
        events << EventPhaseStart << EventPhaseChanging << CardFinished << TurnStart;
        global = true;
    }

    virtual bool triggerable(const ServerPlayer *) const
    {
        return false;
    }

    virtual void record(TriggerEvent triggerEvent, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (triggerEvent == TurnStart && !player->hasFlag("Point_ExtraTurn")) {
            if (room->getTag("ruler_card_turn").toString() == player->objectName()){
                room->setTag("ruler_card_turn", QVariant());
                foreach(auto p, room->getOtherPlayers(player)){
                   room->setPlayerMark(p, "ruler_card_turn", 0);
                }
            }
        }
        if (triggerEvent == EventPhaseStart) {
            if (player->getPhase() == Player::NotActive) {
                foreach (ServerPlayer *p, room->getAlivePlayers()) {
                    //room->setPlayerMark(p, "GlobalDiscardCount", 0);
                    room->setPlayerMark(p, "GlobalKilledCount", 0);
                    room->setPlayerMark(p, "GlobalInjuredCount", 0);
                    room->setPlayerMark(p, "Global_MaxcardsIncrease", 0);
                    room->setPlayerMark(p, "Global_MaxcardsDecrease", 0);
                    p->tag.remove("RoundUsedCards");
                    p->tag.remove("RoundRespondedCards");
                    p->tag.remove("PhaseUsedCards");
                    p->tag.remove("PhaseRespondedCards");

                    room->setPlayerMark(p, "skill_invalidity", 0);
                    room->setPlayerMark(p, "skill_invalidity_head", 0);
                    room->setPlayerMark(p, "skill_invalidity_deputy", 0);
                    room->setPlayerProperty(p, "usecard_targets", QVariant());

                    room->setPlayerMark(p, "Global_DamagePiont_Round", 0);
                    room->setPlayerMark(p, "Global_InjuredPiont_Round", 0);


                }
            }
        } else if (triggerEvent == EventPhaseChanging) {
            foreach (ServerPlayer *p, room->getAlivePlayers()) {
                room->setPlayerMark(p, "GlobalLoseCardCount", 0);
                room->setPlayerMark(p, "Global_InjuredTimes_Phase", 0);
                room->setPlayerProperty(p, "Global_DamagePlayers_Phase", QVariant());
            }
        }
        else if(triggerEvent == CardFinished){
            CardUseStruct use = data.value<CardUseStruct>();
            if (use.card->isKindOf("RulerCard")){
                int n = 0;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->getMark("@rulers")>n){
                        n= p->getMark("@rulers");
                    }
                }
                QList<ServerPlayer *> list;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->getMark("@rulers")==n){
                        list << p;
                    }
                    room->setPlayerMark(p, "@rulers", 0);
                }
                room->sortByActionOrder(list);
                if (list.length()==1){
                    foreach(auto p, list){
                        room->loseHp(p);
                    }
                }

            }
        }
    }
};

CompanionCard::CompanionCard()
{
    target_fixed = true;
    m_skillName = "companion";
}

void CompanionCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@companion");
}

void CompanionCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    Peach *peach = new Peach(Card::NoSuit, 0);
    peach->setSkillName("_companion");

    ServerPlayer *dying = room->getCurrentDyingPlayer();
    if (dying && dying->hasFlag("Global_Dying") && !player->isLocked(peach) && !player->isProhibited(dying, peach)) {
        room->useCard(CardUseStruct(peach, player, dying));
        return;
    }

    if (peach->isAvailable(player) && room->askForChoice(player, "companion", "peach+draw", QVariant()) == "peach")
        room->useCard(CardUseStruct(peach, player, player));
    else
        player->drawCards(2, "companion");
}

class Companion : public ZeroCardViewAsSkill
{
public:
    Companion() : ZeroCardViewAsSkill("companion")
    {
        frequency = Limited;
        limit_mark = "@companion";
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@companion") > 0;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach") && player->getMark("@companion") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new CompanionCard;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("Peach") ? 0 : -1;
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
        int n = 0;
        if (target->hasFlag("HalfMaxHpEffect"))
            n = n+2;
        if (target->hasFlag("CareermanEffect"))
            n = n+2;
        return n;
    }
};

FirstShowCard::FirstShowCard()
{
    m_skillName = "firstshow";
}

bool FirstShowCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const
{
    return targets.isEmpty() && !to_select->hasShownAllGenerals() && to_select != Self;
}

bool FirstShowCard::targetsFeasible(const QList<const Player *> &targets, const Player *Self) const
{
    foreach (const Player *p, Self->getAliveSiblings()) {
        if (!p->hasShownAllGenerals())
            return targets.length() == 1;
    }
    return targets.length() == 0;
}

void FirstShowCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@firstshow");
}

void FirstShowCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &targets) const
{
    player->fillHandCards(4, "firstshow");

    if (targets.isEmpty()) return;

    ServerPlayer *to = targets.first();

    QStringList choices;
    if (!to->hasShownGeneral1())
        choices << "head_general";
    if (to->getGeneral2() && !to->hasShownGeneral2())
        choices << "deputy_general";

    if (choices.isEmpty()) return;
    to->setFlags("XianquTarget");// For AI
    QString choice = room->askForChoice(player, "firstshow_see", choices.join("+"), QVariant::fromValue(to));
    to->setFlags("-XianquTarget");

    LogMessage log;
    log.type = "#KnownBothView";
    log.from = player;
    log.to << to;
    log.arg = choice;
    foreach (ServerPlayer *p, room->getOtherPlayers(player, true)) {
        room->doNotify(p, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
    }


    QStringList list = room->getTag(to->objectName()).toStringList();
    list.removeAt(choice == "head_general" ? 1 : 0);
    foreach (const QString &name, list) {
        LogMessage log;
        log.type = "$KnownBothViewGeneral";
        log.from = player;
        log.to << to;
        log.arg = name;
        log.arg2 = choice;
        room->doNotify(player, QSanProtocol::S_COMMAND_LOG_SKILL, log.toVariant());
    }
    JsonArray arg;
    arg << "firstshow";
    arg << JsonUtils::toJsonArray(list);
    room->doNotify(player, QSanProtocol::S_COMMAND_VIEW_GENERALS, arg);

}

class FirstShow : public ZeroCardViewAsSkill
{
public:
    FirstShow() : ZeroCardViewAsSkill("firstshow")
    {
        frequency = Limited;
        limit_mark = "@firstshow";
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        if (player->getMark(limit_mark) > 0) {
            if (player->getHandcardNum() < 4) return true;
            foreach (const Player *p, player->getAliveSiblings()) {
                if (!p->hasShownAllGenerals())
                    return true;
            }
        }
        return false;
    }

    virtual const Card *viewAs() const
    {
        return new FirstShowCard;
    }
};

CareermanCard::CareermanCard()
{
    target_fixed = true;
    m_skillName = "careerman";
}

void CareermanCard::extraCost(Room *room, const CardUseStruct &card_use) const
{
    room->removePlayerMark(card_use.from, "@careerist");
}

void CareermanCard::use(Room *room, ServerPlayer *player, QList<ServerPlayer *> &) const
{
    Peach *peach = new Peach(Card::NoSuit, 0);
    peach->setSkillName("_careerman");

    ServerPlayer *dying = room->getCurrentDyingPlayer();
    if (dying && dying->hasFlag("Global_Dying") && !player->isLocked(peach) && !player->isProhibited(dying, peach)) {
        room->useCard(CardUseStruct(peach, player, dying));
        return;
    }

    QStringList choices, all_choices;
    all_choices << "draw1card" << "draw2cards" << "peach" << "firstshow";
    choices << "draw1card" << "draw2cards";
    if (peach->isAvailable(player))
        choices << "peach";
    if (player->getHandcardNum() < 4)
        choices << "firstshow";
    else {
        QList<ServerPlayer *> allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (!p->hasShownAllGenerals()) {
                choices << "firstshow";
                break;
            }
        }
    }

    QString choice = room->askForChoice(player, "careerman", choices.join("+"), QVariant());

    if (choice == "draw1card") {
        player->drawCards(1, "careerman");
    }
    if (choice == "draw2cards") {
        player->drawCards(2, "careerman");
    }
    if (choice == "peach") {
        room->useCard(CardUseStruct(peach, player, player));
    }
    if (choice == "firstshow") {
        QList<ServerPlayer *> targets, tos;

        QList<ServerPlayer *> allplayers = room->getAlivePlayers();
        foreach (ServerPlayer *p, allplayers) {
            if (!p->hasShownAllGenerals()) {
                targets << p;
            }
        }

        if (!targets.isEmpty()) {
            ServerPlayer *victim = room->askForPlayerChosen(player, targets, "careerman", "@careerman-target");
            room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), victim->objectName());
            tos << victim;
        }

        FirstShowCard firstshow_card;
        firstshow_card.use(room, player, tos);
    }
}

class Careerman : public ZeroCardViewAsSkill
{
public:
    Careerman() : ZeroCardViewAsSkill("careerman")
    {
        frequency = Limited;
        limit_mark = "@careerist";
        attached_lord_skill = true;

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getMark("@careerist") > 0;
    }

    virtual bool isEnabledAtResponse(const Player *player, const QString &pattern) const
    {
        return pattern.contains("peach") && !player->hasFlag("Global_PreventPeach") && player->getMark("@careerist") > 0;
    }

    virtual const Card *viewAs() const
    {
        return new CareermanCard;
    }

    virtual int getEffectIndex(const ServerPlayer *, const Card *card) const
    {
        return card->isKindOf("Peach") ? 0 : -1;
    }
};

ShowHeadCard::ShowHeadCard()
{
    target_fixed = true;
}

const Card *ShowHeadCard::validate(CardUseStruct &card_use) const
{
    card_use.from->showGeneral();
    return NULL;
}

ShowDeputyCard::ShowDeputyCard()
{
    target_fixed = true;
}

const Card *ShowDeputyCard::validate(CardUseStruct &card_use) const
{
    card_use.from->showGeneral(false);
    return NULL;
}

class ShowHead : public ZeroCardViewAsSkill
{
public:
    ShowHead() : ZeroCardViewAsSkill("showhead")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return !player->hasShownGeneral1() && player->canShowGeneral("h");
    }

    virtual const Card *viewAs() const
    {
        return new ShowHeadCard;
    }
};

class ShowDeputy : public ZeroCardViewAsSkill
{
public:
    ShowDeputy() : ZeroCardViewAsSkill("showdeputy")
    {

    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return player->getGeneral2() && !player->hasShownGeneral2() && player->canShowGeneral("d");
    }

    virtual const Card *viewAs() const
    {
        return new ShowDeputyCard;
    }
};

class ScenecardDisplay : public ZeroCardViewAsSkill
{
public:
    ScenecardDisplay() : ZeroCardViewAsSkill("scenecarddisplay")
    {
        guhuo_type = "mm";
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return true;
    }

    virtual const Card *viewAs() const
    {
        return NULL;
    }
};
class EventcardDisplay : public ZeroCardViewAsSkill
{
public:
    EventcardDisplay() : ZeroCardViewAsSkill("eventcarddisplay")
    {
        guhuo_type = "mmm";
        attached_lord_skill = true;
    }

    virtual bool isEnabledAtPlay(const Player *player) const
    {
        return true;
    }

    virtual const Card *viewAs() const
    {
        return NULL;
    }
};

class SpecialCards_Trigger : public TriggerSkill
{
public:
    SpecialCards_Trigger() : TriggerSkill("SpecialCards_Trigger")
    {
        events << GeneralShown << Death << BuryVictim;
        global = true;
    }


    virtual TriggerList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        TriggerList trigger_map;


        if (room->getTag("specialcardslist").toString().split("+").isEmpty())
            return trigger_map;

        QStringList cardlist = room->getTag("specialcardslist").toString().split("+");
        if (event == GeneralShown) {
            if (player->getKingdom()=="science" && cardlist.contains("GakuenToshi")){
                int n = 0;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->hasShownOneGeneral() && p->getKingdom() == "science"){
                        n = n+1;
                    }
                }
                if (n < 3) return trigger_map;
                player->tag["scenecard_will"] = QVariant("GakuenToshi");
                trigger_map.insert(player, QStringList(objectName()));
            }
            if (player->getKingdom()=="magic" && cardlist.contains("SeihaiWar")){
                int n = 0;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->hasShownOneGeneral() && p->getKingdom() == "magic"){
                        n = n+1;
                    }
                }
                if (n < 3) return trigger_map;
                player->tag["eventcard_will"] = QVariant("SeihaiWar");
                room->setPlayerMark(room->getCurrent(), "#SeihaiWar", 2);
                trigger_map.insert(player, QStringList(objectName()));
            }
            if (player->getKingdom()=="game" && cardlist.contains("Gensoukyou")){
                int n = 0;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->hasShownGeneral1() && Sanguosha->translate("@"+p->getActualGeneral1Name()) == "東方project"){
                        n = n+1;
                    }
                    if (p->hasShownGeneral2() && Sanguosha->translate("@"+p->getActualGeneral2Name()) == "東方project"){
                        n = n+1;
                    }
                }
                if (n < 2) return trigger_map;
                player->tag["scenecard_will"] = QVariant("Gensoukyou");
                trigger_map.insert(player, QStringList(objectName()));
            }
        }
        if (event == BuryVictim){
            DeathStruct death = data.value<DeathStruct>();
            if (death.who->getKingdom()=="real" && cardlist.contains("SSSschool")){
                int n = 0;
                foreach(auto p, room->getAlivePlayers()){
                    if (p->hasShownOneGeneral() && p->getKingdom() == "real"){
                        n = n+1;
                    }
                }
                if (n == 0) return trigger_map;
                death.who->tag["scenecard_will"] = QVariant("SSSschool");
                trigger_map.insert(death.who, QStringList(objectName()));
            }
        }

        return trigger_map;
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *player) const
    {

            if (player->tag["eventcard_will"].toString()!= ""){
                QString name = player->tag["eventcard_will"].toString();
                QStringList current = room->getTag("currentEventCards").toString().split("+");
                current << name;
                room->setTag("currentEventCards", QVariant(current.join("+")));
                foreach(auto p, room->getAllPlayers(true)){
                    room->setPlayerMark(p, name + ":event_card", 1);
                }
                QStringList cardlist = room->getTag("specialcardslist").toString().split("+");
                cardlist.removeOne(name);
                room->setTag("specialcardslist", QVariant(cardlist.join("+")));
                room->doLightbox("image=image/special-card/"+name+".png");
                QString name_type;
                foreach(QString s, Sanguosha->getAllSpecialCards()){
                    if (s.split(":").first() == name){
                        name_type = s.split(":").last();
                        break;
                    }
                }

                LogMessage log;
                log.type = "$specialcard_effect",
                log.arg = name;
                log.arg2 = name_type;
                room->sendLog(log);
            }


           if (player->tag["scenecard_will"].toString()!= ""){

               QString name = player->tag["scenecard_will"].toString();

               QString current = room->getTag("currentSceneCard").toString();
               if (current != ""){
                   foreach(auto p, room->getAllPlayers(true)){
                       room->setPlayerMark(p, current +":scene_card", 0);
                   }
               }

               room->setTag("currentSceneCard", QVariant(name));
               foreach(auto p, room->getAllPlayers(true)){
                   room->setPlayerMark(p, name + ":scene_card", 1);
               }

              QStringList cardlist = room->getTag("specialcardslist").toString().split("+");
              cardlist.removeOne(name);
              room->setTag("specialcardslist", QVariant(cardlist.join("+")));
              room->doLightbox("image=image/special-card/"+name+".png");
              QString name_type;
              foreach(QString s, Sanguosha->getAllSpecialCards()){
                  if (s.split(":").first() == name){
                      name_type = s.split(":").last();
                      break;
                  }
              }

              LogMessage log;
              log.type = "$specialcard_effect",
              log.arg = name;
              log.arg2 = name_type;
              room->sendLog(log);

              if (name == "SSSschool"){
                  int aidelay = Config.AIDelay;
                  Config.AIDelay = 0;
                  Config.AIDelay = aidelay;
                  foreach(auto target, room->getAllPlayers(true)){
                      if (target->isDead() && target->getKingdom() == "real"){
                          QStringList avaliable_generals;
                          foreach(QString s,Sanguosha->getLimitedGeneralNames()){
                              const General *general = Sanguosha->getGeneral(s);
                              if (!room->getUsedGeneral().contains(s) && general->getKingdom() == "real")
                                  avaliable_generals << s;
                          }

                          room->setPlayerProperty(player, "Duanchang", QVariant());
                          QString to_change = room->askForGeneral(target, avaliable_generals, QString(), true, "SSSschool", player->getKingdom());

                          if (!to_change.isEmpty()) {

                              room->revivePlayer(target);
                              room->transformHeadGeneralTo(target, to_change);
                              if (target->getActualGeneral2()->isMale()){
                                  room->transformDeputyGeneralTo(target, "sujiang");
                              }
                              else{
                                  room->transformDeputyGeneralTo(target, "sujiangf");
                              }
                              room->setPlayerProperty(target, "hp", 2);

                              target->setChained(false);
                              room->broadcastProperty(target, "chained");

                              target->setFaceUp(true);
                              room->broadcastProperty(target, "faceup");

                              room->setPlayerMark(target, "##SSSschool", 1);
                      }
                  }
              }
              }
           }
        return false;
    }
};

class SpecialCards_Effect : public TriggerSkill
{
public:
    SpecialCards_Effect() : TriggerSkill("SpecialCards_Effect")
    {
        events << CardUsed << TurnStart << DrawNCards << EventPhaseStart << CardsMoveOneTime << TargetConfirmed;
        global=true;
    }
    virtual void record(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data) const
    {
        if (event == TurnStart){
            if(player->getMark("#SeihaiWar")>0 && !player->hasFlag("Point_ExtraTurn")){
                room->setPlayerMark(player, "#SeihaiWar", player->getMark("#SeihaiWar")-1);
                if (player->getMark("#SeihaiWar") == 0){
                    QStringList current = room->getTag("currentEventCards").toString().split("+");
                    if (current.contains("SeihaiWar")) current.removeOne("SeihaiWar");
                    room->setTag("currentEventCards", QVariant(current.join("+")));
                    foreach(auto p, room->getAllPlayers(true)){
                        room->setPlayerMark(p, "SeihaiWar:event_card", 0);
                    }
                }
            }
            bool  has = false;
            foreach(auto p, room->getAlivePlayers()){
                if (player->getMark("#SeihaiWar") > 0){
                    has = true;
                    break;
                }
            }
            if (!has ){
                QStringList current = room->getTag("currentEventCards").toString().split("+");
                if (current.contains("SeihaiWar")) current.removeOne("SeihaiWar");
                room->setTag("currentEventCards", QVariant(current.join("+")));
                foreach(auto p, room->getAllPlayers(true)){
                    room->setPlayerMark(p, "SeihaiWar:event_card", 0);
                }
            }
        }
        if (event == CardsMoveOneTime){
            bool  has = false;
            foreach(auto p, room->getAlivePlayers()){
                foreach(auto e, p->getEquips()){
                    if (e->isKindOf("JadeSeal")){
                        has = true;
                        break;
                    }
                }
            }
            if (has ){
                QStringList current = room->getTag("currentEventCards").toString().split("+");
                if (current.contains("SeihaiWar")) current.removeOne("SeihaiWar");
                room->setTag("currentEventCards", QVariant(current.join("+")));
                foreach(auto p, room->getAllPlayers(true)){
                    room->setPlayerMark(p, "SeihaiWar:event_card", 0);
                    room->setPlayerMark(p, "#SeihaiWar", 0);
                }
            }
        }

    }
    virtual QStringList triggerable(TriggerEvent event, Room *room, ServerPlayer *player, QVariant &data, ServerPlayer * &) const
    {
        QString current = room->getTag("currentSceneCard").toString();
        QStringList current2 = room->getTag("currentEventCards").toString().split("+");
        if (event == CardUsed){
            auto use = data.value<CardUseStruct>();
            if (current == "GakuenToshi" && player->getKingdom() == "science" && use.card->getSuitString()=="spade" && use.card->getTypeId() != Card::TypeSkill && !room->getCurrent()->hasFlag("GakuenToshi_used")){
                return QStringList(objectName());
            }
            if (current == "SSSschool" && player->getMark("##SSSschool")>0 && use.card->getTypeId() != Card::TypeSkill && !room->getCurrent()->hasFlag("SSSschool_used")){
                bool has = false;
                foreach(auto p, use.to){
                    if (p->getMark("##SSSschool") == 0) has = true;
                }

                if (!has && use.to.length()>0) return QStringList(objectName());
            }
        }
        if (event == EventPhaseStart){
            auto phase = player->getPhase();
            if (phase == Player::Start && current2.contains("SeihaiWar") && player->getKingdom() == "magic" && player->hasShownGeneral2() && !Sanguosha->translate("@"+player->getActualGeneral2Name()).contains("Fate")){
                return QStringList(objectName());
            }
            if (phase == Player::Start && current == "Gensoukyou" && player->getKingdom() == "game"){
                return QStringList(objectName());
            }

        }
        if (event == DrawNCards){
            if (current2.contains("SeihaiWar") && player->getKingdom() == "magic" && player->hasShownGeneral2() && Sanguosha->translate("@"+player->getActualGeneral2Name()).contains("Fate")){
                return QStringList(objectName());
            }
        }
        return QStringList();
    }

    virtual bool cost(TriggerEvent, Room *, ServerPlayer *, QVariant &, ServerPlayer *ask_who) const
    {
        return true;
    }

    virtual bool effect(TriggerEvent event, Room *room, ServerPlayer *target, QVariant &data, ServerPlayer *player) const
    {
        QString current = room->getTag("currentSceneCard").toString();
        QStringList current2 = room->getTag("currentEventCards").toString().split("+");
        if (event == CardUsed){
            auto use = data.value<CardUseStruct>();
            if (current == "GakuenToshi"){
                QList <ServerPlayer *> list;
                foreach(auto p, room->getOtherPlayers(player)){
                    if (p->isFriendWith(player)) list << p;
                }
                ServerPlayer *target = room->askForPlayerChosen(player, list, "GakuenToshi", QString(), true, true);
                if (target){
                    room->setPlayerFlag(room->getCurrent(), "GakuenToshi_used");
                    int index = player->startCommand("GakuenToshi");
                    ServerPlayer *dest = NULL;
                    if (index == 0) {
                        dest = room->askForPlayerChosen(player, room->getAlivePlayers(), "command_GakuenToshi", "@command-damage");
                        room->doAnimate(QSanProtocol::S_ANIMATE_INDICATE, player->objectName(), dest->objectName());
                    }
                    if (target->doCommand("GakuenToshi",index,player,dest)){
                        target->drawCards(1);
                    }
                }
            }
            if (current == "SSSschool"){
                room->setPlayerFlag(room->getCurrent(), "SSSschool_used");
                player->drawCards(1);
            }
        }
        if (event == EventPhaseStart){
            if (current2.contains("SeihaiWar") && player->askForSkillInvoke("SeihaiWar_EireiShoukan")){
                Card *card = Sanguosha->cloneCard("eirei_shoukan");
                CardUseStruct use;
                use.from = player;
                use.to << player;
                use.card = card;
                room->useCard(use);
            }
            if (current == "Gensoukyou" && player->askForSkillInvoke("Gensoukyou_Judge")){
                JudgeStruct judge;
                judge.reason = "Gensoukyou";
                judge.who = player;
                room->judge(judge);
                if (judge.card->getSuitString() == "heart"){
                    player->drawCards(1);
                }
                else if (judge.card->getSuitString() == "spade"){
                    QList<ServerPlayer *> list;
                    foreach(auto p, room->getAlivePlayers()){
                        if (p->getEquips().length()>0 && p->getJudgingArea().length()>0){
                            list << p;
                        }
                    }
                    ServerPlayer *target = room->askForPlayerChosen(player, list, "Gensoukyou", QString(), true);
                    if (target){
                        if (target->getEquips().length()>0 && target->getJudgingArea().length()>0){
                            int id = room->askForCardChosen(player, target, "ej", objectName());
                            room->throwCard(id, target, player);
                        }
                    }
                }
            }
        }
        if (event == DrawNCards){
            if (current2.contains("SeihaiWar")){
                int n = data.toInt();
                n = n+1;
                data.setValue(n);
            }
        }
        return false;
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
    addMetaObject<CompanionCard>();
    addMetaObject<FirstShowCard>();
    addMetaObject<CompanionCard>();
    addMetaObject<CareermanCard>();
    addMetaObject<ShowHeadCard>();
    addMetaObject<ShowDeputyCard>();

    skills << new GlobalFakeMoveSkill << new AnimeShana << new Companion << new HalfMaxHp << new HalfMaxHpMaxCards << new FirstShow <<new Careerman << new GlobalClear << new ShowHead << new ShowDeputy << new SpecialCards_Trigger << new SpecialCards_Effect << new EventcardDisplay << new ScenecardDisplay;

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
    patterns["nullification+igiari"] = new ExpPattern("Nullification,Igiari");
    patterns["igiari"] = new ExpPattern("Igiari");
    patterns["himitsu"] = new ExpPattern("HimitsuKoudou");
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

    special_cards << "GakuenToshi:scene_card";
    special_cards << "SeihaiWar:event_card";
    special_cards << "Gensoukyou:scene_card";
    special_cards << "SSSschool:scene_card";

    addEquipSkills();
}

ADD_PACKAGE(StandardCard)

