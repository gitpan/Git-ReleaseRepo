package Git::ReleaseRepo::Command::deploy;
{
  $Git::ReleaseRepo::Command::deploy::VERSION = '0.001';
}
# ABSTRACT: Deploy a release repository

use strict;
use warnings;
use Moose;
extends 'Git::ReleaseRepo::CreateCommand';
use File::Spec::Functions qw( catdir );
use File::Copy qw( move );

override usage_desc => sub {
    my ( $self ) = @_;
    return super() . " <repo_url> [<repo_name>]";
};

sub description {
    return 'Deploy a release repository';
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    return $self->usage_error( "Repository URL is required" ) if ( @$args < 1 );
    return $self->usage_error( "Too many arguments" ) if ( @$args > 2 );
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig,
        [ 'branch=s' => 'Specify the release branch to deploy. Defaults to the latest release branch.' ],
        [ 'master' => 'Deploy the "master" version of the repository and all submodules, for testing.' ],
    );
};

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my $repo_name = $args->[1];
    my $rename_repo = 0;
    if ( !$repo_name ) {
        # The automatic name will come from the release branch of the deployed repository, which
        # we won't have until we actually clone the repository, so create a temporary
        # directory instead
        $rename_repo = 1;
        $repo_name = join "-", $self->repo_name_from_url( $args->[0] ), 'deploy', time;
    }
    my $repo_dir = catdir( $self->repo_root, $repo_name );
    my $cmd = Git::Repository->command( clone => $args->[0], $repo_dir );
    my @stderr = readline $cmd->stderr;
    my @stdout = readline $cmd->stdout;
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        die "Could not clone '$args->[0]'.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
            . "\nSTDOUT: " . ( join "\n", @stdout );
    }
    my $repo = Git::Repository->new( work_tree => $repo_dir );
    $repo->release_prefix( $self->release_prefix );
    my $version = $opt->{master}  ? "master"
                : $opt->{branch} ? $repo->latest_version( $opt->{branch} )
                : $repo->latest_version;
    my $branch  = $opt->{master} ? "master"
                : $opt->{branch} ? $opt->{branch}
                : $repo->latest_release_branch;
    $cmd = $repo->command( checkout => $version );
    @stderr = readline $cmd->stderr;
    @stdout = readline $cmd->stdout;
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        die "Could not checkout '$version'.\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
            . "\nSTDOUT: " . ( join "\n", @stdout );
    }
    $repo->run( submodule => 'update', '--init' );
    if ( $opt->{master} ) {
        my $cmd = $repo->command( submodule => 'foreach', 'git checkout master && git pull origin master' );
        my @stderr = readline $cmd->stderr;
        my @stdout = readline $cmd->stdout;
        $cmd->close;
        if ( $cmd->exit != 0 ) {
            die "Could not checkout master\nEXIT: " . $cmd->exit . "\nSTDERR: " . ( join "\n", @stderr )
                . "\nSTDOUT: " . ( join "\n", @stdout );
        }
    }
    if ( $rename_repo ) {
        $repo_name = join "-", $self->repo_name_from_url( $args->[0] ), $branch;
        move( $repo_dir, catdir( $self->repo_root, $repo_name ) );
    }
    # Set new default repo and configuration
    # Deploy creates a detatched HEAD, so we need to know what branch we're
    # tracking
    $self->update_config( $opt, $repo_name, { track => $branch } );
};

1;


=pod

=head1 NAME

Git::ReleaseRepo::Command::deploy - Deploy a release repository

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


