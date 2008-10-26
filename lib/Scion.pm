package Scion;

use 5.008_001;
use strict;
use warnings;
#use warnings::unused;

our $VERSION = '0.01';

use Sub::Name ();
use Data::Util ();

use Carp qw(confess);

#use Smart::Comments;

use Exporter qw(import);
our @EXPORT_OK = qw(meta scion confess);
our %EXPORT_TAGS = (
	std => \@EXPORT_OK,
);

BEGIN{
	require MRO::Compat if $] < 5.010;
}

# meta class properties
my $global_meta_id = -1;

my(
	@id_ref_of,
	@pool_of,

	@prop_storage_of, # the storages of properties of a class
	@prop_fqn_of,     # fqn: full qualified name
	@prop_name_of,
	@prop_validator_of,
	@prop_necessity_of,
	@prop_ambiguity_of,
	@prop_privacy_of,
#	@getter_of,
#	@setter_of,

	@name_of, # class name
);

my $DEFAULT_ID = 0;

# meta object storage
my %meta_of;

#===================
# class methods
#===================

# it may be overrided in Scion subclass
sub scion(){__PACKAGE__ }

sub meta{
	confess('Class name not specified for Scion::meta()')
		unless defined $_[0];

	return $meta_of{ref($_[0]) || $_[0]} || do{
		my($object) = @_;
		my $metaclass = $object->can('scion') ? $object->scion : scion();
		Data::Util::instance(
			$metaclass->_init_meta(ref($object) || $object),
			scion()
		);
	};
}


sub _init_meta{
	my($metaclass, $class) = @_;

	my $meta_id = ++$global_meta_id;

	my $meta = bless \$meta_id, $metaclass;
	Internals::SvREADONLY($meta_id, 1); # lock

	$name_of[$meta_id]  = $class;

	my $object_id = 0;
	$id_ref_of[$meta_id] = \$object_id;
	$pool_of[$meta_id]    = [];

	$meta_of{$class} = $meta;

	# meta properties
	$prop_storage_of[$meta_id]   = [];
	$prop_fqn_of[    $meta_id]   = [];
	$prop_name_of[   $meta_id]   = [];

	$prop_validator_of[$meta_id] = [];
	$prop_necessity_of[$meta_id] = [];
	$prop_ambiguity_of[$meta_id] = [];
	$prop_privacy_of  [$meta_id] = [];

	mro::set_mro($class, 'c3'); # always 'C3'

	$meta->update();

	return $meta;
}


#===================
# instance methods
#===================

sub name{
	return $name_of[ ${ $_[0] } ];
}


sub new_object{
	my($meta, $param) = @_;

	my $object_id_slot;
	my $object = bless \$object_id_slot, $name_of[$$meta];

	$meta->initialize_object($object, $param);
	return $object;
}

sub initialize_object{
	my($meta, $object, $param) = @_;

	Data::Util::instance($object, $name_of[$$meta]);

	defined $$object
		and confess 'The object is already initialized';

	$$object = pop(@{ $pool_of[$$meta] }) || ++${$id_ref_of[$$meta]};
	Internals::SvREADONLY($$object, 1); # lock

	my $fqns_ref     = $prop_fqn_of[$$meta];
	my $names_ref    = $prop_name_of[$$meta];
	my $storages_ref = $prop_storage_of[$$meta];

	my $validators_ref  = $prop_validator_of[$$meta];
	my $ambiguities_ref = $prop_ambiguity_of[$$meta];
	my $necessities_ref = $prop_necessity_of[$$meta];
	my $privacies_ref   = $prop_privacy_of[$$meta];

	local $_;

	for(my $i = 0; $i < @{$fqns_ref}; $i++){
		if($privacies_ref->[$i]){
			$_ = undef;
		}
		elsif(defined($_ = $param->{$fqns_ref->[$i]})){ # full qualified name
			; # noop
		}
		elsif(defined($_ = $param->{$names_ref->[$i]})){ # unqualified name
			$ambiguities_ref->[$i] > 1
				and confess(
					qq{Ambiguous property name "$names_ref->[$i]" supplied\n},
					qq{(You should use its full qualified name like "$fqns_ref->[$i]")},
				);
		}
		else{ # parameter not supplied
			$necessities_ref->[$i]
				and confess qq{Necessary property "$fqns_ref->[$i]" not supplied};
		}

		unless(defined $_){
			$_ = $storages_ref->[$i][$DEFAULT_ID];

			$_ = $_->() if ref $_;
		}

		if(defined $_){
			_validation_failed($meta, $fqns_ref->[$i], $_)
				if $validators_ref->[$i] and not $validators_ref->[$i]->();

			$storages_ref->[$i][$$object] = $_;
		}
	}

	return;
}

