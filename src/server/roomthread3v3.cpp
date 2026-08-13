#include "roomthread3v3.h"
#include "room.h"
#include "engine.h"
#include "ai.h"
#include "lua.hpp"
#include "settings.h"
#include "generalselector.h"
#include "json.h"
#include "util.h"
#include "roomthread.h"

using namespace QSanProtocol;

RoomThread3v3::RoomThread3v3(Room *room)
    :room(room)
{
    room->getRoomState()->reset();
}

QStringList RoomThread3v3::getGeneralsWithoutExtension() const
{
    QList<const General *> generals;

    QStringList list_name = Sanguosha->getLimitedGeneralNames();

    foreach(QString general_name, list_name)
        generals << Sanguosha->getGeneral(general_name);

    // QString rule = Config.value("3v3/OfficialRule", "2016").toString();

    QStringList general_names;
    foreach(const General *general, generals){
        general_names << general->objectName();
    }

    return general_names;
}

void RoomThread3v3::run()
{
    // initialize the random seed for this thread
    qsrand(
        QTime(0, 0, 0).secsTo(
            QTime::currentTime()
        )
    );

    QString scheme =
        Config.value(
            "3v3/RoleChoose",
            "Normal"
        ).toString();

    assignRoles(scheme);
    room->adjustSeats();

    warm_leader = NULL;
    cool_leader = NULL;

    foreach (
        ServerPlayer *player,
        room->m_players
    ) {
        switch (player->getRoleEnum()) {
        case Player::Lord:
            warm_leader = player;
            break;

        case Player::Renegade:
            cool_leader = player;
            break;

        default:
            break;
        }
    }

    /*
     * 每次开始3v3选将前清空成员变量，
     * 防止残留上一次游戏的候选人物。
     */
    general_names.clear();

    const bool using_extension =
        Config.value(
            "3v3/UsingExtension",
            false
        ).toBool();

    const QStringList configured =
        Config.value(
            "3v3/ExtensionGenerals"
        ).toStringList();

    qDebug()
        << "3v3 UsingExtension ="
        << using_extension;

    qDebug()
        << "3v3 ExtensionGenerals ="
        << configured;

    if (using_extension) {
        /*
         * 自定义选将池：
         * 严格读取用户在设置窗口中勾选的人物。
         *
         * 不使用getLimitedGeneralNames()；
         * 不根据BanPackages过滤；
         * 不把非空自定义名单替换成全部人物。
         */
        foreach (
            const QString &name,
            configured
        ) {
            const General *general =
                Sanguosha->getGeneral(name);

            /*
             * 只排除当前游戏中确实不存在的人物，
             * 避免错误内部名导致后续闪退。
             */
            if (general == NULL) {
                qWarning()
                    << "Invalid 3v3 custom general:"
                    << name;

                continue;
            }

            if (!general_names.contains(name))
                general_names << name;
        }

        qDebug()
            << "3v3 loaded custom generals ="
            << general_names;

        /*
         * 只有玩家没有保存任何自定义人物时，
         * 才回退至默认人物池。
         *
         * configured非空但加载失败时不自动回退，
         * 避免错误被“所有人物登场”掩盖。
         */
        if (configured.isEmpty()) {
            qWarning()
                << "3v3 custom pool is not configured;"
                << "use default pool.";

            general_names =
                getGeneralsWithoutExtension();
        }

    } else {
        /*
         * 标准选将池。
         */
        general_names =
            getGeneralsWithoutExtension();

        qDebug()
            << "3v3 uses default general pool.";
    }

    /*
     * configured非空却没有任何人物成功载入，
     * 说明保存的内部名全部无效。
     *
     * 测试阶段不静默载入全部人物，
     * 否则无法观察真实问题。
     */
    if (general_names.isEmpty()) {
        qWarning()
            << "3v3 general pool is empty."
            << "UsingExtension ="
            << using_extension
            << "Configured ="
            << configured;

        /*
         * 为避免空列表直接造成闪退，
         * 此处仍作最终安全回退。
         *
         * 控制台出现上述警告时，
         * 说明自定义名单中的内部名无法被识别。
         */
        general_names =
            getGeneralsWithoutExtension();
    }

    /*
     * 双将3v3每方最终获得8张候选人物牌，
     * 共需要16张。
     */
    qShuffle(general_names);

    general_names =
        general_names.mid(
            0,
            qMin(
                16,
                general_names.length()
            )
        );

    qDebug()
        << "3v3 final candidate generals ="
        << general_names;

    room->doBroadcastNotify(
        S_COMMAND_FILL_GENERAL,
        JsonUtils::toJsonArray(
            general_names
        )
    );

    QString order =
        room->askForOrder(
            warm_leader,
            "warm"
        );

    ServerPlayer *first;
    ServerPlayer *next;

    if (order == "warm") {
        first = warm_leader;
        next = cool_leader;
    } else {
        first = cool_leader;
        next = warm_leader;
    }

    /*
     * 先手阵营选择一张。
     */
    askForTakeGeneral(first);

    /*
     * 此后双方轮流连续选择两张，
     * 直到只剩最后一张。
     */
    while (general_names.length() > 1) {
        qSwap(first, next);

        askForTakeGeneral(first);
        askForTakeGeneral(first);
    }

    /*
     * 最后一张交给另一方。
     */
    if (!general_names.isEmpty())
        askForTakeGeneral(next);

    /*
     * 双方分别从取得的候选人物中，
     * 为三名角色排列主将与副将。
     */
    startArrange(
        QList<ServerPlayer *>()
            << first
            << next
    );
}

