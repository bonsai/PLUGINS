package Plagger::Plugin::Notify::Line;
use strict;
use warnings;
use base qw( Plagger::Plugin );

# 必要なモジュールをロード
use LWP::UserAgent;

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

    # access_tokenは必須項目
    die "Notify::Line: 'access_token' is required in your config.yaml"
        unless $conf->{access_token};
}

# 通知処理の本体
sub notify {
    my ($self, $context, $args) = @_;

    # 設定とエントリを取得
    my $conf  = $self->conf;
    my $entry = $args->{entry};

    # LINE Notify APIのエンドポイント
    my $api_url = 'https://notify-api.line.me/api/notify';

    # LINEに送るメッセージを整形
    # 1000文字の制限があるため、タイトルとURLを優先
    # メッセージの先頭に改行を入れると見栄えが良い
    my $message = sprintf(
        "\n【%s】\n%s",
        $entry->title,
        $entry->link,
    );

    # 本文を追加する場合（文字数制限に注意）
    if ($entry->body_text) {
        my $body = $entry->body_text;
        # 500文字程度に切り詰めるなど、制限を考慮
        $body = substr($body, 0, 500) . '...' if length($body) > 500;
        $message .= "\n\n" . $body;
    }

    # LWP::UserAgentでPOSTリクエストを送信
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10); # タイムアウトを10秒に設定

    my $response = $ua->post(
        $api_url,
        # ヘッダーにアクセストークンを設定
        'Authorization' => 'Bearer ' . $conf->{access_token},
        # 送信するメッセージ（フォーム形式）
        'Content' => {
            message => $message,
        },
    );

    # エラーハンドリング
    if ($response->is_success) {
        $context->log(info => "Successfully sent a notification to LINE for: " . $entry->title);
    } else {
        $context->log(error => "Failed to send a notification to LINE: " . $response->status_line);
        $context->log(error => "Response: " . $response->decoded_content);
    }

    return 1;
}

1;
