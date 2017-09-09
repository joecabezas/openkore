package websocketBus;

use lib 'C:/strawberry-5.12.2/perl/lib';
use lib 'C:/strawberry-5.12.2/perl/site/lib';
use lib 'C:/strawberry-5.12.2/perl/vendor/lib';
# use lib 'C:/Strawberry/perl/site/lib/auto/Digest/SHA';

use strict;
use Plugins;
use Settings;
our $path;
BEGIN {
	$path = $Plugins::current_plugin_folder;
}
use lib $path;
use Globals;
use Log qw(warning message error);

# Initialize some variables as well as plugin hooks

my $port;
my $bind;
our $socketServer;

Plugins::register('websocketBus', 'PENDING', \&Unload);
my $hook = Plugins::addHooks(
	['mainLoop_post', \&mainLoop],
	['start3', \&post_loading],
);

sub Unload {
	Plugins::delHooks($hook);
}

message "version: ";
message $];


##### Seting webServer after of plugins loads
sub post_loading {
	$bind = $config{webBind} || "localhost";

	eval {
		require WebMonitor::WebSocketServer;
		$socketServer = new WebMonitor::WebSocketServer(8080, $bind);
	};
	unless ($socketServer) {
		error "WebSocket server failed to start: $@\n"
	}
}

sub mainLoop {
	$socketServer->iterate if $socketServer;
}

1;