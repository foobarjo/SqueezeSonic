package Plugins::SqueezeSonic::API;

use strict;

use JSON::XS::VersionOneAndTwo;
use Digest::MD5 qw(md5_hex);

use Slim::Utils::Cache;
use Slim::Utils::Log;
use Slim::Utils::Prefs;

my $cache = Slim::Utils::Cache->new('squeezesonic', 6);
my $prefs = preferences('plugin.squeezesonic');
my $log = logger('plugin.squeezesonic');

sub getAuth {
	my $user = $prefs->get('username');
	my $pass = $prefs->get('password');
	my @chars = ('A'..'Z', 'a'..'z', 0..9);
	my $salt = join '', map $chars[rand @chars], 0..8;
        my $token = md5_hex($pass . $salt);
	my $auth = "u=$user&t=$token&s=$salt&v=1.11.0&f=json&c=SqueezeSonic";
	return $auth;
}

sub submitQuery {
	my ($class, $cb,$query) = @_;

	if (!$query){
		$query = $cb;
		$cb = $class;
	}
	my $auth =  getAuth();
        my $server = $prefs->get('suburl');

	my $url = $server . "/rest/" . $query . "&$auth";
	Slim::Networking::SimpleAsyncHTTP->new(
		sub {
			my $response = shift;
			my $result = eval { from_json($response->content) };
			
			$result ||= {};

			$cb->($result);
		},

		sub {
			$cb->( { error => $_[1] } );
		}

	)->get($url);
}

sub cacheGet {
	my ($item) = @_ ;
		
	return $cache->get($item);

}

sub cacheSet {
	my ($class,$name,$object,$time) = @_ ;
	if ( !$time && ref $name eq 'HASH' ) {
		$time = $object;
                $object = $name;
		$name = $class;
        }
	$cache->set($name,$object,$time);
}
sub cacheRemove {
	my ($class, $id) = @_;
	$cache->remove($id);
}

sub cacheClear {
	my ($class, $id) = @_;
	$cache->clear();
}

sub get {
        my ($class, $cb, $command, $id, $timeout, $params) = @_;

        my $cached = cacheGet($command . $id) || "nc";
        if ($cached eq "nc") {
                my $query = $command . "?" . $params;
                submitQuery(sub {
                        my $result = shift;
                        cacheSet($command . $id,$result, $timeout);
                        $cb->($result);

                }, $query);
        }
        else {
                $cb->($cached);
        }
}

1;

