<?php
# Comment Challenge plugin for Movable Type
# Author: Jay Allen, Six Apart (http://www.sixapart.com)
# Released under the Artistic License
#
# $Id: function.MTCommentChallenge.php 119 2006-11-15 04:57:27Z jallen $

global $mt;

# This retrieves the Smarty instance we use to
# declare our template compilation hints...
$ctx = &$mt->context();

//$ctx->register_function('MTCommentChallenge', 'mtcommentchallenge');

function commchallenge_config($ctx) {
    $config = $ctx->stash('commchallenge_config');
    if ($config)
        return $config;
    $blog_id = $ctx->stash('blog_id');
    $config = $ctx->mt->db->fetch_plugin_config('commchallenge', 'blog:' . $blog_id);
    if (!$config)
        $config = $ctx->mt->db->fetch_plugin_config('commchallenge');
    if (!$config)
        $config = array('commchallenge_mode' => 0);
    $ctx->stash('commchallenge_config', $config);
    return $config;
}

/*
 This is the MTCommentChallenge tag handler. If the beacon is enabled, it 
 is printed out in a hidden form input. If both a challenge and response are
 specified, the challenge text and response input field are output as well.
*/
function smarty_function_MTCommentChallenge($args, &$ctx) {

	// We output the beacon no matter what although we may 
	// not check for it if the plugin is disabled
	$markup = '<input type="hidden" id="commchallenge_beacon" name="commchallenge_beacon" value="1" />';

	// No challenge/response if authenticated commenter
	if ( ! $_COOKIE['commenter_name'] ) {

		// Let's get the plugin config
	    $plugin_cfg = commchallenge_config($ctx);
		$blog_id = $ctx->stash('blog_id');

		// If we're checking the beacon and the challenge/response
		// are configured we return the latter two
		if (isset($plugin_cfg[commchallenge_mode]) &&
			($plugin_cfg[commchallenge_question] != '') &&
			($plugin_cfg[commchallenge_answer] != '') ) {

			$markup .= '<label for="commchallenge_answer">'. 
				$plugin_cfg[commchallenge_question] .
				' <strong>('.'required'.')</strong>:</label>'.
				'<br /><input type="text" id="commchallenge_answer" name="commchallenge_answer" size="40" />'.
				'<input type="hidden" name="commchallenge_question" value="'.
				htmlspecialchars($plugin_cfg[commchallenge_question]).'" />';
		}
	}


    $js = <<<EOD
    <script type="text/javascript">
    <!--	
    if (commenter_name) { hideDocumentElement('comments-open-challenge'); } else { showDocumentElement('comments-open-challenge'); } 
    // -->
    </script>
EOD;

    //return '<p id="comments-open-challenge">'.$markup.'</p>'.$js;
    return '<p id="comments-open-challenge">'.$markup.'</p>';
}

?>