package;

import js.node.Buffer;
import js.Node;
import js.node.ChildProcess;
import vscode.*;

final class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) {
		new Extension(context);
	}

	public function new(context:ExtensionContext) {
		SdkManager.initialize(error -> Vscode.window.showErrorMessage(error), function(sdk:SdkManager) {
			final dm:DeviceManager = new DeviceManager(sdk);
			context.subscriptions.push(Vscode.commands.registerCommand("muroktoolvsc.luanch_emulator", dm.registerLaunchEmulatorCommand));
		});
	}
}

final class SdkManager {
	public final androidPath:String;

	public static function initialize(error:(String) -> Void, success:(SdkManager) -> Void):Void {
		final path = Node.process.env.get("ANDROID_SDK");
		if (path == null) {
			error("ANDROID_SDK variable is not exists.");
		} else {
			Sys.putEnv("ANDROID_HOME", path);
			Sys.putEnv("ANDROID_SDK_ROOT", path);
			success(new SdkManager(path));
		}
	}

	function new(androidPath:String) {
		this.androidPath = androidPath;
	}
}

final class DeviceManager {
	final sdk:SdkManager;
	public function new(sdk:SdkManager) {
		this.sdk = sdk;
	}

	public function registerLaunchEmulatorCommand():Void {
		inline function launchEmulator(selectedItem:Null<QuickPickItem>):Void {
			if (selectedItem != null) {
				Sys.setCwd('${sdk.androidPath}/emulator');

				// Launch selected emulator:
				final emul = ChildProcess.spawn('${sdk.androidPath}/emulator/emulator.exe', ["-avd", selectedItem.label]);
				emul.stdout.on("data", function(data:String):Void {
					trace(data);
				});

				emul.stderr.on("data", (data:Buffer) -> Vscode.window.showErrorMessage(data.toString()));
				emul.on("close", (code:Int) -> Vscode.window.showInformationMessage('Process is closed. Exit code is $code'));
			} else {
				"Nothing selected.";
			}
		};

		inline function listEmulators(emulators:Array<String>):Void {
			final items:Array<QuickPickItem> = [for (name in emulators) {label: name}];
			Vscode.window.showQuickPick(items, {placeHolder: "Select emulator:"}).then(item -> launchEmulator(item));
		};

		ChildProcess.exec('${sdk.androidPath}/emulator/emulator.exe -list-avds', function(error:Null<ChildProcessExecError>, stdout:String, _):Void {
			if (error == null) {
				final results = stdout.split("\n");
				if (results.length > 0) {
					listEmulators(results.splice(0, results.length - 1));
				}
			} else {
				Vscode.window.showErrorMessage(Std.string(error.message));
			}
		});
	}
}