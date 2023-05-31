#!/usr/bin/perl -w
#
# Generate a script which when run recompiles each and every package
# in the Gentoo system.
# This will typically be required on a major GCC upgrade.
#
# $HeadURL: /caches/xsvn/trunk/usr/local/sbin/recompile-entire-system $
# $Author: root $
# $Date: 2006-09-01T14:15:49.548823Z $
# $Revision: 334 $
#
# Written in 2006 by Guenther Brunthaler


use strict;
use File::Temp ':POSIX';


# Change this to any name you like.
my $script= "recompile-remaining-packages";


my $script_header= << '.';
#!/bin/sh
# Run this script repeatedly (if interrupted)
# until no more packages will be compiled.
#
# $Date: 2006-09-01T14:15:49.548823Z $
# $Revision: 334 $
# Written in 2006 by Guenther Brunthaler

STATE_FILE="$HOME/.recompile-entire-system.state"

die() {
        echo "ERROR: $*" >& 2; exit 1
}

save_progress() {
        { echo "$OURGCC"; echo $PROGRESS; } > "$STATE_FILE"
}

item() {
        test "$PROGRESS" -ge "$1" && return
        echo "Emerging package # $1 ('$2')..."
        emerge --oneshot --nodeps "$2" || {
                die "Emerge failed return code $?!"
        }
        echo "Package # $1 rebuild complete."; echo
        PROGRESS="$1"; save_progress
}

OURGCC="`gcc-config --get-current-profile`" || die "gcc-config failed!"
PROGRESS=; LASTGCC=
{ read LASTGCC; read PROGRESS; } < "$STATE_FILE" 2> /dev/null
if [ "$OURGCC" != "$LASTGCC" -o -z "$PROGRESS" ]; then
        PROGRESS=0; save_progress
fi

.

my $script_tail= << '.';

echo
echo "Success! All packages have been re-compiled."
echo "Your system is now up-to-date with respect to $OURGCC!"
echo
echo "If your want to recompile the whole system again"
echo "for the *same* GCC version, please"
echo "\$ rm \"$STATE_FILE\""
echo "in order to reset the sucessfully-recompiled-packages counter."
.


# Remove the largest common whitespace prefix from all lines
# of the first argument.
# (Empty lines or lines containing only whitespace are skipped
# by this operation and will be replaced by
# completely empty lines.)
# The first argument must either be a reference to a multiline
# string containing newline characters or a reference to an
# array of single line strings (without newline characters).
# Then optionally indent all resulting lines with the prefix
# specified as the argument to the -first option.
# For all indented lines do the same, but use the argument
# to option -indent as the value of the -first option then.
# If option -wrap <number> is specified, contiguous non-empty
# lines of the same indentation depth are considered paragraphs,
# and will be word-wrapped on output, resulting in a maximum
# total line length of <number> characters.
# The word-wrappin will occur on whitespaces, which can be
# protected by a backslash.
sub normalize_indentation {
   my($tref, %opt)= @_;
   my(@t, $t, $p, $pl);
   $opt{-first}||= '';
   $opt{-indent}||= ' ';
   $t= ref($tref) eq 'ARRAY' ? $tref : [split /\n/, $$tref];
   foreach (@$t) {
      s/^\s+$//;
      next if $_ eq '';
      if (defined $pl) {
         for (;;) {
            substr($p, $pl= length)= '' if length() < $pl;
            last if substr($_, 0, $pl) eq $p;
            substr($p, --$pl)= '';
         }
      } else {
         ($p)= /^(\s*)/;
         $pl= length $p;
      }
   }
   substr($_, 0, $pl)= '' foreach grep $_ ne '', @$t;
   if (exists $opt{-wrap}) {
      my $width= $opt{-wrap} - length $opt{-first};
      my $i;
      my $wrap= sub {
         my($tref, $aref, $iref, $w)= @_;
         my $buf;
         my $insert= sub {
            my($tref, $aref, $iref)= @_;
            splice @$aref, $$iref++, 0, $$tref if defined $$tref;
            undef $$tref;
         };
         return unless $$tref;
         foreach (split /(?:(?<!\\)\s)+/, $$tref) {
            s/\\\s/ /gs;
            if (length($buf || '') + length > $w) {
               &$insert(\$buf, $aref, $iref);
            }
            if (defined $buf) {$buf.= " $_"} else {$buf= $_}
         }
         &$insert(\$buf, $aref, $iref);
         undef $$tref;
      };
      $width= 1 if $width < 1;
      undef $p;
      for ($i= 0; $i < @$t; ) {
         if ($t->[$i] =~ /^(?:\s|$)/) {
            &$wrap(\$p, $t, \$i, $width);
            ++$i;
         } else {
            if (defined $p) {$p.= ' '} else {$p= ''}
            $p.= $t->[$i];
            splice @$t, $i, 1;
         }
      }
      &$wrap(\$p, $t, \$i, $width);
   }
   for (my $i= 0; $i < @$t; ) {
      if ($t->[$i] =~ /^\s/) {
         push @t, splice @$t, $i, 1;
         next;
      }
      if (@t) {
         &normalize_indentation(\@t, %opt, -first => $opt{-indent});
         splice @$t, $i, 0, @t;
         $i+= @t;
         @t= ();
      }
      ++$i;
   }
   if (@t) {
      &normalize_indentation(\@t, %opt, -first => $opt{-indent});
      push @$t, @t;
   }
   substr($_, 0, 0)= $opt{-first} foreach grep $_ ne '', @$t;
   $$tref= join '', map "$_\n", @$t if ref($tref) ne 'ARRAY';
}


