use v6.d;

use Proc::ZMQed::Abstraction;

#===========================================================
# Make Raku code
#===========================================================

constant $rakuServerCode = q:to/END/;
use Net::ZMQ4;
use Net::ZMQ4::Constants;
use Text::CodeProcessing::REPLSandbox;
use Text::CodeProcessing;
sub MAIN(Str :$url = '`URL`', Str :$port = '`Port`', Str :$rakuOutputPrompt = '`OutputPrompt`', Str :$rakuErrorPrompt = '`ErrorPrompt`') {
    # Socket to talk to clients
    my Net::ZMQ4::Context $context .= new;
    my Net::ZMQ4::Socket $responder .= new($context, ZMQ_REP);
    $responder.connect("$url:$port");
    ## Create a sandbox
    my $sandbox = Text::CodeProcessing::REPLSandbox.new();
    while (1) {
        my $message = $responder.receive();
        say "Received : { $message.data-str }";
        my $res = CodeChunkEvaluate($sandbox, $message.data-str, $rakuOutputPrompt, $rakuErrorPrompt);
        $responder.send($res);
    }
}

END

class Proc::ZMQed::Raku does Proc::ZMQed::Abstraction {

    #============================================================
    # creators
    #============================================================

    submethod BUILD(
            :$!scriptName = 'raku',
            :$!codeOption = '-e',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '558',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}

    #============================================================
    # make-code
    #============================================================

    #| Makes Raku's ZeroMQ infinite loop program.
    method make-code(Str :$prepCode = '', Bool :$proclaim = False) {

        my Str $resCode =
                $prepCode ~ "\n" ~ $rakuServerCode.subst('`URL`', $!url).subst('`Port`', $!port).subst('`OutputPrompt`','').subst('`ErrorPrompt`','#ERR:');

        if !$proclaim {
            $resCode = $resCode.subst(/ ^^ \h* ['say' | 'put'] .*? $$ /, ''):g
        }

        note $resCode;

        $resCode
    };


    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines($setup-lines is copy) {
        # Prep code
        $setup-lines = do given $setup-lines {
            when $_.isa(Whatever) { <Data::Generators Data::Reshapers Data::ExampleDatasets> }
            when $_ ~~ Str { [$_,] }
        };

        my Str $prepCode = '';
        if $setup-lines {
            $prepCode = $setup-lines.map({ 'use ' ~ $_ }).join(";\n");
        }

        return $prepCode;
    }
}