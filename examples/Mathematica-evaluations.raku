#!/usr/bin/env raku
use v6.d;

use lib '.';
use lib './lib';

use Proc::ZMQed::Mathematica;

my Proc::ZMQed::Mathematica $wlProc .= new(url => 'tcp://127.0.0.1', port => '5550');

$wlProc.start-proc():!proclaim;

#say %wlProc.raku;

my $cmd = 'Expand[($x+$y)^4]';
my $wlRes = $wlProc.evaluate($cmd);
say "Sent : $cmd";
say "Got  :\n $wlRes";

say '-' x 120;
$cmd = 'FortranForm[Expand[($x+$y)^4]]';
$wlRes = $wlProc.evaluate($cmd);
say "Sent : $cmd";
say "Got  : $wlRes";

my $x = 5;
my $y = 3;

say '-' x 120;
use MONKEY-SEE-NO-EVAL;
say "Using : {{:$x, :$y}.raku}";
say 'EVAL($wlRes) : ', EVAL($wlRes);

# If we do not use Fortran form we have to certain replacements:
# say EVAL($wlRes.subst(:g, '^', '**');

say '-' x 120;
$cmd = 'Expand[($x+$y)^4] /. {$x->5, $y->3}';
$wlRes = $wlProc.evaluate($cmd);
say "Sent : $cmd";
say "Got  : $wlRes";


say '=' x 120;
$cmd = 'D[($x+$y)^3, $x]';
$wlRes = $wlProc.evaluate($cmd);
say "Sent : $cmd";
say "Got  :\n $wlRes";


say '=' x 120;
$cmd = 'Solve[$x + 2*$y - $x^2 == $x, $x]';
$wlRes = $wlProc.evaluate($cmd);
say "Sent : $cmd";
say "Got  : $wlRes";


$wlProc.terminate;