use Test::More tests => 3;

BEGIN {
	use_ok( 'Scion' );
	use_ok( 'Scion::Object' );
	use_ok( 'Scion::Sugar' );
}

diag( "Testing Scion $Scion::VERSION" );
