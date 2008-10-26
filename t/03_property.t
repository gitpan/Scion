#!perl -w

use strict;

use Test::More tests => 31;
use Test::Exception;

use Scion::Object;

BEGIN{
	package A;
	use Scion::Sugar;

	has xyz => (
		default  => 'A::xyz',

		validate => sub{ not ref $_ },
	);

	package B;
	use Scion::Sugar -base => qw(A);

	has xyz => (
		default => sub{ 'B::xyz' },
	);

	package C;
	use Scion::Sugar -base => qw(A);

	has xyz => (
		default => sub{ 'C::xyz' },
	);

	package D;
	use Scion::Sugar -base => qw(B C);

	has foo => (
		required => 1,

		getter => 'get',
		setter => 'set',
	);

	package E;
	use Scion::Sugar -base;

	has foo => (
		is => 'rw',
		getter => 'foo',
		setter => 'foo',

		validate => sub{ ref($_) eq 'ARRAY' },
	);

	has bar => (
		is => 'ro',
		getter => 'bar',
	);

	has baz => (
		private => 1,
		default => 'the value of baz',
		storage => \my @baz_of,
	);

	sub _baz{
		my $self = shift;
		return $baz_of[$$self];
	}

	define_properties rw_novalidate => {
		getter => 'rw_novalidate',
		setter => 'rw_novalidate',
	};

	register_properties \my(@a_of, @b_of);

	sub _a{
		my $self = shift;
		$a_of[$$self] = shift if @_;
		return $a_of[$$self];
	}
	sub _b{
		my $self = shift;
		$b_of[$$self] = shift if @_;
		return $b_of[$$self];
	}
}

is(A->new->get_xyz, 'A::xyz', 'default');
is(B->new->get_xyz, 'B::xyz');
is(C->new->get_xyz, 'C::xyz');

is(D->new(foo => 1)->get_xyz, 'C::xyz', 'inherited');


throws_ok {
	A->new(xyz => []);
} qr/Validation failed/;
throws_ok{
	A->new->set_xyz([]);
} qr/Validation failed/;
lives_ok{
	A->new(xyz => 1);
} 'validation passed';
lives_ok{
	A->new->set_xyz(1);
} 'validation passed';

lives_ok{
	D->new(foo => 1);
} 'required => 1';
throws_ok{
	D->new();
} qr/Necessary/;

throws_ok {
	B->new(xyz => 10);
} qr/Ambiguous/;

throws_ok {
	C->new(xyz => 10);
} qr/Ambiguous/;

throws_ok {
	D->new(xyz => 10, foo => 1);
} qr/Ambiguous/;

my $x = D->new(foo => 42);

is $x->get(),          42, 'getter';
is $x->set(32)->get(), 32, 'setter';

$x = E->new(foo => [2], bar => 42, baz => 99);

is_deeply $x->foo, [2], q{is => 'rw' with validator (get)};
$x->foo(20, 30);
is_deeply $x->foo, [20, 30], q{is => 'rw' with validator (set)};

is $x->bar, 42, q{is => 'ro'};
throws_ok{
	$x->bar(2);
} qr/read-only/;

throws_ok{
	$x->get_baz();
} qr/Can't locate object method/;
throws_ok{
	$x->set_baz(10);
} qr/Can't locate object method/;
throws_ok{
	$x->baz();
} qr/Can't locate object method/;
is $x->_baz, 'the value of baz', 'private => 1';


$x->rw_novalidate(42);
is $x->rw_novalidate(), 42, 'rw without validator';


$x->_a('a');
$x->_b('b');

is $x->_a, 'a', 'register_properties (anonymous property)';
is $x->_b, 'b', 'register_properties (anonymous property)';

throws_ok{
	package E;
	has x => (
		is => (),
	);
} qr/Odd number/;

throws_ok{
	package E;
	has x => (
		is => 'foo',
	);
} qr/Unrecognized property restrict mode/;

throws_ok{
	package E;
	has x => (
		storage => \my %hash,
	);
} qr/Property storage .+ must be an ARRAY/;

throws_ok{
	package E;
	has x => (
		default => [],
	);
} qr/References are not allowed/;

throws_ok{
	package E;

	has x => (
		required => 1,
		default  => 'foo',
	);
} qr/Exclusive option/;

#Scion->dump_all();
