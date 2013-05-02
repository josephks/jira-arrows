module JiraArrows

  class Graph

    class Node
      attr_reader :name
      attr_accessor :linked_from, :links_to  #arrays of Strings

      def initialize(name)
        @name = name
        @linked_from = []
        @links_to = []
      end

      def hash
        @name.hash
      end

      def is_orphan?
        self.linked_from.empty?
      end

      def is_linked_from(arr)
        ! (self.linked_from & arr.map(&:name)).empty?
      end

      alias to_s name
    end

    def initialize(raw_data)
      @raw_data = raw_data
      require 'set'
      @all_nodenames = @raw_data.each_with_object(Set.new) { |(from, to), acc|
        acc << from
        acc << to
      }.freeze

      @nodes = @all_nodenames.map{ |str| Node.new(str)}
      def @nodes.find_by_name(name)
        return name.map{ |n| self.find_by_name(n) } if name.is_a? Array
        self.find { |n| n.name == name }
      end

      @raw_data.each do |(from, to)|
          @nodes.find_by_name(from).links_to << to
          @nodes.find_by_name(to).linked_from << from
      end
    end

    # Return an Array of clusters.  Each clusters is an array of tiers.  Each tiers is an Array of nodes.
    def all_nodes_clustered(tiered = false)
      clusters = []
      all_node_names = @all_nodenames.to_a
      while all_node_names.length > 0
        node_name = all_node_names[0]
        cluster = nodes_linked_to(node_name) + [node_name]
        all_node_names -= cluster
        clusters << cluster
      end

      if tiered
        clusters = clusters.map do |cluster|
           nodes = @nodes.find_by_name(cluster)
           tiers = []
           gen = nodes.select { |node| node.is_orphan? } #.map(&:name)
           until nodes.empty?
             tiers << gen
             nodes -= gen
             gen = nodes.select{ |node| node.is_linked_from(gen) }
           end
          tiers
        end
      end
      #TODO: rewrite to returns [Node] instead of [String] when tiered == false
      return clusters
    end

    private

    # Return all nodes linked to from this node, directly or indirectly.  Used to find all nodes in a cluster
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