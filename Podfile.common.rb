# Podfile.common.rb
# Shared CocoaPods configuration for Brightcove iOS Player Samples
#
# This helper enables seamless switching between published SDK versions
# and local SDK development builds.
#
# Usage:
#   - Published SDK (default): Just run `pod install`
#   - Local SDK (default path): BRIGHTCOVE_LOCAL_SDK=true pod install
#   - Local SDK (custom path):  BRIGHTCOVE_LOCAL_SDK=/path/to/sdk pod install
#
# The default local SDK path is ../videocloud_agave (sibling directory)

# Mapping from published pod names to local podspec info
# Format: 'Published-Pod-Name' => ['LocalPodspecName', 'relative/path/from/sdk/root']
BRIGHTCOVE_POD_MAPPING = {
  'Brightcove-Player-Core'            => ['BCOVPlayerSDK',   'src/core'],
  'Brightcove-Player-IMA'             => ['BCOVIMA',         'src/ima'],
  'Brightcove-Player-DAI'             => ['BCOVDAI',         'src/dai'],
  'Brightcove-Player-SSAI'            => ['BCOVSSAI',        'src/ssai'],
  'Brightcove-Player-FreeWheel'       => ['BCOVFW',          'src/freewheel'],
  'Brightcove-Player-Pulse'           => ['BCOVPulse',       'src/pulse'],
  'Brightcove-Player-Omniture'        => ['BCOVAMC',         'src/omniture'],
  'Brightcove-Player-GoogleCast'      => ['BCOVGoogleCast',  'src/googlecast'],
  'Brightcove-Player-OpenMeasurement' => ['BCOVOM',          'src/ssai'],
}.freeze

DEFAULT_LOCAL_SDK_PATH = '../videocloud_agave'

# Track registered local pods to avoid duplicates within a single Podfile evaluation
$brightcove_registered_local_pods ||= {}
$brightcove_registered_local_pods.clear

# Determine if we're using local SDK and get the path
def brightcove_local_sdk_path
  env_value = ENV['BRIGHTCOVE_LOCAL_SDK']
  return nil if env_value.nil? || env_value.empty?

  # If set to 'true', '1', or 'yes', use default path
  if %w[true 1 yes].include?(env_value.downcase)
    DEFAULT_LOCAL_SDK_PATH
  else
    # Otherwise, treat the value as a custom path
    env_value
  end
end

# Internal helper to register a local pod
def _register_local_brightcove_pod(name, local_sdk_path)
  return if $brightcove_registered_local_pods[name]

  mapping = BRIGHTCOVE_POD_MAPPING[name]
  return if mapping.nil?

  local_name, relative_path = mapping

  # Resolve the SDK path relative to this file's directory (repo root)
  common_file_dir = File.dirname(__FILE__)
  sdk_root = File.expand_path(local_sdk_path, common_file_dir)
  resolved_path = File.join(sdk_root, relative_path)

  unless File.exist?(resolved_path)
    raise "Local SDK not found at #{resolved_path}. Check BRIGHTCOVE_LOCAL_SDK path or use published version."
  end

  Pod::UI.puts "Using local pod: #{local_name} from #{resolved_path}".yellow
  pod local_name, :path => resolved_path
  $brightcove_registered_local_pods[name] = true
end

# Helper to declare a Brightcove pod with automatic local/published switching
#
# @param name [String] The published pod name (e.g., 'Brightcove-Player-Core')
# @param subspec [String] The subspec to use for published pods (default: '/XCFramework')
#
# Examples:
#   brightcove_pod 'Brightcove-Player-Core'
#   brightcove_pod 'Brightcove-Player-IMA'
#
def brightcove_pod(name, subspec: '/XCFramework')
  local_sdk_path = brightcove_local_sdk_path

  if local_sdk_path
    mapping = BRIGHTCOVE_POD_MAPPING[name]

    if mapping.nil?
      raise "Unknown Brightcove pod: #{name}. Add it to BRIGHTCOVE_POD_MAPPING in Podfile.common.rb"
    end

    # For plugin pods, automatically include the core SDK as a dependency
    # since local podspecs have 'dependency BCOVPlayerSDK'
    if name != 'Brightcove-Player-Core'
      _register_local_brightcove_pod('Brightcove-Player-Core', local_sdk_path)
    end

    _register_local_brightcove_pod(name, local_sdk_path)
  else
    pod "#{name}#{subspec}"
  end
end

# Print SDK mode on load
if brightcove_local_sdk_path
  Pod::UI.puts "Brightcove SDK: Using LOCAL build from #{brightcove_local_sdk_path}".green
else
  Pod::UI.puts "Brightcove SDK: Using PUBLISHED version".green
end
