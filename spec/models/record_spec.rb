# frozen_string_literal: true

require 'rails_helper'

describe Record do
  let(:user) { create(:user) }
  let(:record) { create(:record, user: user, width: 10, height: 20, depth: 30) }

  describe '#calculate_volume' do
    it 'calculates volume correctly from dimensions' do
      expect(record.calculate_volume).to eq(6000)
    end

    it 'returns nil when dimensions are missing' do
      record.width = nil
      expect(record.calculate_volume).to be_nil
    end
  end

  describe '#calculate_diagonal' do
    it 'calculates diagonal distance using Pythagorean theorem' do
      # sqrt(10^2 + 20^2 + 30^2) = sqrt(100 + 400 + 900) = sqrt(1400) ≈ 37.42
      expect(record.calculate_diagonal).to be_within(0.01).of(37.42)
    end

    it 'returns nil when dimensions are missing' do
      record.height = nil
      expect(record.calculate_diagonal).to be_nil
    end
  end

  describe '#calculate_surface_area' do
    it 'calculates surface area correctly' do
      # 2 * (10*20 + 20*30 + 30*10) = 2 * (200 + 600 + 300) = 2200
      expect(record.calculate_surface_area).to eq(2200)
    end
  end

  describe '#calculate_complexity_score using logarithm' do
    it 'calculates complexity score using logarithmic scaling' do
      record.save!
      # This uses Math.log for heavy mathematical operation
      expect(record.complexity_score).to be_a(Float)
      expect(record.complexity_score).to be > 0
    end

    it 'increases with volume using logarithmic function' do
      record1 = create(:record, user: user, width: 5, height: 5, depth: 5)
      record2 = create(:record, user: user, width: 10, height: 10, depth: 10)
      
      # record2 has 8x larger volume, but log scales it
      expect(record2.complexity_score).to be > record1.complexity_score
    end

    it 'factors in file attachments' do
      record.save!
      initial_score = record.complexity_score
      
      # Attach files and recalculate
      record.files.attach(io: StringIO.new("test"), filename: "test.txt")
      record.save!
      
      # Score should increase with more files (using Math.log)
      expect(record.complexity_score).to be > initial_score
    end
  end

  describe '#rotation_angle_radians' do
    it 'converts rotation angle to radians' do
      record.rotation_angle = 90
      # 90 * π / 180 = π/2 ≈ 1.5708
      expect(record.rotation_angle_radians).to be_within(0.0001).of(Math::PI / 2)
    end

    it 'handles 180 degrees correctly' do
      record.rotation_angle = 180
      expect(record.rotation_angle_radians).to be_within(0.0001).of(Math::PI)
    end

    it 'returns nil when rotation_angle is nil' do
      record.rotation_angle = nil
      expect(record.rotation_angle_radians).to be_nil
    end
  end

  describe '#calculate_effective_reach using trigonometry' do
    it 'calculates reach using sine and cosine functions' do
      record.rotation_angle = 0
      reach = record.calculate_effective_reach
      # At 0 degrees, reach should be primarily based on width
      expect(reach).to be_within(0.1).of(record.width)
    end

    it 'uses trigonometric functions for rotated geometry' do
      record.rotation_angle = 45
      reach = record.calculate_effective_reach
      # Uses Math.cos and Math.sin for rotation calculations
      expect(reach).to be_a(Float)
      expect(reach).to be > 0
    end

    it 'returns nil when dimensions missing' do
      record.width = nil
      expect(record.calculate_effective_reach).to be_nil
    end
  end

  describe '#calculate_compression_efficiency using arctangent' do
    it 'calculates efficiency using arctangent smoothing' do
      efficiency = record.calculate_compression_efficiency
      # Uses Math.atan for smooth efficiency curve
      expect(efficiency).to be_between(0, 1)
    end

    it 'returns nil when dimensions missing' do
      record.width = nil
      expect(record.calculate_compression_efficiency).to be_nil
    end

    it 'provides smooth scaling between 0 and 1' do
      record1 = create(:record, user: user, width: 1, height: 1, depth: 1)
      record2 = create(:record, user: user, width: 100, height: 100, depth: 100)
      
      eff1 = record1.calculate_compression_efficiency
      eff2 = record2.calculate_compression_efficiency
      
      # Both should be in valid range
      expect(eff1).to be_between(0, 1)
      expect(eff2).to be_between(0, 1)
    end
  end

  describe '#calculate_alignment_angle using atan2' do
    it 'calculates alignment angle using atan2 for proper quadrant handling' do
      angle = record.calculate_alignment_angle(30, 15)
      # Uses Math.atan2 for robust angle calculation
      expect(angle).to be_a(Float)
    end

    it 'returns nil when dimensions missing' do
      record.width = nil
      expect(record.calculate_alignment_angle(20, 10)).to be_nil
    end

    it 'handles different quadrants with atan2' do
      # atan2 correctly handles all four quadrants
      angle1 = record.calculate_alignment_angle(5, 5)
      angle2 = record.calculate_alignment_angle(-5, 5)
      angle3 = record.calculate_alignment_angle(-5, -5)
      
      expect(angle1).not_to eq(angle2)
      expect(angle2).not_to eq(angle3)
    end
  end
end
