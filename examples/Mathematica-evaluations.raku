#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use Proc::ZMQed::Mathematica;

my Proc::ZMQed::Mathematica $wlProc .= new(url => 'tcp://127.0.0.1', port => '5550');

$wlProc.start-proc():proclaim;

#say %wlProc.raku;

my $wlRes = $wlProc.evaluate('FortranForm[Expand[($x+$y)^4]]');
say $wlRes;

my $x = 5;
my $y = 3;

use MONKEY-SEE-NO-EVAL;
say 'EVAL($wlRes) : ', EVAL($wlRes);

# If we do not use Fortran form we have to certain replacements:
# say EVAL($wlRes.subst(:g, '^', '**');

$wlRes = $wlProc.evaluate('Expand[($x+$y)^4] /. {$x->5, $y->3}');
say "WL : $wlRes";

$wlProc.terminate;