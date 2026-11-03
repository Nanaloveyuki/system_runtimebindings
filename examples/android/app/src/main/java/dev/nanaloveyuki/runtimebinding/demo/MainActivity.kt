package dev.nanaloveyuki.runtimebinding.demo

import android.app.Activity
import android.os.Bundle
import android.view.Gravity
import android.widget.TextView
import dev.nanaloveyuki.ajni.host.NativeBridge

class MainActivity : Activity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    NativeBridge.initialize(this)
    NativeBridge.lifecycle(NativeBridge.LIFECYCLE_CREATED)
    setContentView(TextView(this).apply {
      gravity = Gravity.CENTER
      textSize = 20f
      text = "PASS android-log\nCheck RuntimeBindingSmoke in Logcat."
    })
  }

  override fun onStart() {
    super.onStart()
    NativeBridge.lifecycle(NativeBridge.LIFECYCLE_STARTED)
  }

  override fun onResume() {
    super.onResume()
    NativeBridge.lifecycle(NativeBridge.LIFECYCLE_RESUMED)
  }

  override fun onPause() {
    NativeBridge.lifecycle(NativeBridge.LIFECYCLE_PAUSED)
    super.onPause()
  }

  override fun onStop() {
    NativeBridge.lifecycle(NativeBridge.LIFECYCLE_STOPPED)
    super.onStop()
  }

  override fun onDestroy() {
    try {
      NativeBridge.lifecycle(NativeBridge.LIFECYCLE_DESTROYED)
    } finally {
      try {
        NativeBridge.shutdown()
      } finally {
        super.onDestroy()
      }
    }
  }
}
