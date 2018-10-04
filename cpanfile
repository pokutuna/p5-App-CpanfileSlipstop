requires 'perl', '5.008001';

requires 'CPAN::Meta::Requirements';
requires 'Carton';
requires 'Getopt::Long';
requires 'List::Util';
requires 'Module::CPANfile';
requires 'PPI';
requires 'Pod::Find';
requires 'Pod::Usage';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
