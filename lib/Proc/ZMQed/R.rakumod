use v6.d;

use Proc::ZMQish;

#===========================================================
# Make R code
#===========================================================

constant $rServerCode = q:to/END/;
{
  library(rzmq);
  library(jsonlite);
  context <- init.context();
  socket <- init.socket(context,"ZMQ_REP");
  connect.socket(socket,"$url:$port");
  while(1) {
    message <- receive.string(socket);
    res <- eval(parse(text=message));
    send.socket(socket, deparse(res));
  }
}

END

class  Proc::ZMQed::R does Proc::ZMQish {

    #============================================================
    # creators
    #============================================================
    #    method new($url, $port) {
    #        return Proc::ZMQish.new('wolframscript', '-code', $url, $port) ;
    #    }

    submethod BUILD(
            :$!scriptName = 'Rscript',
            :$!codeOption = '-e',
            :$!url = 'tcp://127.0.0.1',
            :$!port = '556',
            :$!proc = Nil,
            :$!context = Nil,
            :$!receiver = Nil) {}

    #============================================================
    # make-code
    #============================================================

    #| Makes R's ZeroMQ infinite loop program.
    method make-code(Str :$prepCode = '', Bool :$proclaim = False) {

        my Str $resCode =
                $prepCode ~ "\n" ~ $rServerCode.subst('connect.socket(socket,"$url:$port");', "connect.socket(socket,\"$!url:$!port\");");

        if !$proclaim {
            $resCode = $resCode.subst(/ ^^ \h* ['cat' | 'print'] .*? $$ /, ''):g
        }

        $resCode
    };



    #============================================================
    # process setup-lines
    #============================================================

    method process-setup-lines($setup-lines is copy) {
        # Prep code
        $setup-lines = do given $setup-lines {
            when $_.isa(Whatever) { <Matrix tidyverse purrr magrittr> }
            when $_ ~~ Str { [$_,] }
        };

        die 'The argument package is expected to be a string, a list of strings, or Whatever.'
        unless !$setup-lines || $setup-lines ~~ List && $setup-lines.all ~~ Str;

        my Str $prepCode = '';
        if $setup-lines {
            $prepCode = $setup-lines.map({ 'library(' ~ $_ ~ ')' }).join(";\n");
        }

        return $prepCode;
    }
}