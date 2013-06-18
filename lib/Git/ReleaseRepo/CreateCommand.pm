package Git::ReleaseRepo::CreateCommand;
{
  $Git::ReleaseRepo::CreateCommand::VERSION = '0.001';
}
# ABSTRACT: Base class for commands that have to create a new repository

use strict;
use warnings;
use Moose;
extends 'Git::ReleaseRepo::Command';

sub update_config {
    my ( $self, $opt, $repo_name, $extra ) = @_;

    my $config = $self->config;
    # Delete old default repo
    if ( $extra->{default} ) {
        for my $repo_name ( keys %$config ) {
            my $repo_conf = $config->{$repo_name};
            delete $repo_conf->{default};
        }
    }

    my $repo_conf = $config->{$repo_name} ||= {};
    for my $conf ( qw( version_prefix ) ) {
        if ( exists $opt->{$conf} ) {
            $repo_conf->{$conf} = $opt->{$conf};
        }
    }

    $config->{$repo_name} = { %$repo_conf, %$extra };
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error( "Must give a repository URL!" ) if ( @$args < 1 );
    $self->usage_error( "Too many arguments" ) if ( @$args > 2 );
    my $repo_name = $args->[1] || $self->repo_name_from_url( $args->[0] );
    die "Release repository name '$args->[1]' already exists in '@{[$self->repo_root]}'!\n"
        if -d catdir( $self->repo_root, $repo_name );
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        [ 'version_prefix:s' => 'Set the version prefix of the release repository' ],
    );
};

1;

__END__
=pod

=head1 NAME

Git::ReleaseRepo::CreateCommand - Base class for commands that have to create a new repository

=head1 VERSION

version 0.001

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

