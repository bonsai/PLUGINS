package Plagger::Plugin::Notify::Slack;
use strict;
use warnings;
use base qw( Plagger::Plugin );

# 必要なモジュールをロード
use LWP::UserAgent;
use JSON::PP; # Perl 5.14以降はコアモジュール。なければJSONモジュールでも可

# プラグインのバージョン
our $VERSION = '0.01';

# Plaggerに設定項目を登録する
sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \¬ify,
    );
}

# config.yamlで利用可能な設定を定義する
sub MungeConfig {
    my ($self, $conf) = @_;

    # webhook_urlは必須項目
    die "Notify::Slack: 'webhook_url' is required in your config.yaml"
        unless $conf->{webhook_url};
}


# 通知処理の本体
sub notify {
    my ($self, $context, $args) = @_;

    # 設定を取得
    my $conf = $self->conf;
    my $entry = $args->{entry};

    # Slackに送るメッセージを整形
    # Slackのmrkdwn形式を利用: <URL|テキスト> でリンクを作成
    my $text = sprintf(
        "*<%s|%s>*\n%s",
        $entry->link,
        $entry->title,
        $entry->body_text, # HTMLタグを除いた本文
    );

    # Slackに送信するJSONペイロードを作成
    my $payload = {
        text => $text,
    };

    # config.yamlで指定されていれば、チャンネルや表示名、アイコンも設定
    $payload->{channel}    = $conf->{channel}    if $conf->{channel};
    $payload->{username}   = $conf->{username}   if $conf->{username};
    $payload->{icon_emoji} = $conf->{icon_emoji} if $conf->{icon_emoji};
    $payload->{icon_url}   = $conf->{icon_url}   if $conf->{icon_url};
    
    # LWP::UserAgentでPOSTリクエストを送信
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10); # タイムアウトを10秒に設定

    my $json_payload = JSON::PP->new->utf8->encode($payload);

    my $response = $ua->post(
        $conf->{webhook_url},
        'Content-Type' => 'application/json',
        'Content'      => $json_payload,
    );

    # エラーハンドリング
    if ($response->is_success) {
        $context->log(info => "Successfully sent a notification to Slack for: " . $entry->title);
    } else {
        $context->log(error => "Failed to send a notification to Slack: " . $response->status_line);
        $context->log(error => "Response: " . $response->decoded_content);
    }

    return 1;
}

1;
