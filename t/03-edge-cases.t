use strict;
use warnings;
use Test::More;

use Safe;
use Safe::Hole;

my $hole = Safe::Hole->new( {} );

###################################
# call() context propagation
###################################

# Scalar context
my $ctx = $hole->call( sub { wantarray() ? 'list' : 'scalar' } );
is( $ctx, 'scalar', 'call() propagates scalar context' );

# List context
my @ctx = $hole->call( sub { wantarray() ? ( 'a', 'b', 'c' ) : 'scalar' } );
is_deeply( \@ctx, [ 'a', 'b', 'c' ], 'call() propagates list context' );

# Void context — should not die
$hole->call( sub { 1 } );
pass('call() in void context does not die');

###################################
# $@ preservation across successful call() (GH#1 regression)
###################################

{
    $@ = "preserved error\n";
    $hole->call( sub { 1 } );
    is( $@, "preserved error\n", '$@ preserved after successful call()' );
}

{
    $@ = "another preserved\n";
    $hole->call( sub { eval { 1 }; return 42 } );
    is( $@, "another preserved\n", '$@ preserved when coderef contains successful eval' );
}

###################################
# die with blessed reference
###################################

{

    package ErrorClass;
    sub new { bless { msg => $_[1] }, $_[0] }
}

{
    eval { $hole->call( sub { die ErrorClass->new("boom") } ) };
    is( ref($@), 'ErrorClass', 'die with blessed ref preserves object type' );
    is( $@->{msg}, 'boom', 'die with blessed ref preserves object data' );
}

###################################
# die with hash reference
###################################

{
    eval { $hole->call( sub { die { code => 42, msg => "hash error" } } ) };
    is( ref($@), 'HASH', 'die with hash ref preserves reference type' );
    is( $@->{code}, 42, 'die with hash ref preserves data' );
}

###################################
# Nested hole calls
###################################

{
    my $hole2 = Safe::Hole->new( {} );

    my $result = $hole->call(
        sub {
            return $hole2->call( sub { return 42 } );
        }
    );
    is( $result, 42, 'Nested call() through different holes works' );
}

###################################
# Nested call — exception propagation
###################################

{
    my $hole2 = Safe::Hole->new( {} );

    eval {
        $hole->call(
            sub {
                $hole2->call( sub { die "nested die\n" } );
            }
        );
    };
    is( $@, "nested die\n", 'Exception propagates through nested calls' );
}

###################################
# root() method
###################################

{
    my $h1 = Safe::Hole->new( {} );
    is( $h1->root(), 'main', 'root() returns main for hashref constructor' );

    my $h2 = Safe::Hole->new( { ROOT => 'Foo' } );
    is( $h2->root(), 'Foo', 'root() returns specified ROOT' );

    my $h3 = Safe::Hole->new('Bar');
    is( $h3->root(), 'Bar', 'root() returns namespace from string constructor' );

    my $h4 = Safe::Hole->new;
    is( $h4->root(), 'main', 'root() returns main for no-arg constructor' );
}

###################################
# Large argument passing
###################################

{
    my @big_args = ( 1 .. 100 );
    my @result = $hole->call( sub { return @_ }, @big_args );
    is( scalar @result, 100, 'call() passes 100 arguments correctly' );
    is( $result[0],     1,   'First argument correct' );
    is( $result[99],    100, 'Last argument correct' );
}

###################################
# Return undef explicitly
###################################

{
    my $result = $hole->call( sub { return undef } );
    is( $result, undef, 'call() handles explicit undef return' );
}

###################################
# Return empty list
###################################

{
    my @result = $hole->call( sub { return () } );
    is( scalar @result, 0, 'call() handles empty list return' );
}

###################################
# wrap() with blessed array ref
###################################

{

    package ArrayObj;
    sub new   { bless [ 'foo', 'bar' ], shift }
    sub first { return $_[0]->[0] }
    sub count { return scalar @{ $_[0] } }
}

{
    my $safe = Safe->new;
    my $h    = Safe::Hole->new( {} );
    my $obj  = ArrayObj->new;
    $h->wrap( $obj, $safe, '$array_obj' );

    is( $safe->reval('$array_obj->first()'), 'foo', 'Wrapped blessed arrayref method' );
    is( $safe->reval('$array_obj->count()'), 2,     'Wrapped blessed arrayref method (count)' );
    is( $@, '', 'No errors from blessed arrayref wrapping' );
}

###################################
# wrap() with blessed scalar ref
###################################

{

    package ScalarObj;
    sub new { my $v = 42; bless \$v, shift }
    sub value { return ${ $_[0] } }
}

{
    my $safe = Safe->new;
    my $h    = Safe::Hole->new( {} );
    my $obj  = ScalarObj->new;
    $h->wrap( $obj, $safe, '$scalar_obj' );

    is( $safe->reval('$scalar_obj->value()'), 42, 'Wrapped blessed scalarref method' );
    is( $@, '', 'No errors from blessed scalarref wrapping' );
}

###################################
# wrap() error: Safe object required
###################################

{
    eval { $hole->wrap( sub { 1 }, "not a Safe", '&foo' ) };
    like( $@, qr/Safe object required/, 'wrap() croaks when $cpt is not a Safe object' );
}

###################################
# call() passes no arguments when none given
###################################

{
    my $result = $hole->call( sub { scalar @_ } );
    is( $result, 0, 'call() with no extra args passes empty @_ to coderef' );
}

###################################
# Wrapped object method with multiple return values
###################################

{

    package MultiReturn;
    sub new    { bless {}, shift }
    sub triple { return ( 1, 2, 3 ) }
}

{
    my $safe = Safe->new;
    my $h    = Safe::Hole->new( {} );
    $h->wrap( MultiReturn->new, $safe, '$mr' );

    my @vals = $safe->reval('@r = $mr->triple(); @r');
    is_deeply( \@vals, [ 1, 2, 3 ], 'Wrapped method returns multiple values' );
    is( $@, '', 'No error from multi-return wrapped method' );
}

###################################
# Concurrent wrapped objects of different classes in same compartment
###################################

{

    package TypeA;
    sub new  { bless { t => 'A' }, shift }
    sub type { return $_[0]->{t} }

    package TypeB;
    sub new  { bless { t => 'B' }, shift }
    sub type { return $_[0]->{t} }
}

{
    my $safe = Safe->new;
    my $h    = Safe::Hole->new( {} );
    $h->wrap( TypeA->new, $safe, '$ta' );
    $h->wrap( TypeB->new, $safe, '$tb' );

    is( $safe->reval('$ta->type()'), 'A', 'First class type correct' );
    is( $safe->reval('$tb->type()'), 'B', 'Second class type correct' );
    is( $@, '', 'No errors from mixed-class compartment' );
}

done_testing();
