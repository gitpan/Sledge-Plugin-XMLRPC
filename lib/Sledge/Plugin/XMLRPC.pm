package Sledge::Plugin::XMLRPC;
use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.01';
use RPC::XML;
use RPC::XML::Parser;

sub import {
    my $class = shift;
    my $pkg   = caller(0);

    $pkg->mk_classdata('_xmlrpc_parser');
    $pkg->_xmlrpc_parser(RPC::XML::Parser->new);

    # BK: I want more smart method...
    $pkg->register_hook(BEFORE_INIT => sub {
        my $self = shift;
        if ($ENV{CONTENT_TYPE} eq 'text/xml') {
            read STDIN, $self->{_body}, $ENV{CONTENT_LENGTH};
        }
    });

    no strict 'refs';
    *{"$pkg\::xmlrpc"} = \&_xmlrpc;
}

sub _xmlrpc {
    my $self = shift;

    # Deserialize
    my $req;
    eval {$req = _deserialize_xmlrpc($self)};
    if ($@ || !$req) {
        warn qq{Invalid XMLRPC request "$@"};
        _serialize_xmlrpc($self, RPC::XML::fault->new( -1, 'Invalid request' ) );
        return 0;
    }

    my $res = 0;
    my $method = $req->{method};
    if ($method) {
        if (my $code = $self->can("xmlrpc_$method")) {
            $res = $self->$code(@{$req->{args}});
        } else {
            warn qq{Couldn't find xmlrpc method "$method"};
        }
    }

    # Serialize response
    _serialize_xmlrpc($self, $res);
    return $res;
}

# Deserializes the xml in request
sub _deserialize_xmlrpc {
    my $self = shift;

    my $p = $self->_xmlrpc_parser->parse;
    $p->parse_more($self->{_body});
    my $req = $p->parse_done;

    # Handle . in method name
    my $name = $req->name;
    $name =~ s/\.//g;
    my @args = map {$_->value} @{$req->args};

    return {method => $name, args => \@args};
}

# Serializes the response and output it
sub _serialize_xmlrpc {
    my ($self, $status) = @_;

    my $res = RPC::XML::response->new($status)->as_string;

    $self->r->content_type('text/xml');
    $self->set_content_length(length $res);
    $self->send_http_header;
    $self->r->print($res);
    $self->invoke_hook('AFTER_OUTPUT');
    $self->finished(1);
}

1;
__END__

=head1 NAME

Sledge::Plugin::XMLRPC - XMLRPC plugin for Sledge

=head1 SYNOPSIS

  package Your::Pages;
  use Sledge::Plugin::XMLRPC;
  sub dispatch_xmlrpc {
    my $self = shift;
    $self->xmlrpc;
  }

  sub xmlrpc_echo {
    my $self = shift;
    return join " ", @_;
  }

  sub xmlrpc_add {
    my $self = shift;
    my $a    = shift;
    my $b    = shift;

    return $a + $b;
  }

=head1 DESCRIPTION

Sledge::Plugin::XMLRPC is easy to implement XMLRPC plugin for Sledge.

=head1 AUTHOR

MATSUNO Tokuhiro E<lt>tokuhirom at mobilefactory.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Bundle::Sledge>, L<Catalyst::Plugin::XMLRPC>, L<RPC::XML>

=cut
