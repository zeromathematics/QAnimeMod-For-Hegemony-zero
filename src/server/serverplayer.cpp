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

#include "serverplayer.h"
#include "engine.h"
#include "standard.h"
#include "ai.h"
#include "settings.h"
#include "recorder.h"
#include "lua-wrapper.h"
#include "json.h"
#include "gamerule.h"
#include "roomthread.h"
#include "clientplayer.h"
#include <QFile>

using namespace QSanProtocol;

const int ServerPlayer::S_NUM_SEMAPHORES = 6;

ServerPlayer::ServerPlayer(Room *room)
    : Player(room), m_isClientResponseReady(false), m_isWaitingReply(false),
    event_received(false), socket(NULL), room(room),
    ai(NULL), trust_ai(new TrustAI(this)), recorder(NULL),
    _m_phases_index(0)
{
    semas = new QSemaphore *[S_NUM_SEMAPHORES];
    for (int i = 0; i < S_NUM_SEMAPHORES; i++)
        semas[i] = new QSemaphore(0);
}

ServerPlayer::~ServerPlayer()
{
    for (int i = 0; i < S_NUM_SEMAPHORES; i++)
        delete semas[i];

    delete[] semas;
    delete trust_ai;
}

void ServerPlayer::drawCard(const Card *card)
{
    handcards << card;
}

Room *ServerPlayer::getRoom() const
{
    return room;
}

void ServerPlayer::broadcastSkillInvoke(const QString &card_name) const
{
    QString gender = "female";
    if (isMale())
        gender = "male";
    int n = 1;
    for (int i = 1;i <= 998; i++){
        QFile lua_file(QString("audio/card/%1/%2%3.ogg").arg(gender).arg(card_name).arg(i));
        if (lua_file.exists()){
            n = n+1;
        }
    }
    QString s= "";
    int m = qrand()% n;
    if (m > 0)
        s = QString::number(m);
    room->broadcastSkillInvoke(card_name+s, isMale(), -1);
}

void ServerPlayer::broadcastSkillInvoke(const Card *card) const
{
    if (card->isMute())
        return;

    QString skill_name = card->getSkillName();
    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL) {
        if (card->getCommonEffectName().isNull())
            broadcastSkillInvoke(card->objectName());
        else
            room->broadcastSkillInvoke(card->getCommonEffectName(), "common");
        return;
    } else {
        int index = skill->getEffectIndex(this, card);
        if (index == 0) return;

        if ((index == -1 && skill->getSources().isEmpty()) || index == -2) {
            if (card->getCommonEffectName().isNull())
                broadcastSkillInvoke(card->objectName());
            else
                room->broadcastSkillInvoke(card->getCommonEffectName(), "common");
        } else
            room->broadcastSkillInvoke(skill_name, "male", index, this, card->getSkillPosition());
    }
}

int ServerPlayer::getRandomHandCardId() const
{
    return getRandomHandCard()->getEffectiveId();
}

const Card *ServerPlayer::getRandomHandCard() const
{
    int index = qrand() % handcards.length();
    return handcards.at(index);
}

void ServerPlayer::obtainCard(const Card *card, bool unhide)
{
    CardMoveReason reason(CardMoveReason::S_REASON_GOTCARD, objectName());
    room->obtainCard(this, card, reason, unhide);
}

void ServerPlayer::throwAllEquips()
{
    QList<const Card *> equips = getEquips();

    if (equips.isEmpty()) return;

    DummyCard card;
    foreach (const Card *equip, equips) {
        if (!isJilei(&card))
            card.addSubcard(equip);
    }
    if (card.subcardsLength() > 0)
        room->throwCard(&card, this);
}

void ServerPlayer::throwAllHandCards()
{
    int card_length = getHandcardNum();
    room->askForDiscard(this, QString(), card_length, card_length);
}

void ServerPlayer::throwAllHandCardsAndEquips()
{
    int card_length = getCardCount(true);
    room->askForDiscard(this, QString(), card_length, card_length, false, true);
}

void ServerPlayer::throwAllMarks(bool visible_only)
{
    // throw all marks
    foreach (const QString &mark_name, marks.keys()) {
        if (!mark_name.startsWith("@"))
            continue;

        int n = marks.value(mark_name, 0);
        if (n != 0)
            room->setPlayerMark(this, mark_name, 0);
    }

    if (!visible_only)
        marks.clear();
}

void ServerPlayer::clearOnePrivatePile(const QString &pile_name)
{
    if (!piles.contains(pile_name))
        return;
    QList<int> &pile = piles[pile_name];

    DummyCard dummy(pile);
    CardMoveReason reason(CardMoveReason::S_REASON_REMOVE_FROM_PILE, this->objectName());
    room->throwCard(&dummy, reason, NULL);
    piles.remove(pile_name);
}

void ServerPlayer::clearPrivatePiles()
{
    foreach(const QString &pile_name, piles.keys())
        clearOnePrivatePile(pile_name);
    piles.clear();
}

void ServerPlayer::bury()
{
    clearFlags();
    clearHistory();
    throwAllCards();
    throwAllMarks();
    clearPrivatePiles();

    room->clearPlayerCardLimitation(this, false);
}

void ServerPlayer::throwAllCards()
{
    DummyCard *card = isKongcheng() ? new DummyCard : wholeHandCards();
    foreach(const Card *equip, getEquips())
        card->addSubcard(equip);
    if (card->subcardsLength() != 0)
        room->throwCard(card, this);
    card->deleteLater();

    QList<const Card *> tricks = getJudgingArea();
    foreach (const Card *trick, tricks) {
        CardMoveReason reason(CardMoveReason::S_REASON_THROW, this->objectName());
        room->throwCard(trick, reason, NULL);
    }
}

int ServerPlayer::getMaxCards(MaxCardsType::MaxCardsCount type) const
{
    int origin = Sanguosha->correctMaxCards(this, true, type);
    if (origin <= 0 && !this->hasShownSkill("zhuangjia"))
        origin = qMax(getHp(), 0);

    origin += Sanguosha->correctMaxCards(this, false, type);

    return qMax(origin, 0);
}

void ServerPlayer::fillHandCards(int n, const QString &reason)
{
    if (isAlive() && n > getHandcardNum())
        drawCards(n - getHandcardNum(), reason);
}

void ServerPlayer::drawCards(int n, const QString &reason)
{
    room->drawCards(this, n, reason);
}

bool ServerPlayer::askForSkillInvoke(const QString &skill_name, const QVariant &data)
{
    return room->askForSkillInvoke(this, skill_name, data);
}

bool ServerPlayer::askForSkillInvoke(const Skill *skill, const QVariant &data)
{
    Q_ASSERT(skill != NULL);
    return room->askForSkillInvoke(this, skill->objectName(), data);
}

QList<int> ServerPlayer::forceToDiscard(int discard_num, bool include_equip, bool is_discard)
{
    QList<int> to_discard;

    QString flags = "h";
    if (include_equip)
        flags.append("e");

    QList<const Card *> all_cards = getCards(flags);
    qShuffle(all_cards);

    for (int i = 0; i < all_cards.length(); i++) {
        if (!is_discard || !isJilei(all_cards.at(i)))
            to_discard << all_cards.at(i)->getId();
        if (to_discard.length() == discard_num)
            break;
    }

    return to_discard;
}

QList<int> ServerPlayer::forceToDiscard(int discard_num, const QString &pattern, const QString &expand_pile, bool is_discard)
{
    QList<int> to_discard;
    QList<const Card *> all_cards;
    foreach (const Card *c, getCards("he")) {
        if (Sanguosha->matchExpPattern(pattern, this, c))
            all_cards << c;
    }
    foreach (const QString &pile,expand_pile.split(",")) {
        foreach (int id, getPile(pile))
            all_cards << Sanguosha->getCard(id);
    }
    qShuffle(all_cards);

    for (int i = 0; i < all_cards.length(); i++) {
        if (!is_discard || !isJilei(all_cards.at(i)))
            to_discard << all_cards.at(i)->getId();
        if (to_discard.length() == discard_num)
            break;
    }

    return to_discard;
}

int ServerPlayer::aliveCount(bool includeRemoved) const
{
    int n = room->alivePlayerCount();
    if (!includeRemoved) {
        foreach (ServerPlayer *p, room->getAllPlayers()) {
            if (p->isRemoved())
                n--;
        }
    }
    return n;
}

int ServerPlayer::getHandcardNum() const
{
    return handcards.length();
}

int ServerPlayer::getPlayerNumWithSameKingdom(const QString &reason, const QString &_to_calculate, MaxCardsType::MaxCardsCount type) const
{
    QString to_calculate = _to_calculate;

    if (to_calculate.isEmpty()) {
        if (getRole() == "careerist")
            to_calculate = "careerist";
        else
            to_calculate = getKingdom();
    }

    ServerPlayer *this_player = room->findPlayer(objectName());
    QList<ServerPlayer *> players = room->getAlivePlayers();

    int num = 0;
    foreach (ServerPlayer *p, players) {
        if (!p->hasShownOneGeneral())
            continue;
        /*if (p->getRole() == "careerist") { // if player is careerist, DO NOT COUNT AS SOME KINGDOM!!!!!
            if (to_calculate == "careerist")
                num = 1;
            continue;
        }
        if (p->getKingdom() == to_calculate)
            ++num;*/
        if ((p->isFriendWith(this) && getKingdom() == to_calculate)|| p->getKingdom() == to_calculate)
            ++num;
    }

    if (reason != "AI") {
        QVariant data = QVariant::fromValue(PlayerNumStruct(num, to_calculate, type, reason));
        room->getThread()->trigger(ConfirmPlayerNum, room, this_player, data);
        PlayerNumStruct playerNumStruct = data.value<PlayerNumStruct>();
        num = playerNumStruct.m_num;
    }

    return qMax(num, 0);
}

void ServerPlayer::setSocket(ClientSocket *socket)
{
    if (socket) {
        connect(socket, &ClientSocket::disconnected, this, &ServerPlayer::disconnected);
        connect(socket, &ClientSocket::message_got, this, &ServerPlayer::getMessage);
        connect(this, &ServerPlayer::message_ready, this, &ServerPlayer::sendMessage);
    } else {
        if (this->socket) {
            this->disconnect(this->socket);
            this->socket->disconnect(this);
            //this->socket->disconnectFromHost();
            this->socket->deleteLater();
        }


        disconnect(this, &ServerPlayer::message_ready, this, &ServerPlayer::sendMessage);
    }

    this->socket = socket;
}

void ServerPlayer::kick()
{
    room->notifyProperty(this, this, "flags", "is_kicked");
    if (socket != NULL)
        socket->disconnectFromHost();
    setSocket(NULL);
}

