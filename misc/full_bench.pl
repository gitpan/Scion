#!perl -w
use strict;
use Benchmark qw(:all);
use Carp ();

BEGIN{
	package Object::Basic;
	sub BUILD{
		my $self = shift;
		while(my($prop, $value) = splice @_, 0, 2){
			my $prop_accessor = $self->can($prop);
			if($prop_accessor){
				$self->$prop_accessor($value);
			}
			else{
				Carp::croak(qq{Invalid property "$prop"});
			}
		}
	}

	package Object::HashRef;
	use base qw(Object::Basic Class::Accessor::Fast);

	__PACKAGE__->mk_accessors(qw(foo bar baz));

	sub new{
		my $self = bless {} => shift;

		$self->BUILD(@_);
		return $self;
	}

	package Object::ArrayRef;
	use base qw(Object::Basic);
	use constant {
		_Foo => 0,
		_Bar => 1,
		_Baz => 2,
	};
	sub new{
		my $self = bless [] => shift;

		$self->BUILD(@_);
		return $self;
	}
	sub foo{
		my $self = shift;
		$self->[_Foo] = shift if @_;
		return $self->[_Foo];
	}
	sub bar{
		my $self = shift;
		$self->[_Bar] = shift if @_;
		return $self->[_Bar];
	}
	sub baz{
		my $self = shift;
		$self->[_Baz] = shift if @_;
		return $self->[_Baz];
	}
	

	package Object::FieldHash;
	use base qw(Object::Basic);
	use Hash::Util::FieldHash qw(:all);

	fieldhashes \my(%foo, %bar, %baz);
	sub new{
		my $self = bless \do{ my $o } => shift;

		$self->BUILD(@_);
		return $self;
	}
	sub foo{
		my $self = shift;
		$foo{$self} = shift if @_;
		return $foo{$self};
	}
	sub bar{
		my $self = shift;
		$bar{$self} = shift if @_;
		return $bar{$self};
	}
	sub baz{
		my $self = shift;
		$baz{$self} = shift if @_;
		return $baz{$self};
	}
	sub dump_all{
		use DDS;
		Dump([\%foo, \%bar, \%baz]);
	}

	package Object::IdArray;
	use base qw(Object::Basic);
	my $idx = -1;
	my @pool;
	my(@foo, @bar, @baz);
	sub new{
		my $self = bless \do{ my $idx = pop(@pool) // ++$idx }
			=> shift;
		$self->BUILD(@_);
		return $self;
	}
	sub foo{
		my $self = shift;
		$foo[$$self] = shift if @_;
		return $foo[$$self];
	}
	sub bar{
		my $self = shift;
		$bar[$$self] = shift if @_;
		return $bar[$$self];
	}
	sub baz{
		my $self = shift;
		$baz[$$self] = shift if @_;
		return $baz[$$self];
	}
	sub DESTROY{
		my $self = shift;

		undef $foo[$$self];
		undef $bar[$$self];
		undef $baz[$$self];

		push @pool, $$self;
		return;
	}
	sub dump_all{
		use DDS;
		Dump [\(@foo, @bar, @baz)];
	}

	package Object::Scion;
	use Scion::Sugar -base;

	define_properties(
		foo => {
			storage => \my @foo_of,
		},
		bar => {
			storage => \my @bar_of,
		},
		baz => {
			storage => \my @baz_of,
		},
	);

	#__PACKAGE__->meta->make_immutable();

	package Object::Moose;
	use Moose;

	has foo => (
		is => 'rw',
	);
	has bar => (
		is => 'rw',
	);
	has baz => (
		is => 'rw',
	);

	__PACKAGE__->meta->make_immutable();
}


print "Construction and destruction\n";

my @args = (foo => 42, bar => 'hoge', baz => {});

my $hashref = Object::HashRef->new(@args);
my $arrayref= Object::ArrayRef->new(@args);
my $fieldhash  = Object::FieldHash->new(@args);
my $idarray = Object::IdArray->new(@args);
my $scion   = Object::Scion->new(@args);
my $moose   = Object::Moose->new(@args);

cmpthese timethese -1 => {
	HashRef => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::HashRef->new(@args);
		}
	},
	ArrayRef => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::ArrayRef->new(@args);
		}
	},
	
	FieldHash => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::FieldHash->new(@args);
		}
	},
	IdArray => sub{
		my @list;
		for(1 .. 10){
			push @list, Object::IdArray->new(@args);
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
	HashRef => sub{
		for(1 .. 10){
			$hashref->foo($_);
			my $x = $hashref->bar;
			my $y = $hashref->baz;
		}
	},
	ArrayRef => sub{
		for(1 .. 10){
			$arrayref->foo($_);
			my $x = $arrayref->bar;
			my $y = $arrayref->baz;
		}
	},

	FieldHash => sub{
		for(1 .. 10){
			$fieldhash->foo($_);
			my $x = $fieldhash->bar;
			my $y = $fieldhash->baz;
		}
	},
	IdArray => sub{
		for(1 .. 10){
			$idarray->foo($_);
			my $x = $idarray->bar;
			my $y = $idarray->baz;
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
