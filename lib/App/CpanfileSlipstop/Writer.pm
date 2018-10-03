package App::CpanfileSlipstop::Writer;
use strict;
use warnings;

use List::Util qw(first);
use PPI::Document;
use PPI::Find;

sub new {
    my ($class, %opts) = @_;

    bless +{
        cpanfile_path => $opts{cpanfile_path},
        dry_run       => $opts{dry_run},
    }, $class;
}

sub cpanfile_path { $_[0]->{cpanfile_path}   }
sub dry_run       { $_[0]->{dry_run} ? 1 : 0 }

sub set_versions {
    my ($self, $version_getter, $logger) = @_;

    my $doc = PPI::Document->new($self->cpanfile_path);

    my $requirements = $doc->find(sub {
        my (undef, $elem) = @_;

        return $elem->isa('PPI::Statement') &&
            (first { $elem->schild(0)->content eq $_ } qw(requires recommends suggests)) ? 1 : 0;
    });

    for my $statement (@$requirements) {
        my ($type, $module, @args) = $statement->schildren;

        my $version_range = $version_getter->($module->string);
        next unless $version_range;

        my @words = grep { !($_->isa('PPI::Token::Operator') || $_->content eq ';') } @args;
        if (@words % 2 == 0) {
            # insert VERSION
            # - requires MODULE;
            # - requries MODULE, KEY => VALUE;
            $self->insert_version($module, $version_range);
            $logger->({
                type   => 'insert',
                module => $module->string,
                before => undef,
                after  => $version_range,
                quote  => quote($module),
            });
        } else {
            # replace VERSION
            # - requries MODULE, VERSION;
            # - requries MODULE, VERSION, KEY => VALUE;
            my $current_version = $words[0];
            $self->replace_version($module, $current_version, $version_range);
            $logger->({
                type   => 'replace',
                module => $module->string,
                before => $current_version->string,
                after  => $version_range,
                quote  => quote($module),
            });
        }
    }

    unless ($self->dry_run) {
        open my $out, ">", $self->cpanfile_path
            or die sprintf('%s, %s', $self->cpanfile_path, $!);

        print $out $doc->serialize;
    }
}

sub insert_version {
    my ($self, $module_elem, $version_range) = @_;

    my $quote = quote($module_elem);
    $module_elem->__insert_after(PPI::Token->new(qq{, $quote$version_range$quote}));
}

sub replace_version {
    my ($self, $module_elem, $version_elem, $version_range) = @_;

    my $quote = quote($module_elem);

    # The giving version on cpanfile must be a string or number for preventing to replace expressions.
    return if !($version_elem->isa('PPI::Token::Quote') || $version_elem->isa('PPI::Token::Number'));

    my $prev_token = $version_elem->previous_sibling;
    $version_elem->remove;
    $prev_token->__insert_after(PPI::Token->new(qq{$quote$version_range$quote}));
}

sub quote {
    my ($elem) = @_;

    return $elem->isa('PPI::Token::Quote::Single') ? "'" : '"';
}

1;
