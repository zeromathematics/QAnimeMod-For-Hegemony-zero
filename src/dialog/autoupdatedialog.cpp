#include "autoupdatedialog.h"

#include "settings.h"
#include "updateconfig.h"

#include <QApplication>
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QHBoxLayout>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QMessageBox>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QProcess>
#include <QProgressBar>
#include <QPushButton>
#include <QStandardPaths>
#include <QUrl>
#include <QVBoxLayout>

namespace {

QString htmlEscaped(const QString &text)
{
    return text.toHtmlEscaped();
}

QStringList jsonStringList(const QJsonValue &value)
{
    QStringList result;
    const QJsonArray array = value.toArray();
    for (int i = 0; i < array.size(); ++i) {
        if (array.at(i).isString())
            result << array.at(i).toString();
    }
    return result;
}

} // namespace

AutoUpdateDialog::AutoUpdateDialog(QWidget *parent)
    : QDialog(parent)
    , manager(new QNetworkAccessManager(this))
    , manifestReply(0)
    , packageReply(0)
    , packageFile(0)
    , packageHash(QCryptographicHash::Sha256)
    , titleLabel(new QLabel(this))
    , versionLabel(new QLabel(this))
    , summaryLabel(new QLabel(this))
    , progressBar(new QProgressBar(this))
    , updateButton(new QPushButton(tr("立即更新"), this))
    , cancelButton(new QPushButton(tr("暂不更新"), this))
    , manualCheck(false)
    , manifestHadError(false)
    , packageHadError(false)
    , manifestRedirectCount(0)
    , packageRedirectCount(0)
    , latestVersionCode(0)
{
    setWindowTitle(tr("动漫杀更新"));
    setMinimumWidth(460);
    setModal(false);

    titleLabel->setTextFormat(Qt::RichText);
    versionLabel->setTextFormat(Qt::RichText);
    summaryLabel->setWordWrap(true);
    summaryLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);

    progressBar->setRange(0, 100);
    progressBar->setVisible(false);

    QHBoxLayout *buttonLayout = new QHBoxLayout;
    buttonLayout->addStretch();
    buttonLayout->addWidget(updateButton);
    buttonLayout->addWidget(cancelButton);

    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->addWidget(titleLabel);
    mainLayout->addWidget(versionLabel);
    mainLayout->addWidget(summaryLabel);
    mainLayout->addWidget(progressBar);
    mainLayout->addLayout(buttonLayout);

    connect(updateButton, &QPushButton::clicked,
            this, &AutoUpdateDialog::startDownload);
    connect(cancelButton, &QPushButton::clicked,
            this, &AutoUpdateDialog::reject);
}

void AutoUpdateDialog::checkForUpdate(bool manual)
{
    // 防止启动检查和手动检查并发。
    if (manifestReply != 0 || packageReply != 0)
        return;

    manualCheck = manual;
    manifestHadError = false;
    manifestRedirectCount = 0;

    requestManifest(QUrl(QString::fromLatin1(QANIME_UPDATE_MANIFEST_URL)));
}

void AutoUpdateDialog::requestManifest(const QUrl &url)
{
    QNetworkRequest request(url);

#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
#endif
    request.setRawHeader("User-Agent", "QAnimeMod-Updater");
    request.setRawHeader("Cache-Control", "no-cache");

    manifestReply = manager->get(request);
    connect(manifestReply, &QNetworkReply::finished,
            this, &AutoUpdateDialog::onManifestFinished);
    connect(manifestReply,
            SIGNAL(error(QNetworkReply::NetworkError)),
            this,
            SLOT(onManifestError(QNetworkReply::NetworkError)));
}

void AutoUpdateDialog::onManifestError(QNetworkReply::NetworkError)
{
    manifestHadError = true;
}

