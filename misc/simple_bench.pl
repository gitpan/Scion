#!perl -w
use strict;
use Benchmark qw(:all);
use Carp ();

BEGIN{
	print "Simple benchmark: Class::Accessor::Fast, Moose and Scion\n";
}

BEGIN{
	package Object::ClassAccessor;
	use base qw(Class::Accessor::Fast);

	__PACKAGE__->mk_accessors(qw(foo bar baz));

	sub new{
		my $self = bless {} => shift();
		$self->BUILD(@_);
		return $self;
	}
	sub BUILD{
		my $self = shift;
		%{$self} = @_;
		return;
	}

}
BEGIN{
	package Object::Moose;
	use Moose;

	has foo => (
		is => 'rw',
		required => 1,
	);
	has bar => (
		is => 'rw',
		required => 1,
	);
	has baz => (
		is => 'rw',
		required => 1,
	);

	__PACKAGE__->meta->make_immutable();
}
BEGIN{
	package Object::Scion;
	use Scion::Sugar;

	has foo => (
		required => 1,
	);

	has bar => (
		required => 1,
	);

	has baz => (
		required => 1,
	);

	__PACKAGE__->meta->make_immutable();
}

print "Construction and destruction\n";

my @args = (foo => 42, bar => 'bar', baz => 'baz');

my $hashref = Object::ClassAccessor->new(@args);
my $scion   = Object::Scion->new(@args);
my $moose   = Object::Moose->new(@args);

cmpthese timethese -1 => {
	ClassAccessor => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::ClassAccessor->new(@args);
		}
	},
	Scion => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::Scion->new(@args);
		}
	},

	Moose => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::Moose->new(@args);
		}
	},
};

print "Accesses\n";

cmpthese timethese -1 => {
	ClassAccessor => sub{
		for(1 .. 10){
			$hashref->foo($_);
			my $x = $hashref->bar;
			my $y = $hashref->baz;
		}
	},
	Scion => sub{
		for(1 .. 10){
			$scion->set_foo($_);
			my $x = $scion->get_bar;
			my $y = $scion->get_baz;
		}
	},
	Moose => sub{
		for(1 .. 10){
			$moose->foo($_);
			my $x = $moose->bar;
			my $y = $moose->baz;
		}
	},
};
