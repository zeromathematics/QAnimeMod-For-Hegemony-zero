#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QSaveFile>
#include <QTemporaryDir>
#include <QTextStream>
#include <QThread>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

namespace {

struct Arguments
{
    qint64 pid;
    QString packagePath;
    QString targetPath;
    QString restartPath;
    QString version;
};

void logLine(const QString &line)
{
    QFile file(QCoreApplication::applicationDirPath() + "/update.log");
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text))
        return;
    QTextStream out(&file);
    out.setCodec("UTF-8");
    out << line << "\n";
}

bool parseArguments(const QStringList &args, Arguments *result)
{
    if (!result)
        return false;
    result->pid = 0;

    for (int i = 1; i + 1 < args.size(); i += 2) {
        const QString key = args.at(i);
        const QString value = args.at(i + 1);
        if (key == "--pid")
            result->pid = value.toLongLong();
        else if (key == "--package")
            result->packagePath = value;
        else if (key == "--target")
            result->targetPath = value;
        else if (key == "--restart")
            result->restartPath = value;
        else if (key == "--version")
            result->version = value;
        else
            return false;
    }

    return result->pid > 0
        && QFileInfo(result->packagePath).isFile()
        && QDir(result->targetPath).exists()
        && QFileInfo(result->restartPath).isFile()
        && !result->version.isEmpty();
}

bool waitForProcess(qint64 pid, unsigned long timeoutMs)
{
#ifdef Q_OS_WIN
    HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, static_cast<DWORD>(pid));
    if (process == NULL)
        return true; // 主程序可能已先一步退出。
    const DWORD result = WaitForSingleObject(process, timeoutMs);
    CloseHandle(process);
    return result == WAIT_OBJECT_0;
#else
    Q_UNUSED(pid);
    QThread::msleep(timeoutMs);
    return true;
#endif
}

bool copyFileAtomically(const QString &source, const QString &target)
{
    const QString temporary = target + ".update-new";
    QFile::remove(temporary);
    if (!QFile::copy(source, temporary))
        return false;

    const QFile::Permissions permissions = QFile::permissions(source);
    QFile::setPermissions(temporary, permissions);

    const QString backup = target + ".update-old";
    QFile::remove(backup);
    if (QFile::exists(target) && !QFile::rename(target, backup)) {
        QFile::remove(temporary);
        return false;
    }
    if (!QFile::rename(temporary, target)) {
        if (QFile::exists(backup))
            QFile::rename(backup, target);
        QFile::remove(temporary);
        return false;
    }
    QFile::remove(backup);
    return true;
}

bool copyTree(const QString &sourceRoot, const QString &targetRoot)
{
    QDir source(sourceRoot);
    if (!source.exists())
        return false;
    if (!QDir().mkpath(targetRoot))
        return false;

    const QFileInfoList entries = source.entryInfoList(
        QDir::NoDotAndDotDot | QDir::AllEntries,
        QDir::DirsFirst | QDir::Name);

    for (int i = 0; i < entries.size(); ++i) {
        const QFileInfo entry = entries.at(i);
        const QString destination = QDir(targetRoot).filePath(entry.fileName());
        if (entry.isDir()) {
            if (!copyTree(entry.absoluteFilePath(), destination))
                return false;
        } else if (entry.isFile()) {
            // 更新器正在运行，Windows 下不能覆盖自身；更新包不得包含它。
            if (entry.fileName().compare("QAnimeUpdater.exe", Qt::CaseInsensitive) == 0)
                continue;
            if (!copyFileAtomically(entry.absoluteFilePath(), destination))
                return false;
        }
    }
    return true;
}

bool extractPackage(const Arguments &args, const QString &stagingPath)
{
    const QString sevenZip = QDir(args.targetPath).filePath("7za.exe");
    if (!QFileInfo(sevenZip).isFile()) {
        logLine("7za.exe not found: " + sevenZip);
        return false;
    }

    QProcess process;
    QStringList commandArgs;
    commandArgs << "x" << args.packagePath << ("-o" + stagingPath) << "-y";
    process.start(sevenZip, commandArgs);
    if (!process.waitForStarted(10000))
        return false;
    if (!process.waitForFinished(10 * 60 * 1000)) {
        process.kill();
        process.waitForFinished();
        return false;
    }

    if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
        logLine(QString::fromLocal8Bit(process.readAllStandardError()));
        return false;
    }
    return true;
}

bool writeCompletionMarker(const Arguments &args)
{
    const QString updateDir = QDir(args.targetPath).filePath("update");
    if (!QDir().mkpath(updateDir))
        return false;

    QJsonObject object;
    object.insert("version", args.version);
    object.insert("show_notes", true);

    QSaveFile file(QDir(updateDir).filePath("update_completed.json"));
    if (!file.open(QIODevice::WriteOnly))
        return false;
    file.write(QJsonDocument(object).toJson(QJsonDocument::Indented));
    return file.commit();
}

} // namespace

int main(int argc, char *argv[])
{
    QCoreApplication application(argc, argv);
    QCoreApplication::setApplicationName("QAnimeUpdater");

    Arguments args;
    if (!parseArguments(application.arguments(), &args)) {
        logLine("Invalid updater arguments.");
        return 2;
    }

    if (!waitForProcess(args.pid, 60000)) {
        logLine("Timed out waiting for the game process.");
        return 3;
    }

    QTemporaryDir staging;
    if (!staging.isValid()) {
        logLine("Cannot create staging directory.");
        return 4;
    }

    if (!extractPackage(args, staging.path())) {
        logLine("Cannot extract update package.");
        return 5;
    }

    if (!copyTree(staging.path(), args.targetPath)) {
        logLine("Cannot copy update files to target directory.");
        return 6;
    }

    if (!writeCompletionMarker(args)) {
        logLine("Update installed, but completion marker could not be written.");
        return 7;
    }

    QFile::remove(args.packagePath);

    if (!QProcess::startDetached(args.restartPath, QStringList(), args.targetPath)) {
        logLine("Update installed, but the game could not be restarted.");
        return 8;
    }

    return 0;
}
