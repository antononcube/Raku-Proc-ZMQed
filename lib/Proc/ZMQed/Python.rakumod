use v6.d;

use Proc::ZMQed::Abstraction;

constant $pythonServerCode = q:to/END/;
import logging
import zmq
import json

logging.basicConfig(format="%(levelname)s: %(message)s", level=logging.INFO)

context = zmq.Context()
server = context.socket(zmq.REP)
server.connect("tcp://*:5554")

while True:
    request = server.recv().decode("utf-8")
    logging.info("Received request")
    res = eval(request)
    logging.info("Evaluated request")
    server.send(json.dumps(res).encode('utf-8'))
END

class Proc::ZMQed::Python
        does Proc::ZMQed::Abstraction {

    #============================================================
    # creators
    #============================================================

    submethod BUILD(
            :$!cli-name = 'python',
            :$!code-option = '-c',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '5552',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}


    #============================================================
    # make-python-code
    #============================================================

    #| Makes WL's ZeroMQ infinite loop program.
    method make-code(Str :$prepCode = '',
                     Bool :$proclaim = False)  {

        my Str $resCode = $prepCode ~ "\n" ~ $pythonServerCode.subst('server.connect("tcp://*:5554")', "server.connect(\"$!url:$!port\")");

        if !$proclaim {
            $resCode = $resCode.subst(/ ^^ \h* ['logging.info' | 'print'] .*? $$ /, ''):g
        }

        return $resCode;
    };

    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines($setup-lines is copy) {
        # Prep code
        $setup-lines = do given $setup-lines {
            when $_.isa(Whatever) { <math numpy pandas> }
            when $_ ~~ Str { [$_,] }
        };

        my Str $prepCode = '';
        if $setup-lines {
            $prepCode = $setup-lines.map({ 'import ' ~ $_ }).join("\n");
        }

        return $prepCode;
    }
}