requires 'perl', '5.008001';

requires 'CPAN::Meta::Requirements';
requires 'Carton';
requires 'List::Util';
requires 'Module::CPANfile';
requires 'PPI';

on 'test' => sub {
    requires 'Test::More', '0.98';
};
