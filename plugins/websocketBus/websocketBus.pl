package websocketBus;

use lib $Plugins::current_plugin_folder;

use strict;
use Plugins;
use Settings;
use Globals;
use Log qw(warning message error);

use Data::Dumper;
use websocketBus::Client::MainClient;

# Initialize some variables as well as plugin hooks
our $websocketClient;

Plugins::register('websocketBus', 'PENDING', \&unload);
my $hook = Plugins::addHooks(
	['mainLoop_pre', \&mainLoop],
	['start3', \&post_loading],
);

sub unload {
	Plugins::delHooks($hook);
}

sub post_loading {
	my $host = $config{websocketBusHost} || "localhost";
	my $port = $config{websocketBusPort} || "51115";

	Log::message ">>>websocketBus 0"."\n";

	eval {
		Log::message ">>>websocketBus 1"."\n";
		# require websocketBus::Client::MainClient;
		# $websocketClient = new websocketBus::Client::MainClient($host, $port);
		$websocketClient = new websocketBus::Client::MainClient({
			host => $host,
			port => $port,
			on_message_received => \&on_message_received
		});
		Log::message ">>>websocketBus 2"."\n";
	};
	unless ($websocketClient) {
		Log::message ">>>websocketBus 3"."\n";
		error "WebSocket server failed to start: $@\n"
	}

	# my $i = 3;
	# # delete me
	# while($i > 0){
	# 	$i--;
	# 	mainLoop();
	# }

	# delete me
	# while(1){
	# 	mainLoop();
	# }
}

sub on_message_received {
	my $message = shift;
	Log::message ">>>websocketBus on_message_received START ***********************************\n";
	Log::message "$message\n";
	Log::message Dumper($message);

	#TODO: filter by 'to' field
	# if (($char && $1 eq $char->name) || $1 eq "all");
	Plugins::callHook('websocketBus_received', {message => $message});
}

sub mainLoop {
	# Log::message ">>>websocketBus mainLoop 0 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"."\n";
	$websocketClient->iterate if $websocketClient;
}

1;