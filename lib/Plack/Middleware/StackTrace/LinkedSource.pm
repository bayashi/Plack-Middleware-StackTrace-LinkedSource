package Plack::Middleware::StackTrace::LinkedSource;
use strict;
use warnings;
use parent 'Plack::Middleware::StackTrace';
use Plack::App::SourceViewer;
use Plack::Util;
use Plack::Util::Accessor qw/
    lib
    viewer
    view_root
/;

our $VERSION = '0.04';

sub prepare_app {
    my ($self) = @_;

    if (!$self->lib) {
        $self->lib([@INC]);
    }
    elsif (ref $self->lib ne 'ARRAY') {
        $self->lib([$self->lib]);
    }

    unless ($self->viewer) {
        my $source_viewer = Plack::App::SourceViewer->new(root => $self->lib);
        $source_viewer->prepare_app;
        $self->viewer($source_viewer);
    }

    $self->view_root
        or $self->view_root('/source');
}

sub call {
    my($self, $env) = @_;

    my $path = $self->view_root;

    if ($env->{PATH_INFO} =~ m!^$path!) {
        my $path_info = $env->{PATH_INFO};
        $path_info =~ s!^$path/!!;
        local $env->{PATH_INFO} = $path_info;
        return $self->viewer->call($env);
    }

    my $res = $self->SUPER::call($env);

    if ($res->[0] == 500 && Plack::Util::header_get($res->[1], 'content-type') =~ m!text/html!) {
        my $body = $res->[2][0];
        $self->_add_link(\$body);
        $res->[2][0] = $body;
    }

    return $res;
}

sub _add_link {
    my ($self, $body_ref) = @_;

    for my $lib_path (@{$self->lib}) {
        next if $lib_path eq '.';
        ${$body_ref} =~ s!(\Q$lib_path\E[/\\]([^\.]+\.[^\s]+)\s+line\s+(\d+))!_link_html($1, $2, $3)!eg;
    }
}

sub _link_html {
    my ($matched, $path, $line_count) = @_;

    $path =~ s!\\!/!g; # for win

    return qq|<a href="/source/$path#L$line_count">$matched</a>|;
}

1;


__END__

=encoding UTF-8

=head1 NAME

Plack::Middleware::StackTrace::LinkedSource - Adding links to library source codes in stacktrace


=head1 SYNOPSIS

    enable 'StackTrace::LinkedSource', lib => ['/your/project/lib', @INC];


=head1 DESCRIPTION

Plack::Middleware::StackTrace::LinkedSource provides stacktrace which includes links to library source code.

NOTE that B<you should turn off this middleware in the production environment>.


=head1 MIDDLEWARE CONFIGURATION

=head2 lib => ($lib || \@lib) //  [@INC]

library path

=head2 viewer => $code_ref_for_plack // Plack::App::SourceViewer instance

source code viewer instance

=head2 view_root => $view_root // '/source'

root of source code path

see more configurations on L<Plack::Middleware::StackTrace>


=head1 METHODS

=head2 prepare_app

=head2 call


=head1 REPOSITORY

=begin html

<a href="http://travis-ci.org/bayashi/Plack-Middleware-StackTrace-LinkedSource"><img src="https://secure.travis-ci.org/bayashi/Plack-Middleware-StackTrace-LinkedSource.png?_t=1455612039"/></a> <a href="https://coveralls.io/r/bayashi/Plack-Middleware-StackTrace-LinkedSource"><img src="https://coveralls.io/repos/bayashi/Plack-Middleware-StackTrace-LinkedSource/badge.png?_t=1455612039&branch=master"/></a>

=end html

Plack::Middleware::StackTrace::LinkedSource is hosted on github: L<http://github.com/bayashi/Plack-Middleware-StackTrace-LinkedSource>

I appreciate any feedback :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

L<Plack::Middleware::StackTrace>

L<Plack::App::SourceViewer>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
