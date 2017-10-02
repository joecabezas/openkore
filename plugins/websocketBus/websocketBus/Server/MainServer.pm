package websocketBus::Server::MainServer;

use strict;
use warnings;
use Time::HiRes qw(sleep);
use websocketBus::Server::AbstractServer;
use base qw(websocketBus::Server::AbstractServer);
use utf8;

use Data::Dumper;

sub new {
	my $class = shift;
	my $args = shift;

	Log::message ">>>websocketBus::Server::MainServer new START\n";
	Log::message "class\n";
	Log::message Dumper($class);
	Log::message "args\n";
	Log::message Dumper($args);

	my $self = $class->SUPER::new({
		host => $args->{host},
		port => $args->{port}
	});

	$self->{quiet} = $args->{quiet};
	$self->{host} = $args->{host};
	$self->{port} = $args->{port};

	# $self->message("port");
	# $self->message(Dumper($port));
	# $self->message("bind");
	# $self->message(Dumper($bind));

	return $self;
}

sub websocket_message_received {
    my ($self, $message, $client) = @_;
    $self->message(">>>websocketBus::Server::MainServer:websocket_message_received 0");
    $self->message("message");
    $self->message(Dumper($message));

    $self->broadcast($message, $client);
}

1;
