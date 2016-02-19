use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;

use Plack::Middleware::StackTrace::LinkedSource;

{
    my $traceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { die "orz" }, no_print_errors => 1);
    my $app = sub {
        my $env = shift;
        my $ret = $traceapp->($env);
        return $ret;
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $req = GET "/";
        $req->header(Accept => "text/html,*/*");
        my $res = $cb->($req);

        ok $res->is_error;
        is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
        like $res->content, qr/<title>Error: orz/;
        like $res->content, qr!<a href="/source/Try/Tiny\.pm\#L\d+">.+[/\\]Try[/\\]Tiny\.pm line \d+</a>!;
    }
}

{
    my $sourceapp = Plack::Middleware::StackTrace::LinkedSource->wrap(sub { [200, [], ["OK"]] });
    my $app = sub {
        my $env = shift;
        return $sourceapp->($env);
    };
    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/source/Try/Tiny.pm");
        is $res->code, 200;
        like $res->content, qr!<title>Try/Tiny\.pm!;
    }
}

done_testing;
