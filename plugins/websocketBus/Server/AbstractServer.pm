package websocketBus::Server::AbstractServer;

use strict;
use warnings;

use Log;
use Base::Server;
use base qw(Base::Server);
use Protocol::WebSocket;

# TODO: remove
use Data::Dumper;

sub message {
    my ($self, $message) = @_;
    return if ($self->{quiet});
    Log::message "[MESSAGE] $message"."\n";
}

sub warning {
    my ($self, $message) = @_;
    return if ($self->{quiet});
    Log::warning "[WARNING] $message"."\n";
}

##
# websocketBus::Server::AbstractServer->new([int port, String bind])
# port: Start the server at the specified port.
# bind: Bind the server at the specified IP.
#
# Create a new websocket bus server. See Base::Server->new() for a description of the parameters.
sub new {
    my ($class, $port, $bind) = @_;
    my $self;

    $self = $class->SUPER::new($port, $bind);
    $self->{BAS_maxID} = 0;

    return $self;
}

# #######################################
# ### CATEGORY: Abstract methods
# #######################################

##
# abstract void message(String message, Base::WebServer::Client client)
#
# This virtual method will be called every time a message is received.
sub websocket_message_received {}


#######################################
# Abstract method implementations
#######################################

sub onClientNew {
    my ($self, $client) = @_;

    $self->message(">>>websocketBus::Server::AbstractServer:onClientNew 0");
    $self->message(">>>self");
    $self->message(Dumper($self));

    $client->{ID} = $self->{BAS_maxID};
    $self->{BAS_maxID}++;

    $self->message("New Websocket client: " . $client->getIP() . " ($client->{ID})\n");
}

sub onClientExit {
    my ($self, $client) = @_;
    $self->message("Websocket Client disconnected: " . $client->getIP() . " ($client->{ID})\n");
}


sub onClientData {
    my ($self, $client, $data, $index) = @_;

    $self->message(">>>websocketBus::Server::AbstractServer:onClientData 0");
    # $self->message(">>>client");
    # $self->message(Dumper($client));
    $self->message(">>>data");
    $self->message(Dumper($data));
    $self->message(">>>index");
    $self->message(Dumper($index));

    $self->message(">>>websocket_hs");
    $self->message(Dumper($client->{websocket_hs}));
    $self->message(">>>websocket_frame");
    $self->message(Dumper($client->{websocket_frame}));

    $client->{websocket_hs} ||= Protocol::WebSocket::Handshake::Server->new;
    $client->{websocket_frame} ||= Protocol::WebSocket::Frame->new;

    $self->message(">>>websocket_hs");
    $self->message(Dumper($client->{websocket_hs}));
    $self->message(">>>websocket_frame");
    $self->message(Dumper($client->{websocket_frame}));

    unless ($client->{websocket_hs}->is_done) {
        $client->{websocket_hs}->parse($data);

        $self->message(">>>websocketBus::Server::AbstractServer:onClientData 1");

        if ($client->{websocket_hs}->is_done) {
            $self->message(">>>websocketBus::Server::AbstractServer:onClientData 2");
            $self->message(">>>to_string");
            $self->message(Dumper($client->{websocket_hs}->to_string));
            $client->send($client->{websocket_hs}->to_string);
        }

        return
    }

    $client->{websocket_frame}->append($data);

    $self->message(">>>websocketBus::Server::AbstractServer:onClientData 3");
    $self->message(">>>websocket_frame");
    $self->message(Dumper($client->{websocket_frame}));

    while (defined(my $message = $client->{websocket_frame}->next)) {
        $self->message(">>>websocketBus::Server::AbstractServer:onClientData 4");
        $self->websocket_message_received($message, $client);
    }

    $self->message(">>>websocketBus::Server::AbstractServer:onClientData 5");
}

##
# void $BaseWebSocketServer->broadcast(String message)
#
# Send a message to all clients, except the sender
sub broadcast {
    my ($self, $message, $client_sender) = @_;

    for my $client (@{$self->{BS_clients}->getItems}) {
        next unless $client->{websocket_hs} && $client->{websocket_hs}->is_done;
        next if $client_sender->getIndex() eq $client->getIndex();

        $client->send($client->{websocket_frame}->new($message)->to_bytes);
    }
}

return 1;
