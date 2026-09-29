package com.championforms.clipboard;

import io.flutter.embedding.engine.plugins.FlutterPlugin;

/**
 * Registration stub. Flutter only builds a plugin's Android module (and so
 * only merges its manifest, which declares {@link ClipboardContentProvider})
 * when the plugin names a plugin class; this one has nothing to do. The
 * clipboard itself is driven from Dart through package:jni.
 */
public final class ChampionformsClipboardPlugin implements FlutterPlugin {
  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {}

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {}
}
