class Record < ApplicationRecord
  searchkick

  belongs_to :user

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :softwares
  has_many_attached :files
  has_many_attached :images

  validates :title, presence: true, length: { maximum: 50 }
  validates :description, presence: true, length: { maximum: 150 }
  validates :width, :height, :depth, numericality: { greater_than: 0 }, allow_nil: true
  validates :rotation_angle, numericality: { greater_than_or_equal_to: 0, less_than: 360 }, allow_nil: true

  # Data sanitization callbacks - ensures all user input is safe from XSS and injection attacks
  before_validation :sanitize_input_data
  # Callback to calculate complexity score whenever dimensions change
  before_save :calculate_complexity_score

  def search_data
    {
      name: title,
      tags: tags.map(&:name),
      softwares: softwares.map(&:name),
      user_name: user.full_name,
      user_username: user.username
    }
  end

  def tag_list=(tags_string)
    tag_names = tags_string.split(",").collect { |s| s.strip.downcase }.uniq
    new_or_found_tags = tag_names.collect { |name| Tag.find_or_create_by(name: name) }
    self.tags = new_or_found_tags
  end

  def tag_list
    self.tags.map(&:name).join(", ")
  end

  def software_list=(softwares_string)
    software_names = softwares_string.split(",").collect { |s| s.strip.downcase }.uniq
    new_or_found_softwares = software_names.collect { |name| Software.find_or_create_by(name: name) }
    self.softwares = new_or_found_softwares
  end

  def software_list
    self.softwares.map(&:name).join(", ")
  end

  # Calculates the 3D volume using all dimensions
  # Returns volume in cubic millimeters
  def calculate_volume
    return nil unless width && height && depth
    width * height * depth
  end

  # Calculates diagonal distance in 3D space using mathematical functions
  # Uses Pythagorean theorem extended to 3D
  def calculate_diagonal
    return nil unless width && height && depth
    Math.sqrt(width**2 + height**2 + depth**2)
  end

  # Calculates surface area of the rectangular CAD model
  def calculate_surface_area
    return nil unless width && height && depth
    2 * (width * height + height * depth + depth * width)
  end

  # Calculates complexity score using logarithmic scaling
  # Heavier mathematical operation: logarithm helps compress large dimension variations into manageable scores
  # This is useful for CAD models that can range from 1mm to 10000mm in size
  def calculate_complexity_score
    return if width.nil? || height.nil? || depth.nil?
    
    # Calculate volume
    volume = calculate_volume
    
    # Use logarithm to scale complexity based on size
    # log(volume + 1) prevents log(0) errors and creates a reasonable complexity score
    base_complexity = Math.log(volume + 1)
    
    # Factor in number of attached files (more files = more complex model)
    file_count_factor = Math.log(files.count + 1)
    
    # Factor in number of softwares used (more tools = more complex)
    software_count_factor = Math.log(softwares.count + 1)
    
    # Combine all factors with weighted average (using exponential smoothing concept)
    self.complexity_score = (base_complexity * 0.5 + file_count_factor * 0.3 + software_count_factor * 0.2)
  end

  # Calculates the angle of rotation in radians for geometric transformations
  def rotation_angle_radians
    return nil unless rotation_angle
    rotation_angle * Math::PI / 180
  end

  # Calculates the effective reach of a model in a circular workspace
  # Uses trigonometric functions to determine coverage
  def calculate_effective_reach
    return nil unless width && height && rotation_angle
    
    # Convert angle to radians for trigonometric calculations
    angle_rad = rotation_angle_radians
    
    # Use sine and cosine for rotational geometry calculations
    # This determines how far the model extends in different directions after rotation
    x_reach = Math.cos(angle_rad) * width + Math.sin(angle_rad) * height
    y_reach = Math.sin(angle_rad) * width + Math.cos(angle_rad) * height
    
    # Return the maximum reach distance
    Math.sqrt(x_reach**2 + y_reach**2)
  end

  # Calculates compression efficiency using arctangent for smooth scaling
  # Arctangent provides smooth, bounded scaling function useful for efficiency metrics
  def calculate_compression_efficiency
    return nil unless calculate_volume && calculate_surface_area
    
    volume = calculate_volume
    surface_area = calculate_surface_area
    
    # Use arctangent to create a smooth efficiency curve between 0 and 1
    # atan(x) is useful here because it naturally bounds the result between -π/2 and π/2
    ratio = volume / surface_area
    efficiency = Math.atan(ratio) / (Math::PI / 2)  # Normalize to 0-1 range
    
    efficiency.round(4)
  end

  # Calculates angular displacement needed for model alignment
  # Uses atan2 for proper quadrant handling in 2D plane
  def calculate_alignment_angle(target_height, target_width)
    return nil unless width && height
    
    # atan2 is superior to atan for determining angle in a plane
    # It correctly handles all four quadrants
    current_angle = Math.atan2(height, width)
    target_angle = Math.atan2(target_height, target_width)
    
    # Calculate the angular difference needed for alignment
    angle_diff = target_angle - current_angle
    
    # Normalize to [-π, π] range for optimal rotation direction
    angle_diff = angle_diff - 2 * Math::PI if angle_diff > Math::PI
    angle_diff = angle_diff + 2 * Math::PI if angle_diff < -Math::PI
    
    Math.atan(angle_diff)  # Final arctangent smoothing for smooth transition
  end

  private

  # Sanitizes all user input to prevent XSS and injection attacks
  # Uses Rails framework sanitization helpers
  def sanitize_input_data
    # Sanitize text fields to prevent XSS
    # Uses DataSanitizer service which leverages Rails' ActionController::Base.helpers.sanitize
    self.title = DataSanitizer.sanitize_text(title) if title.present?
    self.description = DataSanitizer.sanitize_html(description, %w[p br strong em]) if description.present?
  end
end
