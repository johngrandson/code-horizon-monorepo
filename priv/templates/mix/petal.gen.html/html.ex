defmodule <%= inspect context.web_module %>.<%= inspect Module.concat(schema.web_namespace, schema.alias) %>HTML do
  use <%= inspect context.web_module %>, :html

  import <%= inspect context.web_module %>.PageComponents

  embed_templates "<%= schema.singular %>_html/*"
end
