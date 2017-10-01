#!/usr/bin/env perl

use strict;
use FindBin qw($RealBin);
use lib "$RealBin";
use lib "$RealBin/..";
use lib "$RealBin/../deps";
use lib "$RealBin/../..";
use lib "$RealBin/../../src";
use lib "$RealBin/../../src/deps";
# use lib "../../";
# use lib "../../src";
# use lib "../../src/deps";
use Getopt::Long;

use Log;
use Data::Dumper;

use Utils::Daemon;
use Utils::Exceptions;

my $server;
my %options;


sub __start {
	Log::message ">>>websocketBus-server.pl __start START\n";
	#### Parse arguments. ####
	$options{port} = 0;
	if (!GetOptions(
		"port=i"     => \$options{port},
		"quiet"      => \$options{quiet},
		"bind=s"     => \$options{bind},
		"nodaemon"   => \$options{nodaemon}
	)) {
		usage(1);
	} elsif ($options{help}) {
		usage(0);
	}

	Log::message ">>>websocketBus-server.pl __start 1\n";
	Log::message "options\n";
	Log::message Dumper(\%options);

	#### Start the server, if not already running. ####
	my $daemon = new Utils::Daemon("OpenKore-websocketBus");
	if (!$options{nodaemon}) {
		Log::message ">>>websocketBus-server.pl __start 2\n";
		eval {
			Log::message ">>>websocketBus-server.pl __start 3\n";
			$daemon->init(\&startServer);
		};
		if (my $e = caught('Utils::Daemon::AlreadyRunning')) {
			Log::message ">>>websocketBus-server.pl __start 4\n";
			my $address = $e->info->{host} . ":" . $e->info->{port};
			print STDERR "The bus server is already running at port $address\n";
			exit 2;
		} elsif ($@) {
			Log::message ">>>websocketBus-server.pl __start 5\n";
			print "Cannot start websocketBus server: $@\n";
			exit 3;
		}
	} else {
		Log::message ">>>websocketBus-server.pl __start 6\n";
		&startServer();
	}

	if (!$options{quiet}) {
		printf "websocketBus server started at %s : %d\n", $server->getHost(), $server->getPort();
	}
	while (1) {
		$server->iterate(-1);
	}
}

sub startServer {
	Log::message ">>>websocketBus-server.pl startServer START\n";
	require websocketBus::Server::MainServer;
	$server = new websocketBus::Server::MainServer({
		host => $options{bind},
		port => $options{port},
		quiet => $options{quiet}
	});
	return {
		host => $server->getHost(),
		port => $server->getPort()
	};
}

sub usage {
	print "Usage: bus-server.pl [OPTIONS]\n\n";
	print "Options:\n";
	print " --port=PORT      Start the server at the specified port. Leave empty to use\n" .
	      "                  the first available port.\n";
	print " --bind=IP        Bind the server at the specified IP.\n";
	print " --quiet          Don't print status messages.\n";
	print " --help           Display this help message.\n";
	exit $_[0];
}

__start() unless defined $ENV{INTERPRETER};
