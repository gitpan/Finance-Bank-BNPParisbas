use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Finance::Bank::BNPParisbas',
	VERSION_FROM  => 'lib/Finance/Bank/BNPParisbas.pm',
	PREREQ_PM     => {
		'WWW::Mechanize' => 0,
		'Carp'           => 0,		# Core
	},
	ABSTRACT_FROM => 'lib/Finance/Bank/BNPParisbas.pm',
	AUTHOR        => 'Briac Pilpré <briac@cpan.org>',
);
