#########################################################################
#  OpenKore - Bus system
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#
#  $Revision$
#  $Id$
#
#########################################################################
##
# MODULE DESCRIPTION: Low-level bus client implementation.
#
# This module is a bare-bones implementation of a bus client. It can
# only parse messages, but knows nothing about the actual protocol.

package websocketBus::Client::SimpleClient;

use strict;
use warnings;
no warnings 'redefine';
use IO::Socket::INET;

use Modules 'register';
use Utils qw(dataWaiting);
use Utils::Exceptions;
# use Protocol::WebSocket::Handshake::Client;
use Protocol::WebSocket::Client;

use Data::Dumper;

##
# Bus::Client->new(String host, int port)
# host: host address of the IPC manager.
# port: port number of the IPC manager.
#
# Create a new Bus::Client object.
#
# Throws a SocketException if unable to connect.

#TODO: use our?
my $socket;
# my $on_message_received;

sub new {
    my $class = shift;
    my $args = shift;
    my $self = bless {}, $class;

    Log::message ">>>websocketBus::Client::SimpleClient new 0"."\n";
    Log::message ">>>class"."\n";
    Log::message Dumper($class);

    $self->{host} = $args->{host};
    $self->{port} = $args->{port};
    $self->{on_message_received} = $args->{on_message_received};

    Log::message ">>>self"."\n";
    Log::message Dumper($self);

    Log::message ">>>websocketBus::Client::SimpleClient new 1"."\n";
    #TODO: use a module for URI
    $self->{websocket_client} = Protocol::WebSocket::Client->new(
        url => 'ws://'.$self->{host}.':'.$self->{port}
    );
    $self->{websocket_frame} ||= Protocol::WebSocket::Frame->new;

    $self->{websocket_client}->on(read => sub {
        my ($client, $message) = @_;

        Log::message ">>>websocketBus::Client::SimpleClient on_read 0 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"."\n";
        Log::message ">>>message"."\n";
        Log::message Dumper($message);

        # Make callback
        $self->{on_message_received}($message);
    });
    $self->{websocket_client}->on(write => sub {
        my $client = shift;
        my ($buf) = @_;

        Log::message ">>>websocketBus::Client::SimpleClient on_write 0 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"."\n";
        # Log::message ">>>sock"."\n";
        # Log::message Dumper($sock);
        Log::message ">>>buf"."\n";
        Log::message Dumper($buf);

        $socket->send($buf, 0);
        $socket->flush;
    });

    Log::message ">>>websocketBus::Client::SimpleClient new 4"."\n";

    return $self;
}

sub connect {
    my ($self) = @_;
    Log::message ">>>websocketBus::Client::SimpleClient connect START"."\n";
    # Log::message ">>>self"."\n";
    # Log::message Dumper($self);

    $socket = new IO::Socket::INET(
        PeerHost => $self->{host},
        PeerPort => $self->{port},
        Proto => 'tcp'
        # Blocking => 0,
        # Timeout => 4
    );
    if (!$socket) {
        SocketException->throw($@);
    }
    $self->{sock} = $socket;
    $self->{sock}->autoflush(1);

    # Sends a correct handshake header
    $self->{websocket_client}->connect;
}

#abstract method
# sub on_message_received {
#     my ($self, $message) = @_;
#     $self->{on_message_received}($message);
# }

sub DESTROY {
    my ($self) = @_;
    $self->{sock}->close if ($self->{sock});
}

##
# void $Bus_Client->send(String messageID, args)
#
# Send a message through the bus. Throws IOException if it fails.
sub send {
    # Log::message ">>>websocketBus::Client::SimpleClient send START\n";
    my ($self, $message) = @_;
    eval {
        Log::message "message\n";
        Log::message Dumper($message);
        # Log::message ">>>websocketBus::Client::SimpleClient send 1\n";
        $self->{websocket_client}->write(
            $message
        );
        # Log::message ">>>websocketBus::Client::SimpleClient send 2\n";
    };
    if ($@) {
        Log::message ">>>websocketBus::Client::SimpleClient send 3\n";
        Log::message ">>>error:"."\n";
        Log::message Dumper($@);
        IOException->throw($@);
    }
}

##
# Scalar* $Bus_Client->readNext()
# Read the next message from the bus, if any. This method returns undef immediately
# when there are no messages.
#
# Throws IOException if reading from the socket fails.
sub readNext {
    my ($self) = @_;
    # Log::message ">>>websocketBus::Client::SimpleClient readNext START"."\n";

    if (dataWaiting($self->{sock})) {
        # Log::message ">>>websocketBus::Client::SimpleClient readNext 1"."\n";
        my $data;
        eval {
            # Log::message ">>>websocketBus::Client::SimpleClient readNext 2"."\n";
            $self->{sock}->recv($data, 1024 * 32, 0);
            # Log::message ">>>websocketBus::Client::SimpleClient readNext 3"."\n";
        };
        if ($@) {
            # Log::message ">>>websocketBus::Client::SimpleClient readNext 4"."\n";
            IOException->throw($@);
        } elsif (!defined $data || length($data) == 0) {
            # Log::message ">>>websocketBus::Client::SimpleClient readNext 5"."\n";
            IOException->throw("Bus server closed connection.");
        }

        # Log::message ">>>websocketBus::Client::SimpleClient readNext 6"."\n";
        $self->{websocket_client}->read($data);

        if($data){
            return 1;
        }
    }
}

1;
