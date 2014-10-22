package Git::ReleaseRepo::Command::use;
{
  $Git::ReleaseRepo::Command::use::VERSION = '0.001';
}
# ABSTRACT: Set a release repository as the default

use strict;
use warnings;
use Moose;
use Git::ReleaseRepo -command;
use Cwd qw( abs_path );
use File::Spec::Functions qw( catdir catfile );
use File::HomeDir;
use File::Path qw( make_path );
use File::Slurp qw( write_file );

override usage_desc => sub {
    my ( $self ) = @_;
    return super() . " <repo_name>";
};

sub description {
    return 'Set a release repository as the default';
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    $self->usage_error( "Must give a repository name to use!" ) if ( @$args != 1 );
    die "Could not find release repository '$args->[0]' in directory '@{[$self->repo_root]}'!\n"
        if !-d catdir( $self->repo_root, $args->[0] );
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        [ 'version_prefix:s' => 'Set the version prefix of the release repository' ],
    );
};

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my $config = $self->config;
    # Delete old default repo
    for my $repo_name ( keys %$config ) {
        my $repo_conf = $config->{$repo_name};
        delete $repo_conf->{default};
    }
    # Set new default repo and configuration
    my $repo_conf = $config->{$args->[0]} ||= {};
    $repo_conf->{default} = 1;
    for my $conf ( qw( version_prefix ) ) {
        if ( exists $opt->{$conf} ) {
            $repo_conf->{$conf} = $opt->{$conf};
        }
    }
};

1;


=pod

=head1 NAME

Git::ReleaseRepo::Command::use - Set a release repository as the default

=head1 VERSION

version 0.001

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


