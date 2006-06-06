#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Email::Handle' );
}

diag( "Testing Email::Handle $Email::Handle::VERSION, Perl $], $^X" );
