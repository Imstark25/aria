package com.example.aria
import android.app.Activity

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import kotlin.math.abs

import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.widget.Toast
import android.content.Context

class VolumeOverlayService : Service() {

    private lateinit var windowManager: WindowManager
    
    // Views
    private var overlayView: VolumeView? = null
    private var floatingButton: FloatingButton? = null
    private var removeView: View? = null
    
    // Params
    private lateinit var buttonParams: WindowManager.LayoutParams
    private lateinit var overlayParams: WindowManager.LayoutParams
    private lateinit var removeParams: WindowManager.LayoutParams

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Screenshot functionality removed
        return START_STICKY
    }

    private fun startCapture(resultCode: Int, data: Intent) {
         val projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
         val metrics = resources.displayMetrics
         
         val screenWidth = metrics.widthPixels
         val screenHeight = metrics.heightPixels
         val screenDensity = metrics.densityDpi
         
         val mediaProjection = projectionManager.getMediaProjection(resultCode, data)
         val imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
         
         val flags = DisplayManager.VIRTUAL_DISPLAY_FLAG_OWN_CONTENT_ONLY or DisplayManager.VIRTUAL_DISPLAY_FLAG_PUBLIC
         val virtualDisplay = mediaProjection?.createVirtualDisplay(
             "ScreenCapture",
             screenWidth,
             screenHeight,
             screenDensity,
             flags,
             imageReader.surface,
             null,
             null
         )
         
         imageReader.setOnImageAvailableListener({ reader ->
             // Trigger only once
             reader.setOnImageAvailableListener(null, null)
             
             var image: Image? = null
             try {
                 image = reader.acquireLatestImage()
                 if (image != null) {
                     val planes = image.planes
                     val buffer = planes[0].buffer
                     val pixelStride = planes[0].pixelStride
                     val rowStride = planes[0].rowStride
                     val rowPadding = rowStride - pixelStride * screenWidth
                     
                     // Create bitmap
                     val bitmap = Bitmap.createBitmap(
                         screenWidth + rowPadding / pixelStride,
                         screenHeight,
                         Bitmap.Config.ARGB_8888
                     )
                     bitmap.copyPixelsFromBuffer(buffer)
                     
                     // Crop if there is padding
                     val finalBitmap = if (rowPadding == 0) {
                        bitmap
                     } else {
                        Bitmap.createBitmap(bitmap, 0, 0, screenWidth, screenHeight)
                     }
                     
                     saveScreenshot(finalBitmap)
                 }
             } catch (e: Exception) {
                 e.printStackTrace()
                 Handler(Looper.getMainLooper()).post {
                    Toast.makeText(this, "Capture Failed: ${e.message}", Toast.LENGTH_SHORT).show()
                 }
             } finally {
                 image?.close()
                 virtualDisplay?.release()
                 mediaProjection?.stop()
                 imageReader.close()

                 // Show button back
                 Handler(Looper.getMainLooper()).post {
                     showFloatingButton()
                 }
             }
             
         }, Handler(Looper.getMainLooper()))
    }

    private fun saveScreenshot(bitmap: Bitmap) {
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
        val fileName = "Screenshot_$timeStamp.png"
        
        val contentValues = android.content.ContentValues().apply {
            put(MediaStore.Images.Media.DISPLAY_NAME, fileName)
            put(MediaStore.Images.Media.MIME_TYPE, "image/png")
            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/VolumeMaster")
        }
        
        val uri = contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
        if (uri != null) {
            contentResolver.openOutputStream(uri).use { stream ->
                if (stream != null) {
                    bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                     Handler(Looper.getMainLooper()).post {
                        Toast.makeText(this, "Screenshot Saved!", Toast.LENGTH_SHORT).show()
                     }
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        
        startForegroundServiceNotification()
        
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        initParams()
        initRemoveView()
        
        // Start by showing the button
        showFloatingButton()
    }

    private fun startForegroundServiceNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "volume_master_overlay"
            val channelName = "Volume Overlay Service"
            val channel = NotificationChannel(
                channelId, 
                channelName, 
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)

            val notification = Notification.Builder(this, channelId)
                .setContentTitle("Volume Master")
                .setContentText("Overlay is running")
                .setSmallIcon(R.mipmap.ic_launcher)
                .build()

            startForeground(1, notification)
        }
    }
    
    private fun initParams() {
        // Overlay Params (Right side, aligned vertically by logic)
        overlayParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        )
        overlayParams.gravity = Gravity.TOP or Gravity.END
        overlayParams.x = 20

        // Button Params (Top-Right init, draggable) - Optimized
        buttonParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        )
        buttonParams.gravity = Gravity.TOP or Gravity.END
        buttonParams.x = 30
        buttonParams.y = 150
        
        // Remove View Params (Bottom Center)
        removeParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                    WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            PixelFormat.TRANSLUCENT
        )
        removeParams.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        removeParams.y = 50 // Margin from bottom
    }
    
    private fun initRemoveView() {
        removeView = LayoutInflater.from(this).inflate(R.layout.remove_view, null)
        removeView?.visibility = View.GONE
        windowManager.addView(removeView, removeParams)
    }

    fun showFloatingButton() {
        if (overlayView != null) {
            try { windowManager.removeView(overlayView) } catch (e: Exception) { e.printStackTrace() }
            overlayView = null
        }

        if (floatingButton == null) {
            floatingButton = FloatingButton(this)
            
            floatingButton?.setupDragListener(
                buttonParams, 
                windowManager, 
                onOpenOverlay = { showOverlay() },
                onDragStart = {
                    removeView?.visibility = View.VISIBLE
                },
                onDragEnd = { rawX, rawY ->
                    removeView?.visibility = View.GONE
                    if (isOverRemoveView(rawX, rawY)) {
                        floatingButton?.cleanup()
                        stopSelf()
                    }
                },
                onDragMove = { _, _ ->
                    // Minimal operations during drag for performance
                }
            )
            
            windowManager.addView(floatingButton, buttonParams)
        } else {
            floatingButton?.visibility = View.VISIBLE
        }
    }
    
    private fun isOverRemoveView(x: Float, y: Float): Boolean {
        // Simple logic: Check if Y is near bottom and X is near center
        val screenHeight = resources.displayMetrics.heightPixels
        val screenWidth = resources.displayMetrics.widthPixels
        
        // Remove view is at bottom center.
        // Let's say bottom 150 pixels and center +/- 100 pixels
        val inBottomZone = y > (screenHeight - 250)
        val inCenterZone = abs(x - (screenWidth / 2)) < 150
        
        return inBottomZone && inCenterZone
    }

    fun showOverlay() {
        if (floatingButton != null) {
            floatingButton?.cleanup()
            try { windowManager.removeView(floatingButton) } catch (e: Exception) { e.printStackTrace() }
            floatingButton = null
        }

        if (overlayView == null) {
            overlayView = VolumeView(this)
            overlayParams.y = buttonParams.y
            windowManager.addView(overlayView, overlayParams)
        }
    }

    private fun takeScreenshot() {
        // Hide button
        if (floatingButton != null) {
            floatingButton?.visibility = View.GONE
        }
        
        // Start Permission Activity
        val intent = Intent(this, ScreenshotActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        
        // Listener for when to show button back is handled via onStartCommand or BroadcastReceiver.
        // For simplicity, we used startService with intent in Activity.
    }

    override fun onDestroy() {
        super.onDestroy()
        floatingButton?.cleanup()
        if (overlayView != null) windowManager.removeView(overlayView)
        if (floatingButton != null) windowManager.removeView(floatingButton)
        if (removeView != null) windowManager.removeView(removeView)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
