# encoding: utf-8

# usage: ruby jira-arrows.rb inputfile.csv  output.html
# This script expects a CSV of two columns: from and to

inputfilename = ARGV[0]
outputfilename = ARGV[1]

unless inputfilename
  puts "Usage: jira-arrows.rb inputfile.csv > output.html"
  exit 1
end

require 'csv'
require File.expand_path('../lib/jira-arrows/graph', File.dirname(__FILE__))


raw_data = CSV.read(inputfilename)
raw_data.delete_at(0)

graph = JiraArrows::Graph.new(raw_data)

require 'haml'
renderer = Haml::Engine.new(File.read( File.expand_path('../templates/template.html.haml', File.dirname(__FILE__)) ))

html_output = renderer.to_html(nil, { all_connections: raw_data, all_nodes_clustered: graph.all_nodes_clustered,
                                      nodes_with_no_parents: graph.nodes_with_no_parents} )
temp_file = File.new(outputfilename, "w+")
temp_file.puts(html_output)
temp_file.close
temp_file

__END__