require("install.sbar")

sbar = require("sketchybar")

sbar.begin_config()
sbar.hotload(true)

require("constants")
require("config")
require("bar")
require("default")
require("items")

sbar.end_config()
sbar.event_loop()

-- defaults write com.knollsoft.Rectangle screenEdgeGapTop -int 44
-- defaults write com.knollsoft.Rectangle screenEdgeGapTopNotch -int 10
-- defaults delete com.knollsoft.Rectangle screenEdgeGapTop
-- defaults delete com.knollsoft.Rectangle screenEdgeGapTopNotch
