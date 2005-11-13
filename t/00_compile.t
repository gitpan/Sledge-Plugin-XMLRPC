use strict;
use Test::More tests => 1;

# dummy methods for success to compile.
sub mk_classdata {}
sub register_hook {}
sub _xmlrpc_parser {}
BEGIN { use_ok 'Sledge::Plugin::XMLRPC' }
