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

sub new {
    my $class = shift;
    my $args = shift;
    my %self;

    Log::message ">>>websocketBus::Client::SimpleClient new 0"."\n";
    Log::message ">>>args"."\n";
    Log::message Dumper($args);

    $socket = new IO::Socket::INET(
        PeerHost => $args->{host},
        PeerPort => $args->{port},
        Proto => 'tcp'
        # Blocking => 0,
        # Timeout => 4
    );
    if (!$socket) {
        Log::message ">>>websocketBus::Client::SimpleClient new 1"."\n";
        SocketException->throw($@);
    }
    $self{sock} = $socket;
    # $self{sock}->autoflush(0);

    Log::message ">>>websocketBus::Client::SimpleClient new 1"."\n";
    #TODO: use a module for URI
    $self{websocket_client} = Protocol::WebSocket::Client->new(
        url => 'ws://'.$args->{host}.':'.$args->{port}
    );
    $self{websocket_frame} ||= Protocol::WebSocket::Frame->new;

    $self{websocket_client}->on(write => \&on_write);
    $self{websocket_client}->on(read => \&on_read);

    Log::message ">>>websocketBus::Client::SimpleClient new 4"."\n";

    # Sends a correct handshake header
    $self{websocket_client}->connect;

    # Register on connect handler
    # $self{websocket_client}->on(
    #     connect => sub {
    #         Log::message ">>>websocketBus::Client::SimpleClient new 5"."\n";
    #         $self{websocket_client}->write('hi there');
    #     }
    # );

    # # Parses incoming data and on every frame calls on_read
    # Log::message ">>>websocketBus::Client::SimpleClient new 6"."\n";
    # my $data;
    # Log::message ">>>data"."\n";
    # Log::message Dumper($data);
    # $self{sock}->recv($data, 1024 * 32, 0);
    # Log::message ">>>data"."\n";
    # Log::message Dumper($data);
    # $self{websocket_client}->read($data);

    return bless \%self, $class;
}

sub on_read {
    my $client = shift;
    my ($buf) = @_;

    Log::message ">>>websocketBus::Client::SimpleClient on_read 0 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"."\n";
    Log::message ">>>buf"."\n";
    Log::message Dumper($buf);
}

sub on_write {
    my $client = shift;
    my ($buf) = @_;

    Log::message ">>>websocketBus::Client::SimpleClient on_write 0 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"."\n";
    # Log::message ">>>sock"."\n";
    # Log::message Dumper($self{sock});
    Log::message ">>>buf"."\n";
    Log::message Dumper($buf);

    $socket->send($buf, 0);
    $socket->flush;
}

sub DESTROY {
    my ($self) = @_;
    $self->{sock}->close if ($self->{sock});
}

##
# void $Bus_Client->send(String messageID, args)
#
# Send a message through the bus. Throws IOException if it fails.
sub send {
    my ($self, $message) = @_;
    eval {
        $self->{sock}->send(
            $self->{websocket_frame}->new($message)->to_bytes
        );
        # $self->{websocket_client}->send(
        #     $self->{websocket_frame}->new($message)->to_bytes);
        # $self->{sock}->flush();
    };
    if ($@) {
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
        # Parses incoming data and on every frame calls on_read
        # Log::message ">>>data"."\n";
        # Log::message Dumper($data);
        $self->{websocket_client}->read($data);
        return $data;
    }
}

1;
