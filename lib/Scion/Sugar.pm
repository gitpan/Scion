package Scion::Sugar;

use strict;
use warnings;

our $VERSION = '0.01';

use Scion::Object;
use Scion qw(confess meta);

my $BASE = 'Scion::Object';

sub export_sugars{
	return qw(extends has define_properties register_properties);
}

sub import{
	my $class = shift;
	my $into  = caller;

	if(@_){
		my $cmd = shift;
		if($cmd eq '-base'){
			$into->Scion::Sugar::extends(@_ ? @_ : $BASE);
		}
		else{
			confess(qq{Invalid import command "$cmd"});
		}
	}
	else{
		$into->Scion::Sugar::extends($BASE);
	}

	foreach my $sugar($class->export_sugars){
		my $method = $class->can($sugar);

		my $function = sub{
			unshift @_, $into;
			goto &{$method};
		};

		$into->meta->install_subroutine($sugar, $function);
	}

	return;
}


sub extends :method{
	my $class = shift;

	my $meta = $class->can('meta') ? $class->meta : meta($class);

	$meta->add_superclasses(@_);

	unless($class->isa($BASE)){
		confess("Invalid hierarchy: $class should be $BASE",
			map{ sprintf qq{\n(%s is not a subclass of %s)}, $_, $BASE  } @_);
	}

	return;
}


sub define_properties :method{
	my $class = shift;
	$class->meta->define_properties(@_);
	return;
}

sub register_properties :method{
	my $class = shift;

	$class->meta->define_properties(
		map{ (undef => { storage => $_, private => 1 }) } @_
	);
	return;
}

sub has :method{
	my $class     = shift;
	my $property_name = shift;

	confess qq{Odd number of options for has() on $class}
		if @_ % 2;

	$class->meta->define_properties($property_name => {@_});
	return;
}


1;
__END__

=head1 NAME

Scion::Sugar - A driver module to setup Scion object system

=head1 SYNOPSIS

	use Scion::Sugar;

=head1 DESCRIPTION

(TODO)

=head1 INTERFACE

=head2 Utility functions

=over 4

=item C<< extends @base_classes >>

=item C<< has $property_name => %property_config >>

=item C<< define_properties $property_name => \%property_config [, ...] >>

=item C<< register_properties \my(@property1, @property2 [, ...]) >>

=back

=head1 SEE ALSO

L<Scion>.

L<Scion::Object>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut