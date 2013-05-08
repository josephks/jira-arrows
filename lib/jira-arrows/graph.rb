module JiraArrows

  class Graph

    class Node
      attr_reader :name
      attr_reader :linked_from, :links_to  #arrays of Strings

      def initialize(name, summary, color)
        @name = name
        @attribs = {summary: summary, color: color, name: name}
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

      def[](key)
        @attribs[key]
      end
    end

    attr_reader :link_data

    def initialize(raw_data)
      headers = raw_data[0]  #From,From_summary,From_Color,TO,To_summary,To_Color
      headers.each{ |s| s.downcase! }
      row_hashes = raw_data.each_with_object([]) do |row, acc|
        acc << Hash[headers.zip(row)] if row != headers
      end

      @nodes = {}
      @link_data = []
      row_hashes.each_with_index do |row_hash, idx|
        if  row_hash['from'] && row_hash['to']
          ['from', 'to'].each do |from_or_to|
            mcc_name = row_hash[from_or_to]
            unless @nodes[mcc_name] || !mcc_name || mcc_name.strip.length == 0
              @nodes[mcc_name] = Node.new(mcc_name, row_hash["#{ from_or_to}_summary"], row_hash["#{ from_or_to}_color"] )
            end
          end
          @link_data << [ row_hash['from'], row_hash['to'] ]
          @nodes[row_hash['from']].links_to << row_hash['to']
          @nodes[row_hash['to']].linked_from << row_hash['from']
        else
          puts "bad data on line #{idx + 1}"
        end
      end

      require 'set'
      @all_nodenames = @link_data.each_with_object(Set.new) { |(from, to), acc|
        acc << from
        acc << to
      }.freeze

      def @nodes.find_by_name(name)
        return name.map{ |n| self.find_by_name(n) } if name.is_a? Array
        self[name] #.find { |n| n.name == name }
      end

      @link_data.freeze
    end

    # Return an Array of clusters.  Each clusters is an array of tiers.  Each tier is an Array of nodes.
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
      node_names = @link_data.each_with_object([]) { |(src, target), acc|
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