sub deinitialize_object{
	my($meta, $object) = @_;
	Data::Util::instance($object, $name_of[$$meta]);

	foreach my $storage_ref(@{ $prop_storage_of[ $$meta ] }){
		$storage_ref->[$$object] = undef;
	}

	push @{$pool_of[$$meta]}, $$object;

	Internals::SvREADONLY($$object, 0); # unlock
	undef $$object;

	return;
}

# inherit meta-properties form the superclasses and update the ambiguities
sub update{
	my($meta) = @_;

	my $storages_ref = $prop_storage_of[$$meta];
	my $fqns_ref  = $prop_fqn_of[$$meta];
	my $names_ref = $prop_name_of[$$meta];

	my $validators_ref  = $prop_validator_of[$$meta];
	my $necessities_ref = $prop_necessity_of[$$meta];
	my $ambiguities_ref = $prop_ambiguity_of[$$meta];
	my $privacies_ref   = $prop_privacy_of  [$$meta];

	my $super_meta_id;

	# inherits meta properties from the superclasses
	foreach my $class(reverse $meta->get_superclasses){
		my $super_meta = meta($class);

		push @{$fqns_ref},  @{$prop_fqn_of[$$super_meta]};
		push @{$names_ref}, @{$prop_name_of[$$super_meta]};
		push @{$storages_ref}, @{$prop_storage_of[$$super_meta]};

		push @{$validators_ref},  @{$prop_validator_of[$$super_meta]};
		push @{$necessities_ref}, @{$prop_necessity_of[$$super_meta]};
		push @{$ambiguities_ref}, @{$prop_ambiguity_of[$$super_meta]};
		push @{$privacies_ref},   @{$prop_privacy_of[  $$super_meta]};

		if(!defined($super_meta_id) && @{$prop_fqn_of[$$super_meta]}){
			$super_meta_id = $$super_meta;
		}
	}

	if(defined $super_meta_id){ # inherit "id" and "pool"
		$id_ref_of[$$meta] = $id_ref_of[ $super_meta_id ];
		$pool_of[$$meta]   = $pool_of[$super_meta_id];
	}

	# normalize duplication
	{
		my %seen;
		my $i = 0;
		while($i < @{$fqns_ref}){
			if($seen{ $storages_ref->[$i] }++){ # it's duplicated property
				splice @{$fqns_ref},        $i, 1;
				splice @{$names_ref},       $i, 1;
				splice @{$storages_ref},    $i, 1;
				splice @{$validators_ref},  $i, 1;
				splice @{$necessities_ref}, $i, 1;
				splice @{$ambiguities_ref}, $i, 1;
				splice @{$privacies_ref},   $i, 1;
			}
			else{
				$i++;
			}
		}
	}

	# calculate ambiguities
	my %count;
	$count{$_}++ for @{$names_ref};

	for(my $i = 0; $i < @{$names_ref}; $i++){
		$ambiguities_ref->[$i] = $count{ $names_ref->[$i] };
	}

	return;
}


