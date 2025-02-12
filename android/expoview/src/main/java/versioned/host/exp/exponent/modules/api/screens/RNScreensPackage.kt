package versioned.host.exp.exponent.modules.api.screens

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class RNScreensPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext) =
        emptyList<NativeModule>()

    override fun createViewManagers(reactContext: ReactApplicationContext) =
        listOf<ViewManager<*, *>>(
            ScreenContainerViewManager(),
            ScreenViewManager(),
            ScreenStackViewManager(),
            ScreenStackHeaderConfigViewManager(),
            ScreenStackHeaderSubviewManager(),
            SearchBarManager()
        )
}
