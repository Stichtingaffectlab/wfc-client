require "yaml"

def load_fixture(file_name)
  YAML.load_file(File.join(File.dirname(__FILE__), "fixtures", file_name))
end
