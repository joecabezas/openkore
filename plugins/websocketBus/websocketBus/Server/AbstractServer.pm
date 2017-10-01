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
    my $class = shift;
    my $args = shift;
    my $self;

    $self->{host} = $args->{host};
    $self->{port} = $args->{port};

    $self = $class->SUPER::new($self->{port}, $self->{host});
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
    # $self->message(">>>self");
    # $self->message(Dumper($self));

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
    $self->message(">>>data");
    $self->message(Dumper($data));
    $self->message(">>>index");
    $self->message(Dumper($index));

    # $self->message(">>>websocket_hs");
    # $self->message(Dumper($client->{websocket_hs}));
    # $self->message(">>>websocket_frame");
    # $self->message(Dumper($client->{websocket_frame}));

    $client->{websocket_hs} ||= Protocol::WebSocket::Handshake::Server->new;
    $client->{websocket_frame} ||= Protocol::WebSocket::Frame->new;

    # $self->message(">>>websocket_hs");
    # $self->message(Dumper($client->{websocket_hs}));
    # $self->message(">>>websocket_frame");
    # $self->message(Dumper($client->{websocket_frame}));

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
        $self->message(">>>message");
        $self->message(Dumper($message));
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
    $self->message(">>>websocketBus::Server::AbstractServer:broadcast START");

    for my $client (@{$self->{BS_clients}->getItems}) {
        $self->message(">>>websocketBus::Server::AbstractServer:broadcast 0");
        next unless $client->{websocket_hs} && $client->{websocket_hs}->is_done;
        $self->message(">>>websocketBus::Server::AbstractServer:broadcast 1");
        next if $client_sender->getIndex() eq $client->getIndex();

        $self->message(">>>websocketBus::Server::AbstractServer:broadcast 2");
        $client->send($client->{websocket_frame}->new($message)->to_bytes);
    }
    $self->message(">>>websocketBus::Server::AbstractServer:broadcast 3");
}

return 1;
