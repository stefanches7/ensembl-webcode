package Bio::EnsEMBL::GlyphSet::chr_band;

use strict;
use warnings;
no warnings 'uninitialized';

use base qw(Bio::EnsEMBL::GlyphSet);

sub _init {
  my $self = shift;

  return $self->render_text if $self->{'text_export'};
  
  ########## only draw contigs once - on one strand
  
  my ($fontname, $fontsize) = $self->get_font_details('innertext');
  my $bands      = $self->features;
  my $h          = [ $self->get_text_width(0, 'X', '', font => $fontname, ptsize => $fontsize) ]->[3];
  my $pix_per_bp = $self->scalex;
  my @t_colour   = qw(gpos25 gpos75);
  my $length     = $self->{'container'}->length;
  
  foreach my $band (@$bands) {
    my $bandname   = $band->name;
    my $stain      = $band->stain;
    my $start      = $band->start;
    my $end        = $band->end;
       $start      = 1       if $start < 1;
       $end        = $length if $end   > $length;
    my $col        = $self->my_colour($stain);
    my $fontcolour = $self->my_colour($stain, 'label') || 'black';
    
    if (!$stain) {
      $stain      = shift @t_colour;
      $col        = $self->my_colour($stain);
      $fontcolour = $self->my_colour($stain, 'label');
      
      push @t_colour, ($stain = shift @t_colour);
    }
    
    $self->push($self->Rect({
      x            => $start - 1 ,
      y            => 0,
      width        => $end - $start + 1 ,
      height       => $h + 4,
      colour       => $col || 'white',
      absolutey    => 1,
      title        => "Band: $bandname",
      href         => $self->href($band),
      bordercolour => 'black'
    }));
    
    if ($fontcolour ne 'invisible') {
      my @res = $self->get_text_width(($end - $start + 1) * $pix_per_bp, $bandname, '', font => $fontname, ptsize => $fontsize);
      
      # only add the lable if the box is big enough to hold it
      if ($res[0]) {
        $self->push($self->Text({
          x         => ($end + $start - 1 - $res[2]/$pix_per_bp) / 2,
          y         => 1,
          width     => $res[2] / $pix_per_bp,
          textwidth => $res[2],
          font      => $fontname,
          height    => $h,
          ptsize    => $fontsize,
          colour    => $fontcolour,
          text      => $res[0],
          absolutey => 1,
        }));
      }
    }
  }
  
  $self->no_features unless scalar @$bands;
}

sub render_text {
  my $self = shift;
  my $export;
  
  foreach (@{$self->features}) {
    $export .= $self->_render_text($_, 'Chromosome band', { 
      headers => [ 'name' ], 
      values  => [ $_->name ] 
    });
  }
  
  return $export;
}

sub features {
  my $self = shift;
  return [ sort { $a->start <=> $b->start } @{$self->{'container'}->get_all_KaryotypeBands || []} ];
}

sub href {
  my ($self, $band) = @_;
  my $slice = $band->project('toplevel')->[0]->to_Slice;
  return $self->_url({ r => sprintf('%s:%s-%s', map $slice->$_, qw(seq_region_name start end)) });
}

sub colour_key { return $_[1]->stain; }

sub feature_label {
  my ($self, $f) = @_;
  return $self->my_colour($self->colour_key($f), 'label') eq 'invisible' ? '' : $f->name;
}

sub canvas_attributes { return ( borderColor => '#000000' ); }

1;