void RoomThread3v3::askForTakeGeneral(ServerPlayer *player)
{
    room->tryPause();

    QString name;
    if (general_names.length() == 1 || player->getState() != "online")
        name = GeneralSelector::getInstance()->select3v3(player, general_names);

    if (name.isNull()) {
        bool success = room->doRequest(player, S_COMMAND_ASK_GENERAL, QVariant(), true);
        QVariant clientReply = player->getClientReply();
        if (success && JsonUtils::isString(clientReply)) {
            name = clientReply.toString();
            takeGeneral(player, name);
        } else {
            name = GeneralSelector::getInstance()->select3v3(player, general_names);
            takeGeneral(player, name);
        }
    } else {
        msleep(Config.AIDelay);
        takeGeneral(player, name);
    }
}

void RoomThread3v3::takeGeneral(ServerPlayer *player, const QString &name)
{
    general_names.removeOne(name);
    player->addToSelected(name);

    QString group = player->isLord() ? "warm" : "cool";

    LogMessage log;
    log.type = "#VsTakeGeneral";
    log.arg = group;
    log.arg2 = name;
    room->sendLog(log);

    QString rule = Config.value("3v3/OfficialRule", "2016").toString();
    room->doBroadcastNotify(S_COMMAND_TAKE_GENERAL, JsonUtils::toJsonArray(QStringList() << group << name << rule));
}

void RoomThread3v3::startArrange(QList<ServerPlayer *> &players)
{
    room->tryPause();
    QList<ServerPlayer *> online = players;
    foreach (ServerPlayer *player, players) {
        if (!player->isOnline()) {
            GeneralSelector *selector = GeneralSelector::getInstance();
            arrange(player, selector->arrange3v3(player));
            online.removeOne(player);
        }
    }
    if (online.isEmpty()) return;

    foreach(ServerPlayer *player, online)
        player->m_commandArgs = QVariant();

    room->doBroadcastRequest(online, S_COMMAND_ARRANGE_GENERAL);

    foreach (ServerPlayer *player, online) {
        JsonArray clientReply = player->getClientReply().value<JsonArray>();
        if (player->m_isClientResponseReady && clientReply.size() == 6) {
            QStringList arranged;
            JsonUtils::tryParse(clientReply, arranged);
            arrange(player, arranged);
        } else {
            GeneralSelector *selector = GeneralSelector::getInstance();
            arrange(player, selector->arrange3v3(player));
        }
    }
}

