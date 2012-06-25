SuperMusicPhotoShow
===================

An Rdio Hack Day Project - Uses the Rdio iOS SDK and Echonest API to make a musical slideshow of your photos.

## Building

If you want to build this project you need to download the Rdio iOS SDK here: http://developer.rdio.com/docs/read/iOS

And you'll need an Echonest API key and secret which you can get here: https://developer.echonest.com/account/register

Put your Rdio and Echonest API keys and secrets in a resource named secret.plist and use the keys:
Rdio.Key
Rdio.Secret
Echonest.Key


## Disclaimer

This was built in 8 hours for the Rdio Hack Day on 6/22/2012. Hence, there are a lot of bad things that are done, and it is quite messy, but the end result is a slideshow that is synced to the playing song.

## Future

It would be nice to create a library out of the general code that would provide an easy way to give it a track key and get back interesting segments.
