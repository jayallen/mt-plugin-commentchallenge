# Comment Challenge plugin for Movable Type
# Author: Jay Allen, Endevver Consulting (http://endevver.com)
# Released under the Artistic License
#
# $Id: commchallenge.pm 1485 2009-03-04 05:00:16Z jallen $

package commchallenge;

use MT::JunkFilter qw(ABSTAIN);

use constant DEBUG_MODE => 0;
use constant NOT_ENABLED => 1;

# Allows for comments from authenticated commenters to bypass
# the Comment Challenge JunkFilter.  This is always a good setting
# so we're not even making it a configuration option. If someone 
# wants to change it, they can hack the code.
use constant AUTH_BYPASS => 1;

# JunkFilter callback score constants
use constant NOBEACON => -10;
use constant BLANKANSWER => -5;
use constant WRONGANSWER => -2;
use constant CORRECTANSWER => 1;

# This is the MTCommentChallenge tag handler. If the beacon is enabled, it 
# is printed out in a hidden form input. If both a challenge and response are
# specified, the challenge text and response input field are output as well.
sub hdlr_comment_challenge {

    debug("In hdlr_comment_challenge");    

    # We output the beacon no matter what although we may 
    # not check for it if the plugin is disabled
    my $markup = '<input type="hidden" id="commchallenge_beacon" name="commchallenge_beacon" value="1" />';

    my $plugin = shift;
    my $ctx = shift;

    my $blog_id = $ctx->stash('blog_id');
    debug("In comment challenge handler for blog ID #$blog_id".($preview ? ' (PREVIEW)':''));
    my $plugin_cfg = $plugin->get_config_hash("blog:$blog_id");

    # If we're checking the beacon and the challenge/response
    # are configured we return the latter two
    if ($plugin_cfg && $plugin_cfg->{commchallenge_mode} &&
        ($plugin_cfg->{commchallenge_question} ne '') &&
        ($plugin_cfg->{commchallenge_answer} ne '')) {

        # TODO: Add javascript to hide challenge/response if commenter auth'd 
        debug('commchallenge_question: '.$plugin_cfg->{commchallenge_question});
        debug('commchallenge_answer: '.$plugin_cfg->{commchallenge_answer});

        my $preview_val = '';
        my $q = MT->instance->{query};

        if (defined($q) && $q->param('preview')) {
            require MT::Util;
            $preview_val = 'value="'.
                (MT::Util::encode_html($q->param('commchallenge_answer')) || "").'"';    
        }

        $markup .= '<label for="commchallenge_answer">'.$plugin_cfg->{commchallenge_question}.
            ' <strong>('.'required'.')</strong>:</label>'.
            '<br /><input type="text" id="commchallenge_answer" name="commchallenge_answer" '.
            $preview_val.'/>';
    }

    my $js = <<EOD;
<script type="text/javascript">
<!--    
if ((typeof commenter_name != 'undefined') ||
    (typeof getCommenterName != 'undefined' &&  getCommenterName())) {
    mtHide('comments-open-challenge');
} else {
    mtShow('comments-open-challenge');
} 
// -->
</script>
EOD
    
    return '<p id="comments-open-challenge">'.$markup.'</p>'.$js;

}


# Removes spaces from front and back of string
sub fulltrim {
    for (@_) {
        s/(^\s+|\s+$)//sg if is_not_null($_);
    }
    @_;
}

# Tests for a defined and not_null value
sub is_not_null {
    my $var = shift;
    return (defined($var) && ($var ne '')) || 0;
}
sub is_null { ! is_not_null(+shift) }

sub is_enabled {
    my $cfg = shift;
    return undef unless $cfg && $cfg->{commchallenge_mode};
    my ($q, $a) = fulltrim( $cfg->{commchallenge_question},
                            $cfg->{commchallenge_answer});
    return  is_not_null($q) && is_not_null($a) ? ($q, $a) : undef;
}

sub is_auth_bypass {
    my $app = MT->instance;
    my %cookies = $app->cookies();
    my $commenter = $cookies{'tk_commenter'}->value
        if $cookies{'tk_commenter'};
    return (AUTH_BYPASS && is_not_null($commenter));
}

