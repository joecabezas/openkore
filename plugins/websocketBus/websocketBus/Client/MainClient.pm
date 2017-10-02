package websocketBus::Client::MainClient;

use strict;
use Time::HiRes qw(time);

use Modules 'register';
use websocketBus::Client::SimpleClient;
use base qw(websocketBus::Client::SimpleClient);
use websocketBus::Server::Starter;
use Utils::Exceptions;

# TODO: remove
use Data::Dumper;

# State constants.
use constant {
    NOT_CONNECTED   => 1,
    STARTING_SERVER => 2,
    HANDSHAKING     => 3,
    CONNECTED       => 4
};

# Time constants.
use constant {
    RECONNECT_INTERVAL => 5,
    RESTART_INTERVAL   => 5
};


sub new {
    my $class = shift;
    my $args = shift;
    # my $self = bless {}, $class;

    # $self->{host} = $args->{host};
    # $self->{port} = $args->{port};
    # $self->{on_message_received} = $args->{on_message_received};

    Log::message ">>>websocketBus::Client::MainClient 0"."\n";
    Log::message ">>>class"."\n";
    Log::message Dumper($class);

    # $self->{client} = new websocketBus::Client::SimpleClient({
    #     host => $self->{host},
    #     port => $self->{port}
    # });
    # $self->{state} = HANDSHAKING;
    my $self = $class->SUPER::new({
        host => $args->{host},
        port => $args->{port},
        on_message_received => $args->{on_message_received}
    });

    $self->{starter} = new websocketBus::Server::Starter({
        host => $self->{host},
        port => $self->{port},
    });

    # A queue containing messages to be sent next time we're
    # connected to the bus.
    $self->{sendQueue} = [];
    # $self->{seq} = 0;

    # Log::message ">>>self"."\n";
    # Log::message Dumper($self);

    $self->{state} = STARTING_SERVER;

    # if (!$self->{host} && !$self->{port}) {
    #   Log::message ">>>websocketBus::Client::MainClient 1"."\n";
    #   $self->{starter} = new websocketBus::Server::Starter();
    #   $self->{state} = STARTING_SERVER;
    #   Log::message ">>>websocketBus::Client::MainClient 2"."\n";
    # } else {
    #   Log::message ">>>websocketBus::Client::MainClient 3"."\n";
    #   $self->reconnect();
    # }

    return bless $self, $class;
}

sub iterate {
    # Log::message ">>>websocketBus::Client::MainClient iterate START"."\n";
    my ($self) = @_;
    my $state = $self->{state};

    if ($state == NOT_CONNECTED) {
        # Log::message ">>>websocketBus::Client::MainClient iterate NOT_CONNECTED 0"."\n";
        if (time - $self->{connectTime} > RECONNECT_INTERVAL) {
            $self->reconnect();
        }
    } elsif ($state == STARTING_SERVER) {
        Log::message ">>>websocketBus::Client::MainClient iterate STARTING_SERVER 0"."\n";
        if (time - $self->{startTime} > RESTART_INTERVAL) {
            Log::message ">>>websocketBus::Client::MainClient iterate STARTING_SERVER 1"."\n";
            #print "Starting\n";
            # Log::message Dumper($self->{starter});
            my $state = $self->{starter}->iterate();
            if ($state == websocketBus::Server::Starter::STARTED) {
                Log::message ">>>websocketBus::Client::MainClient iterate STARTING_SERVER 2"."\n";
                $self->{host}  = $self->{starter}->getHost();
                $self->{port}  = $self->{starter}->getPort();
                $self->{state} = NOT_CONNECTED;
                print "websocketBus server started at $self->{host}:$self->{port}\n";
                $self->reconnect();
                $self->{startTime} = time;

            } elsif ($state == websocketBus::Server::Starter::FAILED) {
                Log::message ">>>websocketBus::Client::MainClient iterate STARTING_SERVER 3"."\n";
                # # Cannot start; try again.
                print "Start failed, trying again.\n";
                $self->{starter} = new websocketBus::Server::Starter();
                $self->{startTime} = time;
            }
        }
    } elsif ($state == HANDSHAKING) {
        Log::message ">>>websocketBus::Client::MainClient iterate HANDSHAKING"."\n";
        # print "Handshaking\n";
        my $args = $self->readNext();
        if ($args) {
            $self->{state} = CONNECTED;
            print "Connected\n";
        }

    } elsif ($state == CONNECTED) {
        # Log::message ">>>websocketBus::Client::MainClient iterate CONNECTED 0"."\n";
        # Send queued messages.
        while (@{$self->{sendQueue}} > 0) {
            Log::message ">>>websocketBus::Client::MainClient iterate CONNECTED 1"."\n";
            my $message = shift @{$self->{sendQueue}};
            last if (!$self->send($message));
            Log::message ">>>websocketBus::Client::MainClient iterate CONNECTED 2"."\n";
        }

        # Log::message ">>>websocketBus::Client::MainClient iterate CONNECTED 3"."\n";

        if ($self->{state} == CONNECTED) {
            # Log::message ">>>websocketBus::Client::MainClient iterate CONNECTED 4"."\n";
            while (my $args = $self->readNext()) {
                Log::message ">>>websocketBus::Client::MainClient iterate CONNECTED 5"."\n";
            }
        }
    }

    return $self->{state};
}

