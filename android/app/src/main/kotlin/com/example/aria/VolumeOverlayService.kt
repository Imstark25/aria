package com.example.aria

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

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

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
        return START_STICKY
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
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        overlayParams.gravity = Gravity.TOP or Gravity.END
        overlayParams.x = 20

        // Button Params (Top-Left init, draggable)
        buttonParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )
        buttonParams.gravity = Gravity.TOP or Gravity.END
        buttonParams.x = 50
        buttonParams.y = 200
        
        // Remove View Params (Bottom Center)
        removeParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
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
                onClick = { showOverlay() },
                onDragStart = {
                    removeView?.visibility = View.VISIBLE
                },
                onDragEnd = { rawX, rawY ->
                    removeView?.visibility = View.GONE
                    if (isOverRemoveView(rawX, rawY)) {
                        stopSelf()
                    }
                },
                onDragMove = { rawX, rawY ->
                    // Optional: Scale remove view if close?
                }
            )
            
            windowManager.addView(floatingButton, buttonParams)
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
            try { windowManager.removeView(floatingButton) } catch (e: Exception) { e.printStackTrace() }
            floatingButton = null
        }

        if (overlayView == null) {
            overlayView = VolumeView(this)
            overlayParams.y = buttonParams.y
            windowManager.addView(overlayView, overlayParams)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (overlayView != null) windowManager.removeView(overlayView)
        if (floatingButton != null) windowManager.removeView(floatingButton)
        if (removeView != null) windowManager.removeView(removeView)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
