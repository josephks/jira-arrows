module JiraArrows

  class Graph

    def initialize(raw_data)
      @raw_data = raw_data
      require 'set'
      @all_nodenames = @raw_data.each_with_object(Set.new) { |(from, to), acc|
        acc << from
        acc << to
      }.freeze
    end

    def all_nodes_clustered
      clusters = []
      all_node_names = @all_nodenames.to_a
      while all_node_names.length > 0
        node_name = all_node_names[0]
        cluster = nodes_linked_to(node_name) + [node_name]
        all_node_names -= cluster
        clusters << cluster
      end
      return clusters
      all_node_names.each do |mod_name|
        unless clusters.flatten.include?(mod_name)
          clusters << nodes_linked_to(mod_name, false) + [mod_name]
        end
      end
      clusters
    end

    private

    def nodes_linked_to(node_name, exclude=[])
      node_names = @raw_data.each_with_object([]) { |(src, target), acc|
        acc << target if node_name == src && !exclude.include?(target)
        acc << src if node_name == target && !exclude.include?(src)
      }.freeze

      to_exclude = node_names + [node_name] + exclude
      node_names.map do |mn|
        sec_tier = nodes_linked_to(mn, to_exclude)
        to_exclude += sec_tier
        sec_tier + [mn]
      end.flatten
    end

  end
end