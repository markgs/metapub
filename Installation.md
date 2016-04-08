# What you need before installing #

A server running Metafogl. MetaPub was tested with v8.3, but it should work with other versions of Metafogl.

# How to install #

  * Go to Downloads and get the latest zip file
  * Extract the zip file to the **left4dead2** directory on your server
  * To have MetaPub automatically run when versus mode is selected, move **confogl\_autoloader.smx** from **addons/sourcemod/plugins/optional/** to **addons/sourcemod/plugins/** and add the following line to your **server.cfg**:

```
confogl_autoloader_config "metapub"
```