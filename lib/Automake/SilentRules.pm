package Automake::SilentRules;

use Automake::Utils;
use Automake::Variable;
use Exporter;

use vars '@ISA', '@EXPORT';

@ISA = qw (Exporter);

@EXPORT = qw (verbose_flag verbose_nodep_flag silent_flag
	      define_verbose_texinfo define_verbose_libtool
	      handle_silent);

# Silent rules handling functions.

# verbose_flag (NAME)
# -------------------
# Contents of '%VERBOSE%' variable to expand before rule command.
sub verbose_flag
{
    my ($name) = @_;
    return '$(' . verbose_var ($name) . ')';
}

sub verbose_nodep_flag
{
    my ($name) = @_;
    return '$(' . verbose_var ($name) . subst ('am__nodep') . ')';
}

# silent_flag
# -----------
# Contents of %SILENT%: variable to expand to '@' when silent.
sub silent_flag ()
{
    return verbose_flag ('at');
}

# Engage the needed silent rules machinery for assorted texinfo commands.
sub define_verbose_texinfo ()
{
  my @tagvars = ('DVIPS', 'MAKEINFO', 'INFOHTML', 'TEXI2DVI', 'TEXI2PDF');
  foreach my $tag (@tagvars)
    {
      define_verbose_tagvar($tag);
    }
  define_verbose_var('texinfo', '-q');
  define_verbose_var('texidevnull', '> /dev/null');
}

# Engage the needed silent rules machinery for 'libtool --silent'.
sub define_verbose_libtool ()
{
    define_verbose_var ('lt', '--silent');
    return verbose_flag ('lt');
}

sub handle_silent ()
{
    # Define "$(AM_V_P)", expanding to a shell conditional that can be
    # used in make recipes to determine whether we are being run in
    # silent mode or not.  The choice of the name derives from the LISP
    # convention of appending the letter 'P' to denote a predicate (see
    # also "the '-P' convention" in the Jargon File); we do so for lack
    # of a better convention.
    define_verbose_var ('P', 'false', ':');
    # *Always* provide the user with '$(AM_V_GEN)', unconditionally.
    define_verbose_tagvar ('GEN');
    define_verbose_var ('at', '@');
}

1;
