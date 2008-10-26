#!perl -w
use strict;

use Test::More tests => 48;

use Scion::Object;

BEGIN{
	package BaseClass;
	use Scion::Object -base;

	__PACKAGE__->meta->define_properties(
		foo => {
			storage => \my @foo_of,
		},
		bar => {
			storage => \my @bar_of,
		},
	);
}
BEGIN{
	package DerivedClass;
	use Scion::Object -base => qw(BaseClass);

	__PACKAGE__->meta->define_properties(
		baz => {
			storage => \my @baz_of,
		},
	);
}
BEGIN{
	package MoreDerivedClass;
	use Scion::Object -base => qw(DerivedClass);

	__PACKAGE__->meta->define_properties(
		bax => {
			storage => \my @bax_of,
		},
	);

	__PACKAGE__->meta->make_immutable();
}


for my $i(1 .. 3){
	my $x = DerivedClass->new( foo => 10, bar => 20, baz => 30 );
	my $y = BaseClass->new( foo => 100, bar => 200);

	ok $x && $y, "Scion::Object creation($i)";

	isa_ok $x, 'DerivedClass';
	isa_ok $y, 'BaseClass';

	is $x->get_foo, 10, 'DerivedClass getter';
	is $x->get_bar, 20;
	is $x->get_baz, 30;

	$x->set_foo(42);
	is $x->get_foo(), 42, 'DerivedClass setter';
	is $x->set_foo(43)->get_foo(), 43, 'DerivedClass setter (chained)';

	is $y->get_foo, 100, 'BaseClass getter';
	is $y->get_bar, 200;

	is $y->set_foo(300)->get_foo(), 300, 'DerivedClass setter (chained)';
}

for my $i(1 .. 2){
	my $x = MoreDerivedClass->new(
		foo => 10+$i,
		bar => 20+$i, 
		baz => 30+$i,
		bax => 40+$i,
	);

	isa_ok $x, 'MoreDerivedClass', "object($i)";

	is $x->get_foo, 10+$i, 'getter';
	is $x->get_bax, 40+$i, 'getter';

	$x->set_bax(-$x->get_bax);
	is $x->get_bax, -(40+$i), 'setter';

	my $map = $x->get_property_map();

	is_deeply $map, {
		'BaseClass::foo'        => 10+$i,
		'BaseClass::bar'        => 20+$i,
		'DerivedClass::baz'     => 30+$i,
		'MoreDerivedClass::bax' => -(40+$i),
	}, 'get_property_map()';
}

my $x = MoreDerivedClass->new(foo => 1, bar => 2, baz => 3, bax => 4);

is $x->meta->name, 'MoreDerivedClass', 'meta->name';
is(DerivedClass->meta->name, 'DerivedClass', 'meta->name');

is_deeply eval('my ' .$x->dump), {qw(
	BaseClass::foo 1
	BaseClass::bar 2
	DerivedClass::baz 3
	MoreDerivedClass::bax 4
)}, '$object->dump()';

is_deeply
	[BaseClass->meta->get_property_names],
	[qw(BaseClass::foo BaseClass::bar)],
		'BaseClass->meta->get_property_names';

is_deeply
	[MoreDerivedClass->meta->get_property_names],
	[qw(BaseClass::foo BaseClass::bar DerivedClass::baz MoreDerivedClass::bax)],
		'MoreDerivedClass->meta->get_property_names (dupliation removed)';

