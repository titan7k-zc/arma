package com.zerocrow.arma

import android.os.Bundle
import android.util.Log
import com.google.android.gms.common.GooglePlayServicesNotAvailableException
import com.google.android.gms.common.GooglePlayServicesRepairableException
import com.google.android.gms.security.ProviderInstaller
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        installSecurityProvider()
    }

    private fun installSecurityProvider() {
        try {
            ProviderInstaller.installIfNeeded(applicationContext)
        } catch (error: GooglePlayServicesRepairableException) {
            Log.w("MainActivity", "Security provider can be repaired.", error)
        } catch (error: GooglePlayServicesNotAvailableException) {
            Log.w("MainActivity", "Google Play Services not available.", error)
        } catch (error: Exception) {
            Log.w("MainActivity", "Security provider installation failed.", error)
        }
    }
}
