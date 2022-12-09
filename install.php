<?php
/**
 * The following functions are used by the extension engine to generate a new table
 * for the plugin / destroy it on removal.
 */


/**
 * This function is called on installation and is used to
 * create database schema for the plugin
 */
function extension_install_uefisettings()
{
    $commonObject = new ExtensionCommon;

    $commonObject -> sqlQuery(
        "CREATE TABLE uefisettings (
        ID INTEGER NOT NULL AUTO_INCREMENT,
        HARDWARE_ID INTEGER NOT NULL,
        UEFISETTING VARCHAR(255) DEFAULT NULL,
        UEFIVALUE VARCHAR(255) DEFAULT NULL,
        PRIMARY KEY (ID,HARDWARE_ID)) ENGINE=INNODB;"
    );
}

/**
 * This function is called on removal and is used to
 * destroy database schema for the plugin
 */
function extension_delete_uefisettings()
{
    $commonObject = new ExtensionCommon;
    $commonObject -> sqlQuery("DROP TABLE IF EXISTS `uefisettings`");
}

/**
 * This function is called on plugin upgrade
 */
function extension_upgrade_uefisettings()
{

}

?>