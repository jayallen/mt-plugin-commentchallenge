# Comment Challenge plugin for Movable Type
# Author: Jay Allen, Endevver Consulting (http://endevver.com)
# Released under the Artistic License
#
# $Id$

# Comment challenge localization file
#
# This package defines the English phrases used by the plugin
# and can be used as a basis for localization of Comment Challenge
#
# To create a localization, simply do the following:
#
# 1) Create a copy of this file with a name beginning with your
#    language code and ending in '.pm'.  For example, a French
#    localization file would be named 'fr.pm'.
# 2) Translate the strings on the right side of the => operators
#    below or on the following line if following a => operator.
#    You must use a backslash to escape single quotes.
# 3) Replace all occurances of 'en_us' in this file with your
#    own language code
#
package commchallenge::L10N::en_us;
use strict;
use base 'commchallenge::L10N';
use vars qw( %Lexicon );

%Lexicon = (

    #
    # Strings from plugin template
    #
    'Beacon:'            => 'Beacon:',
    'BEACON_SETTING'     => 'Check for MTCommentChallenge beacon in comment submissions.',
    'BEACON_DESCRIPTION' =>
'This option prevents spam bots from directly injecting comments into the system via the comment script.',
    'BEACON_WARNING'     => 'WARNING: Make sure that the MTCommentChallenge tag is in your templates and that they are rebuilt before enabling this option',

    'THROTTLE_SETTING'     => 'Deny (&quot;throttle&quot;) submissions without beacon (instead of Junking)',
    'THROTTLE_DESCRIPTION' => 'While throttling such submissions reduces the load on the system, it could also cause lost comments if the MTCommentChallenge tag is not in your comment form. <strong>See plugin documentation for discussion</strong> before enabling this option.',

    'Challenge/Response CAPTCHA:' => 'Challenge/Response CAPTCHA:',
    'CAPTCHA_DESCRIPTION'         => 'You can optionally present your commenters with a challenge CAPTCHA.  The answer given will be compared case-insensitively to the answer you provide below.',
    'Challenge:'      => 'Challenge:',
    'Response:'       => 'Response:',
    'REBUILD_WARNING' => 'WARNING: If you change this setting and the template containing your comment form is static, you must immediately rebuild that template type after you save this configuration! For most people, this means a rebuild of your individual entries.',

    'Incorrect response action:'  => 'Incorrect response action:',
    'Score comment as Junk'       => 'Score comment as Junk',
    'Inform commenter of problem' => 'Inform commenter of problem',
    'RESPONSE_DESCRIPTION'        => 'Informing the commenter of a blank or incorrect response allows them to correct the error, but if your question is too difficult, their comment is never submitted.  See plugin documentation for discussion.',

    #
    # Strings within the application code
    #
    'This anti-spam plugin stops direct injection of comment spam into Movable Type and enables you to implement a challenge/response defense via an accessible CAPTCHA.'   =>
    'This anti-spam plugin stops direct injection of comment spam into Movable Type and enables you to implement a challenge/response defense via an accessible CAPTCHA.',
    
    'Beaconless comment from commenter \'[_1]\' throttled' =>
    'Beaconless comment from commenter \'[_1]\' throttled',

    'A response to the challenge question (\'[_1]\') is required for comment submission. Please go back and enter the correct value.'   =>
    'A response to the challenge question (\'[_1]\') is required for comment submission. Please go back and enter the correct value.',
    
    'Comment throttled from commenter (\'[_1]\') due to blank challenge response.'  =>
    'Comment throttled from commenter (\'[_1]\') due to blank challenge response.',

    'Your response to the challenge question (\'[_1]\') was not correct. Please go back and try again.' =>
    'Your response to the challenge question (\'[_1]\') was not correct. Please go back and try again.',

    'Comment throttled from commenter (\'[_1]\') due to incorrect challenge response (\'[_2]\').' =>
    'Comment throttled from commenter (\'[_1]\') due to incorrect challenge response (\'[_2]\').',

    'Challenge beacon not submitted with comment.'  =>
    'Challenge beacon not submitted with comment.',

    'Challenge question (\'[_1]\') answered correctly.' =>
    'Challenge question (\'[_1]\') answered correctly.',

    'Comment challenge question (\'[_1]\') not answered.'   =>
    'Comment challenge question (\'[_1]\') not answered.',

    'Answer (\'[_1]\') to challenge question (\'[_2]\') does not match stored answer (\'[_3]\').'   =>
    'Answer (\'[_1]\') to challenge question (\'[_2]\') does not match stored answer (\'[_3]\').',

);

if ($MT::VERSION < 3.3) {
    require MT::L10N::en_us;
    $MT::L10N::en_us::Lexicon{$_} = $Lexicon{$_}
        foreach keys %Lexicon;
}

1;
