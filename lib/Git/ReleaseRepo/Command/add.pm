package Git::ReleaseRepo::Command::add;
{
  $Git::ReleaseRepo::Command::add::VERSION = '0.005';
}
# ABSTRACT: Add a new module to the next release

use strict;
use warnings;
use Moose;
use Git::ReleaseRepo -command;
use File::Spec::Functions qw( catdir );

with 'Git::ReleaseRepo::WithVersionPrefix';

override usage_desc => sub {
    my ( $self ) = @_;
    return super() . " <module_name> <module_url>";
};

sub description {
    return 'Add a new module to the next release';
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    if ( scalar @$args > 2 ) {
        return $self->usage_error( "Too many arguments" );
    }
}

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my $git = $self->git;
    my $branch = $git->current_branch;
    my $repo = $args->[1];
    my $module = $args->[0];
    $git->run(
        submodule => add => '--', $repo, $module,
    );
    $git->run( commit => ( '.gitmodules', $module ), -m => "Adding $module to release" );
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::add - Add a new module to the next release

=head1 VERSION

version 0.005

=head1 DESCRIPTION

Add a module to the next release.

=head1 NAME

Git::ReleaseRepo::Command::add - Add a module to the next release

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
