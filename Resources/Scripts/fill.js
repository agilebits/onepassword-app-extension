/**
 * Executes the 1Password generated fill script in the same WKWebView instance that the `collect_page_info.js` script
 * ran within. 
 *
 * It is up to the caller to prepend the contents of execute_fill_script_dependencies.min.js, and append a self 
 * executing function call, along with the script JSON string, to the last line in this file.
 */

(function execute_fill_script(scriptJSON) {
	var script = null, error = null, filled_fields = 0, filled_passwords = 0;
 
	try {
		script = JSON.parse(scriptJSON);
	}
	catch (e) {
		error = e;
	}
 
	if (!script) {
		return {
			"success": false,
			"error": "Unable to parse fill script JSON. Javascript exception: " + error
		};
	}
 
	document.fill(script);
	return {"success": true};
 })