sub wrap0(@) {
   my $text= join ' ', @_;
   normalize_indentation \$text, -indent => '    ', -wrap => 79;
   return \$text;
}


sub pwrap(@) {
   print ${wrap0 @_};
}


our $step= 0;
our $substep;


sub check {
   my %opt= @_;
   my %a= (y => {qw/name yes/}, n => {qw/name no/}, a => {qw/name abort/});
   my($q, $default, $k, $v, $m, $a, @a);
   die "Missing question" unless $q= $opt{q};
   delete $opt{q};
   while (($k, $v)= each %opt) {
      if (!exists $a{$k} && exists $a{$k= lc $k}) {
         die "Duplicate default answer '$k' in $q" if $default;
         $default= $k;
      } elsif (!exists $a{$k}) {
         die "Unsupported key '$k' in '$q'";
      }
      $a{$k}->{val}= $v;
   }
   unless ($a{y}->{val} && $a{n}->{val}) {
      if ($a{y}->{val} || $a{n}->{val}) {
         # Only one of (yes, no).
         # The other automatically means 'continue'.
         $a{y}->{val}= sub{} unless $a{y}->{val};
         $a{n}->{val}= sub{} unless $a{n}->{val};
      } else {
         # Neither yes nor no available. Only "abort" remains.
         delete $a{y};
         delete $a{n};
      }
   }
   if ($substep) {
      $k= $step . $substep++;
   } else {
      $k= ++$step;
   }
   substr($q, 0, 0)= "Step $k: ";
   $q.=
      "? ["
      . join(
         "/"
         , map {
            my $s= $a{$_}->{name};
            $s =~ s/^(.)/\u$1/ if $_ eq $default;
            $m= length $s if !defined($m) || length($s) > $m;
            $s;
         } keys %a
      )
      . "] "
   ;
   $q.= '#' x ++$m;
   $q= ${wrap0 $q};
   substr($q, -($m + 1))= '';
   for (;;) {
      {
         local $|= 1;
         print $q;
         $a= <STDIN>;
         $a =~ s/^\s*|\s*$//g;
      }
      if ($a) {
         @a= grep {
            length($a) <= length()
            && lc($a) eq substr($_, 0, length)
         } keys %a;
         if (@a == 0) {
            pwrap
               "Sorry, I do not understand your answer '$a'!"
               , "Please select one of the available answers.\n\n"
            ;
            next;
         }
         if (@a > 1) {
            pwrap
               "Sorry, but your answer '$a' is ambiguous!"
               , "Please provide a more specific answer.\n\n"
            ;
            next;
         }
         $a= shift @a;
      } elsif (eof STDIN) {
         # Got EOF. Get the 'abort' equivalent.
         ($a)= grep !defined($a{$_}->{val}), keys %a;
         die unless $a;
      } else {
         # Just an empty string.
         $a= $default;
      }
      last;
   }
   $m= $a{$a}->{val} || sub {
      pwrap
         "OK, then check out the things yourself."
         , "Come back and re-run this script when you are done."
      ;
      exit 0;
   };
   unless (ref $m eq 'CODE') {
      die "Answer '$a' in '$q' has invalid contents";
   }
   $k= $substep;
   local $substep= $k ? $k++ : 'a';
   &$m;
}


