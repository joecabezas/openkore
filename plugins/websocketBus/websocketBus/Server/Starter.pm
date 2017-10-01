package websocketBus::Server::Starter;

use strict;
use Time::HiRes qw(time);
use File::Spec;
use Cwd qw(realpath);

use Utils::PerlLauncher;
use Utils::Daemon;

use Data::Dumper;

use constant NOT_STARTED => 1;
use constant STARTING => 2;
use constant STARTED  => 3;
use constant FAILED   => 4;

our $busServerScript;

BEGIN {
	# my ($drive, $dirs) = File::Spec->splitpath(realpath(__FILE__));
	# $dirs = "$drive$dirs";
	$busServerScript = realpath(File::Spec->catfile($Plugins::current_plugin_folder, "websocketBus-server.pl"));
}

sub new {
	my $class = shift;
	my $options = shift;

	Log::message ">>>websocketBus::Server::Starter new START"."\n";
	Log::message "class\n";
	Log::message Dumper($class);
	Log::message "options\n";
	Log::message Dumper($options);

	my %self = (
		host => $options->{host},
		port => $options->{port},
		state => NOT_STARTED,
		daemon => new Utils::Daemon('OpenKore-websocketBus')
	);
	return bless \%self, $class;
}

sub iterate {
	Log::message ">>>websocketBus::Server::Starter iterate START"."\n";
	my ($self) = @_;
	if ($self->{state} == NOT_STARTED) {
		Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 0"."\n";
		my $info = $self->{daemon}->getInfo();
		Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 1"."\n";
		if ($info) {
			Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 2"."\n";
			$self->{state} = STARTED;
			$self->{host} = $info->{host};
			$self->{port} = $info->{port};
		} else {
			Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 3"."\n";
			my $launcher = new PerlLauncher(
				\@INC,
				$busServerScript,
				'--bind='.$self->{host},
				'--port='.$self->{port},
			);
			Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 4"."\n";
			if ($launcher->launch(1)) {
				Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 5"."\n";
				$self->{state} = STARTING;
				$self->{start_time} = time;
			} else {
				Log::message ">>>websocketBus::Server::Starter iterate NOT_STARTED 6"."\n";
				$self->{state} = FAILED;
				$self->{error} = $launcher->getError();
			}
		}
	} elsif ($self->{state} == STARTING) {
		Log::message ">>>websocketBus::Server::Starter iterate STARTING 0"."\n";
		my $info = $self->{daemon}->getInfo();
		if ($info) {
			Log::message ">>>websocketBus::Server::Starter iterate STARTING 1"."\n";
			$self->{state} = STARTED;
			$self->{host} = $info->{host};
			$self->{port} = $info->{port};
		} elsif (time - $self->{start_time} > 10) {
			Log::message ">>>websocketBus::Server::Starter iterate STARTING 2"."\n";
			# 10 seconds passed and bus server is still not started.
			$self->{state} = FAILED;
			$self->{error} = "Timeout when starting server.";
		}
	}
	Log::message ">>>websocketBus::Server::Starter iterate END"."\n";
	return $self->{state};
}

sub getHost {
	return $_[0]->{host};
}

sub getPort {
	return $_[0]->{port};
}

sub getError {
	return $_[0]->{error};
}

1;
