use v6.d;

use Proc::ZMQed::Abstraction;

#===========================================================
# Make Raku code
#===========================================================

constant $jsServerCode = q:to/END/;
const zmq = require("zeromq")

const sock = new zmq.Request

sock.connect("$url:$port")
console.log("Producer bound to port $url:$port")

while (true) {
  let command = sock.receive()
  console.log("Recieved : " + command)
  let res = eval(command)
  sock.send(res)
  console.log("Sent : " + res)
}

END

class Proc::ZMQed::JavaScript does Proc::ZMQed::Abstraction {

    #============================================================
    # creators
    #============================================================

    submethod BUILD(
            :$!scriptName = 'node',
            :$!codeOption = '-e',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '5560',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}

    #============================================================
    # make-code
    #============================================================

    #| Makes Raku's ZeroMQ infinite loop program.
    method make-code(Str :$prepCode = '', Bool :$proclaim = False) {

        my Str $resCode =
                $prepCode ~ "\n" ~ $jsServerCode.subst('$url', $!url).subst('$port', $!port);

        if !$proclaim {
            $resCode = $resCode.subst(/ ^^ \h* ['console.log'] .*? $$ /, ''):g
        }

        $resCode
    };


    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines($setup-lines is copy) {
        # Prep code
        $setup-lines = do given $setup-lines {
            when $_.isa(Whatever) { Empty }
            when $_ ~~ Str { [$_,] }
        };

        my Str $prepCode = '';
        if $setup-lines {
            $prepCode = $setup-lines.map({ 'require(' ~ $_ ~ ')' }).join(";\n");
        }

        return $prepCode;
    }
}