void ServerPlayer::getMessage(QByteArray request)
{
    if (request.endsWith('\n'))
        request.chop(1);

    emit request_got(request);

    Packet packet;
    if (packet.parse(request)) {
        switch (packet.getPacketDestination()) {
        case S_DEST_ROOM:
            emit roomPacketReceived(packet);
            break;
            //unused destination. Lobby hasn't been implemented.
        case S_DEST_LOBBY:
            emit lobbyPacketReceived(packet);
            break;
        default:
            emit invalidPacketReceived(request);
        }
    } else {
        emit invalidPacketReceived(request);
    }
}

void ServerPlayer::unicast(const QByteArray &message)
{
    emit message_ready(message);

    if (recorder)
        recorder->recordLine(message);
}

void ServerPlayer::startNetworkDelayTest()
{
    test_time = QDateTime::currentDateTime();
    Packet packet(S_SRC_ROOM | S_TYPE_NOTIFICATION | S_DEST_CLIENT, S_COMMAND_NETWORK_DELAY_TEST);
    unicast(&packet);
}

qint64 ServerPlayer::endNetworkDelayTest()
{
    return test_time.msecsTo(QDateTime::currentDateTime());
}

void ServerPlayer::startRecord()
{
    recorder = new Recorder(this);
}

void ServerPlayer::saveRecord(const QString &filename)
{
    if (recorder)
        recorder->save(filename);
}

void ServerPlayer::addToSelected(const QString &general)
{
    selected.append(general);
}

QStringList ServerPlayer::getSelected() const
{
    return selected;
}

QString ServerPlayer::findReasonable(const QStringList &generals, bool no_unreasonable)
{
    foreach (const QString &name, generals) {
        if (getGeneral() && getGeneral()->getKingdom() != Sanguosha->getGeneral(name)->getKingdom())
            continue;
        return name;
    }

    if (no_unreasonable)
        return QString();

    return generals.first();
}

void ServerPlayer::clearSelected()
{
    selected.clear();
}

void ServerPlayer::sendMessage(const QByteArray &message)
{
    if (socket) {
#ifndef QT_NO_DEBUG
        printf("%s", qPrintable(objectName()));
#endif
        socket->send(message);
    }
}

void ServerPlayer::unicast(const AbstractPacket *packet)
{
    unicast(packet->toJson());
}

void ServerPlayer::notify(CommandType type, const QVariant &arg)
{
    Packet packet(S_SRC_ROOM | S_TYPE_NOTIFICATION | S_DEST_CLIENT, type);
    packet.setMessageBody(arg);
    unicast(packet.toJson());
}

QString ServerPlayer::reportHeader() const
{
    QString name = objectName();
    return QString("%1 ").arg(name.isEmpty() ? tr("Anonymous") : name);
}

void ServerPlayer::removeCard(const Card *card, Place place)
{
    switch (place) {
    case PlaceHand: {
        handcards.removeOne(card);
        break;
    }
    case PlaceEquip: {
        const EquipCard *equip = qobject_cast<const EquipCard *>(card->getRealCard());
        if (equip == NULL)
            equip = qobject_cast<const EquipCard *>(Sanguosha->getEngineCard(card->getEffectiveId()));
        Q_ASSERT(equip != NULL);
        equip->onUninstall(this);

        WrappedCard *wrapped = Sanguosha->getWrappedCard(card->getEffectiveId());
        removeEquip(wrapped);

        bool show_log = true;
        foreach(const QString &flag, flags)
            if (flag.endsWith("_InTempMoving")) {
                show_log = false;
                break;
            }
        if (show_log) {
            LogMessage log;
            log.type = "$Uninstall";
            log.card_str = wrapped->toString();
            log.from = this;
            room->sendLog(log);
        }
        break;
    }
    case PlaceDelayedTrick: {
        removeDelayedTrick(card);
        break;
    }
    case PlaceSpecial: {
        int card_id = card->getEffectiveId();
        QString pile_name = getPileName(card_id);

        //@todo: sanity check required
        if (!pile_name.isEmpty())
            piles[pile_name].removeOne(card_id);

        break;
    }
    default:
        break;
    }
}

void ServerPlayer::addCard(const Card *card, Place place)
{
    switch (place) {
    case PlaceHand: {
        handcards << card;
        break;
    }
    case PlaceEquip: {
        WrappedCard *wrapped = Sanguosha->getWrappedCard(card->getEffectiveId());
        const EquipCard *equip = qobject_cast<const EquipCard *>(wrapped->getRealCard());
        setEquip(wrapped);
        equip->onInstall(this);
        break;
    }
    case PlaceDelayedTrick: {
        addDelayedTrick(card);
        break;
    }
    default:
        break;
    }
}

bool ServerPlayer::isLastHandCard(const Card *card, bool contain) const
{
    if (!card->isVirtualCard()) {
        return handcards.length() == 1 && handcards.first()->getEffectiveId() == card->getEffectiveId();
    } else if (card->getSubcards().length() > 0) {
        if (!contain) {
            foreach (int card_id, card->getSubcards()) {
                if (!handcards.contains(Sanguosha->getCard(card_id)))
                    return false;
            }
            return handcards.length() == card->getSubcards().length();
        } else {
            foreach (const Card *ncard, handcards) {
                if (!card->getSubcards().contains(ncard->getEffectiveId()))
                    return false;
            }
            return true;
        }
    }
    return false;
}

QList<int> ServerPlayer::handCards() const
{
    QList<int> cardIds;
    foreach(const Card *card, handcards)
        cardIds << card->getId();
    return cardIds;
}

QList<const Card *> ServerPlayer::getHandcards() const
{
    return handcards;
}

QList<const Card *> ServerPlayer::getCards(const QString &flags) const
{
    QList<const Card *> cards;
    if (flags.contains("h"))
        cards << handcards;
    if (flags.contains("e"))
        cards << getEquips();
    if (flags.contains("j"))
        cards << getJudgingArea();

    return cards;
}

DummyCard *ServerPlayer::wholeHandCards() const
{
    if (isKongcheng()) return NULL;

    DummyCard *dummy_card = new DummyCard;
    foreach(const Card *card, handcards)
        dummy_card->addSubcard(card->getId());

    return dummy_card;
}

bool ServerPlayer::hasNullification() const
{
    foreach (const Card *card, handcards) {
        if (card->isKindOf("Nullification"))
            return true;
    }
    foreach (const QString &pile, getHandPileList(false)) {
        foreach (int id, getPile(pile)) {
            if (Sanguosha->getCard(id)->isKindOf("Nullification"))
                return true;
        }
    }
    foreach (const Skill *skill, getVisibleSkillList(true)) {
        if (hasSkill(skill->objectName())) {
            if (skill->inherits("ViewAsSkill")) {
                const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(skill);
                if (vsskill->isEnabledAtNullification(this)) return true;
            } else if (skill->inherits("TriggerSkill")) {
                const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(skill);
                if (trigger_skill && trigger_skill->getViewAsSkill()) {
                    const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(trigger_skill->getViewAsSkill());
                    if (vsskill && vsskill->isEnabledAtNullification(this)) return true;
                }
            }
        }
    }

    return false;
}

bool ServerPlayer::hasIgiari() const
{
    foreach (const Card *card, handcards) {
        if (card->isKindOf("Igiari"))
            return true;
    }
    foreach (const Skill *skill, getVisibleSkillList(true)) {
        if (hasSkill(skill->objectName())) {
            if (skill->inherits("ViewAsSkill")) {
                const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(skill);
                if (vsskill->isEnabledAtIgiari(this)) return true;
            } else if (skill->inherits("TriggerSkill")) {
                const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(skill);
                if (trigger_skill && trigger_skill->getViewAsSkill()) {
                    const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(trigger_skill->getViewAsSkill());
                    if (vsskill && vsskill->isEnabledAtIgiari(this)) return true;
                }
            }
        }
    }

    return false;
}

bool ServerPlayer::hasHimitsu() const
{
    foreach (const Card *card, handcards) {
        if (card->isKindOf("HimitsuKoudou"))
            return true;
    }
    foreach (const Skill *skill, getVisibleSkillList(true)) {
        if (hasSkill(skill->objectName())) {
            if (skill->inherits("ViewAsSkill")) {
                const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(skill);
                if (vsskill->isEnabledAtHimitsu(this)) return true;
            } else if (skill->inherits("TriggerSkill")) {
                const TriggerSkill *trigger_skill = qobject_cast<const TriggerSkill *>(skill);
                if (trigger_skill && trigger_skill->getViewAsSkill()) {
                    const ViewAsSkill *vsskill = qobject_cast<const ViewAsSkill *>(trigger_skill->getViewAsSkill());
                    if (vsskill && vsskill->isEnabledAtHimitsu(this)) return true;
                }
            }
        }
    }

    return false;
}


PindianStruct *ServerPlayer::pindianSelect(ServerPlayer *target, const QString &reason, const Card *card1)
{
    if (target == this) return NULL;
    PindianStruct *pd = pindianSelect(QList<ServerPlayer *>() << target, reason, card1);
    return pd;
}

PindianStruct *ServerPlayer::pindianSelect(const QList<ServerPlayer *> &targets, const QString &reason, const Card *card1)
{
    foreach (ServerPlayer *p, targets) {
        Q_ASSERT(p != this);
        if (p == this) return NULL;
    }
    LogMessage log;
    log.type = "#Pindian";
    log.from = this;
    log.to = targets;
    room->sendLog(log);

    room->tryPause();

    QList<const Card *> cards = room->askForPindianRace(this, targets, reason, card1);
    card1 = cards.first();
    QList<int> ids;
    foreach (const Card *card, cards) {
        if (card == NULL) return NULL;
        if (card != card1) ids << card->getNumber();
    }
    cards.removeOne(card1);

    PindianStruct *pindian = new PindianStruct;
    pindian->from = this;
    pindian->tos = targets;
    pindian->from_card = card1;
    pindian->to_cards = cards;
    pindian->from_number = card1->getNumber();
    pindian->to_numbers = ids;
    pindian->reason = reason;
    if (targets.length() == 1) pindian->to = targets.first();

    QList<CardsMoveStruct> pd_move;
    CardsMoveStruct move1;
    move1.card_ids << pindian->from_card->getEffectiveId();
    move1.from = pindian->from;
    move1.to = NULL;
    move1.to_place = Player::PlaceTable;
    CardMoveReason reason1(CardMoveReason::S_REASON_PINDIAN, pindian->from->objectName(), QString(), pindian->reason, QString());
    move1.reason = reason1;
    pd_move << move1;

    for (int i = 0; i < targets.length(); i++) {
        CardsMoveStruct move2;
        move2.card_ids << cards.at(i)->getEffectiveId();
        move2.from = targets.at(i);
        move2.to = NULL;
        move2.to_place = Player::PlaceTable;
        CardMoveReason reason2(CardMoveReason::S_REASON_PINDIAN, targets.at(i)->objectName());
        move2.reason = reason2;
        pd_move << move2;
    }


    LogMessage log2;
    log2.type = "$PindianResult";
    log2.from = pindian->from;
    log2.card_str = QString::number(pindian->from_card->getEffectiveId());
    room->sendLog(log2);

    for (int i = 0; i < targets.length(); i++) {
        log2.type = "$PindianResult";
        log2.from = pindian->tos.at(i);
        log2.card_str = QString::number(pindian->to_cards.at(i)->getEffectiveId());
        room->sendLog(log2);
    }

    room->moveCardsAtomic(pd_move, true);

    return pindian;
}

