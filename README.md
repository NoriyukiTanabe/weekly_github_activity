# １週間のgithubアクティビティをまとめてメッセージ通知するプログラム

月曜日からコマンド実行時までのgithubアクティビティを取得し、issueおよびpull requestのタイトルを時系列順に出力します

## USAGE

### auto send message to slack

```
$ cp .env.sample .env
$ vi .env
# edit github auth info & add slack api url
$ whenever --update-crontab
```

初期設定では毎週金曜日の12時に通知されます

### manual

```
$ rake report
user: <input username>
password: <input password>
```

標準出力に内容が出力されます

## LIMIT

月曜からコマンド実行時までのアクティビティ数が300件を超えると正しく動作しない可能性があります
