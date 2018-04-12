package Plugins::SqueezeSonic::ProtocolHandler;

use strict;
use Scalar::Util qw(blessed);

use Slim::Utils::Log;
use Slim::Utils::Misc;
use Slim::Utils::Prefs;

use Plugins::SqueezeSonic::API;

my $log   = logger('plugin.squeezesonic');
my $prefs = preferences('plugin.squeezesonic');

sub scanUrl {
	my ($class, $url, $args) = @_;
	$args->{cb}->( $args->{song}->currentTrack() );
}

sub getFormatForURL {
	my ($class, $url) = @_;
	
	my ($format) = $url =~ m{\.(.+?)$};

	if ($format =~ /^flac$/) {
		$format =~ s/flac/flc/;
	}
	return $format;
}

sub parseDirectHeaders {
	my $class   = shift;
	my $client  = shift || return;
	my $url     = shift;
	my @headers = @_;
	
	if ( blessed($url) ) {
		$url = $url->url;
	}
	my $length;
	my $duration;
	my $type;

       	foreach my $header (@headers) {

                if ($header =~ /^Content-Type:\s*([^;\n]*)/i) {
                        $type = $1;
                }

                elsif ($header =~ /^Content-Length:\s*(.*)/i) {
                        $length = $1;
                }

                elsif ($header =~ /^X-Content-Duration:\s*(.*)/i) {
                        $duration = $1;
                }
	}
	my $bitrate = int($length/$duration*8) if $duration > 0;

	if ($client) {
		$client->currentPlaylistUpdateTime( Time::HiRes::time() );
		Slim::Control::Request::notifyFromArray( $client, [ 'newmetadata' ] );
	}
	return (undef, $bitrate, 0, undef, $type, $length, undef);
}

sub getMetadataFor {
	my ( $class, $client, $url ) = @_;

	my ($id) = $url =~ m{^sonics?://(.+?)$};
	Plugins::SqueezeSonic::API->get(sub {
		my $track = shift;
		my $bitrate;
		
		my ($format) = $url =~ m{\.(.+?)$};

		my ($bitrate) = ($url =~ m{-(.*)\.});
		if ($bitrate eq "raw") {
			$bitrate = $track->{bitRate};
		}
		my $meta = {
                	title    => $track->{title} || $track->{id},
                	album    => $track->{album} || '',
                	albumId  => $track->{albumId} || '',
                	artist   => $track->{artist} || '',
                	artistId => $track->{artistId} || '',
                	cover    => $track->{image} || '',
                	duration => $track->{duration} || 0,
                	year     => $track->{year} || 0,
			type	 => $format || '',
			bitrate  => $bitrate || '',
        	};

		$meta->{bitrate} = sprintf("%.0f" . Slim::Utils::Strings::string('KBPS'), $meta->{bitrate});
		return $meta;
	},'getSong',$id,$prefs->get('tmusic'),"id=" . $id);
}

sub getNextTrack {
	my ($class, $song, $successCb, $errorCb) = @_;
	
	my $url = $song->currentTrack()->url;
	my ($id) = $url =~ m{^sonics?://(.+?)$};
	my ($tid) = $url =~ m{^sonics?://(.*)-};;
	Plugins::SqueezeSonic::API->get(sub {
		my $track = shift;
		my $br;
		my $stream;

		my $auth=Plugins::SqueezeSonic::API->getAuth();

		my ($format) = my ($format) = $url =~ m{\.(.+?)$};
		my ($bitrate) = ($url =~ m{-(.*)\.});

		$tid = $track->{streamId} if $track->{type} eq 'podcast';
		
		if ($bitrate eq "raw") {
			$stream = $prefs->get('suburl') . "/rest/stream?id=" . $tid . "&format=raw&" . $auth;
			$br = $track->{bitRate}*1000;
                } else {
			$stream = $prefs->get('suburl') . "/rest/stream?id=" . $tid . "&format=" . $format . "&estimateContentLength=true&maxBitRate=" . $bitrate . "&" . $auth;			
			$br = $bitrate*1000;
		}
                $song->pluginData($format);
		$song->streamUrl($stream);
		$song->duration($track->{duration});
		$song->bitrate($br);
		$successCb->();
		return;
		$errorCb->('Failed to get next track', 'SqueezeSonic');
	},'getSong',$id,$prefs->get('tmusic'),"id=" . $id);
}

sub audioScrobblerSource {
	return 'P';
}

1;