bool ServerPlayer::pindian(PindianStruct *pd, int index)
{
    Q_ASSERT(pd != NULL);
    Q_ASSERT(index <= pd->tos.length());
    room->tryPause();

    ServerPlayer *target = pd->tos.at(index - 1);
    const Card *to_card = pd->to_cards.at(index - 1);
    int to_number = pd->to_numbers.at(index - 1);
    int old_number = pd->from_number;
    PindianStruct &pindian_struct = *pd;
    pindian_struct.to = target;
    pindian_struct.to_card = to_card;
    pindian_struct.to_number = to_number;
    RoomThread *thread = room->getThread();
    PindianStruct *pindian_star = pd;

    JsonArray arg;
    arg << (int)S_GAME_EVENT_REVEAL_PINDIAN;
    arg << pd->to->objectName();
    room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

    QVariant data = QVariant::fromValue(pindian_star);
    Q_ASSERT(thread != NULL);
    thread->trigger(PindianVerifying, room, this, data);

    PindianStruct *new_star = data.value<PindianStruct *>();
    pindian_struct.from_number = new_star->from_number;
    pindian_struct.to_number = new_star->to_number;
    pindian_struct.success = (new_star->from_number > new_star->to_number);

    thread->delay();
    thread->delay();

    arg.clear();
    int pindian_type = pindian_struct.success ? 1 : new_star->from_number == new_star->to_number ? 2 : 3;
    arg << S_GUANXING_FINISH;
    arg << pindian_type;
    arg << index;
    room->doBroadcastNotify(S_COMMAND_PINDIAN, arg);

    thread->delay();
    thread->delay();

    LogMessage log;
    log.type = pindian_struct.success ? "#PindianSuccess" : "#PindianFailure";
    log.from = this;
    log.to.clear();
    log.to << pd->to;
    log.card_str.clear();
    room->sendLog(log);

    pindian_star = &pindian_struct;
    data = QVariant::fromValue(pindian_star);
    thread->trigger(Pindian, room, this, data);

    pindian_struct.from_number = old_number;    //return the old for the next pd

    QList<CardsMoveStruct> pd_move;

    if (room->getCardPlace(pindian_struct.from_card->getEffectiveId()) == Player::PlaceTable && index == pd->tos.length()) {
        CardsMoveStruct move1;
        move1.card_ids << pindian_struct.from_card->getEffectiveId();
        move1.from = pindian_struct.from;
        move1.to = NULL;
        move1.to_place = Player::DiscardPile;
        CardMoveReason reason1(CardMoveReason::S_REASON_PINDIAN, pindian_struct.from->objectName(), pindian_struct.to->objectName(),
            pindian_struct.reason, QString());
        move1.reason = reason1;
        pd_move << move1;
    }

    if (room->getCardPlace(pindian_struct.to_card->getEffectiveId()) == Player::PlaceTable) {
        CardsMoveStruct move2;
        move2.card_ids << pindian_struct.to_card->getEffectiveId();
        move2.from = pindian_struct.to;
        move2.to = NULL;
        move2.to_place = Player::DiscardPile;
        CardMoveReason reason2(CardMoveReason::S_REASON_PINDIAN, pindian_struct.to->objectName());
        move2.reason = reason2;
        pd_move << move2;
    }

    if (!pd_move.isEmpty())
        room->moveCardsAtomic(pd_move, true);

    QVariant decisionData = QVariant::fromValue(QString("pindian:%1:%2:%3:%4:%5")
        .arg(pd->reason)
        .arg(this->objectName())
        .arg(pindian_struct.from_card->getEffectiveId())
        .arg(pd->to->objectName())
        .arg(pindian_struct.to_card->getEffectiveId()));
    thread->trigger(ChoiceMade, room, this, decisionData);

    bool r = pindian_struct.success;
    if (index == pd->tos.length()) delete pd;
    return r;
}

int ServerPlayer::startCommand(const QString &reason, ServerPlayer *target)
{
    QStringList allcommands, commands;
    allcommands << "command1" << "command2" << "command3" << "command4" << "command5" << "command6";
    QStringList commandscopy = allcommands;

    QString command1 = commandscopy.at(qrand()%commandscopy.length());
    commandscopy.removeOne(command1);
    commands << command1;
    QString command2 = commandscopy.at(qrand()%commandscopy.length());
    commands << command2;

    QString prompt = "@startcommand";

    if (target)
        prompt = prompt+"to::"+target->objectName();
    else
        prompt = prompt + "::";

    prompt = prompt+":"+reason;

    prompt = prompt+":#"+command1+":#"+command2;

    QString choice = room->askForChoice(this, reason, commands.join("+"), QVariant());

    LogMessage log;
    log.type = "#CommandChoice";
    log.from = this;
    log.arg = "#"+choice;
    room->sendLog(log);

    return allcommands.indexOf(choice);
}

bool ServerPlayer::doCommand(const QString &reason, int index, ServerPlayer *source, ServerPlayer *dest)
{
    QStringList allcommands;
    allcommands << "command1" << "command2" << "command3" << "command4" << "command5" << "command6";

    QString command = allcommands.at(index);

    QString prompt = "@docommand:"+source->objectName()+"::"+reason+":#"+command;

    if (index == 0) {
        if (dest == NULL || dest->isDead()) return false;
        prompt = "@docommand1:"+source->objectName()+":"+ dest->objectName()+":"+reason;
    }else if (index == 1) {
        prompt = "@docommand2:"+source->objectName()+"::"+reason;
    }

    QString choice = room->askForChoice(this, "docommand_"+reason, "yes+no", QVariant::fromValue(index));


    LogMessage log;
    log.type = "#CommandChoice";
    log.from = this;
    log.arg = "#commandselect_"+choice;
    room->sendLog(log);

    if (choice == "yes") {
        switch (index+1) {
        case 1: {
            room->damage(DamageStruct("command", this, dest, 1));
            break;
        }
        case 2: {
            drawCards(1, "command");
            if (this == source || getCardCount(true) == 0) break;
            else if (getCardCount(true) == 1) {
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, objectName(), source->objectName(), "command", QString());
                reason.m_playerId = source->objectName();
                room->obtainCard(source, getCards("he").first(), reason, false);
            } else {
                QList<int> result = room->askForExchange(this, "command", 2, 2, "@command-give:"+source->objectName());
                if (result.isEmpty()){
                    QList<const Card*> list = this->getCards("he");
                    result << list.at(0)->getEffectiveId();
                    result << list.at(1)->getEffectiveId();
                }
                DummyCard dummy(result);
                CardMoveReason reason(CardMoveReason::S_REASON_GIVE, objectName(), source->objectName(), "command", QString());
                reason.m_playerId = source->objectName();
                room->obtainCard(source, &dummy, reason, false);
            }
            break;
        }
        case 3: {
            room->loseHp(this);
            break;
        }
        case 4: {
            addMark("command4_effect");
            room->setPlayerMark(this, "skill_invalidity", 1);
            room->setPlayerCardLimitation(this, "use,response", ".|.|.|hand", true);

            foreach(ServerPlayer *p, room->getAllPlayers())
                room->filterCards(p, p->getCards("he"), true);

            JsonArray args;
            args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
            room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

            break;
        }
        case 5: {
            turnOver();
            addMark("command5_effect");
            tag["CannotRecover"] = true;
            break;
        }
        case 6: {
            if (getHandcardNum() < 2 && getEquips().length() < 2) break;
            QList<int> to_remain;
            if (!isKongcheng())
                to_remain << handCards().first();
            if (hasEquip())
                to_remain << getEquips().first()->getEffectiveId();
            const Card *card = room->askForCard(this, "@@commandefect!", "@command-select", QVariant(), Card::MethodNone);
            if (card != NULL)
                to_remain = card->getSubcards();

            DummyCard *to_discard = new DummyCard;
            to_discard->deleteLater();
            foreach (const Card *c, getCards("he")) {
                if (!isJilei(c) && !to_remain.contains(c->getEffectiveId()))
                    to_discard->addSubcard(c);
            }
            if (to_discard->subcardsLength() > 0) {
                CardMoveReason mreason(CardMoveReason::S_REASON_THROW, objectName(), QString(), "command", QString());
                room->throwCard(to_discard, mreason, this);
            }
            break;
        }
        default: break;
        }
        return true;
    }
    return false;
}

void ServerPlayer::doCommandForcely(const QString &reason, int index, ServerPlayer *source, ServerPlayer *dest)
{
    QStringList allcommands;
    allcommands << "command1" << "command2" << "command3" << "command4" << "command5" << "command6";

    QString command = allcommands.at(index);

    QString prompt = "@docommand:"+source->objectName()+"::"+reason+":#"+command;

    if (index == 0) {
        if (dest == NULL || dest->isDead()) return;
        prompt = "@docommand1:"+source->objectName()+":"+ dest->objectName()+":"+reason;
    }else if (index == 1) {
        prompt = "@docommand2:"+source->objectName()+"::"+reason;
    }

    switch (index+1) {
    case 1: {
        room->damage(DamageStruct("command", this, dest, 1));
        break;
    }
    case 2: {
        drawCards(1, "command");
        if (this == source || getCardCount(true) == 0) break;
        else if (getCardCount(true) == 1) {
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, objectName(), source->objectName(), "command", QString());
            reason.m_playerId = source->objectName();
            room->obtainCard(source, getCards("he").first(), reason, false);
        } else {
            QList<int> result = room->askForExchange(this, "command", 2, 2, "@command-give:"+source->objectName());
            if (result.isEmpty()){
                QList<const Card*> list = this->getCards("he");
                result << list.at(0)->getEffectiveId();
                result << list.at(1)->getEffectiveId();
            }
            DummyCard dummy(result);
            CardMoveReason reason(CardMoveReason::S_REASON_GIVE, objectName(), source->objectName(), "command", QString());
            reason.m_playerId = source->objectName();
            room->obtainCard(source, &dummy, reason, false);
        }
        break;
    }
    case 3: {
        room->loseHp(this);
        break;
    }
    case 4: {
        addMark("command4_effect");
        room->setPlayerMark(this, "skill_invalidity", 1);
        room->setPlayerCardLimitation(this, "use,response", ".|.|.|hand", true);

        foreach(ServerPlayer *p, room->getAllPlayers())
            room->filterCards(p, p->getCards("he"), true);

        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
        room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);

        break;
    }
    case 5: {
        turnOver();
        addMark("command5_effect");
        tag["CannotRecover"] = true;
        break;
    }
    case 6: {
        if (getHandcardNum() < 2 && getEquips().length() < 2) break;
        QList<int> to_remain;
        if (!isKongcheng())
            to_remain << handCards().first();
        if (hasEquip())
            to_remain << getEquips().first()->getEffectiveId();
        const Card *card = room->askForCard(this, "@@commandefect!", "@command-select", QVariant(), Card::MethodNone);
        if (card != NULL)
            to_remain = card->getSubcards();

        DummyCard *to_discard = new DummyCard;
        to_discard->deleteLater();
        foreach (const Card *c, getCards("he")) {
            if (!isJilei(c) && !to_remain.contains(c->getEffectiveId()))
                to_discard->addSubcard(c);
        }
        if (to_discard->subcardsLength() > 0) {
            CardMoveReason mreason(CardMoveReason::S_REASON_THROW, objectName(), QString(), "command", QString());
            room->throwCard(to_discard, mreason, this);
        }
        break;
    }
    default: break;
    }
}

