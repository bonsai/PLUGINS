package Plagger::Plugin::Notify::LineMessagingAPI;
use strict;
use warnings;
use base qw( Plagger::Plugin );

# 必要なモジュールをロード
use LWP::UserAgent;
use JSON::PP; # またはJSON

# プラグインのバージョン
our $VERSION = '0.01';

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'publish.entry' => \¬ify,
    );
}

sub MungeConfig {
    my ($self, $conf) = @_;

    # 必須項目のチェック
    die "Notify::LineMessagingAPI: 'channel_access_token' is required in your config.yaml"
        unless $conf->{channel_access_token};
    die "Notify::LineMessagingAPI: 'to' (user_id or group_id) is required in your config.yaml"
        unless $conf->{to};
}

sub notify {
    my ($self, $context, $args) = @_;

    my $conf  = $self->conf;
    my $entry = $args->{entry};

    # Messaging APIのPushメッセージ用エンドポイント
    my $api_url = 'https://api.line.me/v2/bot/message/push';

    # 送信するメッセージを整形
    # 5000文字まで送信可能だが、見やすさを考慮して簡潔に
    my $text = sprintf(
        "【%s】\n%s",
        $entry->title,
        $entry->link
    );

    # 送信するJSONペイロードを作成
    # https://developers.line.biz/ja/reference/messaging-api/#send-push-message
    my $payload = {
        to => $conf->{to},
        messages => [
            {
                type => 'text',
                text => $text,
            }
        ],
    };

    my $json_payload = JSON::PP->new->utf8->encode($payload);

    my $ua = LWP::UserAgent->new;
    $ua->timeout(15);

    my $response = $ua->post(
        $api_url,
        'Content-Type'  => 'application/json',
        'Authorization' => 'Bearer ' . $conf->{channel_access_token},
        'Content'       => $json_payload,
    );

    # エラーハンドリング
    if ($response->is_success) {
        $context->log(info => "Successfully sent a notification via LINE Messaging API for: " . $entry->title);
    } else {
        $context->log(error => "Failed to send a notification via LINE Messaging API: " . $response->status_line);
        $context->log(error => "Response: " . $response->decoded_content);
    }

    return 1;
}

1;
