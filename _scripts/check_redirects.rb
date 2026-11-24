require "jekyll"

source = File.expand_path(ARGV.fetch(0, Dir.pwd))
config = Jekyll.configuration("source" => source, "safe" => true, "quiet" => true)
site = Jekyll::Site.new(config)
site.read

documents = site.pages + site.collections.values.flat_map(&:docs)
invalid = documents.select do |document|
  target = document.data["redir_to"]
  document.data["layout"] == "redirect" &&
    (!target.is_a?(String) || target.strip.empty?)
end

unless invalid.empty?
  abort "Redirects missing a nonempty redir_to:\n#{invalid.map(&:path).join("\n")}"
end

puts "Redirect destinations are present."
