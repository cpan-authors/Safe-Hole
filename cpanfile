requires 'ExtUtils::CBuilder';

on 'configure' => sub {
    requires 'Module::Build', '0.42';
};

on 'build' => sub {
    requires 'Module::Build', '0.35';
};

on 'test' => sub {
    requires 'Test::More', '0.40';
};
