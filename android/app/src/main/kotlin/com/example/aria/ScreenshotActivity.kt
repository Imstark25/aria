package com.example.aria

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.content.Context
import android.widget.Toast

class ScreenshotActivity : Activity() {

    companion object {
        const val REQUEST_CODE = 100
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Request MediaProjection Permission
        val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(projectionManager.createScreenCaptureIntent(), REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQUEST_CODE) {
            if (resultCode == RESULT_OK && data != null) {
                // Permission Granted
                // We will send a broadcast to the Service to proceed with capturing
                // because this Activity needs to finish to not block the screen.
                // Or better, we start a service action to handle the projection.
                
                val intent = Intent(this, VolumeOverlayService::class.java)
                intent.action = "ACTION_SCREENSHOT_PERMISSION_GRANTED"
                intent.putExtra("resultCode", resultCode)
                intent.putExtra("data", data)
                startService(intent)
                
            } else {
                Toast.makeText(this, "Screenshot permission denied", Toast.LENGTH_SHORT).show()
                val intent = Intent("com.example.aria.ACTION_SCREENSHOT_DONE")
                sendBroadcast(intent)
            }
        }
        finish()
    }
}