sub quote_command(@) {
   return join(
      ' '
      , map {
         /[\s"]|^$/
         ? do {
            my $s= $_;
            $s =~ s/"/\\"/g;
            qq'"$s"';
         }
         : $_
      } @_
   );
}


sub xsystem(@) {
   print "Simulation: ", @_, "\n";
   0;
}


sub run(@) {
   my $self= shift;
   die "No command specified for execution" unless @_;
   if (xsystem(@_) != 0) {
      if ($? == -1) {
         die "Could not launch command: $!";
      } elsif ($? & 127) {
         die sprintf(
            "Child process died with signal %d, %s coredump"
            , $? & 127, $? & 128 ? 'with' : 'without'
         );
      } else {
         die sprintf "Child process exited with value %d", $? >> 8;
      }
   }
}


sub shall_run(@) {
   my $disp= quote_command @_;
   check(
      q => "Shall I run '$disp' for you now"
      , Y => sub {run @_}
   );
}


$_=q<
But only run this script after taking the following steps:
* Do an 'emerge --sync' in order to ensure your portage tree is up to date.
* Run 'emerge --update --deep --newuse world' to ensure all packages are up to
  date (using your old compiler).
* Optionally run 'emerge --ask --depclean' in order to remove any leftover
  old packages (You don't want to recompile those later, don't you?)
* Emerge the new compiler you want>;

$ENV{LC_ALL}= "C";
my $home= $ENV{HOME};
unless ($home && -d $home) {
   die 'Please set $HOME to your home directory';
}
$home =~ s!/*$!/!;
substr($script, 0, 0)= $home;
if (-e $script) {
   die "Please remove the existing '$script'.\nIt is in the way";
}
pwrap "$0 -", << '.';
Recompile Entire System Helper

Script version as of $Date: 2006-09-01T14:15:49.548823Z $

Written in 2006 by Guenther Brunthaler

This script will generate another script to be run by you.
That other script will then recompile each and every package
in the whole system in the correct order.

This will typically be required on a major GCC upgrade.

IMPORTANT: Do not execute this script before all of the following
prerequisites are met:

* Portage tree is up-to-date (emerge --sync)

* Your system is up-to-date (emerge --ask --update --deep --newuse world)

* gentoolkit is available. (The script uses it.) If you are unsure, just
do an 'emerge\ --update\ gentoolkit' and it will be emerged unless it is
already installed.

* The new compiler you want is already *installed*. (No packages need have to
be recompiled with it yet. It also need not be the currently selected default
compiler version yet.) As GCC allows multislot installations, it is not a
problem in Gentoo to have both your current and a new compiler be installed at
the same time.

* If all the above conditions are met, and no more packages need to be
compiled in order to have an up-to-date system, set the new compiler as the
new system default compiler using "gcc-config".

* If you want to change your Gentoo system profile to a new one using
eselect\ profile, it is now also the right time to do it.

* Only then continue running this script!

Press [Ctrl]+[C] now in order to abort processing if some of the above
preconditions are not met. Come back and re-run this script after you have
managed to establish all the preconditions as specified.

Press [Enter] now to continue if you dare.

.
<STDIN>;
#But before the build-script can be generated, there is a check list
#you have to go through, because recompiling an entire system is
#a delicate and highly error-prone task.
#
#So let's start with the check list now!
#.
#print "\n";
#check(
#   q => 'Is your portage tree up to date (have you run "emerge\ --sync" lately)'
#   , N => sub {shall_run 'emerge --sync'}
#);
#exit;
my $tmp= tmpnam or die "No temporary file names left";
print "Collecting list of packages and evaluating installation order...\n";
my @head= qw(
   sys-kernel/linux-headers
   sys-devel/gcc
   sys-libs/glibc
   sys-devel/binutils
);
my $r= join '|', map quotemeta, @head;
$r= qr/ ^ (?: $r ) - \d /x;
open OUT, (
   '| sort -k1,1 | sort -suk3,3 | sort -nk2,2 | sort -sk1,1 '
   . '| cut -d" " -f3 >> "' . $tmp . '"'
) or die "Cannot open output pipe: $!";
my $n= 0;
foreach my $f (qw/system world/) {
   open IN, "emerge -pe $f |" or die "Cannot open input pipe for '$f': $!";
   while (defined($_= <IN>)) {
      if (/]\s+(.*?)\s/) {
         (my $t, $_)= ($f, $1);
         if (/$r/o) {
            for (my $i= @head; $i--; ) {
               my $L= length $head[$i];
               if (length >= $L && substr($_, 0, $L) eq $head[$i]) {
                  print OUT "begin $i";
                  goto field3;
               }
            }
         }
         print OUT "$t ", ++$n;
         field3:
         print OUT " =$_\n";
      }
   }
   close IN or die $!;
}
close OUT or die $!;
open IN, '<', $tmp or die "Cannot open file '$tmp': $!";
open OUT, '>', "$script" || die "Could not create '$script': $!";
print OUT $script_header;
$n= 1;
while (defined($_= <IN>)) {
   next if m!^=sys-devel/gcc!; # It's already up to date!
   print OUT "item $n $_"; ++$n;
}
print OUT $script_tail;
close OUT or die "Could not finish writing '$script': $!";
close IN or die $!;
unlink($tmp) == 1 or warn "Could not remove temorary file '$tmp': $!";
unless (chmod(0755, $script) == 1) {
   die "Could not set permissions for '$script': $!";
}
#pwrap << ".";
