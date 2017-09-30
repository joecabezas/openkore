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
	my $port = shift;
	my $bind = shift;
	my %args = @_;
	my $self = $class->SUPER::new($port, $bind);
	$self->{quiet} = $args{quiet};

	return $self;
}

sub websocket_message_received {
    my ($self, $message) = @_;
    $self->message(">>>websocketBus::Server::MainServer:websocket_message_received 0");
    $self->message("message");
    $self->message(Dumper($message));

    # my $message_object;

	# try {
	# 	$message_object = JSON::decode_json($message);
	# } catch {
	# 	warning "WARNING: websocketBus: $_"."\n";
	# };

    #broadcast message to all clients
    #TODO: dont send message to sender

    $self->broadcast($message);
}

1;
