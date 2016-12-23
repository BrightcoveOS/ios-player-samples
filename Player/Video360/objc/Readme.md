#Video 360 Player Sample App 
##Purpose

This sample app shows how to retrieve and play a 360 video.

The code for retrieving and playing the video is the same as any other code that retrieves and plays a video from Video Cloud.

What makes this code different is the use of the `BCOVPUIPlayerViewDelegate` delegate method `-didSetVideo360NavigationMethod:projectionStyle:` This method is called when the Video 360 button is tapped, and indicates that you probably want to set the device orientation to landscape if the projection method has changed to VR Goggles mode.

The sample code shows how to handle changing the device orientation when that delegate is called.
