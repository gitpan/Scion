#!perl -w

use strict;

use Test::More tests => 9;
use Test::Exception;

use Scion::Object;

BEGIN{
	package Foo;
	use Scion::Object -base => qw(Scion::Object);

	__PACKAGE__->meta->define_properties(
		bar => {},
	);

	package Bar;
	use Scion::Object -base => qw(Scion::Object);
}

throws_ok{
	Foo->meta->define_properties(
		foo => [],
	);
} qr/must be a HASH reference/;
throws_ok{
	Foo->meta->define_properties(qw(Foo Bar));
} qr/must be a HASH reference/;

throws_ok{
	Scion::Object->import(-foo => 'bar');
} qr/Invalid import command/;

my $x = Foo->new(bar => 10);

throws_ok{
	$x->new();
} qr/Cannot call new\(\) as an instance method/;


throws_ok{
	Foo->new(1);
} qr/Odd number/;


throws_ok{
	Scion::meta(undef);
} qr/Class name not specified/;

throws_ok{
	Foo->meta->get_property_map_of(Bar->new());
} qr/Validation failed/, 'Fatal: $meta->get_property_map_of($unmatched_object)';

throws_ok{
	Foo->meta->get_property_map_of('Foo');
} qr/Validation failed/, 'Fatal: $meta->get_property_map_of("Foo")';

throws_ok{
	Foo->meta->get_property_map_of(undef);
} qr/Validation failed/, 'Fatal: $meta->get_property_map_of(undef)';