void ServerPlayer::turnOver()
{
    //for zhengchang
    if (this->faceUp() && this->hasSkill("zhengchang")){
        if (this->hasShownSkill("zhengchang") || this->askForSkillInvoke("zhengchang")) {
            if (!this->hasShownSkill("zhengchang"))
                this->showSkill("zhengchang");
            this->getRoom()->sendCompulsoryTriggerLog(this, "zhengchang");
            return;
        }
    }

    setFaceUp(!faceUp());
    room->broadcastProperty(this, "faceup");

    LogMessage log;
    log.type = "#TurnOver";
    log.from = this;
    log.arg = faceUp() ? "face_up" : "face_down";
    room->sendLog(log);

    Q_ASSERT(room->getThread() != NULL);
    room->getThread()->trigger(TurnedOver, room, this);
}

void ServerPlayer::setChained(bool chained)
{
    if (this->isChained() != chained) {
        //for zhengchang
        ServerPlayer *player = this;
        if (!player->isChained() && player->hasSkill("zhengchang")){
            if (player->hasShownSkill("zhengchang") || player->askForSkillInvoke("zhengchang")) {
                player->getRoom()->sendCompulsoryTriggerLog(player, "zhengchang");
                if (!player->hasShownSkill("zhengchang"))
                    player->showSkill("zhengchang");
                return;
            }
        }

        Sanguosha->playSystemAudioEffect("chained");
        player->getRoom()->setPlayerProperty(player, "chained", QVariant(chained));
    }
}

bool ServerPlayer::changePhase(Player::Phase from, Player::Phase to)
{
    RoomThread *thread = room->getThread();
    Q_ASSERT(room->getThread() != NULL);

    setPhase(PhaseNone);

    PhaseChangeStruct phase_change;
    phase_change.from = from;
    phase_change.to = to;
    QVariant data = QVariant::fromValue(phase_change);

    bool skip = thread->trigger(EventPhaseChanging, room, this, data);
    if (skip && to != NotActive) {
        setPhase(from);
        return true;
    }

    setPhase(to);
    room->broadcastProperty(this, "phase");

    if (!phases.isEmpty())
        phases.removeFirst();

    if (!thread->trigger(EventPhaseStart, room, this)) {
        if (getPhase() != NotActive)
            thread->trigger(EventPhaseProceeding, room, this);
    }
    if (getPhase() != NotActive)
        thread->trigger(EventPhaseEnd, room, this);

    return false;
}

void ServerPlayer::play(QList<Player::Phase> set_phases)
{
    if (!set_phases.isEmpty()) {
        if (!set_phases.contains(NotActive))
            set_phases << NotActive;
    } else
        set_phases << RoundStart << Start << Judge << Draw << Play
        << Discard << Finish << NotActive;

    phases = set_phases;
    _m_phases_state.clear();
    for (int i = 0; i < phases.size(); i++) {
        PhaseStruct _phase;
        _phase.phase = phases[i];
        _m_phases_state << _phase;
    }

    for (int i = 0; i < _m_phases_state.size(); i++) {
        if (isDead()) {
            changePhase(getPhase(), NotActive);
            break;
        }

        _m_phases_index = i;
        PhaseChangeStruct phase_change;
        phase_change.from = getPhase();
        phase_change.to = phases[i];

        RoomThread *thread = room->getThread();
        setPhase(PhaseNone);
        QVariant data = QVariant::fromValue(phase_change);

        bool skip = thread->trigger(EventPhaseChanging, room, this, data);
        phase_change = data.value<PhaseChangeStruct>();
        _m_phases_state[i].phase = phases[i] = phase_change.to;

        setPhase(phases[i]);
        room->broadcastProperty(this, "phase");

        if ((skip || _m_phases_state[i].finished)
            && !thread->trigger(EventPhaseSkipping, room, this, data)
            && phases[i] != NotActive)
            continue;

        if (!thread->trigger(EventPhaseStart, room, this)) {
            if (getPhase() != NotActive)
                thread->trigger(EventPhaseProceeding, room, this);
        }
        if (getPhase() != NotActive)
            thread->trigger(EventPhaseEnd, room, this);
        else
            break;
    }
}

QList<Player::Phase> &ServerPlayer::getPhases()
{
    return phases;
}

void ServerPlayer::skip(bool sendLog)
{
    for (int i = 0; i < _m_phases_state.size(); i++)
        _m_phases_state[i].finished = true;

    if (sendLog) {
        LogMessage log;
        log.type = "#SkipAllPhase";
        log.from = this;
        room->sendLog(log);
    }
}

void ServerPlayer::skip(Player::Phase phase, bool sendLog)
{
    for (int i = _m_phases_index; i < _m_phases_state.size(); i++) {
        if (_m_phases_state[i].phase == phase) {
            if (_m_phases_state[i].finished) return;
            _m_phases_state[i].finished = true;
            break;
        }
    }

    static QStringList phase_strings;
    if (phase_strings.isEmpty())
        phase_strings << "round_start" << "start" << "judge" << "draw"
        << "play" << "discard" << "finish" << "not_active";
    int index = static_cast<int>(phase);

    if (sendLog) {
        LogMessage log;
        log.type = "#SkipPhase";
        log.from = this;
        log.arg = phase_strings.at(index);
        room->sendLog(log);
    }
}

void ServerPlayer::insertPhase(Player::Phase phase)
{
    PhaseStruct _phase;
    _phase.phase = phase;
    phases.insert(_m_phases_index, phase);
    _m_phases_state.insert(_m_phases_index, _phase);
}

bool ServerPlayer::isSkipped(Player::Phase phase)
{
    for (int i = _m_phases_index; i < _m_phases_state.size(); i++) {
        if (_m_phases_state[i].phase == phase)
            return _m_phases_state[i].finished;
    }
    return false;
}

void ServerPlayer::gainMark(const QString &mark, int n)
{
    int value = getMark(mark) + n;

    if (!mark.startsWith("@amclub_")){
        LogMessage log;
        log.type = "#GetMark";
        log.from = this;
        log.arg = mark;
        log.arg2 = QString::number(n);

        room->sendLog(log);
    }
    /*LogMessage log;
    log.type = "#GetMark";
    log.from = this;
    if (mark.startsWith("#"))
        log.arg = mark.mid(1);
    else
        log.arg = mark;
    log.arg2 = QString::number(n);

    room->sendLog(log);*/
    room->setPlayerMark(this, mark, value);
}

void ServerPlayer::loseMark(const QString &mark, int n)
{
    if (getMark(mark) == 0) return;
    int value = getMark(mark) - n;
    if (value < 0) {
        value = 0; n = getMark(mark);
    }

    if (!mark.startsWith("@amclub_")){
        LogMessage log;
        log.type = "#LoseMark";
        log.from = this;
        log.arg = mark;
        log.arg2 = QString::number(n);
        room->sendLog(log);
    }
    room->setPlayerMark(this, mark, value);
}

void ServerPlayer::loseAllMarks(const QString &mark_name)
{
    loseMark(mark_name, getMark(mark_name));
}

void ServerPlayer::removeCurrentClub(const QString &club_name){
    if (hasClub(club_name)){
        //QString club_name = getClubName();
        LogMessage log;
        log.type = "$quit_club";
        log.from = this;
        log.arg = club_name;
        room->sendLog(log);
        loseAllMarks("@amclub_" + club_name);
    }
}

void ServerPlayer::addClub(const QString &club_name){
    //removeCurrentClub();
    LogMessage log;
    log.type = "$join_club";
    log.from = this;
    log.arg = club_name;
    room->sendLog(log);
    gainMark("@amclub_" + club_name);
}

