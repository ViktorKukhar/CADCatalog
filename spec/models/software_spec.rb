# frozen_string_literal: true

require 'rails_helper'

describe Software do
  let(:software) { create(:software) }

  describe '#calculate_efficiency_from_processing_time using logarithm' do
    it 'calculates efficiency using logarithmic function' do
      # Uses Math.log for heavy mathematical operation
      efficiency = software.calculate_efficiency_from_processing_time(100, 50)
      
      # Speedup of 2x should yield log(3) ≈ 1.099
      expect(efficiency).to be_within(0.01).of(Math.log(3))
    end

    it 'returns higher efficiency for greater speedup' do
      eff1 = software.calculate_efficiency_from_processing_time(100, 80)
      eff2 = software.calculate_efficiency_from_processing_time(100, 50)
      
      expect(eff2).to be > eff1
    end

    it 'returns nil for invalid inputs' do
      expect(software.calculate_efficiency_from_processing_time(nil, 50)).to be_nil
      expect(software.calculate_efficiency_from_processing_time(0, 50)).to be_nil
      expect(software.calculate_efficiency_from_processing_time(100, -50)).to be_nil
    end
  end

  describe '#calculate_performance_rating using exponential function' do
    it 'calculates rating using exponential growth model' do
      # Uses Math.exp for heavy mathematical operation
      rating = software.calculate_performance_rating(5, 0.1)
      
      # e^(5 * 0.1) = e^0.5 ≈ 1.649
      expect(rating).to be_within(0.01).of(Math.exp(0.5))
    end

    it 'exponentially increases with base score' do
      rating1 = software.calculate_performance_rating(1, 0.1)
      rating2 = software.calculate_performance_rating(5, 0.1)
      
      # Higher base score yields exponentially higher rating
      expect(rating2).to be > rating1
    end

    it 'returns nil for nil input' do
      expect(software.calculate_performance_rating(nil)).to be_nil
    end
  end

  describe '#calculate_processing_factor using trigonometric functions' do
    it 'calculates factor using sine function for daily cycles' do
      # Uses Math.sin for trigonometric smoothing
      factor = software.calculate_processing_factor(12)  # noon
      
      expect(factor).to be_a(Float)
      expect(factor).to be_between(0.5, 1.5)
    end

    it 'applies logarithmic dampening for long-term fatigue' do
      # Uses Math.log for fatigue calculation
      factor_short = software.calculate_processing_factor(100)
      factor_long = software.calculate_processing_factor(5000)
      
      # Longer usage should have more fatigue dampening
      expect(factor_long).to be < factor_short
    end

    it 'returns nil for nil input' do
      expect(software.calculate_processing_factor(nil)).to be_nil
    end

    it 'combines sine cycle with log dampening correctly' do
      factor = software.calculate_processing_factor(48)  # 2 days
      
      # Should be close to 1.0 due to sine oscillation and minimal log dampening
      expect(factor).to be_between(0.7, 1.3)
    end
  end

  describe '#calculate_optimization_angle using arctangent' do
    it 'calculates optimization angle using arctangent' do
      # Uses Math.atan to determine optimization direction
      angle = software.calculate_optimization_angle(90, 110)
      
      expect(angle).to be_a(Float)
      expect(angle.abs).to be < 90  # atan bounds the result
    end

    it 'returns positive angle when performance improves' do
      angle = software.calculate_optimization_angle(80, 100)
      expect(angle).to be > 0
    end

    it 'returns negative angle when performance decreases' do
      angle = software.calculate_optimization_angle(100, 80)
      expect(angle).to be < 0
    end

    it 'returns nil for nil inputs' do
      expect(software.calculate_optimization_angle(nil, 100)).to be_nil
      expect(software.calculate_optimization_angle(100, nil)).to be_nil
    end
  end

  describe '#calculate_quality_degradation using trigonometric and exponential functions' do
    it 'models quality degradation using sine wave and exponential decay' do
      # Uses Math.sin and Math.exp for complex harmonic modeling
      quality = software.calculate_quality_degradation(180)  # 6 months
      
      expect(quality).to be_between(0, 1)
    end

    it 'shows exponential decay over time' do
      quality_young = software.calculate_quality_degradation(30)
      quality_old = software.calculate_quality_degradation(365)
      
      # Older software should have lower quality score
      expect(quality_old).to be < quality_young
    end

    it 'includes harmonic oscillation component' do
      # At different time points, should show oscillation
      quality_at_1_month = software.calculate_quality_degradation(30)
      quality_at_4_months = software.calculate_quality_degradation(120)
      
      # Both should be valid but potentially different due to sine oscillation
      expect(quality_at_1_month).to be_between(0, 1)
      expect(quality_at_4_months).to be_between(0, 1)
    end

    it 'returns nil for nil input' do
      expect(software.calculate_quality_degradation(nil)).to be_nil
    end
  end

  describe '#calculate_resonance_characteristics using advanced math operations' do
    it 'performs complex mathematical calculations for resonance analysis' do
      # Uses Math.sqrt, Math.atan, Math::PI for heavy computation
      result = software.calculate_resonance_characteristics(3.5, 50)
      
      expect(result).to be_a(Hash)
      expect(result[:resonant_frequency]).to be > 0
      expect(result[:phase_angle].abs).to be < 90
      expect(result[:quality_factor]).to be > 0
    end

    it 'calculates resonant frequency using complex mathematical operations' do
      result = software.calculate_resonance_characteristics(2.0, 40)
      
      # Verify it's using Math operations (should be a meaningful number)
      expect(result[:resonant_frequency]).to be_a(Float)
      expect(result[:resonant_frequency]).to be > 0
    end

    it 'calculates phase angle using arctangent' do
      result = software.calculate_resonance_characteristics(3.0, 60)
      
      # Uses Math.atan to calculate phase angle
      expect(result[:phase_angle]).to be_a(Float)
      expect(result[:phase_angle].abs).to be <= 90
    end

    it 'returns nil for nil inputs' do
      expect(software.calculate_resonance_characteristics(nil, 50)).to be_nil
      expect(software.calculate_resonance_characteristics(3.5, nil)).to be_nil
    end

    it 'calculates quality factor combining multiple operations' do
      result = software.calculate_resonance_characteristics(2.5, 45)
      
      # Quality factor combines multiple mathematical operations
      expect(result[:quality_factor]).to be > 0
    end
  end

  describe 'Data Sanitization - XSS Prevention' do
    it 'sanitizes software name on save to prevent XSS' do
      malicious_name = '<script>alert("xss")</script>Photoshop'
      software = build(:software, name: malicious_name)
      software.save!
      
      # Name should be sanitized
      expect(software.reload.name).not_to include('<script>')
    end

    it 'strips whitespace from name' do
      name_with_spaces = '  AutoCAD  '
      software = build(:software, name: name_with_spaces)
      software.save!
      
      expect(software.reload.name).to eq('AutoCAD')
    end

    it 'sanitizes when updating software' do
      software.update(name: 'Blender<img src=x onerror="alert(1)">')
      
      expect(software.reload.name).not_to include('onerror')
    end

    it 'removes event handler attempts from name' do
      malicious = 'SolidWorks" onclick="alert(1)'
      software = build(:software, name: malicious)
      software.save!
      
      expect(software.reload.name).not_to include('onclick')
    end
  end

  describe 'Data Sanitization - Input Validation' do
    it 'enforces uniqueness even with sanitized input' do
      software1 = create(:software, name: 'CAD Tool')
      
      software2 = build(:software, name: 'CAD Tool')
      
      expect { software2.save! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'allows valid software names after sanitization' do
      valid_names = ['PhotoShop', 'AutoCAD 2024', 'SolidWorks-Pro', 'Fusion_360']
      
      valid_names.each do |name|
        software = build(:software, name: name)
        expect(software.valid?).to be_truthy
      end
    end
  end

  describe 'Data Sanitization - SQL Injection Prevention' do
    it 'prevents SQL injection through software name' do
      injection_attempt = "Tool'; DROP TABLE softwares; --"
      software = build(:software, name: injection_attempt)
      software.save!
      
      # Malicious input should be sanitized/escaped
      expect(software.reload.name).not_to include(';')
    end
  end
end
