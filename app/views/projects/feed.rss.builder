#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "CII Best Practices BadgeApp"
    xml.author "Core Infrastructure Initiative"
    xml.description "Most Recently Updated Projects"
    xml.link "https://bestpractices.coreinfrastructure.org"
    xml.language "en"

    for project in @projects
      xml.item do
        xml.title "#{project.try(:name) || '(Name Unknown)'} | #{project.try(:homepage_url) || project.try(:repo_url)}"
        xml.author project.try(:user).try(:name)
        xml.pubDate project.updated_at.to_s(:rfc822)
        xml.link link_to(project)
        xml.guid project.id

        text = markdown((project.description || '')
                 .truncate(160, separator: ' '))

        xml.description text
      end
    end
  end
end
