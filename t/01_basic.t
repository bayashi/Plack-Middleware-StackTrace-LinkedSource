use strict;
use warnings;
use Test::More;

use Plack::Middleware::StackTrace::LinkedSource;

can_ok 'Plack::Middleware::StackTrace::LinkedSource', qw/new/;

# write more tests

done_testing;
