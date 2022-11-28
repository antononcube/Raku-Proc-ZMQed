#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use Proc::ZMQed::Julia;

my Proc::ZMQed::Julia $juliaProc .= new(url => 'tcp://127.0.0.1', port => '5560');

$juliaProc.start-proc(setup-lines => Empty):!proclaim;

my $juliaRes = $juliaProc.evaluate('sqrt(323)');
say $juliaRes;

$juliaProc.terminate;