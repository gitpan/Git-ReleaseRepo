package Git::ReleaseRepo::Command::add;
{
  $Git::ReleaseRepo::Command::add::VERSION = '0.003';
}
# ABSTRACT: Add a module to the next release

use strict;
use warnings;
use Moose;
use Git::ReleaseRepo -command;
use File::Spec::Functions qw( catdir );

with 'Git::ReleaseRepo::WithVersionPrefix';

override usage_desc => sub {
    my ( $self ) = @_;
    return super() . " <module_name> [<module_url>]";
};

sub description {
    return 'Add a module to the next release';
}

around opt_spec => sub {
    my ( $orig, $self ) = @_;
    return (
        $self->$orig(),
        [ 'bugfix' => 'Add to the latest release branch as a bug fix' ],
        [ 'all|a' => "Add all out-of-date modules to the release" ],
    );
};

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    if ( $opt->all ) { 
        if ( @$args ) {
            return $self->usage_error( "--all does not make sense with module names to add" );
        }
    }
    else {
        if ( scalar @$args < 1 ) {
            return $self->usage_error( "You must specify a submodule to add to the next release" );
        }
        if ( scalar @$args > 2 ) {
            return $self->usage_error( "Too many arguments" );
        }
    }
}

augment execute => sub {
    my ( $self, $opt, $args ) = @_;
    my $git = $self->git;
    my $branch;
    if ( $opt->bugfix ) {
        $branch = $git->latest_release_branch;
        die "Cannot add with --bugfix: No release branch found!\n" if !$branch;
    }
    else {
        $branch = "master";
    }
    if ( $git->has_branch( $branch ) ) {
        $git->checkout( $branch );
    }
    if ( $opt->all ) {
        my @outdated = $git->outdated;
        for my $outdated ( @outdated ) {
            $self->update_submodule( $outdated, $branch );
        }
        my $message = "Updating all outdated:\n"
                    . join "\n", map { sprintf "\t\%s", $_ } sort @outdated;
        $git->run( commit => ( @outdated ), -m => $message );
    }
    elsif ( @$args == 1 ) {
        $self->update_submodule( @$args, $branch );
        $git->run( commit => ( @$args ), -m => "Updating $args->[0]" );
    }
    elsif ( @$args == 2 ) {
        $self->add_submodule( @$args );
        $git->run( commit => ( '.gitmodules', $args->[0] ), -m => "Adding $args->[0] to release" );
    }
    $git->checkout;
};

sub update_submodule {
    my ( $self, $module, $branch ) = @_;
    $branch ||= "master";
    my $git = $self->git;
    if ( !$git->submodule->{ $module } ) {
        die "Cannot add $module: Submodule does not exist\n";
    }
    my $subgit = $git->submodule_git( $module );
    my $cmd = $subgit->command( 'fetch' );
    $cmd->close;
    $cmd = $subgit->command( checkout => 'origin/' . $branch );
    my @stdout = readline $cmd->stdout;
    my @stderr = readline $cmd->stderr;
    $cmd->close;
    if ( $cmd->exit != 0 ) {
        die "Could not checkout 'origin/$branch': \nSTDERR: " . ( join "\n", @stderr )
            . "\nSTDOUT: " . ( join "\n", @stdout );
    }
}

sub add_submodule {
    my ( $self, $module, $repo ) = @_;
    my $git = $self->git;
    $git->run(
        submodule => add => '--', $repo, $module,
    );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Git::ReleaseRepo::Command::add - Add a module to the next release

=head1 VERSION

version 0.003

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
