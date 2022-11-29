#!/usr/bin/env raku
use v6.d;

use Proc::ZMQed;
use Proc::ZMQed::Python;

# Here we connect to a Python virtual environment (made and used with miniforge).
# Replace the script name with preferred path.
my Proc::ZMQed::Python $pythonProc .= new(url => 'tcp://127.0.0.1',
                                          port => '5554',
                                          cli-name => $*HOME ~ '/miniforge3/envs/SciPyCentric/bin/python');

$pythonProc.start-proc(setup-lines => Whatever):proclaim;

my $pyRes = $pythonProc.evaluate('[math.sqrt(x) for x in list(range(12))]');
say $pyRes;

$pythonProc.terminate;