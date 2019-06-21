# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a node for each occurence of
    # a given link format. To transform references to DB
    # resources in place, prefer to inherit from AbstractReferenceFilter.
    class InlineEmbedsFilter < HTML::Pipeline::Filter
      # Find every relevant link, create a new node based on
      # the link, and insert this node after any html content
      # surrounding the link.
      def call
        doc.xpath(xpath_search).each do |node|
          next unless params = embed_params(node)

          element = element_to_embed(doc, params)

          next unless element

          # We want this to follow any surrounding content. For example,
          # if a link is inline in a paragraph.
          node.parent.children.last.add_next_sibling(element)
        end

        doc
      end

      # Implement in child class.
      #
      # Return a Nokogiri::XML::Element to embed in the
      # markdown.
      def element_to_embed(doc, params)
      end

      # Implement in child class unless overriding #embed_params
      #
      # Returns the regex pattern used to filter
      # to only matching urls.
      def url_regex
      end

      # Returns the query string used to select nodes
      # from the html document on which the embed is based.
      #
      # Override to select nodes other than links.
      def xpath_search
        'descendant-or-self::a[@href]'
      end

      # Returns a hash of named parameters based on the
      # provided regex with string keys.
      #
      # Override to select nodes other than links.
      def embed_params(node)
        url = node['href']

        url_regex.match(url) { |m| m.named_captures }
      end
    end
  end
end
