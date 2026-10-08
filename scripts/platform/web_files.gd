class_name WebFiles
extends RefCounted

## File transfer for the web build. A browser page cannot open a native file dialog or write
## to the player's disk, so exports become browser downloads and imports go through the
## browser's file picker. Both pass through a temporary file in user://, so the rest of the game
## (LevelLoader) keeps working with plain paths.

const TEMP_DIR: String = "user://web_transfer"

## Defines window.godotPickFile(accept, callback): opens the browser's file picker and calls
## callback(file_name, base64_bytes) with the chosen file. Base64 because a string is the
## simplest thing to hand from JavaScript to GDScript.
const PICKER_JS: String = """
window.godotPickFile = function (accept, callback) {
	var input = document.createElement('input');
	input.type = 'file';
	input.accept = accept;
	input.onchange = function () {
		var file = input.files[0];
		if (!file) {
			return;
		}
		var reader = new FileReader();
		reader.onload = function () {
			var bytes = new Uint8Array(reader.result);
			var binary = '';
			for (var i = 0; i < bytes.length; i++) {
				binary += String.fromCharCode(bytes[i]);
			}
			callback(file.name, btoa(binary));
		};
		reader.readAsArrayBuffer(file);
	};
	input.click();
};
"""

## The JavaScript callback must stay referenced until the browser calls it.
static var _pick_callback: JavaScriptObject = null
static var _helper_ready: bool = false


## True in a browser build, where these functions replace the native file dialogs.
static func available() -> bool:
	return OS.has_feature("web")


## Offers `bytes` to the player as a browser download named `file_name`.
static func download(bytes: PackedByteArray, file_name: String, mime: String) -> void:
	JavaScriptBridge.download_buffer(bytes, file_name, mime)


## Opens the browser's file picker; `on_picked` gets (file_name: String, bytes: PackedByteArray).
## `accept` is a comma-separated list of extensions, e.g. ".zip,.json".
static func pick_file(accept: String, on_picked: Callable) -> void:
	if not _helper_ready:
		JavaScriptBridge.eval(PICKER_JS, true)
		_helper_ready = true
	_pick_callback = JavaScriptBridge.create_callback(func(args: Array) -> void:
		on_picked.call(str(args[0]), Marshalls.base64_to_raw(str(args[1]))))
	var window := JavaScriptBridge.get_interface("window")
	window.godotPickFile(accept, _pick_callback)


## A path in the temporary folder for a file named `file_name` (the folder is created).
static func temp_path(file_name: String) -> String:
	DirAccess.make_dir_recursive_absolute(TEMP_DIR)
	return TEMP_DIR.path_join(file_name.get_file())


## Writes `bytes` to a temporary file and returns its path ("" on failure).
static func write_temp(file_name: String, bytes: PackedByteArray) -> String:
	var path := temp_path(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_buffer(bytes)
	file.close()
	return path
