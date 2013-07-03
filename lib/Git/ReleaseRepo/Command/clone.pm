package Git::ReleaseRepo::Command::clone;
{
  $Git::ReleaseRepo::Command::clone::VERSION = '0.002';
}
# ABSTRACT: Clone an existing release repository

use strict;
use warnings;
use Moose;
extends 'Git::ReleaseRepo::CreateCommand';
use Cwd qw( abs_path );
use File::Spec::Functions qw( catdir catfile );
use File::HomeDir;
use File::Path qw( make_path );
use File::Slurp qw( write_file );
use File::Basename qw( basename );

override usage_desc => sub {
    my ( $self ) = @_;
    return super() . " <repo_url> [<repo_name>]";
};

sub description {
    return 'Clone an existing release repository';
}

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    # Clone the repo
    my $repo_name = $args->[1] || $self->repo_name_from_url( $args->[0] );
    my $repo_dir  = catdir( $self->repo_root, $repo_name );
    my $cmd = Git::Repository->command( clone => $args->[0], $repo_dir );
    my @stdout = readline $cmd->stdout;
    my @stderr = readline $cmd->stderr;
    $cmd->close;
    print @stdout if @stdout;
    print @stderr if @stderr;

    # Set new default repo and configuration
    $self->update_config( $opt, $repo_name, { default => 1 } );
};

1;


=pod

=head1 NAME

Git::ReleaseRepo::Command::clone - Clone an existing release repository

=head1 VERSION

version 0.002

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


