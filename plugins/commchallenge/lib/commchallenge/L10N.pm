package commchallenge::L10N;
use strict;

eval {
    require MT::Plugin::L10N; 
    @commchallenge::L10N::ISA = ('MT::Plugin::L10N');
};
# use base 'MT::Plugin::L10N';

1;
