import { Command } from '@expo/commander';
import spawnAsync from '@expo/spawn-async';
import chalk from 'chalk';
import fs from 'fs-extra';
import path from 'path';

import { EXPO_DIR, ANDROID_DIR } from '../Constants';
import { getReactNativeSubmoduleDir } from '../Directories';
import { getNextSDKVersionAsync } from '../ProjectVersions';
import { transformFileAsync } from '../Transforms';

type ActionOptions = {
  checkout?: string;
  sdkVersion?: string;
};

const REACT_NATIVE_SUBMODULE_PATH = getReactNativeSubmoduleDir();
const REACT_ANDROID_PATH = path.join(REACT_NATIVE_SUBMODULE_PATH, 'ReactAndroid');
const REACT_ANDROID_GRADLE_PATH = path.join(REACT_ANDROID_PATH, 'build.gradle');

async function updateReactAndroidAsync(sdkVersion: string): Promise<void> {
  console.log(
    `Running ${chalk.blue('ReactAndroidCodeTransformer')} with ${chalk.yellow(
      `./gradlew :tools:execute --args ${sdkVersion}`
    )} command...`
  );
  await spawnAsync('./gradlew', [':tools:execute', '--args', sdkVersion], {
    cwd: ANDROID_DIR,
    stdio: 'inherit',
  });
}

async function action(options: ActionOptions) {
  // When we're updating React Native, we mostly want it to be for the next SDK that isn't versioned yet.
  const androidSdkVersion = options.sdkVersion || (await getNextSDKVersionAsync('android'));

  if (!androidSdkVersion) {
    throw new Error(
      'Cannot obtain next SDK version. Try to run with --sdkVersion <sdkVersion> flag.'
    );
  }

  console.log(
    `Updating ${chalk.green('ReactAndroid')} for SDK ${chalk.cyan(androidSdkVersion)} ...`
  );
  await updateReactAndroidAsync(androidSdkVersion);
}

export default (program: Command) => {
  program
    .command('update-react-native')
    .alias('update-rn', 'urn')
    .description(
      'Updates React Native submodule and applies Expo-specific code transformations on ReactAndroid and ReactCommon folders.'
    )
    .option(
      '-s, --sdkVersion [string]',
      'SDK version for which the forked React Native will be used. Defaults to the newest SDK version increased by a major update.'
    )
    .asyncAction(action);
};
