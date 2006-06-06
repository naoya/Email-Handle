package Email::Handle;
use warnings;
use strict;
use base qw/Class::Accessor::Fast/;
use overload '""' => \&as_string, fallback => 1;
use Carp;
use UNIVERSAL::require;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw/user host/);

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    if (@_ > 0 and not @_ % 2) {
        my %args = @_;
        if ($args{user} && $args{host}) {
            $self->user($args{user});
            $self->host($args{host});
        }
    } else {
        $self->email(shift);
    }
}

sub email {
    my $self = shift;
    if (@_) {
        my ($user, $host) = $self->_parse_email(@_);
        if ($user && $host) {
            $self->user($user);
            $self->host($host);
        }
    }
    $self->user && $self->host ? join '@', $self->user, $self->host : '';
}

sub _parse_email {
    my $self = shift;
    my $email = shift || '';
    return split /@/, $email;
}

sub is_valid {
    my $self = shift;
    my %args = @_;
    my $validator = 'Email::Valid';
    $validator = join '::', $validator, 'Loose'
        if delete $args{loose} or delete $args{-loose};
    $validator->require;
    die $@ if $@;
    $validator->address(-address => $self->email, %args);
}

sub obfuscate {
    my $self = shift;
    require HTML::Email::Obfuscate;
    HTML::Email::Obfuscate->new(@_)->escape_html($self->email);
}

sub anonymize { # FIXME: method name
    my $self = shift;
    my $ph = shift;
    defined $ph or $ph = '...';
    sprintf "%s@%s%s", $self->user, substr($self->host, 0, 1), $ph;
}

our $MIME_CLASS = 'MIME::Lite';

sub mime {
    my $self = shift;
    $MIME_CLASS->require;
    die $@ if $@;
    $MIME_CLASS->new(To => $self->email, @_);
}

sub send {
    shift->mime(@_)->send;
}

sub as_string {
    shift->email;
}

1;

__END__

=head1 NAME

Email::Handle - A Objective Email Handler

=head1 SYNOPSIS

  use Email::Handle;

  my $email = Email::Handle->new('root@example.com');
  print $email->is_valid ? 'yes' : 'no';
  print $email->obfuscate;
  print $email->anonymize;
  print $email;
  $email->send(From => 'foo@example.com');

This module is also convenient for using on the DB application with
L<Template> and L<Class::DBI> / L<DBIx::Class>.

  # setup the table that has column of email with this module
  my $loader = Class::DBI::Loader->new(
     ...
     namespace => 'MyApp'
  );
  $loader->find_class('user')->has_a(email => 'Email::Handle');

  # then output records with TT2
  my $tmpl = Template->new;
  $tmpl->process(
      'sample.tt',
      { users => $loader->find_class('user')->retrieve_all }
  );

  # You can write the template with some methods of this module like this
  [% WHILE (user IN users) %]
  [% user.email.obfuscate IF user.email.is_valid %]
  [% END %]

=head1 DESCRIPTION

This module allows you to handle an email address as a object.

=head1 METHODS

=head2 new

Returns Email::Handle object. It has three forms of construction.

  my $email = Email::Handle->new('root@example.com');

or

  my $email = Email::Handle->new(
     user => 'root',
     host => 'example.com'
  );

or

  my $email = Email::Handle->new;
  $email->user('root');
  $email->host('example.com');

=head2 email

Set/get an email address. A passed string will be splited and setted
as user and host internally.

=head2 as_string

Returns a Email::Handle object to a plain string. Email::Handle
objects are also converted to plain strings automatically by
overloading. This means that objects can be used as plain strings in
most Perl constructs.

  my $email = Email::Handle->new('root@example.com');
  print $email->as_string; # 'root@example.com'
  print $email;            # 'root@example.com'

=head2 user

Set/get a user name for an email address.

  $email->user;        # 'root'
  $email->user('foo'); # changing the user from 'root' to 'foo'

=head2 host

Set/get a host name for an email address.

  $email->host;             # 'examplle.com'
  $email->host('cpan.org'); # changing the host from 'example.com' to 'cpan.org'

=head2 is_valid

Validates whether an address is well-formed with
L<Email::Valid>/L<Email::Valid::Loose> and returns false if the
address is not valid. This method takes some options
as arguments.

  $email->is_valid;             # validating with Email::Valid
  $email->is_valid(loose => 1); # validating with Email::Valid::Loose

  # Any other arguments will be passed to the validator.
  $email->is_valid(-mxcheck => 1);

=head2 obfuscate

Returns obfuscated HTML email addresses which is hard to be
scraped. It requires L<HTML::Email::Obfuscate >.

  $email->obfuscate;

This code generates obfuscated strings like this:

  ro&#x6F;<span>t</span><!-- @ -->&#64;h&#x61;t<span>e</span>na<B>&#46;</b>n&#x65;<B>&#46;</b><span>j</span>&#x70;

Arguments will be passed to the constructor of the HTML::Email::Obfuscate.

  $email->obfuscate(javascript => 1);
  $email->obfuscate(lite => 1);

=head2 anonymize

Returns an anonymized email address like this:

  $email->anonymize;        # 'root@e...'
  $email->anonymize('***'); # 'root@e***'

=head2 mime

Returns MIME::Lite message object for sending mail to the
address. Arguments will be passed to the constructor of MIME::Lite;

  $email->mime(
      From => 'me@myhost.com', 
      Subject => 'Hello'
  )->send;

If you want to use any other MIME classes like L<MIME::Lite::TT>
rather than MIME::Lite, override package variable
C<$Email::Handle::MIME_CLASS>

  $Email::Handle::MIME_CLASS = 'MIME::Lite::TT';
  my $msg = $email->mime(...)

=head2 send

A shortcut method for sending mail with MIME::Lite.

  $email->send(From => 'me@myhost.com', Subject => 'Hello');

=head1 AUTHOR

Naoya Ito, C<< <naoya at bloghackers.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-email-handle at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-Handle>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Email::Handle

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Email-Handle>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Email-Handle>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Email-Handle>

=item * Search CPAN

L<http://search.cpan.org/dist/Email-Handle>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 Naoya Ito, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
