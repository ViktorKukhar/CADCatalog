# frozen_string_literal: true

##
# DataAggregator
#
# Service class for performing efficient database aggregation operations to optimize data analysis.
# Uses Rails ActiveRecord aggregation functions for group queries, statistics generation, and
# report creation without loading all records into memory.
#
# All aggregation operations use database-level grouping and calculations for optimal performance.
#
# Examples:
#   aggregator = DataAggregator.new
#   aggregator.records_by_tag
#   aggregator.average_dimensions_by_tag
#   aggregator.software_usage_frequency(limit: 10)
#
class DataAggregator
  # Aggregate record count by tag
  #
  # Returns array of hashes with tag name and count
  # Example: [{name: "CAD", count: 45}, {name: "3D", count: 32}]
  #
  def records_by_tag
    Tag.left_outer_joins(:records)
       .group('tags.id', 'tags.name')
       .select('tags.name', 'COUNT(records.id) as record_count')
       .order('record_count DESC')
       .map { |tag| { name: tag.name, count: tag.record_count } }
  end

  # Aggregate record count by user
  #
  # Returns array of hashes with user name and count
  # Includes users with no records (zero count)
  #
  def records_by_user
    User.left_outer_joins(:records)
        .group('users.id')
        .select("CONCAT(users.first_name, ' ', users.last_name) as user_name", 
                'COUNT(records.id) as record_count')
        .order('record_count DESC')
        .map { |user| { name: user.user_name, count: user.record_count } }
  end

  # Calculate average dimensions (width, height, depth) across all records
  #
  # Returns hash with average width, height, depth
  # Example: {width: 120.5, height: 90.2, depth: 75.3}
  #
  def average_dimensions
    stats = Record.where.not(width: nil, height: nil, depth: nil)
                  .select('AVG(width) as avg_width, 
                           AVG(height) as avg_height, 
                           AVG(depth) as avg_depth')
                  .first

    {
      width: stats&.avg_width&.round(2) || 0,
      height: stats&.avg_height&.round(2) || 0,
      depth: stats&.avg_depth&.round(2) || 0
    }
  end

  # Calculate average dimensions grouped by tag
  #
  # Returns array of hashes with tag name and average dimensions
  # Useful for understanding size patterns by category
  #
  def average_dimensions_by_tag
    Tag.joins(:records)
       .where.not(records: { width: nil, height: nil, depth: nil })
       .group('tags.id', 'tags.name')
       .select('tags.name',
               'AVG(records.width) as avg_width',
               'AVG(records.height) as avg_height',
               'AVG(records.depth) as avg_depth',
               'COUNT(records.id) as record_count')
       .order('record_count DESC')
       .map do |tag|
         {
           name: tag.name,
           width: tag.avg_width&.round(2) || 0,
           height: tag.avg_height&.round(2) || 0,
           depth: tag.avg_depth&.round(2) || 0,
           count: tag.record_count
         }
       end
  end

  # Get dimension range statistics (min/max)
  #
  # Returns hash with minimum and maximum dimensions
  # Useful for understanding dataset bounds
  #
  def dimension_range_statistics
    stats = Record.where.not(width: nil, height: nil, depth: nil)
                  .select('MIN(width) as min_width, MAX(width) as max_width,
                           MIN(height) as min_height, MAX(height) as max_height,
                           MIN(depth) as min_depth, MAX(depth) as max_depth')
                  .first

    {
      width: {
        min: stats&.min_width&.round(2) || 0,
        max: stats&.max_width&.round(2) || 0
      },
      height: {
        min: stats&.min_height&.round(2) || 0,
        max: stats&.max_height&.round(2) || 0
      },
      depth: {
        min: stats&.min_depth&.round(2) || 0,
        max: stats&.max_depth&.round(2) || 0
      }
    }
  end

  # Aggregate software performance metrics
  #
  # Returns hash with overall performance statistics
  # Example: {avg_rating: 7.5, max_rating: 9.8, total_usage: 450}
  #
  def software_performance_stats
    stats = Software.select('COUNT(id) as total_count',
                           'AVG(performance_rating) as avg_rating',
                           'MAX(performance_rating) as max_rating',
                           'MIN(performance_rating) as min_rating',
                           'AVG(efficiency_score) as avg_efficiency')
                    .first

    {
      total_count: stats&.total_count || 0,
      avg_rating: stats&.avg_rating&.round(2) || 0,
      max_rating: stats&.max_rating&.round(2) || 0,
      min_rating: stats&.min_rating&.round(2) || 0,
      avg_efficiency: stats&.avg_efficiency&.round(2) || 0
    }
  end

  # Get software usage frequency
  #
  # Returns array of softwares with record count, ordered by most used
  # Useful for popular software identification
  # Options:
  #   - limit: number of results (default: nil, returns all)
  #   - min_usage: minimum usage count filter (default: 0)
  #
  def software_usage_frequency(limit: nil, min_usage: 0)
    query = Software.joins(:records)
                    .group('softwares.id', 'softwares.name')
                    .select('softwares.id', 'softwares.name', 'COUNT(records.id) as usage_count')
                    .where('COUNT(records.id) >= ?', min_usage)
                    .order('usage_count DESC')

    query = query.limit(limit) if limit.present?

    query.map { |software| { id: software.id, name: software.name, count: software.usage_count } }
  end

  # Get complexity score distribution
  #
  # Returns array of complexity ranges with record counts
  # Useful for understanding dataset complexity profile
  #
  def complexity_score_distribution
    buckets = [
      { range: '0-2', condition: 'complexity_score >= 0 AND complexity_score < 2' },
      { range: '2-4', condition: 'complexity_score >= 2 AND complexity_score < 4' },
      { range: '4-6', condition: 'complexity_score >= 4 AND complexity_score < 6' },
      { range: '6-8', condition: 'complexity_score >= 6 AND complexity_score < 8' },
      { range: '8-10', condition: 'complexity_score >= 8 AND complexity_score <= 10' }
    ]

    buckets.map do |bucket|
      count = Record.where(bucket[:condition]).count
      { range: bucket[:range], count: count }
    end
  end

  # Get tag co-occurrence (which tags appear together most often)
  #
  # Returns array of tag pair frequencies
  # Useful for tag recommendations and categorization insights
  # Limit specifies number of results
  #
  def tag_cooccurrence(limit: 10)
    # Find tag pairs that appear on the same record
    query = <<~SQL
      SELECT t1.name as tag1, t2.name as tag2, COUNT(*) as co_count
      FROM tags t1
      JOIN records_tags rt1 ON t1.id = rt1.tag_id
      JOIN records_tags rt2 ON rt1.record_id = rt2.record_id
      JOIN tags t2 ON t2.id = rt2.tag_id
      WHERE t1.id < t2.id
      GROUP BY t1.name, t2.name
      ORDER BY co_count DESC
      LIMIT ?
    SQL

    results = ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.send(:sanitize_sql_array, [query, limit])
    )

    results.to_a.map do |row|
      { tag1: row['tag1'], tag2: row['tag2'], count: row['co_count'] }
    end
  end

  # Get user contribution statistics
  #
  # Returns array with per-user statistics (records, avg complexity, etc.)
  #
  def user_contribution_stats
    User.joins(:records)
        .group('users.id', 'users.first_name', 'users.last_name')
        .select("CONCAT(users.first_name, ' ', users.last_name) as user_name",
                'COUNT(records.id) as record_count',
                'AVG(records.complexity_score) as avg_complexity',
                'MAX(records.complexity_score) as max_complexity')
        .order('record_count DESC')
        .map do |user|
          {
            name: user.user_name,
            record_count: user.record_count,
            avg_complexity: user.avg_complexity&.round(2) || 0,
            max_complexity: user.max_complexity&.round(2) || 0
          }
        end
  end

  # Get creation timeline (records created per day/week/month)
  #
  # Returns aggregated records by date period
  # Options:
  #   - period: 'day', 'week', or 'month' (default: 'month')
  #   - limit: number of periods to return
  #
  def creation_timeline(period: 'month', limit: 12)
    case period
    when 'day'
      date_format = "%Y-%m-%d"
      order_format = 'DATE(records.created_at) DESC'
    when 'week'
      date_format = "%Y-W%W"
      order_format = 'WEEK(records.created_at) DESC'
    else # month
      date_format = "%Y-%m"
      order_format = 'DATE_TRUNC(\'month\', records.created_at) DESC'
    end

    query = Record.select("DATE_FORMAT(records.created_at, '#{date_format}') as period",
                         'COUNT(*) as record_count')
                  .group("DATE_FORMAT(records.created_at, '#{date_format}')")
                  .order(order_format)
                  .limit(limit)

    query.reverse.map { |record| { period: record.period, count: record.record_count } }
  end

  # Get most tagged records
  #
  # Returns records with highest tag count
  # Useful for identifying well-categorized vs. orphaned records
  #
  def most_tagged_records(limit: 10)
    Record.left_joins(:tags)
          .group('records.id', 'records.title')
          .select('records.id', 'records.title', 'COUNT(tags.id) as tag_count')
          .order('tag_count DESC')
          .limit(limit)
          .map { |record| { id: record.id, title: record.title, tag_count: record.tag_count } }
  end

  # Get records with least tags (potential data quality issue)
  #
  # Returns records with lowest tag count
  #
  def least_tagged_records(limit: 10)
    Record.left_joins(:tags)
          .group('records.id', 'records.title')
          .select('records.id', 'records.title', 'COUNT(tags.id) as tag_count')
          .having('COUNT(tags.id) < ?', 2)
          .order('tag_count ASC')
          .limit(limit)
          .map { |record| { id: record.id, title: record.title, tag_count: record.tag_count } }
  end

  # Get record count statistics
  #
  # Returns overall counts and rates
  #
  def record_count_statistics
    total_count = Record.count
    tagged_count = Record.joins(:tags).distinct.count
    untagged_count = total_count - tagged_count

    {
      total: total_count,
      tagged: tagged_count,
      untagged: untagged_count,
      tagged_percentage: total_count.zero? ? 0 : ((tagged_count.to_f / total_count) * 100).round(2)
    }
  end

  # Get average records per tag
  #
  # Returns statistics about tag distribution
  #
  def tag_distribution_stats
    total_tags = Tag.count
    total_associations = Record.joins(:tags).count

    avg_per_tag = total_tags.zero? ? 0 : (total_associations.to_f / total_tags).round(2)
    avg_per_record = Record.count.zero? ? 0 : (total_associations.to_f / Record.count).round(2)

    {
      total_tags: total_tags,
      total_associations: total_associations,
      avg_records_per_tag: avg_per_tag,
      avg_tags_per_record: avg_per_record
    }
  end

  # Generate comprehensive dashboard statistics
  #
  # Returns hash with all key metrics for dashboard display
  #
  def dashboard_summary
    {
      records: record_count_statistics,
      tags: tag_distribution_stats,
      software: software_performance_stats,
      dimensions: average_dimensions,
      complexity: {
        avg: Record.where.not(complexity_score: nil).average(:complexity_score)&.round(2) || 0,
        distribution: complexity_score_distribution
      },
      top_tags: records_by_tag.first(5),
      top_software: software_usage_frequency(limit: 5),
      top_contributors: user_contribution_stats.first(5),
      top_tagged_records: most_tagged_records(limit: 5)
    }
  end
end