sub getState {
    return $_[0]->{state};
}

sub serverHost {
    return $_[0]->{host};
}

sub serverPort {
    return $_[0]->{port};
}

sub ID {
    return $_[0]->{ID};
}

sub reconnect {
    my ($self) = @_;
    Log::message ">>>websocketBus::Client::MainClient reconnect 0"."\n";
    eval {
        print "(Re)connecting\n";
        Log::message ">>>websocketBus::Client::MainClient reconnect 1"."\n";
        $self->connect();
        $self->{state} = HANDSHAKING;
    };
    Log::message ">>>websocketBus::Client::MainClient reconnect 2"."\n";
    if (caught('SocketException')) {
        #print "Cannot connect: $@\n";
        Log::message ">>>websocketBus::Client::MainClient reconnect 3"."\n";
        $self->{state} = NOT_CONNECTED;
        $self->{connectTime} = time;
    } elsif ($@) {
        Log::message ">>>websocketBus::Client::MainClient reconnect 4"."\n";
        die $@;
    }
    Log::message ">>>websocketBus::Client::MainClient reconnect 5"."\n";
}

# Handle an I/O exception by reconnecting to the bus or restarting the
# bus server.
# sub handleIOException {
#   my ($self) = @_;
#   if ($self->{starter}) {
#       $self->{starter} = new websocketBus::Server::Starter();
#       $self->{state} = STARTING_SERVER;
#       # We add a random delay to prevent clients from starting
#       # the server at the same time.
#       $self->{startTime} = time + rand(3);
#   } else {
#       $self->{state} = NOT_CONNECTED;
#       $self->{connectTime} = time + rand(3);
#   }
# }

# Read the next message from the bus, if any. This method returns undef immediately
# when there are no messages.
#
# If the connection with the bus broke while reading the message, then
# undef is returned, and we'll attempt to reconnect (or restart the bus
# server) on the next iteration.
# sub readNext {
#     $class = shift;
#     my ($self) = @_;
#     my $args;
#     eval {
#         # $args = $self->{client}->readNext();
#         $args = $class->SUPER::readNext();
#     };
#     if (caught('IOException')) {
#         #print "Disconnected from IPC server.\n";
#         $self->handleIOException();
#         return undef;
#     } elsif ($@) {
#         die $@;
#     } else {
#         return $args;
#     }
# }

##
# boolean $Bus_Client->send(String messageID, args)
# Returns: Whether the message was successfully sent.
#
# Send a message over the bus.
#
# If the connection with the bus broke while sending the message, then
# the message is placed in a queue, and we'll attempt to reconnect (or
# restart the bus server) on the next iteration. Once reconnected,
# all queued messages will be sent.
sub send {
    my ($self, $args) = @_;
    if ($self->{state} == CONNECTED) {
        eval {
            $self->{client}->send($args);
        };
        if (caught('IOException')) {
            $self->handleIOException();
            push @{$self->{sendQueue}}, $args;
            return 0;
        } elsif ($@) {
            die $@;
        } else {
            return 1;
        }
    } else {
        push @{$self->{sendQueue}}, $args;
        return 0;
    }
}

