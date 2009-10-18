# prog_error due to invalid $VERSION.

use Automake::Version;

Automake::Version::check ('', '1.2.3');
