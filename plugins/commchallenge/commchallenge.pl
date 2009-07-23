# Comment Challenge plugin for Movable Type
# Author: Jay Allen, Endevver Consulting (http://endevver.com)
# Released under the Artistic License
#
# $Id: commchallenge.pl 1485 2009-03-04 05:00:16Z jallen $

package MT::Plugin::CommentChallenge;

use strict;
use 5.006;    # requires Perl 5.6.x
use MT 3.2;   # requires MT 3.2 or later
use warnings;

use constant DEBUG_MODE => 0;

use base 'MT::Plugin';

our $VERSION = "1.04";

(our $PLUGIN_MODULE = __PACKAGE__) =~ s/^MT::Plugin:://;

my $plugin;
MT->add_plugin($plugin = __PACKAGE__->new({
    name => 'Comment Challenge',
    version => $VERSION,
    key => 'commchallenge',
    description => '<MT_TRANS phrase="This anti-spam plugin stops direct injection of comment spam into Movable Type and enables you to implement a challenge/response defense via an accessible CAPTCHA.">',
    doc_link => 'http://jayallen.org/projects/commentchallenge/docs',
    author_name => 'Jay Allen',
    author_link => 'http://www.jayallen.org/',
    plugin_link => 'http://www.jayallen.org/projects/commentchallenge/',
    blog_config_template => 'blog_config.tmpl',
    l10n_class => 'commchallenge::L10N',
    settings => new MT::PluginSettings([
        ['commchallenge_mode', { Default => 0 }],
        ['commchallenge_question', { Default => '' }],
        ['commchallenge_answer', { Default => '' }],
        ['commchallenge_inform_commenter', { Default => 0 }],
        ['commchallenge_throttle_nobeacon', { Default => 0 }]
    ]),
    registry => {
        callbacks => {
            CommentThrottleFilter => {
                code => sub { $plugin->runner('callback_comment_throttle_filter', @_) },
                priority => 5,
            }
        },
        junk_filters => {
            commentchallenge => {
                label => "Comment challenge",
                code => sub { $plugin->runner('callback_comment_throttle_filter', @_) },
            },
            
        },
        tags => {
            function => {
                CommentChallenge => sub { $plugin->runner('hdlr_comment_challenge', @_) },
            }
        }
    },
}));

# Adding L10N bootstrapping for MT 3.2
if ($MT::VERSION < 3.3) {
    foreach my $class (qw(CMS Comments Trackback)) {
        MT->add_callback('MT::App::'.$class.'::pre_run', 1, $plugin, \&add_l10n);
    }
}

sub runner {
    my $plugin = shift;
    my $method = shift;
    require commchallenge;
    return $_->($plugin, @_) if $_ = \&{"commchallenge::$method"};
    die "Failed to find commchallenge::$method";
}


sub load_tmpl {
    my $self = shift;
    my $tmpl = $self->SUPER::load_tmpl(@_);
    $tmpl->param(add_showhidejs => 1) if $MT::VERSION == '3.2';
    $tmpl;
 }

# Internal config retrieval method
sub get_config_hash {
    debug('In get_config_hash()');

    my $self = shift;
    my $blog_id = $_[0];    

    require MT::Request;
    my $cfg = MT::Request->instance->cache('commchallenge_config_blog_'.$blog_id) || {};

    unless (keys %$cfg) {
        debug('Loading config for blog ID '. $blog_id);
        $cfg = $self->SUPER::get_config_hash(@_);
        MT::Request->instance->cache('commchallenge_config_blog_'.$blog_id, $cfg);
    }
    $cfg;
}

# We use an MT::App::CMS::pre_run callback to
# bootstrap the plugin's localization module
# and then handle the translate calls if needed.
sub add_l10n {
    my ($cb,$app) = @_;
    (my $lang = $app->current_language) =~ s/-/_/g;
    eval "require commchallenge::L10N::$lang";
}
sub translate {
    my $plugin = shift;
    return $MT::VERSION < 3.3   ?   MT->instance->translate(@_)
                                :   $plugin->SUPER::translate(@_);
}

# Utility debug method for writing to error log
sub debug {
    return unless DEBUG_MODE;
    require Jayutils;
    Jayutils::debug(@_);
}
sub debug_ref {
    return unless DEBUG_MODE;
    require Jayutils;
    Jayutils::debug_ref(@_);
}
sub debug_dump {
    return unless DEBUG_MODE;
    require Jayutils;
    Jayutils::debug_dump(@_);
}


1;