void ServerPlayer::addSkill(const QString &skill_name, bool head_skill)
{
    Player::addSkill(skill_name, head_skill);
    JsonArray args;
    args << (int)QSanProtocol::S_GAME_EVENT_ADD_SKILL;
    args << objectName();
    args << skill_name;
    args << head_skill;
    room->doNotify(this, QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

void ServerPlayer::loseSkill(const QString &skill_name, bool head)
{
    Player::loseSkill(skill_name, head);
    JsonArray args;
    args << (int)QSanProtocol::S_GAME_EVENT_LOSE_SKILL;
    args << objectName();
    args << skill_name;
    args << head;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

void ServerPlayer::setGender(General::Gender gender)
{
    if (gender == getGender())
        return;
    Player::setGender(gender);
    JsonArray args;
    args << (int)QSanProtocol::S_GAME_EVENT_CHANGE_GENDER;
    args << objectName();
    args << (int)gender;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_LOG_EVENT, args);
}

bool ServerPlayer::isOnline() const
{
    return getState() == "online";
}

void ServerPlayer::setAI(AI *ai)
{
    this->ai = ai;
}

AI *ServerPlayer::getAI() const
{
    if (getState() == "online")
        return NULL;
    else if (getState() == "robot" || Config.EnableCheat)
        return ai;
    else
        return trust_ai;
}

AI *ServerPlayer::getSmartAI() const
{
    return ai;
}

void ServerPlayer::addVictim(ServerPlayer *victim)
{
    victims.append(victim);
}

QList<ServerPlayer *> ServerPlayer::getVictims() const
{
    return victims;
}

int ServerPlayer::getGeneralMaxHp() const
{
    int max_hp = 0;

    if (getGeneral2() == NULL)
        max_hp = getGeneral()->getDoubleMaxHp();
    else {
        int first = getGeneral()->getMaxHpHead();
        int second = getGeneral2()->getMaxHpDeputy();

        max_hp = (first + second) / 2;
    }

    return max_hp;
}

QString ServerPlayer::getGameMode() const
{
    return room->getMode();
}

QString ServerPlayer::getIp() const
{
    if (socket)
        return socket->peerAddress();
    else
        return QString();
}

void ServerPlayer::introduceTo(ServerPlayer *player)
{
    QString screen_name = screenName();
    QString avatar = property("avatar").toString();

    JsonArray introduce_str;
    introduce_str << objectName();
    introduce_str << screen_name;
    introduce_str << avatar;

    if (player) {
        player->notify(S_COMMAND_ADD_PLAYER, introduce_str);
        room->notifyProperty(player, this, "state");
    } else {
        room->doBroadcastNotify(S_COMMAND_ADD_PLAYER, introduce_str, this);
        room->broadcastProperty(this, "state");
    }

    if (hasShownGeneral1()) {
        foreach (const QString skill_name, head_skills.keys()) {
            if (Sanguosha->getSkill(skill_name)->isVisible()) {
                JsonArray args1;
                args1 << (int)S_GAME_EVENT_ADD_SKILL;
                args1 << objectName();
                args1 << skill_name;
                args1 << true;
                room->doNotify(player, S_COMMAND_LOG_EVENT, args1);
            }

            foreach (const Skill *related_skill, Sanguosha->getRelatedSkills(skill_name)) {
                if (!related_skill->isVisible()) {
                    JsonArray args2;
                    args2 << (int)S_GAME_EVENT_ADD_SKILL;
                    args2 << objectName();
                    args2 << related_skill->objectName();
                    args2 << true;
                    room->doNotify(player, S_COMMAND_LOG_EVENT, args2);
                }
            }
        }
    }

    if (hasShownGeneral2()) {
        foreach (const QString skill_name, deputy_skills.keys()) {
            if (Sanguosha->getSkill(skill_name)->isVisible()) {
                JsonArray args1;
                args1 << S_GAME_EVENT_ADD_SKILL;
                args1 << objectName();
                args1 << skill_name;
                args1 << false;
                room->doNotify(player, S_COMMAND_LOG_EVENT, args1);
            }

            foreach (const Skill *related_skill, Sanguosha->getRelatedSkills(skill_name)) {
                if (!related_skill->isVisible()) {
                    JsonArray args2;
                    args2 << (int)S_GAME_EVENT_ADD_SKILL;
                    args2 << objectName();
                    args2 << related_skill->objectName();
                    args2 << false;
                    room->doNotify(player, S_COMMAND_LOG_EVENT, args2);
                }
            }
        }
    }
}

void ServerPlayer::marshal(ServerPlayer *player) const
{
    room->notifyProperty(player, this, "maxhp");
    room->notifyProperty(player, this, "hp");
    room->notifyProperty(player, this, "general1_showed");
    room->notifyProperty(player, this, "general2_showed");

    if (this == player || hasShownGeneral1())
        room->notifyProperty(player, this, "head_skin_id");
    if (this == player || hasShownGeneral2())
        room->notifyProperty(player, this, "deputy_skin_id");

    if (isAlive()) {
        room->notifyProperty(player, this, "seat");
        if (getPhase() != Player::NotActive)
            room->notifyProperty(player, this, "phase");
    } else {
        room->notifyProperty(player, this, "alive");
        room->notifyProperty(player, this, "role");
        room->doNotify(player, S_COMMAND_KILL_PLAYER, objectName());
    }

    if (!faceUp())
        room->notifyProperty(player, this, "faceup");

    if (isChained())
        room->notifyProperty(player, this, "chained");

    room->notifyProperty(player, this, "gender");

    QList<ServerPlayer*> players;
    players << player;

    QList<CardsMoveStruct> moves;

    if (!isKongcheng()) {
        CardsMoveStruct move;
        foreach (const Card *card, handcards) {
            move.card_ids << card->getId();
            if (player == this) {
                WrappedCard *wrapped = qobject_cast<WrappedCard *>(room->getCard(card->getId()));
                if (wrapped->isModified())
                    room->notifyUpdateCard(player, card->getId(), wrapped);
            }
        }
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceHand;

        if (player == this)
            move.to = player;

        moves << move;
    }

    if (hasEquip()) {
        CardsMoveStruct move;
        foreach (const Card *card, getEquips()) {
            move.card_ids << card->getId();
            WrappedCard *wrapped = qobject_cast<WrappedCard *>(room->getCard(card->getId()));
            if (wrapped->isModified())
                room->notifyUpdateCard(player, card->getId(), wrapped);
        }
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceEquip;

        moves << move;
    }

    if (!getJudgingAreaID().isEmpty()) {
        CardsMoveStruct move;
        foreach(int card_id, getJudgingAreaID())
            move.card_ids << card_id;
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceDelayedTrick;

        moves << move;
    }

    if (!moves.isEmpty()) {
        room->notifyMoveCards(true, moves, false, players);
        room->notifyMoveCards(false, moves, false, players);
    }

    if (!getPileNames().isEmpty()) {
        CardsMoveStruct move;
        move.from_place = DrawPile;
        move.to_player_name = objectName();
        move.to_place = PlaceSpecial;
        foreach (const QString &pile, piles.keys()) {
            move.card_ids.clear();
            move.card_ids.append(piles[pile]);
            move.to_pile_name = pile;

            QList<CardsMoveStruct> moves2;
            moves2 << move;

            bool open = pileOpen(pile, player->objectName());

            room->notifyMoveCards(true, moves2, open, players);
            room->notifyMoveCards(false, moves2, open, players);
        }
    }

    if (!getActualGeneral1Name().isEmpty()) {                       //for actualGeneral
        JsonArray args;
        args << objectName();
        args << getActualGeneral1Name();
        args << true;
        room->doNotify(player, QSanProtocol::S_COMMAND_SET_ACTULGENERAL, args);
    }
    if (!getActualGeneral2Name().isEmpty()) {
        JsonArray args;
        args << objectName();
        args << getActualGeneral2Name();
        args << false;
        room->doNotify(player, QSanProtocol::S_COMMAND_SET_ACTULGENERAL, args);
    }

    QStringList pmarks;
    foreach (QString key, marks.keys()) {                           //for playerMark
        if (!key.startsWith("@") && marks.value(key, 0) > 0) {
            JsonArray arg;
            arg << objectName();
            arg << key;
            arg << marks.value(key, 0);
            room->doNotify(player, S_COMMAND_SET_MARK, arg);
        } else if (key.startsWith("@") && marks.value(key, 0) > 0)
            pmarks << key;
    }
    foreach (const Skill *skill, getSkillList(false, false))
        if (skill->getFrequency() == Skill::Limited && pmarks.contains(skill->getLimitMark()) && !hasShownSkill(skill))
            pmarks.removeOne(skill->getLimitMark());
    foreach (QString mark, pmarks) {
        JsonArray arg;
        arg << objectName();
        arg << mark;
        arg << getMark(mark);
        room->doNotify(player, S_COMMAND_SET_MARK, arg);
    }

    foreach(QString s, Sanguosha->getSkillNames()){
        QStringList huashens = tag[s+"s"].toStringList();
        if (!huashens.isEmpty())
            room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, objectName()+":"+s, huashens.join(":"), QList<ServerPlayer *>() << player);
    }
    /*QStringList huashens = tag["Huashens"].toStringList();          //for huashen
    if (!huashens.isEmpty())
        room->doAnimate(QSanProtocol::S_ANIMATE_HUASHEN, objectName(), huashens.join(":"), QList<ServerPlayer *>() << player);*/

    foreach (QString reason, disableShow(true)) {                   //for disableshow
        JsonArray arg;
        arg << objectName();
        arg << true;
        arg << "h";
        arg << reason;
        room->doNotify(player, S_COMMAND_DISABLE_SHOW, arg);
    }
    foreach (QString reason, disableShow(false)) {
        JsonArray arg;
        arg << objectName();
        arg << true;
        arg << "d";
        arg << reason;
        room->doNotify(player, S_COMMAND_DISABLE_SHOW, arg);
    }

    if (player == this || hasShownOneGeneral()) {
        room->notifyProperty(player, this, "kingdom");
        room->notifyProperty(player, this, "role");
    } else {
        room->notifyProperty(player, this, "kingdom", "god");
    }

    foreach(const QString &flag, flags)
        room->notifyProperty(player, this, "flags", flag);

    foreach (const QString &item, history.keys()) {
        int value = history.value(item);
        if (value > 0) {

            JsonArray arg;
            arg << item;
            arg << value;

            room->doNotify(player, S_COMMAND_ADD_HISTORY, arg);
        }
    }
}

void ServerPlayer::addToPile(const QString &pile_name, const Card *card, bool open, QList<ServerPlayer *> open_players)
{
    QList<int> card_ids;
    if (card->isVirtualCard())
        card_ids = card->getSubcards();
    else
        card_ids << card->getEffectiveId();
    return addToPile(pile_name, card_ids, open, open_players);
}

void ServerPlayer::addToPile(const QString &pile_name, int card_id, bool open, QList<ServerPlayer *> open_players)
{
    QList<int> card_ids;
    card_ids << card_id;
    return addToPile(pile_name, card_ids, open, open_players);
}

void ServerPlayer::addToPile(const QString &pile_name, QList<int> card_ids, bool open, QList<ServerPlayer *> open_players)
{
    return addToPile(pile_name, card_ids, open, open_players, CardMoveReason());
}

void ServerPlayer::addToPile(const QString &pile_name, QList<int> card_ids,
    bool open, QList<ServerPlayer *> open_players, CardMoveReason reason)
{
    if (!open) {
        if (open_players.isEmpty()) {
            foreach (int id, card_ids) {
                ServerPlayer *owner = room->getCardOwner(id);
                if (owner && !open_players.contains(owner))
                    open_players << owner;
            }
        }
    } else {
        open_players = room->getAllPlayers();
    }
    foreach(ServerPlayer *p, open_players)
        setPileOpen(pile_name, p->objectName());
    piles[pile_name].append(card_ids);

    CardsMoveStruct move;
    move.card_ids = card_ids;
    move.to = this;
    move.to_place = Player::PlaceSpecial;
    move.reason = reason;
    room->moveCardsAtomic(move, open);
}

void ServerPlayer::pileAdd(const QString &pile_name, QList<int> card_ids)
{
    piles[pile_name].append(card_ids);
}

void ServerPlayer::gainAnExtraTurn()
{
    QStringList extraTurnList;
    if (!room->getTag("ExtraTurnList").isNull())
        extraTurnList = room->getTag("ExtraTurnList").toStringList();
    extraTurnList.prepend(objectName());
    room->setTag("ExtraTurnList", QVariant::fromValue(extraTurnList));
}

void ServerPlayer::gainAnInstantExtraTurn()
{
    ServerPlayer *current = room->getCurrent();
    try {
        room->setCurrent(this);
        room->setPlayerFlag(this, "Point_ExtraTurn");
        room->getThread()->trigger(TurnStart, room, this);
        room->setCurrent(current);
    }
    catch (TriggerEvent triggerEvent) {
        if (triggerEvent == TurnBroken) {
            if (getPhase() != Player::NotActive) {
                const GameRule *game_rule = NULL;
                if (room->getMode() == "04_1v3")
                    game_rule = qobject_cast<const GameRule *>(Sanguosha->getTriggerSkill("hulaopass_mode"));
                else
                    game_rule = qobject_cast<const GameRule *>(Sanguosha->getTriggerSkill("game_rule"));
                if (game_rule) {
                    QVariant v;
                    if (this->getPhase() == Player::Play)
                        room->addPlayerHistory(this, ".");
                }
                changePhase(getPhase(), Player::NotActive);
            }
            room->setCurrent(current);
        }
        throw triggerEvent;
    }
}

void ServerPlayer::copyFrom(ServerPlayer *sp)
{
    ServerPlayer *b = this;
    ServerPlayer *a = sp;

    b->handcards = QList<const Card *>(a->handcards);
    b->phases = QList<ServerPlayer::Phase>(a->phases);
    b->selected = QStringList(a->selected);

    Player *c = b;
    c->copyFrom(a);
}

bool ServerPlayer::CompareByActionOrder(ServerPlayer *a, ServerPlayer *b)
{
    Room *room = a->getRoom();
    return room->getFront(a, b) == a;
}

bool ServerPlayer::showSkill(const QString &skill_name, const QString &skill_position)
{
    if (skill_name.isEmpty()) return false;
    bool result = false;
    if (skill_name == "showforviewhas") {           //this is for some skills that player doesnt own but need to show, such as hongfa-slash. by weirdouncle
        if (!hasShownOneGeneral()) {
            QStringList q;
            if (canShowGeneral("h")) q << "GameRule_AskForGeneralShowHead";
            if (canShowGeneral("d")) q << "GameRule_AskForGeneralShowDeputy";
            SPlayerDataMap map;
            map.insert(this, q);
            QString name;
            if (q.length() > 1) {
                name = room->askForTriggerOrder(this, "GameRule:ShowGeneral", map, false);
                name.remove(objectName() + ":");
            } else
                 name = q.first();
            showGeneral(name == "GameRule_AskForGeneralShowHead" ? true : false, true, true, false);
            result = true;
        }
        return result;
    }

    const Skill *skill = Sanguosha->getSkill(skill_name);
    if (skill == NULL) return false;
    QString actived_skill = skill->objectName();

    if (ownSkill(actived_skill)) {                                          //acquired skills no need to show
        bool head = inHeadSkills(actived_skill) && canShowGeneral("h");
        if (!skill_position.isEmpty())
            head = skill_position == "left" ? true : false;
        if (head && !hasShownGeneral1()) {
            showGeneral(true);
            result = true;
        }
        if (!head && !hasShownGeneral2()) {
            showGeneral(false);
            result = true;
        }
    } else if (!hasShownSkill(actived_skill)) {                             //for show viewhasSkills, not consider duplicate yet. by weidouncle
        const ViewHasSkill *vhskill = Sanguosha->ViewHas(this, actived_skill, "skill");
        if (vhskill && ownSkill(vhskill)) {
            showGeneral(inHeadSkills(vhskill->objectName()));
            result = true;
        } else if (vhskill && !vhskill->isGlobal()) {
            QStringList q;
            if (canShowGeneral("h")) q << "GameRule_AskForGeneralShowHead";
            if (canShowGeneral("d")) q << "GameRule_AskForGeneralShowDeputy";
            SPlayerDataMap map;
            map.insert(this, q);
            QString name;
            if (q.length() > 1) {
                name = room->askForTriggerOrder(this, "GameRule:ShowGeneral", map, false);
                name.remove(objectName() + ":");
            } else
                name = q.first();
            showGeneral(name == "GameRule_AskForGeneralShowHead" ? true : false, true, true, false);
            result = true;
        }
    }
    return result;
}

void ServerPlayer::showGeneral(bool head_general, bool trigger_event, bool sendLog, bool ignore_rule)
{
    QStringList names = room->getTag(objectName()).toStringList();
    if (names.isEmpty()) return;
    QString general_name;
    bool extra_samekingdom = false;

    room->tryPause();

    if (head_general) {
        if (!ignore_rule && !canShowGeneral("h")) return;
        if (getGeneralName() != "anjiang") return;

        room->removePlayerMark(this, "HaventShowGeneral");

        setSkillsPreshowed("h");
        notifyPreshow();
        room->setPlayerProperty(this, "general1_showed", true);

        general_name = names.first();

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << general_name;
        arg << false;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);
        room->changePlayerGeneral(this, general_name);


        if (!property("Duanchang").toString().split(",").contains("head")) {
            sendSkillsToOthers();
            foreach (const Skill *skill, getHeadSkillList()) {
                if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || hasLordSkill(skill->objectName())) && hasShownSkill(skill)) {
                    JsonArray arg;
                    arg << objectName();
                    arg << skill->getLimitMark();
                    arg << getMark(skill->getLimitMark());
                    room->doBroadcastNotify(QSanProtocol::S_COMMAND_SET_MARK, arg);
                }
            }
        }

        foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
            room->notifyProperty(p, this, "head_skin_id");

        if (getGeneral()->getKingdom() == "careerist" || getRole() == "careerist") {
            if (getGeneral()->getKingdom() == "careerist" && property("CareeristFriend").toString().isEmpty())
                room->setPlayerProperty(this, "kingdom", "careerist");
                //setKingdom("careerist");
            room->setPlayerProperty(this, "role", "careerist");
        }
        else if (!hasShownGeneral2()) {
            QString kingdom = getKingdom() != getGeneral()->getKingdom() ? getKingdom() : getGeneral()->getKingdom();
            room->setPlayerProperty(this, "kingdom", kingdom);

            QString role = HegemonyMode::GetMappedRole(kingdom);
            int i = 1;
            bool has_lord = isAlive() && getGeneral()->isLord();
            if (!has_lord) {
                foreach (ServerPlayer *p, room->getOtherPlayers(this, true)) {
                    if (p->getKingdom() == kingdom) {
                        if (p->getGeneral()->isLord()) {
                            has_lord = true;
                            break;
                        }
                        if (p->hasShownOneGeneral() && p->getRole() != "careerist")
                            ++i;
                    }
                }
            }

            if (((!has_lord && i > (room->getPlayers().length() / 2)) || (has_lord && getLord(true)->isDead()))&& room->getMode()!= "maria_battle")
                role = "careerist";

            room->setPlayerProperty(this, "role", role);
        }

        if (isLord()) {
            QString kingdom = getKingdom();
            foreach (ServerPlayer *p, room->getPlayers()) {
                if (p->getKingdom() == kingdom && p->getRole() == "careerist" && p->property("CareeristFriend").toString().isEmpty()) {
                    room->setPlayerProperty(p, "role", HegemonyMode::GetMappedRole(kingdom));
                    room->broadcastProperty(p, "kingdom");
                }
            }
        }
    } else {
        if (!ignore_rule && !canShowGeneral("d")) return;
        if (getGeneral2Name() != "anjiang") return;

        room->removePlayerMark(this, "HaventShowGeneral2");

        setSkillsPreshowed("d");
        notifyPreshow();
        room->setPlayerProperty(this, "general2_showed", true);

        general_name = names.at(1);
        JsonArray arg;
        arg << S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << general_name;
        arg << true;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);
        room->changePlayerGeneral2(this, general_name);


        if (!property("Duanchang").toString().split(",").contains("deputy")) {
            sendSkillsToOthers(false);
            foreach (const Skill *skill, getDeputySkillList()) {
                if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || hasLordSkill(skill->objectName())) && hasShownSkill(skill)) {
                    JsonArray arg;
                    arg << objectName();
                    arg << skill->getLimitMark();
                    arg << getMark(skill->getLimitMark());
                    room->doBroadcastNotify(QSanProtocol::S_COMMAND_SET_MARK, arg);
                }
            }
        }

        foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
            room->notifyProperty(p, this, "deputy_skin_id");

        if (getRole() == "careerist") {
            room->setPlayerProperty(this, "role", "careerist");
        }else if (!hasShownGeneral1()) {
            QString kingdom = getKingdom() != getGeneral()->getKingdom() ? getKingdom() : getGeneral()->getKingdom();
            room->setPlayerProperty(this, "kingdom", kingdom);

            QString role = HegemonyMode::GetMappedRole(kingdom);
            int i = 1;
            bool has_lord = isAlive() && getGeneral()->isLord();
            if (!has_lord) {
                foreach (ServerPlayer *p, room->getOtherPlayers(this, true)) {
                    if (p->getKingdom() == kingdom) {
                        if (p->getGeneral()->isLord()) {
                            has_lord = true;
                            break;
                        }
                        if (p->hasShownOneGeneral() && p->getRole() != "careerist")
                            ++i;
                    }
                }
            }

            if (((!has_lord && i > (room->getPlayers().length() / 2)) || (has_lord && getLord(true)->isDead())) && room->getMode()!= "maria_battle"){
                extra_samekingdom = true;
                role = "careerist";
            }
            room->setPlayerProperty(this, "role", role);
        }
    }

    if (sendLog) {
        LogMessage log;
        log.type = "#BasaraReveal";
        log.from = this;
        log.arg = getGeneralName();
        log.arg2 = getGeneral2Name();
        room->sendLog(log);
    }

    //test
    /*if (getActualGeneral1()->getKingdom() == "careerist" && !getActualGeneral2()->getKingdom().contains("|")){
        if (!head_general && !hasShownGeneral1()){
            //room->setPlayerProperty(this, "kingdom", QVariant("careerist"));
            setKingdom("careerist");
            room->notifyProperty(this, this, "kingdom");
            if (!extra_samekingdom){
                room->setPlayerProperty(this, "role", QVariant(getActualGeneral2()->getKingdom()));
                setKingdom(getActualGeneral2()->getKingdom());
            }
        }
    }*/

    if (trigger_event) {
        Q_ASSERT(room->getThread() != NULL);
        QVariant _head = head_general;
        room->getThread()->trigger(GeneralShown, room, this, _head);
    }

    room->filterCards(this, getCards("he"), true);


}

