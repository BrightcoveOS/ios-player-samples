SSAI
--------------

The SSAI Plugin for Brightcove Player SDK for iOS includes the [IAB Open Measurement SDK (OM SDK)](https://iabtechlab.com/standards/open-measurement-sdk/) v1.3.

To take advantage of IAB Open Measurement, keep the following points in mind:

* To use Open Measurement you must have version 6.8.2 or greater of the SSAI Plugin for Brightcove Player SDK for iOS.

* Provide a valid OMID Partner name using the new signature, `[BCOVPlayerSDKManager createSSAISessionProviderWithUpstreamSessionProvider:omidPartner]`.

* If using VAST 4.1+, ads must be configured under `<AdVerifications>` nodes in their VAST documents per the VAST 4.1 specification; otherwise, `<Extension type="AdVerifications">` should be used.

	```
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

