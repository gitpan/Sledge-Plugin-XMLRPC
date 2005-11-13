use ExtUtils::MakeMaker;
WriteMakefile(
        'NAME'         => 'Sledge::Plugin::XMLRPC',
        'VERSION_FROM' => 'lib/Sledge/Plugin/XMLRPC.pm', # finds $VERSION
        'PREREQ_PM'    => {
                Test::More => 0.32,
                RPC::XML   => 1.35,
        },
);
