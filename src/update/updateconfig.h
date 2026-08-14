#ifndef QANIME_UPDATECONFIG_H
#define QANIME_UPDATECONFIG_H

// 每次正式发布时递增。程序以整数比较版本，避免 2.10 与 2.9 的字符串比较错误。
#define QANIME_UPDATE_VERSION "3.0.1"
#define QANIME_UPDATE_VERSION_CODE 301

// 建议指向 GitHub Pages 上稳定、可缓存的 JSON 文件。
#define QANIME_UPDATE_MANIFEST_URL \
    "https://zeromathematics.github.io/QAnimeMod-For-Hegemony-zero/update/latest.json"

#define QANIME_UPDATER_FILE_NAME "QAnimeUpdater.exe"

#endif // QANIME_UPDATECONFIG_H
