package Finance::Bank::BNPParisbas;
use strict;
use Carp qw(carp croak);
use WWW::Mechanize;
use vars qw($VERSION);
$VERSION = 0.01;

=pod

=head1 NAME

Finance::Bank::BNPParisbas -  Check your BNP bank accounts from Perl

=head1 SYNOPSIS

 use Finance::Bank::BNPParisbas;

 my @accounts = Finance::Bank::BNPParisbas->check_balance(
    username => "$username",  # Be sure to put the numbers
    password => "$password",  # between quote.
 );

 foreach my $account ( @accounts ){
    local $\ = "\n";
    print "       Name ", $account->name;
    print " Account_no ", $account->account_no;
    print "    Balance ", $account->balance;
    print "  Statement\n";

    foreach my $statement ( $account->statements ){
        print $statement->as_string;
    }
 }

=head1 DESCRIPTION

This module provides a rudimentary interface to the BNPNet online
banking system at L<https://www.bnpnet.bnp.fr/>. You will need
either Crypt::SSLeay or IO::Socket::SSL installed for HTTPS support to
work with LWP.

The interface of this module is directly taken from Simon Cozens'
Finance::Bank::LloydsTSB.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and that
means B<BE CAREFUL>. You are encouraged, nay, expected, to audit the source
of this module yourself to reassure yourself that I am not doing
anything untoward with your banking data. This software is useful to me,
but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 METHODS

=head2 check_balance( username => $username, password => $password, ua => $ua )

Return a list of account (F::B::B::Account) objects, one for
each of your bank accounts. You can provide to this method a
WWW::Mechanize object as third argument.

=cut

sub check_balance {
    my ( $class, %opts ) = @_;
    croak "Must provide a password" unless exists $opts{password};
    croak "Must provide a username" unless exists $opts{username};

    my @accounts;

    $opts{ua} ||= WWW::Mechanize->new;
    $opts{ua}->cookie_jar( {} );

    my $self = bless {%opts}, $class;

    #my $orig_r = $self->{ua}->get("https://www.bnpnet.bnp.fr/NSFR");
    my $orig_r = $self->{ua}->get("https://62.161.61.71/NSFR");
    croak $orig_r->error_as_HTML if $orig_r->is_error;

    $self->{ua}->field( 'ch1', $self->{username} );
    $self->{ua}->field( 'ch2', $self->{password} );
    my $click_r = $self->{ua}->click;
	croak $click_r->error_as_HTML if $click_r->is_error;

    $self->{ua}->get('/SAF_TLC');
    $click_r = $self->{ua}->click;
	croak $click_r->error_as_HTML if $click_r->is_error;


    foreach ( @{ $self->{ua}->{links} } ) {
        my $qif = $_->[0];
        next unless $qif =~ /\.exl$/;
		
        my $qif_r = $self->{ua}->get($qif);
		carp $qif_r->error_as_HTML if $qif_r->is_error;

        next
          if $self->{ua}->{content} =~ /<html>/i;    # no operation for this account
        push @accounts,
          Finance::Bank::BNPParisbas::Account->new( $self->{ua}->{content} );
    }
    @accounts;
}

package Finance::Bank::BNPParisbas::Account;

=pod

=head1 Account methods

=head2 sort_code()

Return the sort code of the account. Currently, it returns an
undefined value.

=head2 name()

Returns the human-readable name of the account.

=head2 account_no()

Return the account number, in the form C<XXX YYYYYYYYY ZZ>, where X, Y
and Z are numbers.

=head2 balance()

Returns the balance of the account. Note that the BNP site displays them
in French format (i.e C<123,75>), but the string returns a number perl
understands (i.e C<123.75>).

=head2 statements()

Return a list of Statement object (Finance::Bank::BNPParisbas::Statement).

=cut

sub new {
    my $class = shift;
    chomp( my @content = split ( /\n/, shift ));
    my $header = shift @content;

    my ( $name, $account_no, $date, $balance ) =
      ( $header =~
          m/^(.+)\s+(\d{5}\s+\d{9}\s+\d{2})\t+(\d{2}\/\d{2}\/\d{2})\t+(\d+,\d+)/
      );

    $balance =~ s/,/./;

    my @statements;
    push @statements, Finance::Bank::BNPParisbas::Statement->new($_) foreach @content;

    bless {
        name       => $name,
        account_no => $account_no,
        sort_code  => undef,
        date       => $date,
        balance    => $balance,
        statements => [@statements],
    }, $class;
}

sub sort_code  { undef }
sub name       { $_[0]->{name} }
sub account_no { $_[0]->{account_no} }
sub balance    { $_[0]->{balance} }
sub statements { @{ $_[0]->{statements} } }

package Finance::Bank::BNPParisbas::Statement;

=pod

=head1 Statement methods

=head2 date()

Returns the date when the statement occured, in DD/MM/YY format.

=head2 description()

Returns a brief description of the statement.

=head2 amount()

Returns the amount of the statement (expressed in Euros).

=head2 as_string($separator)

Returns a tab-delimited representation of the statement. By default, it
uses a tabulation to separate the fields, but the user can provide its
own separator.

=cut

sub new {
    my $class     = shift;
    my $statement = shift;

    my @entry = split ( /\t/, $statement );

    $entry[1] =~ s/\s+/ /g;
    $entry[2] =~ s/,/./;

    bless [ @entry[ 0 .. 2 ] ], $class;
}

sub date        { $_[0]->[0] }
sub description { $_[0]->[1] }
sub amount      { $_[0]->[2] }

sub as_string { join ( $_[1] || "\t", @{ $_[0] } ) }

1;

__END__

=head1 BUGS

Please report any bugs or comments using the Request Tracker interface:
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-BNPParisbas>

=head1 COPYRIGHT

Copyright 2002, Briac Pilpr�. All Rights Reserved. This module can be
redistributed under the same terms as Perl itself.

=head1 AUTHOR

Briac Pilpr� <briac@cpan.org>

Thanks to Simon Cozens for releasing Finance::Bank::LloydsTSB

=head1 SEE ALSO

Finance::Bank::LloydsTSB, WWW::Mechanize

=cut

