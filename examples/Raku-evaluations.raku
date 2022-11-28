#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use Proc::ZMQed::Raku;

my Proc::ZMQed::Raku $rakuProc .= new(url => 'tcp://127.0.0.1', port => '5556', scriptName => $*HOME ~ '/.rakubrew/shims/raku');

$rakuProc.start-proc(setup-lines => Empty):proclaim;

my $rRes = $rakuProc.evaluate('(30,40,2)>>.sqrt');
say $rRes;

$rakuProc.terminate;