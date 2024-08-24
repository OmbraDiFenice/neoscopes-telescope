return require("telescope").register_extension {
  setup = function(ext_config, config)
    -- access extension config and user config
  end,
  exports = {
    search_in_scopes = require("neoscopes-telescope").search_in_scopes,
		build_scope = require("neoscopes-telescope").build_scope,
		load_scopes = require("neoscopes-telescope").load_scopes
  },
}
