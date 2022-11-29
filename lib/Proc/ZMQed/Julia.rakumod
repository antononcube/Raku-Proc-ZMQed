use v6.d;

use Proc::ZMQed::Abstraction;

#===========================================================
# Make Raku code
#===========================================================

constant $juliaServerCode = q:to/END/;
using JSON
using ZMQ
#using Logging

#logger = SimpleLogger(stdout, Logging.Debug)

context = ZMQ.Context(1)

socket = ZMQ.Socket(context, ZMQ.REP)
ZMQ.connect(socket, "$url:$port")

Logging.info("Ready")

while true
    commmad = unsafe_string(ZMQ.recv(socket))
    result = eval(Meta.parse(commmad))
    ZMQ.send(socket, JSON.json(result))
end

END

class Proc::ZMQed::Julia does Proc::ZMQed::Abstraction {

    #============================================================
    # creators
    #============================================================

    submethod BUILD(
            :$!cli-name = 'julia',
            :$!code-option = '-e',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '5562',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}

    #============================================================
    # make-code
    #============================================================

    #| Makes Julia's ZeroMQ infinite loop program.
    method make-code(Str :$prepCode = '', Bool :$proclaim = False) {

        my Str $resCode =
                $prepCode ~ "\n" ~ $juliaServerCode.subst('$url', $!url).subst('$port', $!port);

        if !$proclaim {
            $resCode = $resCode.subst(/ ^^ \h* ['Logging.info'] .*? $$ /, ''):g
        }

        $resCode
    };


    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines($setup-lines is copy) {
        # Prep code
        $setup-lines = do given $setup-lines {
            when $_.isa(Whatever) { <LinearAlgebra DataFrames> }
            when $_ ~~ Str { [$_,] }
        };

        my Str $prepCode = '';
        if $setup-lines {
            $prepCode = $setup-lines.map({ 'using ' ~ $_ }).join(";\n");
        }

        return $prepCode;
    }
}