void ServerPlayer::hideGeneral(bool head_general)
{
    room->tryPause();

    if (head_general) {
        if (getGeneralName() == "anjiang") return;
        if (getActualGeneral1()->isLord()){
            LogMessage log;
            log.type = "#LordHideRule";
            room->sendLog(log);
            return;
        }

        setSkillsPreshowed("h", false);
        // dirty hack for temporary convenience.
        room->setPlayerProperty(this, "flags", "hiding");
        notifyPreshow();
        room->setPlayerProperty(this, "general1_showed", false);
        room->setPlayerProperty(this, "flags", "-hiding");

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << "anjiang";
        arg << false;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

        //for picture adjust
        setHeadSkinId(0);

        room->changePlayerGeneral(this, "anjiang");

        disconnectSkillsFromOthers();

        foreach (const Skill *skill, getVisibleSkillList()) {
            if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || hasLordSkill(skill->objectName())) && !hasShownSkill(skill) && getMark(skill->getLimitMark()) > 0) {
                JsonArray arg;
                arg << objectName();
                arg << skill->getLimitMark();
                arg << 0;
                foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
                    room->doNotify(p, QSanProtocol::S_COMMAND_SET_MARK, arg);
            }
        }

        if (!hasShownGeneral2()) {
            //room->setPlayerProperty(this, "kingdom", "god");
            //room->setPlayerProperty(this, "role", HegemonyMode::GetMappedRole("god"));
        }
    } else {
        if (getGeneral2Name() == "anjiang") return;

        setSkillsPreshowed("d", false);
        // dirty hack for temporary convenience
        room->setPlayerProperty(this, "flags", "hiding");
        notifyPreshow();
        room->setPlayerProperty(this, "general2_showed", false);
        room->setPlayerProperty(this, "flags", "-hiding");

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << "anjiang";
        arg << true;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

        //for picture adjust
        setDeputySkinId(0);

        room->changePlayerGeneral2(this, "anjiang");

        disconnectSkillsFromOthers(false);

        foreach (const Skill *skill, getVisibleSkillList()) {
            if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || hasLordSkill(skill->objectName())) && !hasShownSkill(skill) && getMark(skill->getLimitMark()) > 0) {
                JsonArray arg;
                arg << objectName();
                arg << skill->getLimitMark();
                arg << 0;
                foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
                    room->doNotify(p, QSanProtocol::S_COMMAND_SET_MARK, arg);
            }
        }

        if (!hasShownGeneral1()) {
            //room->setPlayerProperty(this, "kingdom", "god");
            //room->setPlayerProperty(this, "role", HegemonyMode::GetMappedRole("god"));
        }
    }

    LogMessage log;
    log.type = "#BasaraConceal";
    log.from = this;
    log.arg = getGeneralName();
    log.arg2 = getGeneral2Name();
    room->sendLog(log);

    Q_ASSERT(room->getThread() != NULL);
    QVariant _head = head_general;
    room->getThread()->trigger(GeneralHidden, room, this, _head);

    room->filterCards(this, getCards("he"), true);
    setSkillsPreshowed(head_general ? "h" : "d");
    notifyPreshow();
}

