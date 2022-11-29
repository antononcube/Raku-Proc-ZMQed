#!/usr/bin/env raku
use v6.d;

use Proc::ZMQed::Raku;

my Proc::ZMQed::Raku $rakuProc .= new(url => 'tcp://127.0.0.1', port => '5556', cli-name => $*HOME ~ '/.rakubrew/shims/raku');

$rakuProc.start-proc(setup-lines => Empty):!proclaim;

my $rakuRes = $rakuProc.evaluate('(30,40,2)>>.sqrt');
say $rakuRes;

$rakuProc.terminate;