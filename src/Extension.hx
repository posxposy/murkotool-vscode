package;
import sys.FileSystem;
import js.lib.Promise;
import js.node.Buffer;
import js.Node;
import js.node.ChildProcess;
import vscode.*;

@:nullSafety(Loose)
class Extension {
	@:expose("activate")
	static function activate(context:ExtensionContext) new Extension(context);

	public function new(context:ExtensionContext) {
		final androidSdkPath = Node.process.env.get("ANDROID_SDK");
		if (androidSdkPath == null) {
			Vscode.window.showErrorMessage("ANDROID_SDK variable is not exists.");
			return;
		} else {
			Sys.putEnv("ANDROID_HOME", androidSdkPath);
			Sys.putEnv("ANDROID_SDK_ROOT", "E:/SDKs/AndroidSDK/build-tools");
		}

		final disposable = Vscode.commands.registerCommand("muroktoolvsc.luanch_emulator", function():Void {
			inline function launchEmulator(selectedItem:Null<QuickPickItem>):Void {
					if (selectedItem != null) {
						Sys.setCwd('$androidSdkPath/emulator');

						//Launch selected emulator:
						final emul = ChildProcess.spawn('$androidSdkPath/emulator/emulator.exe', ["-avd", selectedItem.label]);
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

			ChildProcess.exec('$androidSdkPath/emulator/emulator.exe -list-avds', function (error:Null<ChildProcessExecError>, stdout:String, _):Void {
				if (error == null) {
					final results = stdout.split("\n");
					if (results.length > 0) {
						listEmulators(results.splice(0, results.length - 1));
					}
				} else {
					Vscode.window.showErrorMessage(Std.string(error.message));
				}
			});
		});

		context.subscriptions.push(disposable);
	}
}


/**
// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
const vscode = require('vscode');

// this method is called when your extension is activated
// your extension is activated the very first time the command is executed

function activate(context) {

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "murkot" is now active!');

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with  registerCommand
	// The commandId parameter must match the command field in package.json
	let disposable = vscode.commands.registerCommand('extension.helloWorld', function () {
		// The code you place here will be executed every time your command is executed

		// Display a message box to the user
		vscode.window.showInformationMessage('Hello World!');
	});

	context.subscriptions.push(disposable);
}
exports.activate = activate;

// this method is called when your extension is deactivated
function deactivate() {}

module.exports = {
	activate,
	deactivate
}
 */
