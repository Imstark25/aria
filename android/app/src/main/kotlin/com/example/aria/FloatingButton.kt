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
    private var iconMain: View? = null

    init {
        LayoutInflater.from(context).inflate(R.layout.floating_button, this, true)
        bubbleView = findViewById(R.id.bubble_view)
        iconMain = findViewById(R.id.icon_main)
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
                        onOpenOverlay()
                    }
                    onDragEnd(event.rawX, event.rawY)
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()
                    
                    if (abs(dx) > 5 || abs(dy) > 5) {
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
    }
    
    fun cleanup() {
    }
}
