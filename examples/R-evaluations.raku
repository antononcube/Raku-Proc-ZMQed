#!/usr/bin/env raku
use v6.d;

use Proc::ZMQed;
use Proc::ZMQed::R;

my Proc::ZMQed::R $rProc .= new(url => 'tcp://127.0.0.1',
                                          port => '5556');

$rProc.start-proc(setup-lines => Whatever):proclaim;

my $rRes = $rProc.evaluate('sqrt(seq(30,40,2))');
say $rRes;

$rProc.terminate;