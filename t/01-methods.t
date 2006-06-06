#!perl -T
use Test::More qw/no_plan/;
use strict;
use warnings;
use Email::Handle;

my $email = Email::Handle->new('root@example.com');
ok $email;
is $email, 'root@example.com';
isa_ok $email, 'Email::Handle';
is $email->user, 'root';
is $email->host, 'example.com';
is $email->anonymize, 'root@e...';
is $email->anonymize('***'), 'root@e***';

$email->user('naoya');
is $email, 'naoya@example.com';

$email->host('mail.example.com');
is $email, 'naoya@mail.example.com';

$email->email('root@example.com');
is $email, 'root@example.com';

$email = Email::Handle->new(
    user => 'root',
    host => 'example.com',
);
is $email, 'root@example.com';

SKIP: {
    eval "use HTML::Email::Obfuscate";
    skip 'because HTML::Email::Obfuscate required for obfuscating', 1 if $@;
    ok $email->obfuscate;
    isnt $email->obfuscate, 'root@cpan.org';
    isnt $email->obfuscate(javascript => 1), $email->obfuscate;
    isnt $email->obfuscate(lite => 1), $email->obfuscate;
}

SKIP: {
    eval "use Email::Valid";
    skip 'because Email::Valid required for validation', 1 if $@;
    ok $email->is_valid;
}

SKIP: {
    eval "use MIME::Lite";
    skip 'because MIME::Lite required for send email', 1 if $@;
    my $mime = $email->mime(
        From    => 'Naoya Ito <naoya@example.com>',
        Subject => 'Greetings',
    );
    ok $mime;
    is $mime->get('From'), 'Naoya Ito <naoya@example.com>';
    is $mime->get('Subject'), 'Greetings';
}

SKIP: {
    eval "use Email::Valid::Loose";
    skip 'because Email::Valid::Loose required for loosely validation', 1 if $@;
    my $loose = Email::Handle->new;
    $loose->user('-aaaa');
    $loose->host('foobar.ezweb.ne.jp');
    ok not $loose->is_valid;
    ok $loose->is_valid(loose => 1);
}