##
# websocketBus::Query $Bus_Client->query(String messageID, [Hash args], [Hash options])
# messageID: The message ID of the message to send.
# args: The arguments for the message.
# options: Extra options for this query.
#
# Send a query message over the bus. The returned websocketBus::Query object allows you to
# asynchronously check for replies for this message, and to fetch replies.
#
# So sending a query over the bus involves these steps:
# `l
# - Send the query.
# - Use the returned websocketBus::Query object to periodically check whether replies have
#   been received for this query.
# - Fetch the replies.
# `l`
#
# Here is a simple example:
# <pre class="code">
# # Send the query.
# my $query = $Bus_Client->query("hello", { name => "Joe" },
#                 { timeout => 10, collectAll => 1 });
#
# # Wait until the query is done or has timed out.
# while ($query->getState() == websocketBus::Query::WAITING) {
#     sleep 1;
# }
#
# if ($query->getState() == websocketBus::Query::DONE) {
#     while (my ($messageID, $args) = $query->getReply()) {
#         print "We have received a reply!\n";
#         # Do something with $messageID and $args...
#     }
#
# } else { # The stat is websocketBus::Query::TIMEOUT
#     print "10 seconds passed and we still don't have a reply!\n";
# }
# </pre>
#
# The following options are allowed:
# `l
# - timeout (float) - The maximum number of seconds to wait for clients to respond to
#       this query. If this reply has been reached, and not a single reply has been
#       received, then the query object's state will be set to websocketBus::Query::TIMEOUT.
#       But if at least one reply has been received by the time the timeout is reached,
#       then the state will be set to websocketBus::Query::DONE.<br>
#       The default timeout is 5 seconds.
# - collectAll (boolean) - Set to false if you only want to receive one reply for this query,
#       set to true if you want to receive multiple replies for this query.<br>
#       If collectAll is false, and a reply has been received (within the timeout), then
#       the websocketBus::Query object's state is immediately set to websocketBus::Query::DONE.<br>
#       If collectAll is true, then the query's state will stay at websocketBus::Query::WAITING
#       until the timeout has been reached. Once the timeout has been reached, the
#       state will be set to websocketBus::Query::DONE (if there are replies) or
#       websocketBus::Query::TIMEOUT (if there are no replies).
# `l`
#
# If the connection with the bus broke while sending the message, then
# the message is placed in a queue, and we'll attempt to reconnect (or
# restart the bus server) on the next iteration. Once reconnected,
# all queued messages will be sent.
# sub query {
#   my ($self, $MID, $args, $options) = @_;
#   my %params = (
#       bus  => $self,
#       seq  => $self->{seq},
#       messageID => $MID,
#       args => $args
#   );
#   if ($options) {
#       while (my ($key, $value) = each %{$options}) {
#           $params{$key} = $value;
#       }
#   }

#   my %params2 = ($args) ? (%{$args}) : ();
#   $params2{SEQ} = $self->{seq};
#   $self->send($MID, \%params2);

#   $self->{seq} = ($self->{seq} + 1) % 4294967295;
#   return new websocketBus::Query(\%params);
# }

# requestDialog(Bytes clientID, String reason, args, Hash options)
# sub requestDialog {
#   my ($self, $clientID, $reason, $args, $options) = @_;
#   $options ||= {};
#   return new websocketBus::DialogMaster({
#       bus => $self,
#       peerID => $clientID,
#       reason => $reason,
#       args   => $args || {},
#       timeout => $options->{timeout}
#   });
# }

##
# CallbackList $Bus_Client->onMessageReceived()
#
# This event is triggered when a message has been received from the bus.
# The event argument is a hash, containing these two items:
# `l
# - messageID (String): The message ID.
# - args (Hash): The message arguments.
# `l`
# sub onMessageReceived {
#   return $_[0]->{onMessageReceived};
# }

# sub onDialogRequested {
#   return $_[0]->{onDialogRequested};
# }

1;
