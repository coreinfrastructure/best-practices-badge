module ApplicationHelper
  MARKDOWN_RENDERER = Redcarpet::Render::HTML.new(
    filter_html: true, no_images: true,
    no_styles: true, safe_links_only: true)
  MARKDOWN_PROCESSOR = Redcarpet::Markdown.new(
    ApplicationHelper::MARKDOWN_RENDERER,
    no_intra_emphasis: true, autolink: true,
    space_after_headers: true, fenced_code_blocks: true)

  def self.markdown(content)
    return '' if content.nil?
    ApplicationHelper::MARKDOWN_PROCESSOR.render(content).html_safe
  end
end
