SSAI
--------------

The [IAB Open Measurement SDK (OM SDK)](https://iabtechlab.com/standards/open-measurement-sdk/) is no longer installed along with the SSAI Plugin for Brightcove Player SDK for iOS since v6.10.3.
The current version for Open Measurement is 1.4.13.

To take advantage of IAB Open Measurement, keep the following points in mind:

* Add `pod 'Brightcove-Player-OpenMeasurement'` in your Podfile to include it in your project.
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

See the *Open Measurement* section of [brightcove-player-sdk-ios-ssai](https://github.com/brightcove/brightcove-player-sdk-ios-ssai#OpenMeasurement) for more information.
