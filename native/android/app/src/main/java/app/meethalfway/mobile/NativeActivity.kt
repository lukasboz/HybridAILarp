package app.meethalfway.mobile
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.view.WindowCompat
import androidx.lifecycle.ViewModelProvider
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.debug.DebugAppCheckProviderFactory
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory

class MainActivity:ComponentActivity() {
    override fun onCreate(savedInstanceState:Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window,false)
        WindowCompat.getInsetsController(window,window.decorView).isAppearanceLightStatusBars=true
        FirebaseService.appContext=applicationContext
        FirebaseApp.initializeApp(this)
        if(FirebaseApp.getApps(this).isNotEmpty())FirebaseAppCheck.getInstance().installAppCheckProviderFactory(if(BuildConfig.DEBUG)DebugAppCheckProviderFactory.getInstance()else PlayIntegrityAppCheckProviderFactory.getInstance())
        val model=ViewModelProvider(this,ViewModelProvider.AndroidViewModelFactory.getInstance(application))[MeetModel::class.java]
        setContent {MeetTheme {MeetRoot(model)}}
    }
}
