use warnings;
use strict;


package Prophet::Test::Participant;
use base qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw/name arena/);
use Prophet::Test;
use Scalar::Util qw/weaken/;




sub new {

    my $self = shift->SUPER::new(@_);
    $self->_setup();
    weaken($self->{'arena'});
    
    return $self;
}

sub _setup {
    my $self = shift;
    as_user($self->name, sub { run_ok('prophet-node-search', [qw(--type Bug --regex .)])});


}

use List::Util qw(shuffle);

my @CHICKEN_DO = qw(create_record create_record delete_record  update_record update_record update_record update_record update_record update_record update_record update_record sync_from_peer sync_from_peer noop);

sub take_one_step {
    my $self = shift;
    my $action = shift || (shuffle(@CHICKEN_DO))[0];
    diag("We're taking a step: $action");
    $self->$action();


}


sub _random_props {
     my @prop_values = Acme::MetaSyntactic->new->name( batman=>5);
     my @prop_keys = Acme::MetaSyntactic->new->name( lotr=>5);

    return( map { "--".$prop_keys[$_] => $prop_values[$_] } (0..4));
        

        
}

sub _permute_props {
    my %props = (@_);
    @props{keys %props} = shuffle(values %props);

    for(keys %props) {
        if(int(rand(10) < 2)){
            delete $props{$_};
        }
    }
    
    if (int(rand(10) < 3)) {
     $props{Acme::MetaSyntactic->new->name( 'lotr')} = Acme::MetaSyntactic->new->name( 'batman');
    }
    

    return %props;
}

sub noop {
    my $self = shift;
    diag($self->name, ' - NOOP');
}
sub delete_record {
    my $self = shift;
    run_ok('prophet-node-delete', [qw(--type Scratch --uuid),  get_random_local_record()]);

}
sub create_record {
    my $self = shift;
    run_ok('prophet-node-create', [qw(--type Scratch),   _random_props()    ], "Created a record");
}

sub update_record {
    my $self = shift;
    my $update_record = get_random_local_record();
    
    my ($ok, $stdout, $stderr) = run_script('prophet-node-show', [qw(--type Scratch --uuid), $update_record]);
    diag($stdout);
    
    my %props = map { split(/: /,$_,2) } split(/\n/,$stdout);
    delete $props{id};
    
    %props =      _permute_props(%props); 
    
    run_ok('prophet-node-update', [qw(--type Scratch --uuid), $update_record,        map { '--'.$_ => $props{$_} } keys %props  ], "Updated a record");


    diag($self->name, ' - update a record');

}
sub sync_from_peer {
    my $self = shift;
    my $lucky = (shuffle(@{$self->arena->chickens}))[0];
  
#    my $lucky = shift @peers;
    diag($self->name, ' - sync from a random peer - ' . $lucky->name);
    run_ok('prophet-merge', ['--from', repo_uri_for($lucky->name), '--to', repo_uri_for($self->name)], "Sync ran ok!");



}

sub get_random_local_record {
    my ($ok, $stdout, $stderr) = run_script('prophet-node-search', [qw(--type Scratch --regex .)]);
    my $update_record = (shuffle( map { $_ =~ /^(\S*)/ } split(/\n/,$stdout)))[0];
    return $update_record;
}


sub sync_from_all_peers {}
sub dump_state {}
sub dump_history {}

1;