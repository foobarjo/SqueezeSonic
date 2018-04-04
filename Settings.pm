package Plugins::SqueezeSonic::Settings;

use strict;
use base qw(Slim::Web::Settings);
use Slim::Utils::Prefs;
use Slim::Utils::Log;
use Digest::MD5 qw(md5_hex);
use Plugins::SqueezeSonic::API;


my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.squeezesonic',
	'defaultLevel' => 'INFO',
	'description'  => 'SqueezeSonic Settings',
});

my $prefs = preferences('plugin.squeezesonic');

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_SQUEEZESONIC');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/SqueezeSonic/settings/basic.html');
}

sub prefs {
	return $prefs;
}

sub handler {
	my ($class, $client, $params) = @_;
	
	if ($params->{'saveSettings'} && $params->{'username'} && $params->{'suburl'}) {
		if ($params->{'username'}) {
			$prefs->set('username', $params->{'username'});
		}
	
		if ($params->{'password'} && ($params->{'password'} ne "**********")) {
			$prefs->set('password', $params->{'password'});
		}
		
		if ($params->{'suburl'}) {
			if ($params->{'suburl'} =~ m/^https?/) {
				$prefs->set('suburl', $params->{'suburl'});
			} else {
				$prefs->set('suburl', "http://" . $params->{'suburl'});
			}			
		}
		if ($params->{'slists'}) {
			$prefs->set('slists', $params->{'slists'});
		}
		if ($params->{'tlists'}) {
			$prefs->set('tlists', $params->{'tlists'});
		}
		if ($params->{'tmusic'}) {
			$prefs->set('tmusic', $params->{'tmusic'});
		}
		if ($params->{'transcode'}) {
			$prefs->set('transcode', $params->{'transcode'});
		}
		if ($params->{'asize'}) {
			$prefs->set('asize', $params->{'asize'});
		}
	}	

	$params->{'prefs'}->{'username'} = $prefs->get('username');
	$params->{'prefs'}->{'password'} = "**********";
	$params->{'prefs'}->{'suburl'} = $prefs->get('suburl');
	$params->{'prefs'}->{'slists'} = $prefs->get('slists') || '200';
	$params->{'prefs'}->{'tlists'} = $prefs->get('tlists') || '600';
	$params->{'prefs'}->{'tmusic'} = $prefs->get('tmusic') || '3600';
	$params->{'prefs'}->{'transcode'} = $prefs->get('transcode') || 'raw';
	$params->{'prefs'}->{'asize'} = $prefs->get('asize') || '800';

	return $class->SUPER::handler($client, $params);
}

1;

__END__
