## これって何？
bitbucketのissueの更新を確認して更新分をhipchatに投稿するスクリプトです。  
cron等で一定時間ごとに処理させると逐次投稿することができます。

## 使い方
1. `bundle install`で必要なgemをインストール 

2. config.yamlの作成 (bitbucket(.passwd, .userid), hipchat(.api_key, .room)が必要)

3. `ruby hipchat_notify.rb`

