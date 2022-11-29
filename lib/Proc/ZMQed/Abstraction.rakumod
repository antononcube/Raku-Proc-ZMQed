use v6.d;

use Net::ZMQ4;
use Net::ZMQ4::Constants;

role Proc::ZMQed::Abstraction {

    has Str $.cli-name = 'raku';
    has Str $.code-option = '-e';
    has Str $.url = 'tcp://127.0.0.1';
    has Str $.port = '5555';

    has $.proc = Nil;
    has Net::ZMQ4::Context $.context = Nil;
    has Net::ZMQ4::Socket $.receiver = Nil;

    #============================================================
    # creators
    #============================================================
#    method new($scriptName, $codeOption, $url, $port) {
#        return self.bless(:$scriptName, :$codeOption, :$url, :$port, proc => Nil, context => Nil, receiver => Nil);
#    }

    submethod BUILD(
            :$!cli-name = 'raku',
            :$!code-option = '-e',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '5555',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}

    #============================================================
    # make-code
    #============================================================

    method make-code(Str :$prepCode = '',
                     Bool :$proclaim = False) {...}


    #============================================================
    # evaluate
    #============================================================

    #| Evaluate commands.
    method evaluate(Str $commands --> Str) {

        # Build-up the WL code
        my $spec = $commands;

        # Send code through ZMQ
        $!receiver.send($spec);

        # Receive result from ZMQ
        my $message = $!receiver.receive();

        # Return result
        return $message.data-str;
    }


    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines( $setup-lines is copy ) {
        return do given $setup-lines {
            when $_ ~~ List && $setup-lines.all ~~ Str { $_.join("\n") }
            when $_ ~~ Str { [$_, ] }
            default { '' }
        }
    }


    #============================================================
    # start-proc
    #============================================================

    #| Start a ZeroMQ process for evaluation.
    method start-proc(
            :$setup-lines is copy = (),
            Bool :$proclaim = False) is export {

        die 'The argument setup-lines is expected to be a string, a list of strings, or Whatever.'
        unless !$setup-lines || $setup-lines ~~ List && $setup-lines.all ~~ Str || $setup-lines.isa(Whatever);

        # Prep code
        my $prepCode = self.process-setup-lines($setup-lines);

        # Launch the script with ZMQ socket
        if $!url and $!port {

            warn "Launching $!cli-name with ZMQ socket..." if $proclaim;

            # Launch script with ZMQ socket
            $!proc = Proc::Async.new:
                    $!cli-name,
                    $!code-option,
                    self.make-code(:$!url, :$!port, :$prepCode, :$proclaim);

            $!proc.start;

            # Socket to talk to clients
            $!context = Net::ZMQ4::Context.new;
            $!receiver .= new($!context, ZMQ_REQ);
            $!receiver.bind("$!url:$!port");

            warn '...DONE' if $proclaim;
        } else {
            warn 'Nothing to do.' if $proclaim;
        }
    }

    #============================================================
    # start-proc
    #============================================================

    method terminate() {
        $!receiver.close;
        $!context.shutdown;
        $!proc.kill;
        $!proc.kill: SIGKILL;
    }
}