# meta->define_properties(
#    prop_name1 => {
#        is       => undef || 'rw' || 'ro',
#        storage  => [] || \my @prop1_storage,
#        validate => undef || sub{ /^\w+$/ },
#        setter   => 'set_prop_name1' || '' || ...,
#        getter   => 'get_prop_name1' || '' || ...,
#        required => 0 || 1,
#    },
#    prop_name2 => { ... },
#    ...
#);

my $anon_prop = 0;

sub define_properties{
	my $meta = shift;

	confess('Odd number of options for define_properties()')
		if @_ % 2;

	my $class = $name_of[$$meta];

	my $fqns_ref      = $prop_fqn_of[$$meta];
	my $names_ref     = $prop_name_of[$$meta];
	my $storages_ref  = $prop_storage_of[$$meta];

	my $validators_ref  = $prop_validator_of[$$meta];
	my $necessities_ref = $prop_necessity_of[$$meta];
	my $ambiguities_ref = $prop_ambiguity_of[$$meta];
	my $privacies_ref   = $prop_privacy_of[  $$meta];

	while(my($prop_name, $config) = splice @_, 0, 2){
		$prop_name = ++$anon_prop unless defined $prop_name;

		Data::Util::is_hash_ref($config)
			or confess(qq{Property config for "$prop_name" must be a HASH reference});

		my $storage_ref = $config->{storage} || [];

		my $getter    = $config->{getter};
		my $setter    = $config->{setter};

		my $validator = $config->{validate};
		my $necessity = $config->{required};
		my $default   = $config->{default};
		my $privacy   = $config->{private};

		# set defaults if necessary

		$getter = 'get_' . $prop_name unless defined $getter;
		$setter = 'set_' . $prop_name unless defined $setter;

		#$validator = undef unless defined $validator;
		#$necessity = 0     unless defined $necessity;
		#$default   = undef unless defined $default;


		if(defined(my $is = $config->{is})){
			if($is eq 'ro'){
				$setter = undef;
			}
			elsif($is eq 'rw'){
				;
			}
			else{
				confess(qq{Unrecognized property restrict mode "$is"\n}
					.q{(It must be 'rw' or 'ro'});
			}
		}

		if($privacy){
			$necessity
				and confess(qq{Exclusive options ("required" vs. "private") supplied for $prop_name configuration});
			$getter = $setter = undef;
		}
	
		# validations

		Data::Util::is_array_ref($storage_ref)
			or confess(qq{Property storage for "$prop_name" must be an ARRAY reference});

		if(ref($default) && !Data::Util::is_code_ref($default)){
			confess(qq{References are not allowed as default values\n},
				qq{you must wrap the default of "$prop_name" in a CODE reference});
		}

		if(defined $default){
			$necessity
				and confess(qq{Exclusive options ("default" vs. "required") supplied for $prop_name configuration});

			if(not ref($default) and $validator){
				local $_ = $default;
				_validation_failed($meta, $prop_name, $_) unless $validator->();
			}
		}

		# installs
		$storage_ref->[$DEFAULT_ID] = $default;

		push @{$fqns_ref},  $class.'::'.$prop_name;
		push @{$names_ref}, $prop_name;
		push @{$storages_ref}, $storage_ref;

		push @{$validators_ref},  $validator;
		push @{$necessities_ref}, $necessity;
		push @{$ambiguities_ref}, 1;
		push @{$privacies_ref},   $privacy;

		$meta->_install_accessor($getter, $setter, $storage_ref, $validator)
			if $getter || $setter;
	}

	$meta->update();
	return;
}

sub _install_accessor{
	my($meta, $getter, $setter, $storage_ref, $validator) = @_;

	my $class = $name_of[$$meta];
	my $method;

	if($getter and $setter and $getter eq $setter){

		if($validator){
			$method = sub :method{
				my $id = ${shift()};

				if(@_){ # setter
					local $_ = ( @_ == 1 ? $_[0] : [@_] );
					_validation_failed($meta, $setter, $_) unless $validator->();

					$storage_ref->[$id] = $_;
				}

				return $storage_ref->[$id];
			}

		}
		else{
			$method = sub :method{
				my $id = ${shift()};
				if(@_){
					$storage_ref->[$id] = ( @_ == 1 ? $_[0] : [@_]);
				}
				return $storage_ref->[$id];
			};
		}

		$meta->install_subroutine($setter, $method);
		return;
	}

	if($getter){
		$meta->install_subroutine(
			$getter => sub :method{
				confess(qq{Too many arguments for "$getter" on $class\n},
					qq{(it is a read-only accessor)})
						if @_ > 1;
				$storage_ref->[ ${ $_[0] } ];
		});
	}

	if($setter){
		if($validator){
			$method = sub :method{
				confess(qq{Not enough arguments for "$setter" on $class})
					if @_ < 2;

				my $self = shift;

				local $_ = ( @_ == 1 ? $_[0] : [@_] );
				_validation_failed($meta, $setter, $_) unless $validator->();

				$storage_ref->[ ${$self} ] = $_;
				return $self;
			};
		}
		else{
			$method = sub :method{
				confess(qq{Not enough arguments for "$setter" on $class})
					if @_ < 2;

				$storage_ref->[ ${ $_[0] } ] = $_[1];
				return $_[0];
			};
		}

		$meta->install_subroutine($setter => $method);
	}
	return;
}


sub install_subroutine{
	my($meta, $name, $entity) = @_;

	my $class = $name_of[$$meta];

	Sub::Name::subname($class . '::' . $name, $entity);

	### install_subroutine: [$class, $name]

	no strict 'refs';

	*{$class . '::' . $name} = $entity;

	return;
}


sub get_superclasses{
	my($meta) = @_;

	my $linear_isa = mro::get_linear_isa($name_of[$$meta]);
	return @{$linear_isa}[1 .. $#{$linear_isa}];
}

# NOTE:
#  Inconsistent hierarchy of C3
#
#             A'
#            /
#      A    B
#       \ .
#        C
#
#  (C is this class, and B will be a base class)
#
#  In such case, A (the parent of C) will be removed from @C::ISA.
sub add_superclasses{
	my $meta = shift;
	return unless @_;

	my $class = $name_of[$$meta];
	my $isa = do{ no strict 'refs'; \@{$class . '::ISA'} };

	foreach my $base(grep{ not $class->isa($_) } @_){
		@{$isa} = ($base, (grep{ !$base->isa($_) } @{$isa}));
	}

	$meta->update();
	return;
}

sub find_all_method_by_name{
	my($meta, $method) = @_;

	my @methods;
	foreach my $class(@{ mro::get_linear_isa( $name_of[$$meta] ) }){
		my $stash = Data::Util::get_stash($class) or next;

		my $gv = $stash->{$method};

		if(Data::Util::is_glob_ref(\$gv) && *{$gv}{CODE}){
			push @methods, *{$gv}{CODE};
		}
	}
	return @methods;
}

sub make_immutable{
	# todo?

	return 1;
}

sub get_property_map_of{
	my($meta, $object) = @_;

	Data::Util::instance($object, $name_of[$$meta]);

	my %map;

	my $fqns_ref     = $prop_fqn_of[$$meta];
	my $storages_ref = $prop_storage_of[$$meta];

	for(my $i = 0; $i < @{$fqns_ref}; $i++){
		$map{ $fqns_ref->[$i] } = $storages_ref->[$i][ $$object ];
	}
	return \%map;
}
sub get_property_names{
	my($meta) = @_;
	return @{ $prop_fqn_of[ $$meta ] };
}


sub _validation_failed{
	my($meta, $prop_name, $value) = @_;

	local $Carp::CarpLevel = $Carp::CarpLevel + 1;
	confess sprintf 'Validation failed: for "%s" on %s with value %s',
		$prop_name, $name_of[$$meta], Data::Util::neat($value);
}

# for debugging

sub dump{
	my($meta) = @_;

	my @properties;
	my %meta = (
			name => $name_of[$$meta],
			pool => $pool_of[$$meta],

			properties => \@properties,
	);
	for(my $i = 0; $i < @{$prop_fqn_of[$$meta]}; $i++){
		push @properties, {
			fq_name   => $prop_fqn_of[$$meta][$i],
			name      => $prop_name_of[$$meta][$i],
			storage   => $prop_storage_of[$$meta][$i],
			ambiguity => $prop_ambiguity_of[$$meta][$i],
			necessity => $prop_necessity_of[$$meta][$i],
			validator => $prop_validator_of[$$meta][$i],
			privacy   => $prop_privacy_of[$$meta][$i],
		};
	}
	return _dump([\%meta], [scion() . ${$id_ref_of[$$meta]} ]);
}

sub dump_object_of{
	my($meta, $object) = @_;
	return _dump([$meta->get_property_map_of($object)], [ref($object).$$object]);
}

sub _dump{
	require Data::Dumper;
	my $ddx = Data::Dumper->new(@_);
	my $s = $ddx->Indent(1)->Sortkeys(1)->Deparse(1)->Quotekeys(0)->Dump();
	return $s if defined wantarray;
	print $s;
}

1;

__END__


=head1 NAME

Scion - Support Class for Inside-Out Nature of objects

=head1 VERSION

This document describes Scion: version 0.01

=head1 SYNOPSIS

In F<FileInputStream.pm>:

	package InputStream;
	use Scion::Sugar;
	use Scalar::Util qw(openhandle);

	has filehandle => (
		validate => sub{ openhandle $_ },
	);

	sub getline{
		my $self = shift;
		return scalar readline( $self->get_filehandle );
	}

	package FileInputStream;
	use Scion::Sugar -base => qw(InputStream);

	has filename => (
		is       => 'ro',
		storage  => \my @filename_of,
		required => 1,
	);

	sub BUILD{
		my($self) = @_;

		open my $in, '<', $filename_of[$$self] or die $!;

		$self->set_filehandle($in);
	}
	sub DEMOLISH{
		my($self) = @_;

		close $self->get_filehandle;
	1;

In F<stream.pl>:

	#!perl -w
	use strict;

	my $x = FileInputStream->new(filename => 'foo.txt');

	while(defined(my $line = $x->getline)){
		print $line;
	}

=head1 DESCRIPTION

This distribution provides an object system for inside-out model.

TODO: write the rest of the document.

=head1 PROVIDED MODULES

C<Scion> is a metaclass for inside-out object system.

C<Scion::Object> is a common base class of C<Scion> classes that provides 
a common infrastructure.

C<Scion::Sugar> is a driver module that provides syntax sugars
in order to setup C<Scion::Object> subclasses.


=head1 INTERFACE

C<Scion> module provides a B<meta> system, so you need not to use this
module directly.

To use this system easily, you can use C<Scion::Sugar> module.

=head2 Exportable utilities

=over 4

=item C<< scion() >>

=item C<< meta($class_name) >>

=item C<< confess(@msg) >>

=back

=head2 Class methods

Nothing.

=head2 Instance methods

=over 4

=item C<< meta->name >>

=item C<< meta->get_superclasses >>

=item C<< meta->add_superclasses(@classes) >>

=item C<< meta->update() >>

=item C<< meta->define_properties(...) >>

=item C<< meta->new_object($param) >>

=item C<< meta->initialize_object($object, $param) >>

=item C<< meta->deinitialize_object($object) >>

=item C<< meta->install_subroutine($name, $coderef) >>

=item C<< meta->make_immutable() >>

=item C<< meta->find_all_method_by_name($method) >>

=item C<< meta->get_property_map_of($object) >>

=item C<< meta->get_property_names >>

=item C<< meta->dump() >>

=item C<< meta->dump_object_of($object) >>

=back

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-scion@rt.cpan.org/>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<Scion::Object>.

L<Scion::Sugar>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
