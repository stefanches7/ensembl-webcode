package EnsEMBL::Web::Command::Account::ShareRecord;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::RegObj;
use EnsEMBL::Web::Data::Group;

use base 'EnsEMBL::Web::Command';

{

sub process {
  my $self = shift;
  my $object = $self->object;

  my $user = $EnsEMBL::Web::RegObj::ENSEMBL_WEB_REGISTRY->get_user;
  my $type = lc($object->param('type')).'s';

  my ($records_accessor) = grep { $_ eq $type } keys %{ $user->relations };
  ## TODO: this should use abstraction limiting facility rather then grep

  my ($user_record)      = grep { $_->id == $object->param('id') } $user->$records_accessor;

  my $group = EnsEMBL::Web::Data::Group->new($object->param('webgroup_id'));

  if ($user_record && $group) {
    my $add_to_accessor = 'add_to_'. $records_accessor;
    my $clone = $user_record->clone;
    $group->$add_to_accessor($user_record->clone);
  } else {
    ## TODO: error exception
  }
  
  $self->ajax_redirect('/Account/Group/Display' {'id'=>$object->param('webgroup_id')});
}

}

1;