# This is a CommentThrottleFilter callback in which we do two things if so configured:
#   1. Short-circuit any comment submission without the challenge beacon
#   2. Inform the commenter in case of a response mismatch
sub callback_comment_throttle_filter {
    debug("In callback_comment_throttle_filter\n");    

    my $plugin = shift;
    my ($eh, $app, $entry) = @_;
    my $q = $app->{query};
    my $blog_id = $entry->blog_id;
    debug("Current Blog ID: $blog_id\n");    

    # Get blog plugin config
    my $plugin_cfg = $plugin->get_config_hash("blog:$blog_id");

    my ($cc_question, $cc_answer) = is_enabled($plugin_cfg)
        or return 1;

    # We're going to do string comparisons here so remove 
    # spaces from front and back of both answers
    my ($response) = fulltrim($q->param('commchallenge_answer'));

    # Throttle if no beacon submitted and THROTTLE_NOBEACON is set.
    # THROTTLE_NOBEACON is a good setting when you know that the plugin 
    # is working and want to make MT work less by short-circuiting the junking
    # of obvious spam by throttling the comment.
    if (    $plugin_cfg->{commchallenge_throttle_nobeacon} 
        and is_not_null($q->param('commchallenge_beacon')) ) {
        require MT::Log;
        $app->log( { level => MT::Log::INFO,
                     blog_id => $blog_id,
                     message => $plugin->translate(
                         'Beaconless comment from commenter \'[_1]\' throttled', $q->param("author")
                         )
                     }
                );
        return 0;
    }

    return 1 if is_auth_bypass();

    # Return if question answered correctly by commenter
    return 1 if equivalent($cc_answer, $response);

    # If we aren't configured to inform the commenter of a response mismatch, 
    # let the submission proceed to the JunkFilter.
    return 1 unless $plugin_cfg->{commchallenge_inform_commenter};

    # Now short-circuiting the comment submission to inform the commenter of the problem.
    my ($user_msg,$log_msg);
    $app->send_http_header;  
    if ($response eq '') { 
        $user_msg = "A response to the challenge question ('[_1]') is required for comment submission. ".
                    "Please go back and enter the correct value.";
        $log_msg = $plugin->translate(
            "Comment throttled from commenter ('[_1]') due to blank challenge response.", $q->param("author")
            );
    } else {
        $user_msg = "Your response to the challenge question ('[_1]') was not correct. ".
                    "Please go back and try again.";
        $log_msg = $plugin->translate(
            "Comment throttled from commenter ('[_1]') due to incorrect challenge response ('[_2]').",
            $q->param("author"),
            $response
            );
    }

    require MT::Log;
    $app->log( { level => MT::Log::INFO,
                 blog_id => $blog_id,
                 message => $log_msg }
            );
    $app->print($app->show_error($app->translate($user_msg, $cc_question)));
    exit;
}


# This is the JunkFilter callback routine where we determine whether a 
# submitted comment has the content specified by the plugin config 
# (i.e. the beacon and, if specified, the correct response to the 
# challenge CAPTCHA)
#
# TODO: Should we disable this is the tag isn't found?
sub eval_comment_challenge {
    debug("In eval_comment_challenge");    

    my ($plugin, $comment) = @_;
    my $q = MT->instance->{query};
    my $blog_id = $comment->blog_id;
    debug("Current Blog ID: $blog_id\n");    

    # Get blog plugin config
    my $plugin_cfg = $plugin->get_config_hash("blog:$blog_id");

    my ($cc_question, $cc_answer) = is_enabled($plugin_cfg)
        or return (ABSTAIN, undef);

    # We're going to do string comparisons here so remove 
    # spaces from front and back of both answers
    my ($response) = fulltrim($q->param('commchallenge_answer'));
    
    # JUNK the comment if NO BEACON
    return (NOBEACON, $plugin->translate('Challenge beacon not submitted with comment.'))
        unless is_not_null($q->param('commchallenge_beacon'));

    return (ABSTAIN, undef) if is_auth_bypass();

    my $result = equivalent($cc_answer, $response) ? CORRECTANSWER
               : is_null($response)                ? BLANKANSWER
               :                                     WRONGANSWER;

    # NOT JUNK if CORRECT challenge response
    if (equivalent($cc_answer, $response)) {        
        return (CORRECTANSWER, 
            $plugin->translate("Challenge question ('[_1]') answered correctly.", $cc_question));

    # JUNK if BLANK challenge response
    } elsif ($response eq '') { 

        # I'd LIKE to return an app error here but there's no check for that... 
        return (BLANKANSWER,
            $plugin->translate("Comment challenge question ('[_1]') not answered.", $cc_question));

    # JUNK if INCORRECT challenge response
    } else {
        return (WRONGANSWER, $plugin->translate(
                    "Answer ('[_1]') to challenge question ('[_2]') does not match stored answer ('[_3]').",
                    $response,
                    $cc_question,
                    $cc_answer
                )
            );        

    }

}

# This test two variables for equality in a case-insensitive manner
sub equivalent { 
    my ($a, $b) = @_;
    return ( is_null($a) && is_null($b)) || (lc($a) eq lc($b) );
}

# Logging function for the MT Activity Log
sub mtlog {
    my $app = MT::App->instance;
    $app->log(+shift);
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
