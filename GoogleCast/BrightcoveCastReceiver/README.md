# Brightcove Cast Receiver

The Brightcove Cast Receiver uses the new Cast Application Framework (CAF) SDK. The Brightcove Cast Receiver supports DRM protected videos, SSAI and `HLSv3` or superior.

The application ID for the Brightcove CAF Receiver is `341387A3` and is assigned to the constant `kBCOVCAFReceiverApplicationID`. You can verify the application ID by checking the [CAF Receiver config.json](https://players.brightcove.net/videojs-chromecast-receiver/2/config.json).

**NOTE: When using the Brightcove Cast Receiver app with the Brightcove Native SDKs, you must send the `catalogParams` object via the `customData` interface. A static URL is not supported. If you are correctly utilizing the `BCOVReceiverAppConfig` class this is handled for you.**
