#ifndef AUTOUPDATEDIALOG_H
#define AUTOUPDATEDIALOG_H

#include <QCryptographicHash>
#include <QDialog>
#include <QNetworkReply>

class QFile;
class QLabel;
class QNetworkAccessManager;
class QProgressBar;
class QPushButton;
class QUrl;

class AutoUpdateDialog : public QDialog
{
    Q_OBJECT

public:
    explicit AutoUpdateDialog(QWidget *parent = 0);

    // manual=false：启动时静默检查；网络失败不打扰玩家。
    // manual=true ：玩家主动点击“检查更新”；应显示检查结果或错误。
    void checkForUpdate(bool manual = false);

    // 更新器写入成功标记后，新版本第一次启动显示说明；随后删除标记。
    static void showPostUpdateNotes(QWidget *parent);

private slots:
    void onManifestFinished();
    void onManifestError(QNetworkReply::NetworkError error);
    void startDownload();
    void onDownloadReadyRead();
    void onDownloadProgress(qint64 received, qint64 total);
    void onDownloadFinished();
    void onDownloadError(QNetworkReply::NetworkError error);

private:
    void requestManifest(const QUrl &url);
    void requestPackage(const QUrl &url);
    bool getRedirectUrl(QNetworkReply *reply, QUrl *redirectUrl) const;
    void resetManifestReply();
    void resetPackageReply(bool removePartialFile);
    void showAvailableUpdate();
    void launchUpdater();
    void showError(const QString &message);
    QString makePackagePath() const;

    QNetworkAccessManager *manager;
    QNetworkReply *manifestReply;
    QNetworkReply *packageReply;
    QFile *packageFile;
    QCryptographicHash packageHash;

    QLabel *titleLabel;
    QLabel *versionLabel;
    QLabel *summaryLabel;
    QProgressBar *progressBar;
    QPushButton *updateButton;
    QPushButton *cancelButton;

    bool manualCheck;
    bool manifestHadError;
    bool packageHadError;
    int manifestRedirectCount;
    int packageRedirectCount;

    int latestVersionCode;
    QString latestVersion;
    QString packageUrl;
    QString backupUrl;
    QString expectedSha256;
    QString updateSummary;
    QString packagePath;
};

#endif // AUTOUPDATEDIALOG_H
