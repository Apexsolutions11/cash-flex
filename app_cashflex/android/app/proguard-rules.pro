# Facebook Audience Network - Ignore missing infer annotation classes
# These are compile-time only annotations that are not needed at runtime
-dontwarn com.facebook.infer.annotation.**
-keep class com.facebook.infer.annotation.** { *; }

# Keep Facebook Ads classes
-keep class com.facebook.ads.** { *; }
-dontwarn com.facebook.ads.**

# Mintegral SDK rules
-keep class com.mbridge.msdk.** { *; }
-dontwarn com.mbridge.msdk.**

# General rules for ad SDKs
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

