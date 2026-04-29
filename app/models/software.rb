class Software < ApplicationRecord
  has_and_belongs_to_many :records

  validates :name, presence: true, uniqueness: true
  validates :performance_rating, :efficiency_score, :processing_factor, 
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  before_save :calculate_performance_metrics

  # Calculates efficiency using logarithmic scale
  # Logarithm compresses large variations in software performance into meaningful scores
  # Useful when efficiency can range from <1% to >100% improvement
  def calculate_efficiency_from_processing_time(baseline_time, optimized_time)
    return nil if baseline_time.nil? || optimized_time.nil?
    return nil if baseline_time <= 0 || optimized_time <= 0

    # Calculate speedup factor
    speedup = baseline_time / optimized_time

    # Use logarithm to create a meaningful efficiency score
    # log(speedup) transforms multiplicative improvements to additive scores
    self.efficiency_score = Math.log(speedup + 1)
    self.efficiency_score
  end

  # Calculates performance rating using exponential growth model
  # Exponential functions are ideal for rating systems where small improvements 
  # at lower levels matter less than at higher levels
  def calculate_performance_rating(base_score, growth_factor = 0.1)
    return nil if base_score.nil?

    # Use exponential function: e^(base_score * growth_factor)
    # This creates a rating that exponentially increases with base score
    # Useful for non-linear performance scaling
    self.performance_rating = Math.exp(base_score * growth_factor)
    self.performance_rating
  end

  # Calculates processing factor using trigonometric smoothing
  # Sine/cosine functions provide smooth, cyclical variation 
  # Useful for modeling periodic performance variations
  def calculate_processing_factor(usage_hours)
    return nil if usage_hours.nil?

    # Model daily performance cycle using sine function
    # Creates a smooth variation between 0.8 and 1.2 based on usage patterns
    cycle = (usage_hours % 24) * (Math::PI / 12)  # Convert to radians for 24-hour cycle
    base_factor = Math.sin(cycle) * 0.2 + 1.0
    
    # Apply logarithmic dampening for long-term fatigue
    # log prevents extreme fluctuations over time
    fatigue = Math.log(usage_hours / 1000.0 + 1) * 0.05
    
    self.processing_factor = (base_factor - fatigue).round(4)
    self.processing_factor
  end

  # Calculates the angle of optimization in parameter space
  # Uses arctangent to determine best optimization direction
  def calculate_optimization_angle(current_performance, target_performance)
    return nil if current_performance.nil? || target_performance.nil?

    performance_delta = target_performance - current_performance
    baseline = 100.0

    # Use arctangent to determine smooth optimization curve
    # atan bounds the result naturally, preventing extreme angle values
    optimization_angle = Math.atan(performance_delta / baseline)
    
    optimization_angle * 180 / Math::PI  # Convert to degrees
  end

  # Calculates harmonic distortion or quality degradation over time using sine wave
  def calculate_quality_degradation(days_in_operation)
    return nil if days_in_operation.nil?

    # Model quality as damped sine wave (gradual degradation with oscillation)
    # Demonstrates practical use of trigonometric functions for modeling real-world phenomena
    time_factor = days_in_operation / 365.0  # Normalize to years
    
    # Harmonic component: oscillates between 0 and 1 over 6-month cycles
    harmonic = Math.sin(2 * Math::PI * time_factor * 2) * 0.1 + 0.05
    
    # Exponential decay component: quality decays exponentially
    decay = Math.exp(-0.1 * time_factor)
    
    # Combined quality score (1.0 = perfect, 0.0 = failed)
    quality_score = decay - harmonic
    [quality_score, 0.0].max  # Ensure non-negative
  end

  # Performs complex resonance analysis using advanced mathematical operations
  # Demonstrates heavy computational operations with elegant mathematical expressions
  def calculate_resonance_characteristics(cpu_frequency_ghz, memory_bandwidth_gbps)
    return nil if cpu_frequency_ghz.nil? || memory_bandwidth_gbps.nil?

    # Calculate resonance frequency using LC circuit analogy
    # This is a practical application of heavy math operations in software analysis
    inductance = 1.0 / cpu_frequency_ghz
    capacitance = memory_bandwidth_gbps / 1000.0
    
    resonant_freq = 1.0 / (2 * Math::PI * Math.sqrt(inductance * capacitance))
    
    # Calculate phase angle using arctangent (useful for identifying bottlenecks)
    impedance_angle = Math.atan(cpu_frequency_ghz / memory_bandwidth_gbps) * 180 / Math::PI
    
    {
      resonant_frequency: resonant_freq.round(2),
      phase_angle: impedance_angle.round(2),
      quality_factor: cpu_frequency_ghz * memory_bandwidth_gbps / (2 * Math::PI * resonant_freq)
    }
  end

  private

  def calculate_performance_metrics
    # Auto-calculate metrics if base values are provided
    # This keeps metrics in sync automatically
    if processing_factor.nil?
      calculate_processing_factor(0)
    end
  end
end

