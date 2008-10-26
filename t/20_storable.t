#!perl -w

use strict;
use Test::More tests => 21;

use Storable qw(freeze thaw dclone);

{
	package Foo;
	use Scion::Sugar;

	has foo => (
		storage => \my @foo_of,
	);

	sub foo{
		my($self) = @_;
		return $foo_of[$$self];
	}
}
{
	package Bar;
	use Scion::Sugar -base => qw(Foo);

	has bar => (
		storage => \my @bar_of
	);

	sub bar{
		my($self) = @_;
		return $bar_of[$$self];
	}

	my $count = 0;
	sub count{ $count }

	sub BUILD{
		$count++;
	}
	sub DEMOLISH{
		$count--;
	}
}
is(Bar->count, 0, 'object count');

{
	my($x, $y, $z);

	# for Foo (a class without BUILD/DEMOLISH)

	$x = Foo->new(foo => 'foo');
	is $x->foo, 'foo', 'before cloning';
	$y = dclone($x);
	isa_ok $y, 'Foo';
	is $y->foo, 'foo', 'after cloning';

	is_deeply $x->get_property_map, $y->get_property_map, 'propety map';

	$y->set_foo('foo of y');
	is $x->foo, 'foo';
	is $y->foo, 'foo of y';

	# fo Bar (a class with BUILD/DEMOLISH)

	$x = Bar->new(foo => 'foo', bar => 'bar');

	is $x->foo, 'foo', 'before cloning';
	is $x->bar, 'bar';
	is $x->count, 1, 'object count';

	$y = dclone($x);

	isa_ok $y, 'Bar';

	is_deeply $y->get_property_map(), $x->get_property_map(), 'dclone';

	is $x->count, 2, 'object count';

	$y->set_foo('cloned foo');
	$y->set_bar('cloned bar');

	is $x->foo, 'foo', 'after cloning: original object is not touched';
	is $x->bar, 'bar';

	is $y->foo, 'cloned foo', 'cloned object';
	is $y->bar, 'cloned bar';

	$z = thaw(freeze($x));

	isa_ok $z, 'Bar';

	is_deeply $z->get_property_map, $x->get_property_map, 'thaw(freeze(.))';

	is $z->count, 3, 'object count';
}

is(Bar->count, 0);
