package builder::MyBuilder;
use strict;
use warnings;
use base 'Module::Build::XSUtil';

use File::Spec::Functions qw(catfile catdir);
use Config;

my $MSGPACK = 'msgpack-3.0.1';

sub new {
    my ($class, %argv) = @_;
    $class->SUPER::new(
        %argv,
        include_dirs => [catdir($MSGPACK, 'include')],
        generate_ppport_h => catfile('lib', 'Data', 'MessagePack', 'ppport.h'),
        cc_warnings => 1,
    );
}

sub _build_msgpack {
    my $self = shift;
    chdir $MSGPACK;
    my $ok = $self->do_system(qw(cmake -DMSGPACK_ENABLE_SHARED=OFF -DCMAKE_POSITION_INDEPENDENT_CODE=ON .));
    $ok &&= $self->do_system($Config{make}, 'msgpackc-static');
    chdir "..";
    $ok;
}

sub ACTION_code {
    my ($self, @argv) = @_;
    my $spec = $self->_infer_xs_spec(catfile("lib", "Data", "MessagePack", "Stream.xs"));
    my $archive = catfile($MSGPACK, "libmsgpackc.a");
    if (!$self->up_to_date($archive, $spec->{lib_file})) {
        $self->_build_msgpack or die;
        push @{$self->{properties}{objects}}, $archive; # XXX
    }
    $self->SUPER::ACTION_code(@argv);
}

1;
