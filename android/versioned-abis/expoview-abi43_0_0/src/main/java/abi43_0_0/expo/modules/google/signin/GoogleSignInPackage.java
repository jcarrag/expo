package abi43_0_0.expo.modules.google.signin;

import android.content.Context;

import java.util.Collections;
import java.util.List;

import abi43_0_0.expo.modules.core.ExportedModule;
import abi43_0_0.expo.modules.core.BasePackage;

public class GoogleSignInPackage extends BasePackage {
    @Override
    public List<ExportedModule> createExportedModules(Context context) {
        return Collections.singletonList((ExportedModule) new GoogleSignInModule(context));
    }
}
