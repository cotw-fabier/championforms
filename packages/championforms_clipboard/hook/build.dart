import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

/// Builds the Rust clipboard backend for the desktop and iOS targets.
///
/// Android uses `package:jni` and the web uses `package:web`, so there is
/// nothing to build for them. RustBuilder has no OS filter of its own and
/// would fail its toolchain-targets check, so the hook returns early.
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;
    const rustOSes = {OS.macOS, OS.iOS, OS.windows, OS.linux};
    if (!rustOSes.contains(input.config.code.targetOS)) return;
    await const RustBuilder(
      assetName: 'championforms_clipboard_native',
      cratePath: 'rust',
    ).run(input: input, output: output);
  });
}
