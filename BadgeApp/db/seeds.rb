# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
User.create!(name:  "Test User",
             email: "test@mail.org",
             password:              "password",
             password_confirmation: "password")

          

20.times do |n|
  name  = Faker::Name.name
  email = "test-#{n+1}@mail.org"
  password = "password"
  User.create!(name:  name,
               email: email,
               password:              password,
               password_confirmation: password)
end

# Projects for testing
Project.create!(name:  "AMTU",
             description: "Obsolete Abstract Machine Test Utility which was once
                           required for Common Criteria certification.",
             project_url: "https://sourceforge.net/projects/amtueal",
             repo_url: "http://amtueal.cvs.sourceforge.net/viewvc/amtueal/",
             license: "Common Public License v.1.0")

20.times do |n|
 name  = "test-name-#{n+1}"
 description = "test-description#{n+1}"
 project_url = "test-project-url-#{n+1}.org"
 repo_url = "test-repo-url-#{n+1}.org"
 license = ["MIT","Apache", "GPL", "Mozilla", "BSD"].sample
 Project.create!(name: name,
                 description: description,
                 project_url: project_url,
                 repo_url: repo_url,
                 license: license)

end
