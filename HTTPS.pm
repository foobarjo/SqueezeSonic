package Plugins::SqueezeSonic::HTTPS;
use base qw(Plugins::SqueezeSonic::ProtocolHandler Slim::Player::Protocols::HTTPS);
sub new {
        my $class  = shift;
        my $args   = shift;

        my $client    = $args->{client};
        my $song      = $args->{song};
        my $streamUrl = $song->streamUrl() || return;

        my $mime = $song->pluginData('mime');

        my $sock = $class->SUPER::new( {
                url     => $streamUrl,
                song    => $song,
                client  => $client,
                bitrate => $song->bitrate(),
        } ) || return;

        ${*$sock}{contentType} = $mime;
        return $sock;
}

sub canDirectStreamSong {
        my ( $class, $client, $song ) = @_;
        return $class->SUPER::canDirectStream( $client, $song->streamUrl());
}
1;
