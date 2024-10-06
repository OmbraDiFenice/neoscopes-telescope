return require("telescope").register_extension {
  setup = function(ext_config, telescope_config)
    -- access extension config and user config
  end,
  exports = require("neoscopes-telescope.operations"),
}
