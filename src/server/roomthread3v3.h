#ifndef _ROOM_THREAD_3V3_H
#define _ROOM_THREAD_3V3_H

class Room;
class ServerPlayer;

#include "structs.h"

#include <QThread>
#include <QVariant>

class RoomThread3v3 : public QThread
{
    Q_OBJECT

public:
    explicit RoomThread3v3(Room *room);
    void takeGeneral(ServerPlayer *player, const QString &name);
    void arrange(ServerPlayer *player, const QStringList &arranged);
    void assignRoles(const QString &scheme);

protected:
    virtual void run();

private:
    Room *room;
    ServerPlayer *warm_leader, *cool_leader;
    QStringList general_names;
    QString result;

    QStringList getGeneralsWithoutExtension() const;
    void askForTakeGeneral(ServerPlayer *player);
    void startArrange(QList<ServerPlayer *> &players);
    void assignRoles(const QStringList &roles, const QString &scheme);
};

#endif
