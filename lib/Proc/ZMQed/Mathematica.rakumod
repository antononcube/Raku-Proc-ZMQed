use v6.d;

use Proc::ZMQed::Abstraction;

constant $wlServerCode = q:to/END/;
socket = SocketConnect["$url:$port", "ZMQ_REP"]

While[True,
 message = SocketReadMessage[socket];
 message2 = ByteArrayToString[message];
 Print["[woflramscirpt] got request:", message2];
 res = Check[ToExpression[message2], ExportString[<|"Error" -> "$Failed"|>, "JSON", "Compact" -> True]];
 Print["[woflramscirpt] evaluated:", res];

 BinaryWrite[socket, StringToByteArray[ToString[res], "UTF-8"]]
]
END

class Proc::ZMQed::Mathematica
        does Proc::ZMQed::Abstraction {

    #============================================================
    # creators
    #============================================================
#    method new($url, $port) {
#        return Proc::ZMQish.new('wolframscript', '-code', $url, $port) ;
#    }

    submethod BUILD(
            :$!cli-name = 'wolframscript',
            :$!code-option = '-code',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '5555',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}

    #============================================================
    # make-wl-code
    #============================================================

    #| Makes WL's ZeroMQ infinite loop program.
    method make-code(Str :$prepCode = '',
                     Bool :$proclaim = False) is export {

        my Str $resCode =
                $prepCode ~ "\n" ~ $wlServerCode.subst('SocketConnect["$url:$port"', "SocketConnect[\"$!url:$!port\"");

        # BinaryWrite[socket, StringToByteArray[ToString[res], \"UTF-8\"], \"Character32\"]
        if !$proclaim {
            $resCode = $resCode.subst(/ ^^ \h* 'Print' .*? $$ /, ''):g
        }
        return $resCode;
    };


    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines( $setup-lines is copy ) {
        $setup-lines = do given $setup-lines {
            when $_.isa(Whatever) {
                ['https://raw.githubusercontent.com/antononcube/NLP-Template-Engine/main/Packages/WL/NLPTemplateEngine.m',]
            }
            when $_ ~~ Str { [$_,] }
        };

        my Str $prepCode = '';
        if $setup-lines {
            $prepCode = $setup-lines.map({ 'Import["' ~ $_ ~ '"]' }).join(";\n");
        }

        return $prepCode;
    }
}