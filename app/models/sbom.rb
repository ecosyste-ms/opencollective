class Sbom < ApplicationRecord

  validates :raw, presence: true

  def convert
    Dir.mktmpdir do |dir|
      # write raw sbom to file
      File.open("#{dir}/sbom.txt", "w") { |f| f.write(raw) }
      puts "Wrote raw sbom to sbom.txt"

      command = "syft convert #{dir}/sbom.txt -o syft-json"

      result = `#{command}`
      update!(converted: result)
    end
  end

  def converted_json
    JSON.parse(converted)
  rescue
    nil
  end

  def artifacts
    return [] unless converted_json
      
    converted_json["artifacts"]
  end

  def packageurls
    artifacts.map { |a| PackageURL.parse a["purl"] }
  end

  def find_projects
    @projects ||= Project.package_urls(packageurls.map(&:to_s))
  end

  def find_project(purl)
    find_projects.select { |p| p.package_urls.include? Project.purl_without_version(purl) }.first
  end
end
