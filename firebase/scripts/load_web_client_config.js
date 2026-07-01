/**
 * Load Firebase Web client config from gitignored firebase/keys/web_client_config.json
 *
 *   cp firebase/keys/web_client_config.example.json firebase/keys/web_client_config.json
 */
const fs = require("fs");
const path = require("path");

const CONFIG_PATH = path.resolve(__dirname, "../keys/web_client_config.json");

function loadWebClientConfig(project = "production") {
  if (!fs.existsSync(CONFIG_PATH)) {
    throw new Error(
      `Missing ${CONFIG_PATH}. Copy web_client_config.example.json and fill in values from Firebase Console.`,
    );
  }
  const parsed = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8"));
  const cfg = parsed[project] || parsed.production;
  if (!cfg || !cfg.apiKey) {
    throw new Error(
      `web_client_config.json has no entry for "${project}" with apiKey.`,
    );
  }
  return cfg;
}

module.exports = { loadWebClientConfig, CONFIG_PATH };
