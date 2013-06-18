package Git::ReleaseRepo::Command::update;
{
  $Git::ReleaseRepo::Command::update::VERSION = '0.001';
}
# ABSTRACT: Update a deployed release repository

use Moose;
extends 'Git::ReleaseRepo::Command';

override usage_desc => sub {
    my ( $self ) = @_;
    return super();
};

sub description {
    return 'Update a deployed release repository';
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    return $self->usage_error( "Too many arguments" ) if ( @$args > 0 );
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
    my $repo_name   = $self->repo_name;
    my $repo        = $self->git;
    my $branch      = $opt->{master} ? "master"
                    : $opt->{branch} ? $opt->{branch}
                    : $self->config->{ $repo_name }{track};
    my $version     = $opt->{master}  ? "master"
                    : $repo->latest_version( $branch );
    $repo->checkout( $version );
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
};

1;


=pod

=head1 NAME

Git::ReleaseRepo::Command::update - Update a deployed release repository

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

