package com.example.aria

import android.content.Context
import android.media.AudioManager
import android.util.AttributeSet
import android.view.LayoutInflater
import android.widget.FrameLayout
import android.widget.SeekBar
import android.widget.TextView

class VolumeView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    private val audioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    init {
        LayoutInflater.from(context).inflate(R.layout.volume_overlay, this, true)

        // --- Media Volume Setup ---
        val sliderMedia = findViewById<SeekBar>(R.id.volumeSliderMedia)
        val ghostMedia = findViewById<TextView>(R.id.ghostMedia)
        
        val maxMedia = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val currentMedia = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)

        sliderMedia.max = maxMedia
        sliderMedia.progress = currentMedia
        ghostMedia.text = "${(currentMedia * 100 / maxMedia)}%"

        sliderMedia.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar?, progress: Int, fromUser: Boolean) {
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, progress, 0)
                if (maxMedia > 0) ghostMedia.text = "${(progress * 100 / maxMedia)}%"
            }
            override fun onStartTrackingTouch(sb: SeekBar?) {}
            override fun onStopTrackingTouch(sb: SeekBar?) {}
        })

        // --- Call Volume Setup ---
        val sliderCall = findViewById<SeekBar>(R.id.volumeSliderCall)
        val ghostCall = findViewById<TextView>(R.id.ghostCall)
        
        val maxCall = audioManager.getStreamMaxVolume(AudioManager.STREAM_VOICE_CALL)
        val currentCall = audioManager.getStreamVolume(AudioManager.STREAM_VOICE_CALL)

        sliderCall.max = maxCall
        sliderCall.progress = currentCall
        if (maxCall > 0) {
             ghostCall.text = "${(currentCall * 100 / maxCall)}%"
        } else {
             ghostCall.text = "0%"
        }

        sliderCall.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(sb: SeekBar?, progress: Int, fromUser: Boolean) {
                audioManager.setStreamVolume(AudioManager.STREAM_VOICE_CALL, progress, 0)
                if (maxCall > 0) ghostCall.text = "${(progress * 100 / maxCall)}%"
            }
            override fun onStartTrackingTouch(sb: SeekBar?) {}
            override fun onStopTrackingTouch(sb: SeekBar?) {}
        })

        // Touch outside -> close overlay (return to button)
        val background = findViewById<FrameLayout>(R.id.rootLayout)
        background?.setOnClickListener {
             // Logic to switch back to floating button
             if (context is VolumeOverlayService) {
                 (context as VolumeOverlayService).showFloatingButton()
             }
        }
    }
}