void AutoUpdateDialog::onManifestFinished()
{
    QNetworkReply *reply = manifestReply;
    manifestReply = 0;
    if (reply == 0)
        return;

    QUrl redirectUrl;
    if (getRedirectUrl(reply, &redirectUrl)) {
        reply->deleteLater();
        if (++manifestRedirectCount > 5) {
            if (manualCheck)
                showError(tr("更新清单重定向次数过多。"));
            return;
        }
        manifestHadError = false;
        requestManifest(redirectUrl);
        return;
    }

    const QByteArray data = reply->readAll();
    const QString networkMessage = reply->errorString();
    reply->deleteLater();

    if (manifestHadError) {
        if (manualCheck)
            showError(tr("无法连接更新服务器：%1").arg(networkMessage));
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(data, &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        if (manualCheck)
            showError(tr("服务器返回的更新信息不是有效的 JSON。"));
        return;
    }

    const QJsonObject object = document.object();
    latestVersion = object.value("version").toString().trimmed();
    latestVersionCode = object.value("version_code").toInt(-1);
    packageUrl = object.value("package_url").toString().trimmed();
    backupUrl = object.value("backup_url").toString().trimmed();
    expectedSha256 = object.value("sha256").toString().trimmed().toLower();

    const QStringList summaryItems = jsonStringList(object.value("summary"));
    QStringList displayItems;
    for (int i = 0; i < summaryItems.size(); ++i)
        displayItems << QString::fromUtf8("• ") + summaryItems.at(i);
    updateSummary = displayItems.join("\n");

    const bool manifestValid = latestVersionCode >= 0
        && !latestVersion.isEmpty()
        && !packageUrl.isEmpty()
        && expectedSha256.size() == 64;
    if (!manifestValid) {
        if (manualCheck)
            showError(tr("更新清单缺少 version、version_code、package_url 或有效的 SHA-256。"));
        return;
    }

    if (latestVersionCode <= QANIME_UPDATE_VERSION_CODE) {
        if (manualCheck) {
            QMessageBox::information(this, tr("检查更新"),
                tr("当前已是最新版本（%1）。").arg(QString::fromLatin1(QANIME_UPDATE_VERSION)));
        }
        return;
    }

    showAvailableUpdate();
}

void AutoUpdateDialog::showAvailableUpdate()
{
    titleLabel->setText(tr("<h2>发现新版本</h2>"));
    versionLabel->setText(tr("当前版本：%1<br/>最新版本：%2")
        .arg(htmlEscaped(QString::fromLatin1(QANIME_UPDATE_VERSION)))
        .arg(htmlEscaped(latestVersion)));
    summaryLabel->setText(updateSummary.isEmpty()
        ? tr("该版本未提供简要更新说明。") : updateSummary);

    progressBar->setVisible(false);
    updateButton->setEnabled(true);
    cancelButton->setEnabled(true);
    show();
    raise();
    activateWindow();
}

QString AutoUpdateDialog::makePackagePath() const
{
    const QString root = QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        + "/QAnimeModUpdate";
    QDir().mkpath(root);
    return root + "/QAnimeMod_Update_" + latestVersion + ".zip";
}

void AutoUpdateDialog::startDownload()
{
    if (packageReply != 0)
        return;

    packagePath = makePackagePath();
    packageFile = new QFile(packagePath, this);
    if (!packageFile->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        showError(tr("无法在临时目录创建更新包：%1").arg(packagePath));
        packageFile->deleteLater();
        packageFile = 0;
        return;
    }

    packageHash.reset();
    packageHadError = false;
    packageRedirectCount = 0;
    progressBar->setVisible(true);
    progressBar->setRange(0, 100);
    progressBar->setValue(0);
    updateButton->setEnabled(false);
    cancelButton->setEnabled(false);

    requestPackage(QUrl(packageUrl));
}

void AutoUpdateDialog::requestPackage(const QUrl &url)
{
    QNetworkRequest request(url);
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
    request.setAttribute(QNetworkRequest::FollowRedirectsAttribute, true);
#endif
    request.setRawHeader("User-Agent", "QAnimeMod-Updater");
    packageReply = manager->get(request);

    connect(packageReply, &QNetworkReply::readyRead,
            this, &AutoUpdateDialog::onDownloadReadyRead);
    connect(packageReply, &QNetworkReply::downloadProgress,
            this, &AutoUpdateDialog::onDownloadProgress);
    connect(packageReply, &QNetworkReply::finished,
            this, &AutoUpdateDialog::onDownloadFinished);
    connect(packageReply,
            SIGNAL(error(QNetworkReply::NetworkError)),
            this,
            SLOT(onDownloadError(QNetworkReply::NetworkError)));
}

void AutoUpdateDialog::onDownloadReadyRead()
{
    if (packageReply == 0 || packageFile == 0)
        return;

    // Qt 5.5 需要在 finished() 中手动跟随重定向；不要把跳转响应正文写进 ZIP。
    QUrl ignoredRedirect;
    if (getRedirectUrl(packageReply, &ignoredRedirect))
        return;

    const QByteArray chunk = packageReply->readAll();
    if (chunk.isEmpty())
        return;

    if (packageFile->write(chunk) != chunk.size()) {
        packageHadError = true;
        packageReply->abort();
        return;
    }
    packageHash.addData(chunk);
}

void AutoUpdateDialog::onDownloadProgress(qint64 received, qint64 total)
{
    if (total <= 0) {
        progressBar->setRange(0, 0);
        return;
    }
    progressBar->setRange(0, 100);
    progressBar->setValue(static_cast<int>(received * 100 / total));
}

void AutoUpdateDialog::onDownloadError(QNetworkReply::NetworkError)
{
    packageHadError = true;
}

void AutoUpdateDialog::onDownloadFinished()
{
    QNetworkReply *reply = packageReply;
    if (reply == 0)
        return;

    QUrl redirectUrl;
    if (getRedirectUrl(reply, &redirectUrl)) {
        packageReply = 0;
        reply->deleteLater();

        if (++packageRedirectCount > 5) {
            resetPackageReply(true);
            showError(tr("更新包重定向次数过多。"));
            return;
        }

        if (packageFile) {
            packageFile->resize(0);
            packageFile->seek(0);
        }
        packageHash.reset();
        packageHadError = false;
        requestPackage(redirectUrl);
        return;
    }

    // readyRead 通常已经读取完；这里再收取可能残留的最后一段数据。
    onDownloadReadyRead();

    packageReply = 0;
    const QString errorMessage = reply ? reply->errorString() : QString();
    if (reply)
        reply->deleteLater();

    if (packageFile) {
        packageFile->flush();
        packageFile->close();
    }

    if (packageHadError) {
        resetPackageReply(true);
        showError(tr("更新包下载失败：%1").arg(errorMessage));
        return;
    }

    const QString actualHash = QString::fromLatin1(packageHash.result().toHex()).toLower();
    if (actualHash != expectedSha256) {
        resetPackageReply(true);
        showError(tr("更新包 SHA-256 校验失败。\n预期：%1\n实际：%2")
            .arg(expectedSha256).arg(actualHash));
        return;
    }

    if (packageFile) {
        packageFile->deleteLater();
        packageFile = 0;
    }
    launchUpdater();
}

bool AutoUpdateDialog::getRedirectUrl(QNetworkReply *reply, QUrl *redirectUrl) const
{
    if (reply == 0 || redirectUrl == 0)
        return false;

    const QVariant target = reply->attribute(QNetworkRequest::RedirectionTargetAttribute);
    if (!target.isValid())
        return false;

    const QUrl relativeUrl = target.toUrl();
    if (relativeUrl.isEmpty())
        return false;

    *redirectUrl = reply->url().resolved(relativeUrl);
    return redirectUrl->isValid()
        && (redirectUrl->scheme() == "http" || redirectUrl->scheme() == "https");
}

void AutoUpdateDialog::resetManifestReply()
{
    if (manifestReply) {
        manifestReply->abort();
        manifestReply->deleteLater();
        manifestReply = 0;
    }
}

void AutoUpdateDialog::resetPackageReply(bool removePartialFile)
{
    if (packageReply) {
        packageReply->abort();
        packageReply->deleteLater();
        packageReply = 0;
    }
    if (packageFile) {
        packageFile->close();
        packageFile->deleteLater();
        packageFile = 0;
    }
    if (removePartialFile && !packagePath.isEmpty())
        QFile::remove(packagePath);

    updateButton->setEnabled(true);
    cancelButton->setEnabled(true);
    progressBar->setVisible(false);
}

void AutoUpdateDialog::launchUpdater()
{
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString updaterPath = appDir + "/" + QString::fromLatin1(QANIME_UPDATER_FILE_NAME);
    if (!QFile::exists(updaterPath)) {
        showError(tr("找不到独立更新程序：%1").arg(updaterPath));
        return;
    }

    QStringList arguments;
    arguments << "--pid" << QString::number(QCoreApplication::applicationPid())
              << "--package" << packagePath
              << "--target" << appDir
              << "--restart" << QCoreApplication::applicationFilePath()
              << "--version" << latestVersion;

    if (!QProcess::startDetached(updaterPath, arguments, appDir)) {
        showError(tr("无法启动独立更新程序。"));
        return;
    }

    QCoreApplication::quit();
}

void AutoUpdateDialog::showError(const QString &message)
{
    QMessageBox::warning(this, tr("更新失败"), message);
}

void AutoUpdateDialog::showPostUpdateNotes(QWidget *parent)
{
    const QString appDir = QCoreApplication::applicationDirPath();
    const QString markerPath = appDir + "/update/update_completed.json";
    const QString notesPath = appDir + "/update_notes.json";
    if (!QFile::exists(markerPath))
        return;

    QFile markerFile(markerPath);
    if (!markerFile.open(QIODevice::ReadOnly))
        return;
    const QJsonDocument markerDoc = QJsonDocument::fromJson(markerFile.readAll());
    markerFile.close();
    if (!markerDoc.isObject())
        return;

    const QString version = markerDoc.object().value("version").toString();
    if (version.isEmpty())
        return;

    const QString lastShown = Config.value("Update/LastShownNotesVersion").toString();
    if (lastShown == version) {
        QFile::remove(markerPath);
        return;
    }

    QString title = QObject::tr("更新完成");
    QStringList content;
    QFile notesFile(notesPath);
    if (notesFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument notesDoc = QJsonDocument::fromJson(notesFile.readAll());
        notesFile.close();
        if (notesDoc.isObject()) {
            const QJsonObject notes = notesDoc.object();
            // 仅展示与更新器记录版本一致的说明，防止残留旧文件误显示。
            if (notes.value("version").toString() == version) {
                title = notes.value("title").toString(title);
                content = jsonStringList(notes.value("content"));
            }
        }
    }

    QStringList lines;
    for (int i = 0; i < content.size(); ++i)
        lines << QString::fromUtf8("• ") + content.at(i);
    if (lines.isEmpty())
        lines << QObject::tr("本次更新已安装完成。");

    QMessageBox box(parent);
    box.setIcon(QMessageBox::Information);
    box.setWindowTitle(title);
    box.setText(QObject::tr("动漫杀已更新至 %1").arg(version));
    box.setInformativeText(lines.join("\n"));
    box.exec();

    Config.setValue("Update/LastShownNotesVersion", version);
    Config.sync();
    QFile::remove(markerPath);
}