void RoomThread3v3::arrange(ServerPlayer *player, const QStringList &arranged)
{
    Q_ASSERT(arranged.length() == 6);

    if (player->isLord()) {
        // 暖色方左先锋
        ServerPlayer *left = room->m_players.at(5);
        left->setGeneralName(arranged.at(0));
        left->setGeneral2Name(arranged.at(1));
        room->setTag(left->objectName(),
                     QStringList() << arranged.at(0) << arranged.at(1));

        // 暖色方主帅
        ServerPlayer *lord = room->m_players.at(0);
        lord->setGeneralName(arranged.at(2));
        lord->setGeneral2Name(arranged.at(3));
        room->setTag(lord->objectName(),
                     QStringList() << arranged.at(2) << arranged.at(3));

        // 暖色方右先锋
        ServerPlayer *right = room->m_players.at(1);
        right->setGeneralName(arranged.at(4));
        right->setGeneral2Name(arranged.at(5));
        room->setTag(right->objectName(),
                     QStringList() << arranged.at(4) << arranged.at(5));
    } else {
        // 冷色方左先锋
        ServerPlayer *left = room->m_players.at(2);
        left->setGeneralName(arranged.at(0));
        left->setGeneral2Name(arranged.at(1));
        room->setTag(left->objectName(),
                     QStringList() << arranged.at(0) << arranged.at(1));

        // 冷色方主帅
        ServerPlayer *lord = room->m_players.at(3);
        lord->setGeneralName(arranged.at(2));
        lord->setGeneral2Name(arranged.at(3));
        room->setTag(lord->objectName(),
                     QStringList() << arranged.at(2) << arranged.at(3));

        // 冷色方右先锋
        ServerPlayer *right = room->m_players.at(4);
        right->setGeneralName(arranged.at(4));
        right->setGeneral2Name(arranged.at(5));
        room->setTag(right->objectName(),
                     QStringList() << arranged.at(4) << arranged.at(5));
    }
}

void RoomThread3v3::assignRoles(const QStringList &roles, const QString &scheme)
{
    QStringList all_roles = roles;
    QStringList roleChoices = all_roles;
    roleChoices.removeDuplicates();
    QList<ServerPlayer *> new_players, abstained;
    for (int i = 0; i < 6; i++)
        new_players << NULL;

    foreach (ServerPlayer *player, room->m_players) {
        if (player->isOnline()) {
            QString role = room->askForRole(player, roleChoices, scheme);
            if (role != "abstain") {
                player->setRole(role);
                all_roles.removeOne(role);
                if (!all_roles.contains(role))
                    roleChoices.removeOne(role);

                for (int i = 0; i < 6; i++) {
                    if (roles.at(i) == role && new_players.at(i) == NULL) {
                        new_players[i] = player;
                        break;
                    }
                }

                continue;
            }
        }

        abstained << player;
    }

    if (!abstained.isEmpty()) {
        qShuffle(abstained);

        for (int i = 0; i < 6; i++) {
            if (new_players.at(i) == NULL) {
                new_players[i] = abstained.takeFirst();
                new_players.at(i)->setRole(roles.at(i));
            }
        }
    }

    room->m_players = new_players;
}

// there are 3 scheme
// Normal: choose team1 or team2
// Random: assign role randomly
// AllRoles: select roles directly
void RoomThread3v3::assignRoles(const QString &scheme)
{
    QStringList roles;
    roles << "lord" << "loyalist" << "rebel"
        << "renegade" << "rebel" << "loyalist";

    if (scheme == "Random") {
        // the easiest way
        qShuffle(room->m_players);

        for (int i = 0; i < roles.length(); i++)
            room->setPlayerProperty(room->m_players.at(i), "role", roles.at(i));
    } else if (scheme == "AllRoles") {
        assignRoles(roles, scheme);
    } else {
        QStringList all_roles;
        all_roles << "leader1" << "guard1" << "guard2"
            << "leader2" << "guard2" << "guard1";
        assignRoles(all_roles, scheme);

        QMap<QString, QString> map;
        if (qrand() % 2 == 0) {
            map["leader1"] = "lord";
            map["guard1"] = "loyalist";
            map["leader2"] = "renegade";
            map["guard2"] = "rebel";
        } else {
            map["leader1"] = "renegade";
            map["guard1"] = "rebel";
            map["leader2"] = "lord";
            map["guard2"] = "loyalist";

            room->m_players.swap(0, 3);
            room->m_players.swap(1, 4);
            room->m_players.swap(2, 5);
        }

        foreach(ServerPlayer *player, room->m_players)
            player->setRole(map[player->getRole()]);
    }

    foreach(ServerPlayer *player, room->m_players)
        room->broadcastProperty(player, "role");
}