void ServerPlayer::hideGeneralWithoutChangingRole(bool head_general)
{
    room->tryPause();

    if (head_general) {
        if (getGeneralName() == "anjiang") return;
        if (getActualGeneral1()->isLord()){
            LogMessage log;
            log.type = "#LordHideRule";
            room->sendLog(log);
            return;
        }

        setSkillsPreshowed("h", false);
        // dirty hack for temporary convenience.
        room->setPlayerProperty(this, "flags", "hiding");
        notifyPreshow();
        room->setPlayerProperty(this, "general1_showed", false);
        room->setPlayerProperty(this, "flags", "-hiding");

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << "anjiang";
        arg << false;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

        //for picture adjust
        setHeadSkinId(0);

        room->changePlayerGeneral(this, "anjiang");

        disconnectSkillsFromOthers();

        foreach (const Skill *skill, getVisibleSkillList()) {
            if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || hasLordSkill(skill->objectName())) && !hasShownSkill(skill) && getMark(skill->getLimitMark()) > 0) {
                JsonArray arg;
                arg << objectName();
                arg << skill->getLimitMark();
                arg << 0;
                foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
                    room->doNotify(p, QSanProtocol::S_COMMAND_SET_MARK, arg);
            }
        }

    } else {
        if (getGeneral2Name() == "anjiang") return;

        setSkillsPreshowed("d", false);
        // dirty hack for temporary convenience
        room->setPlayerProperty(this, "flags", "hiding");
        notifyPreshow();
        room->setPlayerProperty(this, "general2_showed", false);
        room->setPlayerProperty(this, "flags", "-hiding");

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << "anjiang";
        arg << true;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);

        //for picture adjust
        setDeputySkinId(0);

        room->changePlayerGeneral2(this, "anjiang");

        disconnectSkillsFromOthers(false);

        foreach (const Skill *skill, getVisibleSkillList()) {
            if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty() && (!skill->isLordSkill() || hasLordSkill(skill->objectName())) && !hasShownSkill(skill) && getMark(skill->getLimitMark()) > 0) {
                JsonArray arg;
                arg << objectName();
                arg << skill->getLimitMark();
                arg << 0;
                foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
                    room->doNotify(p, QSanProtocol::S_COMMAND_SET_MARK, arg);
            }
        }
    }

    LogMessage log;
    log.type = "#BasaraConceal";
    log.from = this;
    log.arg = getGeneralName();
    log.arg2 = getGeneral2Name();
    room->sendLog(log);

    Q_ASSERT(room->getThread() != NULL);
    QVariant _head = head_general;
    room->getThread()->trigger(GeneralHidden, room, this, _head);

    room->filterCards(this, getCards("he"), true);
    setSkillsPreshowed(head_general ? "h" : "d");
    notifyPreshow();
}

void ServerPlayer::removeGeneral(bool head_general)
{
    QString general_name, from_general;

    room->tryPause();

    room->setEmotion(this, "remove");

    if (head_general) {
        if (!hasShownGeneral1())
            showGeneral();   //zoushi?

        from_general = getActualGeneral1Name();
        if (from_general.contains("sujiang")) return;
        General::Gender gender = getActualGeneral1()->getGender();
        general_name = gender == General::Male ? "sujiang" : "sujiangf";

        room->setPlayerProperty(this, "actual_general1", general_name);
        room->setPlayerProperty(this, "general1_showed", true);

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << general_name;
        arg << false;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);
        room->changePlayerGeneral(this, general_name);

        setSkillsPreshowed("h", false);
        disconnectSkillsFromOthers();

        foreach (const Skill *skill, getHeadSkillList()) {
            if (skill)
                room->detachSkillFromPlayer(this, skill->objectName(), false, false, true);
        }
        QList<QVariant> list = room->getTag("removed_general").value<QList<QVariant>>();
        if (!list.contains(QVariant::fromValue(from_general))) list << QVariant::fromValue(from_general);
        room->setTag("removed_general", QVariant::fromValue(list));
    } else {
        if (!hasShownGeneral2())
            showGeneral(false); //zoushi?

        from_general = getActualGeneral2Name();
        if (from_general.contains("sujiang")) return;
        General::Gender gender = getActualGeneral2()->getGender();
        general_name = gender == General::Male ? "sujiang" : "sujiangf";

        room->setPlayerProperty(this, "actual_general2", general_name);
        room->setPlayerProperty(this, "general2_showed", true);

        JsonArray arg;
        arg << (int)S_GAME_EVENT_CHANGE_HERO;
        arg << objectName();
        arg << general_name;
        arg << true;
        arg << false;
        room->doBroadcastNotify(S_COMMAND_LOG_EVENT, arg);
        room->changePlayerGeneral2(this, general_name);

        setSkillsPreshowed("d", false);
        disconnectSkillsFromOthers(false);

        foreach (const Skill *skill, getDeputySkillList()) {
            if (skill)
                room->detachSkillFromPlayer(this, skill->objectName(), false, false, false);
        }
        QList<QVariant> list = room->getTag("removed_general").value<QList<QVariant>>();
        if (!list.contains(QVariant::fromValue(from_general))) list << QVariant::fromValue(from_general);
        room->setTag("removed_general", QVariant::fromValue(list));
    }

    LogMessage log;
    log.type = "#BasaraRemove";
    log.from = this;
    log.arg = head_general ? "head_general" : "deputy_general";
    log.arg2 = from_general;
    room->sendLog(log);

    Q_ASSERT(room->getThread() != NULL);
    QVariant _from = from_general;
    room->getThread()->trigger(GeneralRemoved, room, this, _from);

    room->filterCards(this, getCards("he"), true);
}

void ServerPlayer::sendSkillsToOthers(bool head_skill /* = true */)
{
    QStringList names = room->getTag(objectName()).toStringList();
    if (names.isEmpty()) return;

    const QList<const Skill *> skills = head_skill ? getHeadSkillList() : getDeputySkillList();
    foreach (const Skill *skill, skills) {
        JsonArray args;
        args << QSanProtocol::S_GAME_EVENT_ADD_SKILL;
        args << objectName();
        args << skill->objectName();
        args << head_skill;
        foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
            room->doNotify(p, QSanProtocol::S_COMMAND_LOG_EVENT, args);
    }
}

void ServerPlayer::disconnectSkillsFromOthers(bool head_skill /* = true */)
{
    foreach (const QString &skill, head_skill ? head_skills.keys() : deputy_skills.keys()) {
        QVariant _skill = skill + ":" + (head_skill ? "head" : "deputy");
        room->getThread()->trigger(EventLoseSkill, room, this, _skill);
        JsonArray args;
        args << (int)QSanProtocol::S_GAME_EVENT_DETACH_SKILL;
        args << objectName();
        args << skill;
        args << head_skill;
        foreach(ServerPlayer *p, room->getOtherPlayers(this, true))
            room->doNotify(p, QSanProtocol::S_COMMAND_LOG_EVENT, args);
    }

}

bool ServerPlayer::askForGeneralShow(bool one, bool refusable)
{
    if (hasShownAllGenerals())
        return false;

    QStringList choices;

    if (!hasShownGeneral1() && disableShow(true).isEmpty())
        choices << "show_head_general";
    if (!hasShownGeneral2() && disableShow(false).isEmpty())
        choices << "show_deputy_general";
    if (choices.isEmpty())
        return false;
    if (!one && choices.length() == 2)
        choices << "show_both_generals";
    if (refusable)
        choices.append("cancel");

    QString choice = room->askForChoice(this, "GameRule_AskForGeneralShow", choices.join("+"));

    if (choice == "show_head_general" || choice == "show_both_generals")
        showGeneral();
    if (choice == "show_deputy_general" || choice == "show_both_generals")
        showGeneral(false);

    return choice.startsWith("s");
}

void ServerPlayer::notifyPreshow()
{
    JsonArray args;
    args << (int)S_GAME_EVENT_UPDATE_PRESHOW;
    JsonObject args1;
    foreach (const QString skill, head_skills.keys() + deputy_skills.keys()) {
        args1.insert(skill, head_skills.value(skill, false)
            || deputy_skills.value(skill, false));
    }
    args << args1;
    room->doNotify(this, S_COMMAND_LOG_EVENT, args);

    JsonArray args2;
    args2 << (int)QSanProtocol::S_GAME_EVENT_UPDATE_SKILL;
    room->doNotify(this, QSanProtocol::S_COMMAND_LOG_EVENT, args2);
}

bool ServerPlayer::inSiegeRelation(const ServerPlayer *skill_owner, const ServerPlayer *victim) const
{
    if (isFriendWith(victim) || !isFriendWith(skill_owner) || !victim->hasShownOneGeneral()) return false;
    if (this == skill_owner)
        return (getNextAlive() == victim && getNextAlive(2)->isFriendWith(this))
        || (getLastAlive() == victim && getLastAlive(2)->isFriendWith(this));
    else
        return (getNextAlive() == victim && getNextAlive(2) == skill_owner)
        || (getLastAlive() == victim && getLastAlive(2) == skill_owner);
}

bool ServerPlayer::inFormationRalation(ServerPlayer *teammate) const
{
    QList<const Player *> teammates = getFormation();
    return teammates.length() > 1 && teammates.contains(teammate);
}

using namespace HegemonyMode;

