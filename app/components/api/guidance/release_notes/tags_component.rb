module API
  module Guidance
    module ReleaseNotes
      class TagsComponent < ViewComponent::Base
        class UnknownTagError < StandardError; end

        TAG_MAPPINGS = {
          "#breaking-change" => "red",
          "#new-feature" => "green",
          "#bug-fix" => "yellow",
          "#new-field" => "turquoise",
          "#data-update" => "blue",
          "#contract-closure" => "orange",
          "#new-course" => "pink",
          "#production-release" => "purple",
          "#sandbox-release" => "grey",
        }.freeze

        attr_accessor :tags

        def initialize(tags:)
          @tags = tags
        end

        def all_tags
          return if tags.blank?

          render_tags
        end

      private

        def render_tags
          sorted_tags = tags.sort_by { |tag| TAG_MAPPINGS.keys.index(tag) }

          %(<div class="release-notes-tags"><div class="tag-group">#{sorted_tags.map { |tag| render_tag(tag) }.join}</div></div>).html_safe
        end

        def render_tag(tag)
          colour = TAG_MAPPINGS[tag] or raise UnknownTagError, "Tag not recognised: #{tag}"
          text = tag.tr("-", " ").tr("#", "").capitalize

          govuk_tag(text:, colour:)
        end
      end
    end
  end
end
