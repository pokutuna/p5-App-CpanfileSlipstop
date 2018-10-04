use strict;
use warnings;
use lib '.';

use t::helper;
use Test::More 0.98;
use Module::Spy qw(spy_on);

use App::CpanfileSlipstop::Resolver;
use App::CpanfileSlipstop::Writer;

my $spy = spy_on('App::CpanfileSlipstop::Writer', 'writedown_cpanfile');

sub run_slipstop {
    my ($name, $stopper) = @_;

    my $resolver = App::CpanfileSlipstop::Resolver->new(
        cpanfile => test_cpanfile($name),
        snapshot => test_snapshot($name),
    );
    $resolver->read_cpanfile_requirements;
    $resolver->merge_snapshot_versions(+{
        minimum => 'add_minimum',
        maximum => 'add_maximum',
        exact   => 'exact_version',
    }->{$stopper});

    my $writer = App::CpanfileSlipstop::Writer->new(
        cpanfile_path => test_file($name . '.cpanfile')->stringify,
    );
    $writer->set_versions(
        sub { $resolver->get_version_range($_[0]) },
        sub {},
    );

    my $doc = $spy->calls_most_recent->[1];
    is $doc->serialize, test_file(join('.', $name, 'cpanfile', $stopper))->slurp;
}

subtest simple => sub {
    run_slipstop('simple', 'minimum');
    run_slipstop('simple', 'exact');
    run_slipstop('simple', 'maximum');
};

subtest indent => sub {
    run_slipstop('indent', 'minimum');
    run_slipstop('indent', 'exact');
};

subtest phases => sub {
    run_slipstop('phases', 'minimum');
};

subtest types => sub {
    run_slipstop('types', 'exact');
};

subtest versioned => sub {
    run_slipstop('versioned', 'minimum');
    run_slipstop('versioned', 'exact');
    run_slipstop('versioned', 'maximum');
};

done_testing;
