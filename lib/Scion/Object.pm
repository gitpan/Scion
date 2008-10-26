package Scion::Object;

use 5.008_001;
use warnings;
use strict;

our $VERSION = '0.01';

use Scion qw(:std);

__PACKAGE__->meta(); # create the meta object

sub import :method{
	my $class = shift;

	if(@_){
		my $into = caller;
		my $cmd  = shift;

		if($cmd eq '-base'){
			my $meta = $into->can('meta') ? $into->meta : meta($into);
			$meta->add_superclasses(@_ ? @_ : $class);
		}
		else{
			confess(qq{Invalid import command "$cmd"});
		}
	}

	return;
}

sub BUILDARGS :method{
	my $class = shift;

	confess(qq{Odd number of elements for new() on $class})
		if @_ % 2;

	return {@_};
}

sub new :method{
	my $class = shift;

	confess('Cannot call new() as an instance method')
		if ref $class;

	my $param = $class->BUILDARGS(@_);
	my $self = $class->meta->new_object($param);

	return $self unless $self->can('BUILD');

	# BUILDALL
	foreach my $method(reverse $self->meta->find_all_method_by_name('BUILD') ){
		$method->($self, $param);
	}

	return $self;
}

sub DESTROY :method{
	my($self) = @_;

	if($self->can('DEMOLISH')){
		# DEMOLISHALL
		local $@;
		foreach my $method($self->meta->find_all_method_by_name('DEMOLISH')){
			$method->($self);
		}
	}

	$self->meta->deinitialize_object($self);
	return;
}

sub STORABLE_freeze :method{
	my($self) = @_;

	return (q{}, $self->meta->get_property_map_of($self));
}
sub STORABLE_thaw :method{
	my($self, undef, undef, $param) = @_;

	$self->meta->initialize_object($self, $param);

	return $self unless $self->can('BUILD');

	# BUILDALL
	foreach my $method(reverse $self->meta->find_all_method_by_name('BUILD') ){
		$method->($self, $param);
	}

	return $self;
}

sub get_property_map :method{
	my($self) = @_;
	return $self->meta->get_property_map_of($self);
}

sub dump :method{
	my($self) = @_;
	return $self->meta->dump_object_of($self);
}

1;
__END__

=head1 NAME

Scion::Object - A common base class for Scion object system

=head1 SYNOPSIS

	use Scion::Object;

=head1 DESCRIPTION

(TODO)

=head1 INTERFACE

=head2 Class methods

=over 4

=item C<< CLASS->new(...) >>

=item C<< CLASS->BUILDARGS(@args) >>

=back

=head2 Instance methods

=over 4

=item C<< INSTANCE->get_property_map >>

=item C<< INSTANCE->dump() >>

=back

=head1 SEE ALSO

L<Scion>.

L<Scion::Sugar>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut