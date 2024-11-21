require 'faker'
require 'open-uri'

# Clear existing data
Record.destroy_all
Tag.destroy_all
User.destroy_all

puts "Creating users..."
users = FactoryBot.create_list(:user, 10)
puts "Created #{users.count} users."

puts "Creating tags..."
tags = FactoryBot.create_list(:tag, 10)
puts "Created #{tags.count} tags."

puts "Creating records..."
50.times do
  user = users.sample
  record = Record.create!(
    title: "#{Faker::Construction.material} Design File", # Example: "Steel Design File"
    description: "CAD file for #{Faker::Construction.material} project. Includes detailed 3D models and drawings.",
    user: user,
    created_at: Faker::Time.between(from: 2.years.ago, to: Time.now)
  )

  # Assign random CAD-related tags to the record
  record.tags << tags.sample(rand(1..5)) # Assign between 1 and 5 random tags

  # Attach avatar to the user
  begin
    image_url = "https://picsum.photos/200/200"
    downloaded_image = URI.open(image_url)
    user.avatar.attach(
      io: downloaded_image,
      filename: "avatar-#{rand(1000)}.jpg",
      content_type: "image/jpeg"
    )
  rescue OpenURI::HTTPError
    puts "Image not found, skipping."
  end

  # Attach multiple images to the record
  3.times do
    begin
      image_url = "https://picsum.photos/600/400"
      downloaded_image = URI.open(image_url)
      record.images.attach(
        io: downloaded_image,
        filename: "cad-image-#{rand(1000)}.jpg",
        content_type: "image/jpeg"
      )
    rescue OpenURI::HTTPError
      puts "Image not found, skipping."
    end
  end

  # Attach multiple files to the record
  2.times do
    begin
      file_url = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
      downloaded_file = URI.open(file_url)
      record.files.attach(
        io: downloaded_file,
        filename: "cad-file-#{rand(1000)}.pdf",
        content_type: "application/pdf"
      )
    rescue OpenURI::HTTPError
      puts "File not found, skipping."
    end
  end
end
puts "Created 50 CAD-related records with associated tags, images, and files."

puts "Seeding complete!"