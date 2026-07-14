# BasicSSAIPlayer — Open Measurement & PAL

The [IAB Open Measurement SDK (OM SDK)](https://iabtechlab.com/standards/open-measurement-sdk/) is no longer installed along with the SSAI Plugin for Brightcove Player SDK for iOS since v6.10.3.

To take advantage of IAB Open Measurement, keep the following points in mind:

* The Open Measurement library ships as the `OMSDK_Brightcove` product of the `brightcove-player-sdk-ios` Swift Package; this sample already links it. In your own app, add the `OMSDK_Brightcove` product to your target to include it.
* Provide a valid OMID Partner name using the new signature, `[BCOVPlayerSDKManager createSSAISessionProviderWithUpstreamSessionProvider:omidPartner]`.
* If using VAST 4.1+, ads must be configured under `<AdVerifications>` nodes in their VAST documents per the VAST 4.1 specification; otherwise, `<Extension type="AdVerifications">` should be used.
* Open Measurement is not supported by MacCatalyst.

```xml
<AdVerifications>
  <Verification vendor="company.com-omid">
   <JavaScriptResource>
    <![CDATA[https://company.com/omid.js]]>
   </JavaScriptResource>
   <VerificationParameters>
    <![CDATA[parameter1=value1&parameter2=value2&parameter3=value3]]>
   </VerificationParameters>
  </Verification>
 </AdVerifications>
 ```

See the [Brightcove Player SDK for iOS](https://github.com/brightcove/brightcove-player-sdk-ios) documentation for more information on Open Measurement.

## PAL SDK Integration

The BasicSSAIPlayer-iOS project provides an example of how to integrate the Brightcove SSAI plugin with the PAL SDK. If you want to use this integration you'll need to download the [PAL SDK XCFramework](https://developers.google.com/ad-manager/pal/ios/download) and add it to the the project and then uncomment the sections of code related to the PAL SDK. There are comments throughout the code that will help you know which code to uncomment.
