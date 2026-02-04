package com.example.aria

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.WindowManager
import android.widget.FrameLayout
import kotlin.math.abs

import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.View

class FloatingButton @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private var bubbleView: View? = null
    private var btnOpenOverlay: View? = null
    private var iconMain: View? = null
    private var isExpanded = false

    init {
        LayoutInflater.from(context).inflate(R.layout.floating_button, this, true)
        bubbleView = findViewById(R.id.bubble_view)
        btnOpenOverlay = findViewById(R.id.btn_open_overlay)
        iconMain = findViewById(R.id.icon_main)
        
        startBreathingAnimation()
    }

    private fun startBreathingAnimation() {
        bubbleView?.let { view ->
            val scaleX = ObjectAnimator.ofFloat(view, "scaleX", 0.95f, 1.05f)
            val scaleY = ObjectAnimator.ofFloat(view, "scaleY", 0.95f, 1.05f)
            
            scaleX.repeatCount = ValueAnimator.INFINITE
            scaleX.repeatMode = ValueAnimator.REVERSE
            scaleY.repeatCount = ValueAnimator.INFINITE
            scaleY.repeatMode = ValueAnimator.REVERSE
            
            scaleX.duration = 1500
            scaleY.duration = 1500
            
            val set = AnimatorSet()
            set.interpolator = AccelerateDecelerateInterpolator()
            set.playTogether(scaleX, scaleY)
            set.start()
        }
    }

    fun setupDragListener(
        params: WindowManager.LayoutParams, 
        windowManager: WindowManager, 
        onOpenOverlay: () -> Unit,
        onDragStart: () -> Unit,
        onDragEnd: (Float, Float) -> Unit,
        onDragMove: (Float, Float) -> Unit
    ) {
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isDragging = false

        setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isDragging = false
                    onDragStart()
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        toggleMenu()
                    }
                    onDragEnd(event.rawX, event.rawY)
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    
                    if (abs(dx) > 10 || abs(dy) > 10) {
                        isDragging = true
                        
                        val isRight = (params.gravity and android.view.Gravity.RIGHT) == android.view.Gravity.RIGHT
                        if (isRight) {
                            params.x = initialX - dx
                        } else {
                            params.x = initialX + dx
                        }
                        
                        params.y = initialY + dy
                        windowManager.updateViewLayout(this, params)
                        onDragMove(event.rawX, event.rawY)
                    }
                    true
                }
                else -> false
            }
        }

        
        // Setup internal click listeners
        btnOpenOverlay?.setOnClickListener {
            onOpenOverlay()
            toggleMenu() // Close after action
        }
    }

    private fun toggleMenu() {
        isExpanded = !isExpanded
        val visibility = if (isExpanded) View.VISIBLE else View.GONE
        
        btnOpenOverlay?.visibility = visibility
        
        // Rotate icon
        val rotation = if (isExpanded) 0f else 45f // 45 is 'close', 0 is '+' or similar, but used icon is close rotated 45 (which looks like plus). Wait. 
        // Icon src in XML is ic_close rotated 45. That is an 'X' rotated to '+'? No, ic_close is 'X'. 45 deg makes it '+'.
        // So default (collapsed) = '+' (45deg). Expanded = 'X' (0deg).
        // Let's assume standard behavior.
        
        iconMain?.animate()?.rotation(if (isExpanded) 180f else 0f)?.setDuration(300)?.start()
    }
}
