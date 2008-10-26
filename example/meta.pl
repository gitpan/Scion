#!perl -w
# foo.pl - the most simple Scion class
use strict;
BEGIN{
	package
		Foo;
	use Scion::Sugar;

	define_properties
		x => {},
		y => {
			is       => 'ro',
			getter   => 'yy',
			validate => sub{ ref($_) eq 'ARRAY' },
			default  => sub{ ['the default value of Foo::y'] },
			storage  => \my @y_of,
		},
	;
}
BEGIN{
	package
		Bar;
	use Scion::Sugar -base => qw(Foo);

	define_properties(
		y => {
			setter  => '',
			getter  => '',
			required => 0,
			default  => 'the default value of Bar::y',
			storage  => \my @y_of,
		},

		z => {
			private => 1,
			default => 'the default value of Bar::z',
		},
	);
}

my $x = Bar->new(
	x => 'the value of x',

	'Foo::y' => ['the value of Foo::y'],
);


$x->meta->dump();

$x->dump();
