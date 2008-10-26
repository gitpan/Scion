#!perl -w
use strict;
use Benchmark qw(:all);
use Carp ();

BEGIN{
	package A::Object::InsideOut;
	use Object::InsideOut;

	my @foo_of :Field :Standard(foo) :Arg(name => 'foo');
	my @bar_of :Field :Standard(bar) :Arg(name => 'bar');
	my @baz_of :Field :Standard(baz) :Arg(name => 'baz');
}
BEGIN{
	package A::Class::InsideOut;
	use Class::InsideOut qw(:all);

	public foo => my %foo_of;
	public bar => my %bar_of;
	public baz => my %baz_of;
}
BEGIN{
	package A::Scion;
	use Scion::Sugar -base;

	define_properties(
		foo => {
			storage => \my @foo_of,
		},
		bar =>{
			storage => \my @bar_of,
		},
		baz => {
			storage => \my @baz_of,
		},
	);
}

print "Construction and destruction\n";

my @args = (foo => 42, bar => 'bar', baz => 'baz');

my $a = A::Object::InsideOut->new({@args});
my $b = A::Class::InsideOut->new(@args);
my $c = A::Scion->new(@args);


#use B::Deparse;
#my $dp = B::Deparse->new();
#foreach my $x($a, $b, $c){
#	my $m = $x->can('get_foo') || $x->can('foo');
#	print ref($x), ' ', $dp->coderef2text($m);
#}
#


cmpthese timethese -1 => {
	ref($a) => sub{
		my @list;
		for(1 .. 10){
			push @list, ref($a)->new(@args);
		}
	},
	ref($b) => sub{
		my @list;
		for(1 .. 10){
			push @list, ref($b)->new(@args);
		}
	},

	ref($c) => sub{
		my @list;
		for(1 .. 10){
			push @list, ref($c)->new(@args);
		}
	},
};

print "Accesses\n";

sub assert{
	if(!$_[0]){
		Carp::croak('Assertion failed');
	}
}

cmpthese timethese -1 => {
	ref($a) => sub{
		for(1 .. 10){
			$a->set_foo($_);
			assert($a->get_bar eq 'bar');
			assert($a->get_baz eq 'baz');
		}
	},
	ref($b) => sub{
		for(1 .. 10){
			$b->foo($_);
			assert($b->bar eq 'bar');
			assert($b->baz eq 'baz');
		}
	},
	ref($c) => sub{
		for(1 .. 10){
			$c->set_foo($_);
			assert($c->get_bar eq 'bar');
			assert($c->get_baz eq 'baz');
		}
	},
};
