#!/usr/bin/env raku
use v6.d;

use Proc::ZMQed::JavaScript;

my Proc::ZMQed::JavaScript $jsProc .= new(url => 'tcp://127.0.0.1', port => '5560');

$jsProc.start-proc(setup-lines => Empty):!proclaim;

my $jsRes = $jsProc.evaluate('Math.sqrt(323)');
say $jsRes;

$jsProc.terminate;