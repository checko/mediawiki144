<?php
# Generated minimal configuration for MediaWiki 1.35 upgrade

$wgSitename = "Temporary Upgrade Wiki";
$wgMetaNamespace = "Temporary_Upgrade_Wiki";

$wgScriptPath = "";
$wgServer = "http://localhost:8050";

$wgDBtype = "mysql";
$wgDBserver = "mysql";
$wgDBname = "mediawiki";
$wgDBuser = "mediawiki";
$wgDBpassword = "mediawiki_password";
$wgDBprefix = "";
$wgDBTableOptions = "ENGINE=InnoDB, DEFAULT CHARSET=binary";

# Minimal skin for compatibility
wfLoadSkin( 'Vector' );
$wgDefaultSkin = "vector";

# Disable all extensions during upgrade
# Extensions will be enabled in 1.44 upgrade
