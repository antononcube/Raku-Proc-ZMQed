#!/usr/bin/env raku
use v6.d;

use NativeCall;

# Lazy Pirate client in Raku
# Use poll to do a safe request-reply
# Modified from Perl's version here: https://zguide.zeromq.org/docs/chapter4/

use Net::ZMQ4;

use Net::ZMQ4::Constants;
use Net::ZMQ4::Context;
use Net::ZMQ4::Message;
use Net::ZMQ4::Pollitem;
use Net::ZMQ4::Socket;
use Net::ZMQ4::Util;
use Net::ZMQ4::Poll;

# ZMQ_EXPORT int zmq_poll (zmq_pollitem_t *items, int nitems, long timeout);
my sub zmq_poll(Net::ZMQ4::Pollitem, int32, int64 --> int32) is native('zmq',v5) { * }

our sub poll_one2(Net::ZMQ4::Socket $socket, $timeout, Bool :$in, Bool :$out, Bool :$err) is export {
    my Net::ZMQ4::Pollitem $pollitem .= new: :$socket, :$in, :$out, :$err;
    my $ret = zmq_poll($pollitem, 1, $timeout);
    note "ret : $ret";
    if $ret < 0 { die "zmq_poll returned error: $ret" }
    return $pollitem.revents;
}

#================================================================
# ^ ^ ^ It does not seem that the poll function is working.
#================================================================

my $REQUEST_TIMEOUT = 2500;
# msecs
my $REQUEST_RETRIES = 3;
# Before we abandon
#my $SERVER_ENDPOINT = 'tcp://localhost:5555';
my $SERVER_ENDPOINT = 'tcp://127.0.0.1:5555';

say 'I: connecting to server...';
# Socket to talk to clients
my Net::ZMQ4::Context $context .= new;
my Net::ZMQ4::Socket $receiver .= new($context, ZMQ_REQ);
$receiver.connect($SERVER_ENDPOINT);

say 'Main loop ...';

my $sequence = 0;
my $retries_left = $REQUEST_RETRIES;

while $retries_left > 0 {

    say "Before first send";
    # We send a request, then we work to get a reply
    my $request = (++$sequence).Str;
    $receiver.send($request);

    say "Before inf loop";

    loop {
        say "ZMQ_POLLIN : {ZMQ_POLLIN}";

        # Poll socket for a reply, with timeout
        my $pollRes = poll_one2($receiver, ($REQUEST_TIMEOUT).Int);

        say "pollRes : {$pollRes.raku}";
        say "ZMQ_POLLIN : {ZMQ_POLLIN}";
        say '$pollRes +& ZMQ_POLLIN : ', ($pollRes +& ZMQ_POLLIN);

        if $pollRes == 0 {
            # We got a reply from the server, must match sequence
            my $reply = $receiver.receive();

            say '$reply.data-str : ', $reply.data-str.trim;
            say '$request        : ', $request;

            if ($reply.data-str.trim eq $request) {
                say "I: server replied OK ($reply)";
                $retries_left = $REQUEST_RETRIES;
                last;
            }
            else {
                say "E: malformed reply from server: $reply";
            }

            $reply.close;
        } elsif --$retries_left == 0 {
            say 'E: server seems to be offline, abandoning';
        } else {
            say "W: no response from server, retrying...";
            # Old socket is confused; close it and open a new one
            $receiver.close;
            say "reconnecting to server...";
            $receiver .= new($context, ZMQ_REQ);
            $receiver.bind($SERVER_ENDPOINT);
            # Send request again, on new socket
            $receiver.send($request.Str);
        }
    };

    last if $retries_left == 0;
}