void ServerPlayer::summonFriends(const ArrayType type)
{
    room->tryPause();

    if (aliveCount() < 4) return;
    LogMessage log;
    log.type = "#InvokeSkill";
    log.from = this;
    log.arg = "GameRule_AskForArraySummon";
    room->sendLog(log);
    LogMessage log2;
    log2.type = "#SummonType";
    log2.arg = type == Siege ? "summon_type_siege" : "summon_type_formation";
    room->sendLog(log2);
    switch (type) {
    case Siege: {
        if (isFriendWith(getNextAlive()) && isFriendWith(getLastAlive())) return;
        bool failed = true;
        if (!isFriendWith(getNextAlive()) && getNextAlive()->hasShownOneGeneral()) {
            ServerPlayer *target = qobject_cast<ServerPlayer *>(getNextAlive(2));
            if (!target->hasShownOneGeneral()) {
                QString prompt = target->willBeFriendWith(this) ? "SiegeSummon" : "SiegeSummon!";
                bool success = room->askForSkillInvoke(target, prompt);
                LogMessage log;
                log.type = "#SummonResult";
                log.from = target;
                log.arg = success ? "summon_success" : "summon_failed";
                room->sendLog(log);
                if (success) {
                    target->askForGeneralShow();
                    room->doAnimate(QSanProtocol::S_ANIMATE_BATTLEARRAY, objectName(), QString("%1+%2").arg(objectName()).arg(target->objectName()));       //player success animation
                    failed = false;
                }
            }
        }
        if (!isFriendWith(getLastAlive()) && getLastAlive()->hasShownOneGeneral()) {
            ServerPlayer *target = qobject_cast<ServerPlayer *>(getLastAlive(2));
            if (!target->hasShownOneGeneral()) {
                QString prompt = target->willBeFriendWith(this) ? "SiegeSummon" : "SiegeSummon!";
                bool success = room->askForSkillInvoke(target, prompt);
                LogMessage log;
                log.type = "#SummonResult";
                log.from = target;
                log.arg = success ? "summon_success" : "summon_failed";
                room->sendLog(log);
                if (success) {
                    target->askForGeneralShow();
                    room->doAnimate(QSanProtocol::S_ANIMATE_BATTLEARRAY, objectName(), QString("%1+%2").arg(objectName()).arg(target->objectName()));       //player success animation
                    failed = false;
                }
            }
        }
        if (failed)
            room->setPlayerFlag(this, "Global_SummonFailed");
        break;
    } case Formation: {
        int n = aliveCount(false);
        int asked = n;
        bool failed = true;
        for (int i = 1; i < n; ++i) {
            ServerPlayer *target = qobject_cast<ServerPlayer *>(getNextAlive(i));
            if (isFriendWith(target))
                continue;
            else if (!target->hasShownOneGeneral()) {
                QString prompt = target->willBeFriendWith(this) ? "FormationSummon" : "FormationSummon!";
                bool success = room->askForSkillInvoke(target, prompt);
                LogMessage log;
                log.type = "#SummonResult";
                log.from = target;
                log.arg = success ? "summon_success" : "summon_failed";
                room->sendLog(log);

                if (success) {
                    target->askForGeneralShow();
                    room->doBattleArrayAnimate(target);       //player success animation
                    failed = false;
                } else {
                    asked = i;
                    break;
                }
            } else {
                asked = i;
                break;
            }
        }

        n -= asked;
        for (int i = 1; i < n; ++i) {
            ServerPlayer *target = qobject_cast<ServerPlayer *>(getLastAlive(i));
            if (isFriendWith(target))
                continue;
            else {
                if (!target->hasShownOneGeneral()) {
                    QString prompt = target->willBeFriendWith(this) ? "FormationSummon" : "FormationSummon!";
                    bool success = room->askForSkillInvoke(target, prompt);
                    LogMessage log;
                    log.type = "#SummonResult";
                    log.from = target;
                    log.arg = success ? "summon_success" : "summon_failed";
                    room->sendLog(log);

                    if (success) {
                        target->askForGeneralShow();
                        room->doBattleArrayAnimate(target);       //player success animation
                        failed = false;
                    }
                }
                break;
            }
        }
        if (failed)
            room->setPlayerFlag(this, "Global_SummonFailed");
        break;
    }
    }
}

QStringList ServerPlayer::getBigKingdoms(const QString &reason, MaxCardsType::MaxCardsCount _type) const
{
    ServerPlayer *jade_seal_owner = NULL;
    foreach (ServerPlayer *p, room->getAlivePlayers()) {
        if (p->hasTreasure("JadeSeal") && p->hasShownOneGeneral()) {
            jade_seal_owner = p;
            break;
        }
    }
    MaxCardsType::MaxCardsCount type = jade_seal_owner ? MaxCardsType::Max : _type;
    // if there is someone has JadeSeal, needn't trigger event because of the fucking effect of JadeSeal
    QMap<QString, int> kingdom_map;
    QStringList kingdoms = Sanguosha->getKingdoms();
    foreach (const QString &kingdom, kingdoms) {
        if (kingdom == "god") continue;
        kingdom_map.insert(kingdom, getPlayerNumWithSameKingdom(reason, kingdom, type));
    }
    QStringList big_kingdoms;
    foreach (const QString &key, kingdom_map.keys()) {
        if (kingdom_map[key] <= 1)
            continue;
        if (big_kingdoms.isEmpty()) {
            big_kingdoms << key;
            continue;
        }
        if (kingdom_map[key] == kingdom_map[big_kingdoms.first()]) {
            big_kingdoms << key;
        } else if (kingdom_map[key] > kingdom_map[big_kingdoms.first()]) {
            big_kingdoms.clear();
            big_kingdoms << key;
        }
    }
    if (jade_seal_owner != NULL) {
        if (jade_seal_owner->getRole() == "careerist") {
            big_kingdoms.clear();
            big_kingdoms << jade_seal_owner->objectName(); // record player's objectName who has JadeSeal.
        } else { // has shown one general but isn't careerist
            QString kingdom = jade_seal_owner->getKingdom();
            big_kingdoms.clear();
            big_kingdoms << kingdom;
        }
    }
    return big_kingdoms;
}

void ServerPlayer::changeToLord()
{
    foreach (const QString &skill_name, head_skills.keys()) {
        Player::loseSkill(skill_name);
        JsonArray arg_loseskill;
        arg_loseskill << (int)QSanProtocol::S_GAME_EVENT_LOSE_SKILL;
        arg_loseskill << objectName();
        arg_loseskill << skill_name;
        arg_loseskill << true;
        room->doNotify(this, QSanProtocol::S_COMMAND_LOG_EVENT, arg_loseskill);

        const Skill *skill = Sanguosha->getSkill(skill_name);
        if (skill != NULL) {
            if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty())
                room->setPlayerMark(this, skill->getLimitMark(), 0);
        }
    }


    QStringList real_generals = room->getTag(objectName()).toStringList();
    QString name = real_generals.takeFirst();

    const General *head = Sanguosha->getGeneral(name);

    name.prepend("lord_");
    real_generals.prepend(name);
    room->setTag(objectName(), real_generals);

    if (hasShownAllGenerals()){
        room->setPlayerMark(this, "@companion", qMax(getMark("@companion"),1));
    }
    else{
        room->setPlayerMark(this, "CompanionEffect", 1);
    }

    const General *lord = Sanguosha->getGeneral(name);
    const General *deputy = Sanguosha->getGeneral(real_generals.last());
    Q_ASSERT(head != NULL && lord != NULL && deputy != NULL);
    int doubleMaxHp = lord->getMaxHpHead() + deputy->getMaxHpDeputy();
    if (hasShownAllGenerals()){
        room->setPlayerMark(this, "@halfmaxhp", getMark("@halfmaxhp")+doubleMaxHp % 2);
    }
    else{
        room->setPlayerMark(this, "HalfMaxHpLeft", doubleMaxHp % 2);
    }

    int x = getMaxHp();
    int y = x + doubleMaxHp / 2 - (head->getMaxHpHead() + deputy->getMaxHpDeputy()) / 2;
    setMaxHp(y);

    if (y > x)
        setHp(getHp() - x + y);

    room->broadcastProperty(this, "maxhp");
    room->broadcastProperty(this, "hp");

    setActualGeneral1Name(name);
    room->notifyProperty(this, this, "actual_general1");

    JsonArray arg_changehero;
    arg_changehero << (int)S_GAME_EVENT_CHANGE_HERO;
    arg_changehero << objectName();
    arg_changehero << name;
    arg_changehero << false;
    arg_changehero << false;
    room->doNotify(this, QSanProtocol::S_COMMAND_LOG_EVENT, arg_changehero);

    foreach (const Skill *skill, lord->getVisibleSkillList(true)) {
        addSkill(skill->objectName());

        if (skill->getFrequency() == Skill::Limited && !skill->getLimitMark().isEmpty()) {
            setMark(skill->getLimitMark(), 1);
            JsonArray arg;
            arg << objectName();
            arg << skill->getLimitMark();
            arg << 1;
            room->doNotify(this, S_COMMAND_SET_MARK, arg);
        }
    }
}

void ServerPlayer::slashSettlementFinished(const Card *slash)
{
    removeQinggangTag(slash);

    QStringList blade_use = property("blade_use").toStringList();

    if (blade_use.contains(slash->toString())) {
        blade_use.removeOne(slash->toString());
        room->setPlayerProperty(this, "blade_use", blade_use);

        if (blade_use.isEmpty())
            room->removePlayerDisableShow(this, "Blade");
    }
}

void ServerPlayer::setActualGeneral1Name(const QString &name)
{
    Player::setActualGeneral1Name(name);
    JsonArray args;
    args << objectName();
    args << name;
    args << true;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_SET_ACTULGENERAL, args);
}

void ServerPlayer::setActualGeneral2Name(const QString &name)
{
    Player::setActualGeneral2Name(name);
    JsonArray args;
    args << objectName();
    args << name;
    args << false;
    room->doBroadcastNotify(QSanProtocol::S_COMMAND_SET_ACTULGENERAL, args);
}

#ifndef QT_NO_DEBUG
bool ServerPlayer::event(QEvent *event) {
#define SET_MY_PROPERTY {\
    ServerPlayerEvent *SPEvent = static_cast<ServerPlayerEvent *>(event); \
    setProperty(SPEvent->property_name, SPEvent->value); \
    room->broadcastProperty(this, SPEvent->property_name); \
    event_received = true; \
}
    if (event->type() == QEvent::User) {
        if (semas[SEMA_MUTEX]) {
            semas[SEMA_MUTEX]->acquire();
            SET_MY_PROPERTY;
            semas[SEMA_MUTEX]->release();
        }
        else
            SET_MY_PROPERTY;
    }
    return Player::event(event);
}

ServerPlayerEvent::ServerPlayerEvent(char *property_name, QVariant &value)
    : QEvent(QEvent::User), property_name(property_name), value(value)
{

}
#endif

